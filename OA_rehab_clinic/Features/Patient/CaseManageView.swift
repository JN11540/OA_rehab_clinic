import SwiftUI
import Foundation

class CaseManageViewModel: ObservableObject {
    @Published var patient: Patient
    @Published var calendarRefreshTrigger = false
    @Published var assessmentUpdateTrigger = false
    
    init(patient: Patient) {
        self.patient = patient
    }
    
    func refreshPatientData() {
        DispatchQueue.main.async {
            if let updatedPatient = PatientStore.shared.patients.first(where: { $0.id == self.patient.id }) {
                self.patient = updatedPatient
                self.calendarRefreshTrigger.toggle()
                self.assessmentUpdateTrigger.toggle()
            }
        }
    }
}

struct CaseManageView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var userModel: UserModel
    @EnvironmentObject private var scheduleStore: TrainingScheduleStore
    @EnvironmentObject private var menuStore: TrainingMenuStore
    @StateObject private var assessmentStore = AssessmentStore.shared
    @StateObject private var viewModel: CaseManageViewModel
    @State private var currentDate = Date()  // 控制當前顯示的月份
    @State private var showingAddNote = false
    @State private var selectedDateRange: (start: Date, end: Date)?
    @State private var isEditingCalendar = false
    
    init(patient: Patient) {
        _viewModel = StateObject(wrappedValue: CaseManageViewModel(patient: patient))
    }
    
    // 確保所有評估類型都被包含
    private var allAssessments: [Assessment] {
        return viewModel.patient.assessments
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                GradientBackground(
                    startColor: Color(red: 0.47, green: 0.84, blue: 0.98),
                    endColor: Color(red: 0.72, green: 0.89, blue: 0.59)
                )
                .ignoresSafeArea(edges: .all)
                
                VStack(spacing: 30) {
                    // Navigation header
                    NavigationHeader(
                        patient: viewModel.patient,
                        pageTitle: ""
                    )
                    
                    // Content Grid
                    Grid(alignment: .leading, horizontalSpacing: 15, verticalSpacing: 30) {
                        // Patient info section
                        GridRow {
                            PatientInfoCard(patient: viewModel.patient)
                                .gridCellColumns(4)
                            PatientActionButtons(patient: viewModel.patient)
                                .environmentObject(scheduleStore)
                                .environmentObject(menuStore)
                                .environmentObject(userModel)
                                .gridCellColumns(1)
                        }
                        .frame(height: UIScreen.main.bounds.height / 5)
                        
                        // Main content section
                        GridRow {
                            // 左側備註區域
                            NotesSection(
                                patient: viewModel.patient,
                                showingAddNote: $showingAddNote
                            )
                            .gridCellColumns(1)
                            
                            // 中間訓練列表區域
                            // 注意：傳遞 currentDate 到 TrainingListCard，使其只顯示當前月份的訓練和評估
                            TrainingListCard(
                                hasTrainingMenu: true,
                                assessments: allAssessments,
                                patient: viewModel.patient,
                                currentDate: currentDate,  // 傳遞當前日期，使 TrainingListCard 只顯示當前月份的內容
                                onDeleteAssessment: { assessment in
                                    // 使用 AssessmentStore 來處理刪除當月的評估日期
                                    AssessmentStore.shared.removeDatesFromAssessment(assessment, inMonthOf: currentDate, for: viewModel.patient.id)
                                    
                                    // 強制更新月曆視圖
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                        viewModel.refreshPatientData()
                                        viewModel.calendarRefreshTrigger.toggle()
                                        viewModel.assessmentUpdateTrigger.toggle()
                                    }
                                }
                            )
                            .id("\(viewModel.calendarRefreshTrigger)_\(viewModel.assessmentUpdateTrigger)_\(currentDate.timeIntervalSince1970)")
                            .environmentObject(scheduleStore)
                            .environmentObject(menuStore)
                            .gridCellColumns(2)
                            
                            // 右側月曆區域
                            VStack(spacing: 0) {
                                UnifiedCalendarContainer(
                                    currentDate: $currentDate,  // 雙向綁定當前日期，當月份變化時會更新 TrainingListCard
                                    patient: viewModel.patient,
                                    selectedMenu: nil,
                                    selectedAssessments: [],  // 空集合才會觸發混合顯示模式
                                    isEditable: false
                                )
                                .id("\(viewModel.calendarRefreshTrigger)_\(viewModel.assessmentUpdateTrigger)")
                                .environmentObject(scheduleStore)
                                .environmentObject(assessmentStore)
                                
                                // 顯示訓練安排
                                ScrollView {
                                    VStack(alignment: .leading, spacing: 8) {
                                        ForEach(scheduleStore.getSchedulesForPatient(viewModel.patient.id)) { schedule in
                                            if let menu = menuStore.getMenu(by: schedule.menuId) {
                                                TrainingScheduleCard(
                                                    menu: menu,
                                                    schedule: schedule,
                                                    onDelete: {
                                                        withAnimation {
                                                            scheduleStore.removeSchedule(schedule)
                                                            // 強制更新月曆視圖
                                                            DispatchQueue.main.async {
                                                                viewModel.calendarRefreshTrigger.toggle()
                                                            }
                                                        }
                                                    }
                                                )
                                            }
                                        }
                                    }
                                    .padding(.top, 8)
                                }
                                .frame(maxHeight: 200)
                                
                                NavigationLink {
                                    EditTrainingCalendarView(patient: viewModel.patient)
                                        .environmentObject(scheduleStore)
                                        .environmentObject(menuStore)
                                        .environmentObject(userModel)
                                } label: {
                                    HStack {
                                        Image(systemName: "square.and.pencil")
                                        Text("編輯訓練月曆")
                                    }
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(Color.orange)
                                    .cornerRadius(8)
                                }
                                .padding(.horizontal, 24)
                                .padding(.vertical, 20)
                            }
                            .gridCellColumns(2)
                        }
                        .frame(height: fixedHeight)
                    }
                    .padding(.horizontal, 30)
                }
            }
            .sheet(isPresented: $showingAddNote) {
                EditNoteView(patientId: viewModel.patient.id)
            }
            .onAppear {
                viewModel.refreshPatientData()
                scheduleStore.reloadSchedules()
                
                // 添加通知觀察者
                NotificationCenter.default.addObserver(
                    forName: .assessmentsDidUpdate,
                    object: nil,
                    queue: .main
                ) { _ in
                    DispatchQueue.main.async {
                        viewModel.refreshPatientData()
                        viewModel.calendarRefreshTrigger.toggle()
                        viewModel.assessmentUpdateTrigger.toggle()
                    }
                }
            }
            .onChange(of: scheduleStore.schedules) { _ in
                viewModel.refreshPatientData()
            }
            .onChange(of: assessmentStore.assessments) { _ in
                viewModel.refreshPatientData()
            }
            .onChange(of: viewModel.patient) { _ in
                DispatchQueue.main.async {
                    viewModel.calendarRefreshTrigger.toggle()
                    viewModel.assessmentUpdateTrigger.toggle()
                }
            }
            // 監聽 currentDate 變化，當月份變化時更新訓練列表
            .onChange(of: currentDate) { _ in
                // 強制更新訓練列表視圖，使其顯示新月份的訓練和評估
                DispatchQueue.main.async {
                    viewModel.calendarRefreshTrigger.toggle()
                }
            }
        }
        .environmentObject(scheduleStore)
        .environmentObject(menuStore)
        .environmentObject(userModel)
    }
    
    private let fixedHeight: CGFloat = 450  // 與 EditTrainingCalendarView 相同的高度
}


// MARK: - Training Item
struct TrainingItem: View {
    let title: String
    let tags: [String]
    
    var body: some View {
        HStack {
            RoundedRectangle(cornerRadius: 4)
                .fill(title.contains("WOMAC") ? Color.blue.opacity(0.2) : Color.orange.opacity(0.2))
                .frame(width: 24, height: 24)
            
            Text(title)
            
            ForEach(tags, id: \.self) { tag in
                Text(tag)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(4)
            }
        }
    }
}

// MARK: - Training Schedule List Item
struct ScheduleListItem: View {
    let schedule: TrainingSchedule
    let menu: TrainingMenu
    let isExpanded: Bool
    let onToggle: () -> Void
    var onDelete: (() -> Void)? = nil
    @State private var showingDeleteAlert = false
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd"
        return formatter
    }()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 標題列
            HStack {
                Circle()
                    .fill(menu.color)
                    .frame(width: 20, height: 20)
                
                Text(menu.title)
                    .font(.system(size: 16, weight: .medium))
                
                Text(schedule.formatTopThreeDates())
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                
                Spacer()
                
                // 時段標籤
                ForEach(Array(schedule.timeSlots), id: \.self) { slot in
                    Text(slot)
                        .font(.system(size: 14))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(4)
                }
                
                Button(action: onToggle) {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.gray)
                }
            }
            
            // 展開的運動內容
            if isExpanded {
                Divider()
                ForEach(menu.exercises) { exercise in
                    CompactExerciseListItem(parameters: exercise)
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .contentShape(Rectangle()) // 確保整個區域都可以接收手勢
        .swipeActions(edge: .trailing) {
            // if let onDelete = onDelete {
                Button(role: .destructive) {
                    showingDeleteAlert = true
                } label: {
                    Label("刪除", systemImage: "trash")
                }
                .tint(.red)
            // }
        }
        .contextMenu {
            // if let onDelete = onDelete {
                Button(role: .destructive) {
                    showingDeleteAlert = true
                } label: {
                    Label("刪除訓練安排", systemImage: "trash")
                }
            // }
        }
        .alert("確認刪除", isPresented: $showingDeleteAlert) {
            Button("取消", role: .cancel) {}
            Button("刪除", role: .destructive) {
                if let onDelete = onDelete {
                    withAnimation {
                        onDelete()
                    }
                }
            }
        } message: {
            Text("確定要刪除這個訓練安排嗎？")
        }
    }
}

// 訓練安排卡片
struct TrainingScheduleCard: View {
    let menu: TrainingMenu
    let schedule: TrainingSchedule
    let onDelete: () -> Void
    @State private var showingDeleteAlert = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .center, spacing: 8) {
                // 左側菜單標識和名稱
                HStack(spacing: 8) {
                    Circle()
                        .fill(menu.color)
                        .frame(width: 20, height: 20)
                    
                    Text(menu.title)
                        .font(.system(size: 16, weight: .medium))
                }
                
                Spacer()
                
                // 右側時段標籤
                ForEach(Array(schedule.timeSlots), id: \.self) { slot in
                    Text(slot)
                        .font(.system(size: 14))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                }
                
                // 最右側日期標籤
                Text(schedule.formatTopThreeDates())
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
            }
            
            DisclosureGroup {
                VStack(spacing: 2) {
                    ForEach(menu.exercises) { exercise in
                        CompactExerciseListItem(parameters: exercise)
                    }
                }
                .padding(.vertical, 2)
            } label: {
                Text("查看訓練內容")
                    .font(.system(size: 14))
                    .foregroundColor(.blue)
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
        // 將 contextMenu 移到整個 VStack 外部，使整個卡片區域都能響應長按
        .contentShape(Rectangle()) // 確保整個區域都可以接收手勢
        .contextMenu {
            Button(role: .destructive) {
                showingDeleteAlert = true
            } label: {
                Label("刪除訓練安排", systemImage: "trash")
            }
        }
        // 添加左滑刪除功能
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                showingDeleteAlert = true
            } label: {
                Label("刪除", systemImage: "trash")
            }
            .tint(.red)
        }
        .alert("確認刪除", isPresented: $showingDeleteAlert) {
            Button("取消", role: .cancel) {}
            Button("刪除", role: .destructive) {
                onDelete()
            }
        } message: {
            Text("確定要刪除這個訓練安排嗎？")
        }
    }
}

// 日期範圍格式化
private extension TrainingSchedule {
    var formattedDateRange: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM/dd"
        let sortedDates = Array(dates).sorted()
        if sortedDates.count <= 3 {
            return sortedDates.map { dateFormatter.string(from: $0) }.joined(separator: ", ")
        } else {
            let topThree = sortedDates.prefix(3).map { dateFormatter.string(from: $0) }.joined(separator: ", ")
            return "\(topThree)..."
        }
    }
}

struct CaseManageView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            CaseManageView(
                patient: Patient.sample
            )
            .environmentObject(UserModel.shared)
            .environmentObject(TrainingScheduleStore.shared)
            .environmentObject(TrainingMenuStore.shared)
        }
        .previewLayout(.fixed(width: 1200, height: 800))
    }
}




import SwiftUI
import Foundation


struct TrainingListCard: View {
    private let fixedHeight: CGFloat = 450
    private let timeColors: [Color] = [.morning, .noon, .afternoon, .night]
    
    let hasTrainingMenu: Bool
    let assessments: [Assessment]
    let patient: Patient
    let currentDate: Date  // 新增：當前日期參數，用於過濾當月的訓練和評估
    var onDeleteAssessment: ((Assessment) -> Void)?
    @EnvironmentObject private var scheduleStore: TrainingScheduleStore
    @State private var expandedSchedules: Set<UUID> = []
    
    @State private var expandedAssessments: Set<String> = []
    
    init(
        hasTrainingMenu: Bool = false,
        assessments: [Assessment] = [],
        patient: Patient,
        currentDate: Date = Date(),  // 新增：當前日期參數，預設為當前日期
        onDeleteAssessment: ((Assessment) -> Void)? = nil
    ) {
        self.hasTrainingMenu = hasTrainingMenu
        self.assessments = assessments
        self.patient = patient
        self.currentDate = currentDate
        self.onDeleteAssessment = onDeleteAssessment
    }
    
    // 新增：檢查日期是否在當前月份
    private func isDateInCurrentMonth(_ date: Date) -> Bool {
        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.year, .month], from: date)
        let currentComponents = calendar.dateComponents([.year, .month], from: currentDate)
        
        return dateComponents.year == currentComponents.year && 
               dateComponents.month == currentComponents.month
    }
    
    // 新增：獲取當前月份的訓練安排
    private var currentMonthSchedules: [TrainingSchedule] {
        let patientSchedules = scheduleStore.getSchedulesForPatient(patient.id)
        let calendar = Calendar.current
        
        // Ensure referenceStartOfDay is the actual start of the month of self.currentDate
        let firstDayOfViewedMonthComponents = calendar.dateComponents([.year, .month], from: self.currentDate)
        guard let firstDayOfViewedMonth = calendar.date(from: firstDayOfViewedMonthComponents) else {
            return [] // Should not happen if self.currentDate is valid
        }
        let referenceStartOfDay = calendar.startOfDay(for: firstDayOfViewedMonth)
        
        return patientSchedules.filter { schedule in
            // 檢查是否有任何日期在當前月份（且在 referenceStartOfDay 或之後）
            return schedule.dates.contains { date in
                let scheduleDateStartOfDay = calendar.startOfDay(for: date)
                return isDateInCurrentMonth(date) && scheduleDateStartOfDay >= referenceStartOfDay
            }
        }
    }
    
    // 新增：獲取當前月份的評估
    private var currentMonthAssessments: [Assessment] {
        let calendar = Calendar.current
        
        // Ensure referenceStartOfDay is the actual start of the month of self.currentDate
        let firstDayOfViewedMonthComponents = calendar.dateComponents([.year, .month], from: self.currentDate)
        guard let firstDayOfViewedMonth = calendar.date(from: firstDayOfViewedMonthComponents) else {
            return [] // Should not happen if self.currentDate is valid
        }
        let referenceStartOfDay = calendar.startOfDay(for: firstDayOfViewedMonth)

        return assessments.filter { assessment in
            // 檢查是否有任何排程日期在當前月份（且在 referenceStartOfDay 或之後）
            let hasScheduledDatesInCurrentMonth = assessment.scheduledDates.contains { date in
                let scheduleDateStartOfDay = calendar.startOfDay(for: date)
                return isDateInCurrentMonth(date) && scheduleDateStartOfDay >= referenceStartOfDay
            }
            
            // 檢查是否有任何完成日期在當前月份
            let hasCompletedDatesInCurrentMonth = assessment.completedDates.contains { date in
                isDateInCurrentMonth(date)
            }
            
            return hasScheduledDatesInCurrentMonth || hasCompletedDatesInCurrentMonth
        }
    }
    
    // 訓練菜單視圖
    @ViewBuilder
    private func trainingMenuSection() -> some View {
        if currentMonthSchedules.isEmpty {  // 修改：使用當前月份的訓練安排
            emptyTrainingMenuView()
                .contentShape(Rectangle()) // 確保空白視圖也可以接收手勢
        } else {
            ForEach(currentMonthSchedules) { schedule in  // 修改：使用當前月份的訓練安排
                if let menu = TrainingMenuStore.shared.getMenu(by: schedule.menuId) {
                    // Create a binding for this specific schedule's expansion state
                    let isExpandedBinding = Binding<Bool>(
                        get: { self.expandedSchedules.contains(schedule.id) },
                        set: { isExpanding in
                            if isExpanding {
                                self.expandedSchedules.insert(schedule.id)
                            } else {
                                self.expandedSchedules.remove(schedule.id)
                            }
                        }
                    )
                    scheduleView(schedule: schedule, menu: menu, isExpanded: isExpandedBinding)
                }
            }
        }
    }
    
    // 單個訓練安排視圖
    private func scheduleView(schedule: TrainingSchedule, menu: TrainingMenu, isExpanded: Binding<Bool>) -> some View {
        let deleteAction = {
            withAnimation {
                scheduleStore.removeDatesFromSchedule(schedule.id, inMonthOf: self.currentDate)
            }
        }
        
        return VStack(spacing: 8) {
            HStack(spacing: 15) {
                VStack(alignment: .leading, spacing: 8) {
                    // 菜單標題
                    HStack(spacing: 8) {
                        Circle()
                            .fill(menu.color)
                            .frame(width: 20, height: 20)
                        Text(menu.title)
                            .font(.system(size: 16))
                    }
                    
                    // 日期顯示 - 只顯示當前月份的日期
                    Text(formatCurrentMonthDates(schedule))
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                    
                    // 時段標籤
                    HStack(spacing: 8) {
                        let timeSlots = ["早", "中", "下", "晚"]
                        ForEach(timeSlots, id: \.self) { slot in
                            let isSelected = schedule.timeSlots.contains(slot)
                            Text(slot)
                                .font(.system(size: 14))
                                .foregroundColor(isSelected ? .white : .gray)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 4)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(isSelected ? getTimeSlotColor(slot) : Color.gray.opacity(0.1))
                                )
                        }
                    }
                }
                
                Spacer()
                
                ToggleButton(
                    isExpanded: isExpanded, // Use the passed binding
                    color: .customTeal
                )
            }
            
            if isExpanded.wrappedValue { // Use the binding's wrappedValue
                ForEach(menu.exercises) { exercise in
                    CompactExerciseListItem(parameters: exercise)
                }
            }
        }
        .padding(.vertical, 12)
        .background(Color.white)
        .cornerRadius(12)
        .contentShape(Rectangle()) // 確保整個區域都可以接收手勢
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                deleteAction()
            } label: {
                Label("刪除", systemImage: "trash")
            }
            .tint(.red)
        }
        .contextMenu {
            Button(role: .destructive) {
                deleteAction()
            } label: {
                Label("刪除訓練安排", systemImage: "trash")
            }
        }
    }
    
    // 空的訓練菜單視圖
    private func emptyTrainingMenuView() -> some View {
        HStack(spacing: 15) {
            TrainingItemView(
                title: "本月尚未安排訓練菜單",  // 修改：更新文字以反映當前月份的未來訓練
                menuColor: nil,
                tags: ["早", "中", "下", "晚"],
                tagColors: Array(repeating: Color.gray.opacity(0.3), count: 4),
                isPlaceholder: true
            )
            Spacer()
            ToggleButton(
                isExpanded: .constant(false),
                color: .gray.opacity(0.3),
                isEnabled: false
            )
        }
        .padding(.vertical, 12)
        .background(Color.white)
        .cornerRadius(12)
    }
    
    // 新增：格式化當前月份的日期
    private func formatCurrentMonthDates(_ schedule: TrainingSchedule) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM/dd"
        let calendar = Calendar.current

        // Ensure referenceStartOfDay is the actual start of the month of self.currentDate
        let firstDayOfViewedMonthComponents = calendar.dateComponents([.year, .month], from: self.currentDate)
        guard let firstDayOfViewedMonth = calendar.date(from: firstDayOfViewedMonthComponents) else {
            return "日期錯誤" // Or handle appropriately
        }
        let referenceStartOfDay = calendar.startOfDay(for: firstDayOfViewedMonth)
        
        // 過濾出當前月份的日期（且在 referenceStartOfDay 或之後）
        let currentMonthDates = schedule.dates.filter { date in
            let scheduleDateStartOfDay = calendar.startOfDay(for: date)
            return isDateInCurrentMonth(date) && scheduleDateStartOfDay >= referenceStartOfDay
        }
        
        // 排序日期
        let sortedDates = currentMonthDates.sorted()
        
        if sortedDates.isEmpty {
            return "本月無未來訓練日期"
        } else if sortedDates.count <= 3 {
            return sortedDates.map { dateFormatter.string(from: $0) }.joined(separator: ", ")
        } else {
            let topThree = sortedDates.prefix(3).map { dateFormatter.string(from: $0) }.joined(separator: ", ")
            return "\(topThree)..."
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            // 訓練菜單區域
            if hasTrainingMenu {
                Text("訓練月曆")
                    .font(.headline)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 15) {
                        trainingMenuSection()
                        
                        Divider()
                            .padding(.vertical, 10)
                        
                        // 量表區域標題
                        Text("量表評估")
                            .font(.headline)
                        
                        // 量表區域 - 只顯示當前月份的評估
                        let scheduledAssessments = currentMonthAssessments  // 修改：使用當前月份的評估
                        
                        if !scheduledAssessments.isEmpty {
                            ForEach(scheduledAssessments, id: \.id) { assessment in
                                AssessmentItemView(
                                    assessment: assessment,
                                    currentDate: currentDate,  // 新增：傳遞當前日期
                                    isExpanded: expandedAssessments.contains(assessment.id),
                                    onToggle: { isExpanded in
                                        withAnimation(.spring(response: 0.3)) {
                                            if isExpanded {
                                                expandedAssessments.insert(assessment.id)
                                            } else {
                                                expandedAssessments.remove(assessment.id)
                                            }
                                        }
                                    },
                                    onDelete: {
                                        withAnimation {
                                            onDeleteAssessment?(assessment)
                                            // 確保刪除後立即更新視圖
                                            expandedAssessments.remove(assessment.id)
                                        }
                                    }
                                )
                            }
                        } else {
                            Text("本月尚未安排評估")  // 修改：更新文字以反映當前月份的未來評估
                                .foregroundColor(.gray)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.white)
                                .cornerRadius(12)
                        }
                    }
                }
            }
        }
        .padding(20)
        .frame(height: fixedHeight)
        .background(Color.white)
        .cornerRadius(12)
    }
    
    // 獲取時段對應的顏色
    private func getTimeSlotColor(_ slot: String) -> Color {
        switch slot {
        case "早": return .morning
        case "中": return .noon
        case "下": return .afternoon
        case "晚": return .night
        default: return .gray.opacity(0.3)
        }
    }
}

// 量表項目視圖
private struct AssessmentItemView: View {
    let assessment: Assessment
    let currentDate: Date  // 新增：當前日期參數
    let isExpanded: Bool
    let onToggle: (Bool) -> Void
    let onDelete: () -> Void
    @State private var showingDeleteAlert = false
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd"
        return formatter
    }()
    
    // 新增：檢查日期是否在當前月份
    private func isDateInCurrentMonth(_ date: Date) -> Bool {
        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.year, .month], from: date)
        let currentComponents = calendar.dateComponents([.year, .month], from: currentDate)
        
        return dateComponents.year == currentComponents.year && 
               dateComponents.month == currentComponents.month
    }
    
    // 新增：獲取當前月份的排程日期
    private var currentMonthScheduledDates: [Date] {
        let calendar = Calendar.current

        // Ensure referenceStartOfDay is the actual start of the month of self.currentDate
        let firstDayOfViewedMonthComponents = calendar.dateComponents([.year, .month], from: self.currentDate) // self.currentDate is from TrainingListCard
        guard let firstDayOfViewedMonth = calendar.date(from: firstDayOfViewedMonthComponents) else {
            return []
        }
        let referenceStartOfDay = calendar.startOfDay(for: firstDayOfViewedMonth)

        return assessment.scheduledDates
            .filter { date in
                let scheduleDateStartOfDay = calendar.startOfDay(for: date)
                // self.isDateInCurrentMonth uses self.currentDate correctly to define the month context
                return self.isDateInCurrentMonth(date) && scheduleDateStartOfDay >= referenceStartOfDay
            }
            .sorted()
    }
    
    // 新增：獲取當前月份的完成日期
    private var currentMonthCompletedDates: [Date] {
        return assessment.completedDates
            .filter { isDateInCurrentMonth($0) }
            .sorted(by: >)
    }
    
    // 新增：獲取最近兩次完成的評量日期（不限月份）
    private var recentCompletedDates: [Date] {
        return assessment.completedDates.sorted(by: >).prefix(2).map { $0 }
    }
    
    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 15) {
                VStack(alignment: .leading, spacing: 8) {
                    // 量表標題
                    HStack(spacing: 8) {
                        Rectangle()
                            .fill(assessment.type.color)
                            .frame(width: 20, height: 20)
                            .cornerRadius(4)
                        Text(assessment.title)
                            .font(.system(size: 16))
                    }
                    
                    // 新增：顯示最近兩次完成的評量日期
                    if !recentCompletedDates.isEmpty {
                        Text("最近評量：\(formatDates(recentCompletedDates))")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                    }
                }
                
                Spacer()
                
                ToggleButton(
                    isExpanded: .constant(isExpanded),
                    color: .blue,
                    action: { onToggle(!isExpanded) }
                )
            }
            
            if isExpanded {
                VStack(alignment: .leading, spacing: 8) {
                    // 只顯示本月未來的預定評量時間
                    if !currentMonthScheduledDates.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("本月預定評量時間：")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(formatDates(currentMonthScheduledDates))
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
            }
        }
        .padding(.vertical, 12)
        .background(Color.white)
        .cornerRadius(12)
        .contentShape(Rectangle()) // 確保整個區域都可以接收手勢
        .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                showingDeleteAlert = true
            } label: {
                Label("刪除", systemImage: "trash")
            }
            .tint(.red)
        }
        .contextMenu {
            Button(role: .destructive) {
                showingDeleteAlert = true
            } label: {
                Label("刪除評估安排", systemImage: "trash")
            }
        }
        .alert("確認刪除", isPresented: $showingDeleteAlert) {
            Button("取消", role: .cancel) {}
            Button("刪除", role: .destructive) {
                withAnimation {
                    onDelete()
                }
            }
        } message: {
            Text("確定要刪除這個評估安排嗎？")
        }
    }
    
    // 新增：格式化日期列表
    private func formatDates(_ dates: [Date]) -> String {
        return dates
            .map { dateFormatter.string(from: $0) }
            .joined(separator: ", ")
    }
}

// 展開/收起按鈕
private struct ToggleButton: View {
    @Binding var isExpanded: Bool
    let color: Color
    var isEnabled: Bool = true
    var action: (() -> Void)? = nil
    
    var body: some View {
        Button(action: {
            if isEnabled {
                withAnimation(.spring(response: 0.3)) {
                    if let customAction = action {
                        customAction()
                    } else {
                        isExpanded.toggle()
                    }
                }
            }
        }) {
            Image(systemName: "chevron.down")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(color)
                .rotationEffect(.degrees(isExpanded ? 180 : 0))
                .padding(8)
                .background(
                    Circle()
                        .fill(color.opacity(0.1))
                )
        }
        .disabled(!isEnabled)
    }
}

// 訓練項目視圖
private struct TrainingItemView: View {
    let title: String
    var menuColor: Color?
    let tags: [String]
    var tagColors: [Color]
    var isPlaceholder: Bool
    
    init(
        title: String,
        menuColor: Color? = nil,
        tags: [String],
        tagColors: [Color]? = nil,
        isPlaceholder: Bool = false
    ) {
        self.title = title
        self.menuColor = menuColor
        self.tags = tags
        self.tagColors = tagColors ?? Array(repeating: .blue, count: tags.count)
        self.isPlaceholder = isPlaceholder
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Circle()
                    .fill(menuColor ?? Color.gray.opacity(0.3))
                    .frame(width: 20, height: 20)
                Text(title)
                    .font(.system(size: 16))
                    .foregroundColor(isPlaceholder ? .gray : .black)
            }
            
            if !tags.isEmpty {
                HStack(spacing: 8) {
                    ForEach(Array(zip(tags.indices, tags)), id: \.0) { index, tag in
                        Text(tag)
                            .font(.system(size: 14))
                            .foregroundColor(isPlaceholder ? .gray : .white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(tagColors[index])
                            )
                    }
                }
            }
        }
    }
}

struct TrainingListCard_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            TrainingListCard(
                hasTrainingMenu: true,
                assessments: Patient.sample.assessments,
                patient: Patient.sample,
                currentDate: Date()  // 新增：傳遞當前日期
            )
            .environmentObject(TrainingScheduleStore.preview)
            .environmentObject(TrainingMenuStore.preview)
            
            TrainingListCard(
                hasTrainingMenu: false,
                assessments: [],
                patient: Patient.sample,
                currentDate: Date()  // 新增：傳遞當前日期
            )
            .environmentObject(TrainingScheduleStore.preview)
            .environmentObject(TrainingMenuStore.preview)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
    }
}

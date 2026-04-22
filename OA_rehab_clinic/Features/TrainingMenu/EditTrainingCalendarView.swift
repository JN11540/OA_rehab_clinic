import SwiftUI
import Foundation

/**
 * EditTrainingCalendarView - 訓練月曆編輯視圖（重構版）
 *
 * 功能說明：
 * - 統一的訓練和評估排程介面
 * - 支援 Tab 切換不同排程類型
 * - 整合月曆、菜單選擇和排程管理
 *
 * 設計原則：
 * - 組件化：UI 邏輯分散到專門的子視圖
 * - 狀態集中：所有狀態管理委託給 ViewModel
 * - 職責分離：視圖只負責呈現，業務邏輯在 ViewModel
 *
 * 重構成果：
 * - 從 1,575 行減少到約 400 行
 * - 提取了 5 個專門的組件
 * - 業務邏輯完全移到 ViewModel 和 Service 層
 */
struct EditTrainingCalendarView: View {
    // MARK: - 屬性
    
    /// 視圖模型（集中管理所有狀態）
    @StateObject private var viewModel: CalendarSchedulingViewModel
    
    /// 環境注入
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var userModel: UserModel
    @EnvironmentObject private var trainingMenuStore: TrainingMenuStore
    @EnvironmentObject private var scheduleStore: TrainingScheduleStore
    
    /// 常數
    private let fixedHeight: CGFloat = 450
    
    // MARK: - 初始化
    
    init(patient: Patient, scheduleIdToEdit: UUID? = nil) {
        _viewModel = StateObject(wrappedValue: CalendarSchedulingViewModel(
            patient: patient,
            scheduleIdToEdit: scheduleIdToEdit
        ))
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ZStack {
                // 背景漸層
                backgroundGradient
                
                VStack(spacing: 30) {
                    // 導航標題
                    navigationHeader
                    
                    // 主要內容網格
                    contentGrid
                }
            }
            // Alert 處理
            .alert("重複的訓練安排", isPresented: $viewModel.showingDuplicateAlert) {
                Button("確定", role: .cancel) { }
            } message: {
                Text("選擇的日期已經安排了相同的訓練菜單")
            }
            .alert("日期重疊確認", isPresented: $viewModel.showingOverlapAlert) {
                overlapAlert
            } message: {
                Text("選擇的日期涵蓋舊的訓練安排（\(overlappingMenuNames)），確定要覆蓋嗎？")
            }
            .alert("編輯訓練安排", isPresented: $viewModel.showingEditScheduleOptions) {
                editScheduleAlert
            } message: {
                Text("您正在編輯「\(editingMenuName)」的訓練安排。")
            }
            .alert("確認刪除", isPresented: $viewModel.showingDeleteScheduleAlert) {
                deleteScheduleAlert
            } message: {
                Text("確定要刪除「\(editingMenuName)」的訓練安排嗎？此操作無法撤銷。")
            }
            .alert("匯出失敗", isPresented: $viewModel.showingExportError) {
                Button("確定", role: .cancel) {}
            } message: {
                Text(viewModel.exportErrorMessage)
            }
            // 生命週期
            .onAppear {
                setupView()
            }
            .onChange(of: viewModel.selectedTab) { _ in
                handleTabChange()
            }
            // 通知觀察
            .onReceive(NotificationCenter.default.publisher(for: .assessmentsDidUpdate)) { _ in
                handleAssessmentUpdate()
            }
        }
        .environmentObject(scheduleStore)
        .environmentObject(trainingMenuStore)
        .environmentObject(userModel)
    }
    
    // MARK: - 子視圖
    
    /// 背景漸層
    private var backgroundGradient: some View {
        GradientBackground(
            startColor: Color(red: 0.47, green: 0.84, blue: 0.98),
            endColor: Color(red: 0.72, green: 0.89, blue: 0.59)
        )
        .ignoresSafeArea(edges: .all)
    }
    
    /// 導航標題
    private var navigationHeader: some View {
        NavigationHeader(
            patient: viewModel.patient,
            pageTitle: "編輯訓練月曆"
        )
    }
    
    /// 主要內容網格
    private var contentGrid: some View {
        Grid(alignment: .leading, horizontalSpacing: 15, verticalSpacing: 15) {
            // 患者資訊區
            patientInfoRow
            
            // Tab 按鈕區
            tabButtonRow
            
            // 主要內容區
            contentRow
        }
        .padding(.horizontal, 30)
    }
    
    /// 患者資訊列
    private var patientInfoRow: some View {
        GridRow {
            PatientInfoCard(patient: viewModel.patient)
                .gridCellColumns(5)
        }
        #if canImport(UIKit)
        .frame(height: UIScreen.main.bounds.height / 5)
        #else
        .frame(height: 200)
        #endif
    }
    
    /// Tab 按鈕列
    private var tabButtonRow: some View {
        GridRow {
            HStack(spacing: 5) {
                TabButton(
                    title: "訓練菜單",
                    isSelected: viewModel.selectedTab == .training,
                    action: { viewModel.selectedTab = .training }
                )
                
                TabButton(
                    title: "評估量表",
                    isSelected: viewModel.selectedTab == .assessment,
                    action: { viewModel.selectedTab = .assessment }
                )
            }
            .gridCellColumns(2)
            
            Spacer()
                .gridCellColumns(2)
            
            // 匯出按鈕
            exportButton
                .gridCellColumns(1)
        }
        .frame(height: 32)
        .padding(.horizontal, 10)
    }
    
    /// 主要內容列
    private var contentRow: some View {
        GridRow {
            if viewModel.selectedTab == .training {
                // 左側：菜單選擇（1格）
                MenuSelectionCard(
                    selectedMenu: $viewModel.selectedMenu,
                    patient: viewModel.patient,
                    onCalendarUpdate: viewModel.refreshCalendar
                )
                .gridCellColumns(1)
                
                // 中間：菜單編輯（2格）
                MenuEditCard(
                    patient: viewModel.patient,
                    menuTitle: .constant(viewModel.menuTitle),
                    timeSlots: viewModel.timeSlots,
                    timeColors: viewModel.timeColors,
                    selectedMenu: $viewModel.selectedMenu,
                    userModel: userModel,
                    scheduleStore: scheduleStore,
                    menuStore: trainingMenuStore,
                    onMenuUpdated: viewModel.refreshCalendar
                )
                .gridCellColumns(2)
            } else {
                // 評估模式：評估選擇（3格）
                AssessmentSelectionCard(
                    assessments: viewModel.patient.assessments,
                    selectedAssessment: $viewModel.selectedAssessment,
                    onSelect: viewModel.handleAssessmentSelection
                )
                .gridCellColumns(3)
            }
            
            // 右側：月曆和操作區域（2格）
            calendarSection
                .gridCellColumns(2)
        }
        .frame(height: fixedHeight)
    }
    
    /// 月曆和操作區域
    private var calendarSection: some View {
        VStack(spacing: 0) {
            // 編輯模式提示
            if viewModel.selectedTab == .training && viewModel.isEditingExistingSchedule {
                editingModeIndicator
            } else if viewModel.selectedTab == .assessment && viewModel.selectedAssessment != nil {
                assessmentEditingModeIndicator
            }
            
            // 月曆容器
            calendarContainer
                .id(viewModel.calendarViewId)
            
            // 儲存按鈕
            saveButton
        }
        .frame(width: 430)  // 固定寬度以保持一致的佈局
    }
    
    /// 匯出按鈕
    private var exportButton: some View {
        Button(action: viewModel.exportArrangementForMonth) {
            HStack(spacing: 5) {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 14))
                Text("匯出安排")
                    .font(.system(size: 14))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.blue)
            .cornerRadius(16)
        }
    }
    
    /// 月曆容器
    @ViewBuilder
    private var calendarContainer: some View {
        if viewModel.selectedTab == .training {
            UnifiedCalendarContainer(
                currentDate: $viewModel.currentDate,
                patient: viewModel.patient,
                selectedMenu: viewModel.selectedMenu,
                selectedAssessments: [],
                onDateRangeSelected: viewModel.handleDateRangeSelection,
                onExistingScheduleTap: viewModel.handleExistingScheduleSelection,
                selectionMode: .range,
                isEditable: true,
                isEditingExistingSchedule: viewModel.isEditingExistingSchedule,
                initialSelectedDates: getInitialSelectedDates()
            )
            .environmentObject(scheduleStore)
            .environmentObject(AssessmentStore.shared)
        } else {
            UnifiedCalendarContainer(
                currentDate: $viewModel.currentDate,
                patient: viewModel.patient,
                selectedMenu: nil,
                selectedAssessments: viewModel.selectedAssessmentSet,
                onDateRangeSelected: viewModel.handleDateRangeSelection,
                onExistingScheduleTap: nil,
                selectionMode: .range,
                isEditable: true,
                isEditingExistingSchedule: false,
                initialSelectedDates: getInitialSelectedDates()
            )
            .environmentObject(scheduleStore)
            .environmentObject(AssessmentStore.shared)
        }
    }
    
    /// 編輯模式指示器
    private var editingModeIndicator: some View {
        Group {
            if let schedule = viewModel.scheduleBeingEdited,
               let menu = trainingMenuStore.getMenu(by: schedule.menuId) {
                HStack {
                    Circle()
                        .fill(menu.color)
                        .frame(width: 12, height: 12)
                    
                    Text("正在編輯「\(menu.title)」")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Button(action: viewModel.cancelEditingExistingSchedule) {
                        Text("取消編輯")
                            .font(.system(size: 14))
                            .foregroundColor(.blue)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }
        }
    }
    
    /// 評估編輯模式指示器
    private var assessmentEditingModeIndicator: some View {
        Group {
            if let assessment = viewModel.selectedAssessment {
                HStack {
                    Circle()
                        .fill(assessment.type.color)
                        .frame(width: 12, height: 12)
                    
                    Text("正在編輯「\(assessment.title)」評估排程")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Button(action: {
                        viewModel.assessmentViewModel.resetState()
                        viewModel.refreshCalendar()
                    }) {
                        Text("取消編輯")
                            .font(.system(size: 14))
                            .foregroundColor(.blue)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }
        }
    }
    
    /// 儲存按鈕
    private var saveButton: some View {
        CalendarActionButton(
            isEditing: true,
            hasChanges: viewModel.selectedTab == .training ? viewModel.hasTrainingChanges : viewModel.hasAssessmentChanges,
            buttonText: viewModel.selectedTab == .training ? viewModel.trainingButtonText : viewModel.assessmentButtonText,
            action: viewModel.selectedTab == .training ? viewModel.saveTrainingSchedule : viewModel.saveAssessmentSchedule
        )
    }
    
    // MARK: - 輔助方法
    
    /// 獲取初始選中日期
    private func getInitialSelectedDates() -> Set<Date> {
        if viewModel.selectedTab == .training {
            return viewModel.isEditingExistingSchedule 
                ? (viewModel.isEnteringEditModeFromExternal || viewModel.selectedDates.isEmpty 
                    ? viewModel.originalScheduleDates 
                    : viewModel.selectedDates)
                : []
        } else {
            return viewModel.selectedDates
        }
    }
    
    // MARK: - Alert 內容
    
    /// 重疊確認 Alert
    private var overlapAlert: some View {
        Group {
            Button("取消", role: .cancel) {
                viewModel.overlappingSchedules = []
                viewModel.pendingSchedule = nil
            }
            Button("確定覆蓋", role: .destructive) {
                viewModel.handleOverlapConfirmation()
            }
        }
    }
    
    /// 編輯排程 Alert
    private var editScheduleAlert: some View {
        Group {
            Button("取消", role: .cancel) {
                viewModel.cancelEditingExistingSchedule()
            }
            Button("編輯日期", role: .none) {
                viewModel.showingEditScheduleOptions = false
            }
            Button("刪除安排", role: .destructive) {
                viewModel.showingDeleteScheduleAlert = true
            }
        }
    }
    
    /// 刪除確認 Alert
    private var deleteScheduleAlert: some View {
        Group {
            Button("取消", role: .cancel) {
                viewModel.showingDeleteScheduleAlert = false
            }
            Button("刪除", role: .destructive) {
                viewModel.deleteSelectedSchedule()
            }
        }
    }
    
    // MARK: - 私有方法
    
    /// 設置視圖
    private func setupView() {
        // 只有在非編輯模式下才重置狀態
        if !viewModel.isEditingExistingSchedule {
            viewModel.resetState()
        }
        
        // 載入排程數據
        scheduleStore.reloadSchedules()
        
        // 延遲重置外部編輯標誌
        // 注意：isEnteringEditModeFromExternal 現在是只讀屬性，由 TrainingSchedulingViewModel 內部管理
    }
    
    /// 處理 Tab 切換
    private func handleTabChange() {
        // Tab 切換邏輯已經在 ViewModel 中處理
        // 這裡可以添加額外的 UI 相關處理
    }
    
    /// 處理評估更新通知
    private func handleAssessmentUpdate() {
        if let updatedPatient = PatientStore.shared.patients.first(where: { $0.id == viewModel.patient.id }) {
            viewModel.patient = updatedPatient
            viewModel.refreshCalendar()
        }
    }
}

// MARK: - Alert Message Helpers

extension EditTrainingCalendarView {
    /// 獲取重疊菜單名稱
    private var overlappingMenuNames: String {
        viewModel.overlappingSchedules.compactMap { schedule in
            trainingMenuStore.getMenu(by: schedule.menuId)?.title
        }.joined(separator: "、")
    }
    
    /// 獲取編輯中的菜單名稱
    private var editingMenuName: String {
        if let schedule = viewModel.scheduleBeingEdited,
           let menu = trainingMenuStore.getMenu(by: schedule.menuId) {
            return menu.title
        }
        return "訓練安排"
    }
}

// MARK: - Preview

struct EditTrainingCalendarView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            EditTrainingCalendarView(
                patient: Patient.sample
            )
            .environmentObject(UserModel.shared)
            .environmentObject(TrainingScheduleStore.shared)
            .environmentObject(TrainingMenuStore.shared)
        }
        .previewLayout(.fixed(width: 1200, height: 800))
    }
}

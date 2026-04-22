import SwiftUI
import Foundation
import Combine

/**
 * CalendarSchedulingViewModel - 月曆排程協調器
 *
 * 功能說明：
 * - 協調訓練和評估排程的管理
 * - 整合 UI 狀態管理器和專門的 ViewModel
 * - 提供統一的介面給視圖層使用
 *
 * 設計原則：
 * - 協調器模式：整合多個專注的 ViewModel
 * - 依賴注入：通過初始化注入所需的服務
 * - 響應式：使用 @Published 和 Combine 確保狀態同步
 *
 * 重構說明（2025-06-24）：
 * - 拆分為三個專注的組件：
 *   - CalendarUIStateManager: UI 狀態管理
 *   - TrainingSchedulingViewModel: 訓練排程邏輯
 *   - AssessmentSchedulingViewModel: 評估排程邏輯
 * - 保持向後兼容的 API
 */
@MainActor
class CalendarSchedulingViewModel: ObservableObject {
    // MARK: - 核心組件
    
    /// UI 狀態管理器
    @Published private(set) var uiStateManager: CalendarUIStateManager
    
    /// 訓練排程視圖模型
    @Published private(set) var trainingViewModel: TrainingSchedulingViewModel
    
    /// 評估排程視圖模型
    @Published private(set) var assessmentViewModel: AssessmentSchedulingViewModel
    
    /// 當前患者資料
    @Published var patient: Patient {
        didSet {
            // 同步更新子 ViewModel 的患者資料
            assessmentViewModel.updatePatient(patient)
        }
    }
    
    // MARK: - 依賴注入
    
    private let trainingMenuStore: TrainingMenuStore
    private let scheduleStore: TrainingScheduleStore
    private let assessmentStore: AssessmentStore
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - 常數（保留以維持向後兼容）
    
    let timeSlots = ["早", "中", "下", "晚"]
    let timeColors: [Color] = [.morning, .noon, .afternoon, .night]
    
    // MARK: - 類型定義（轉發以維持向後兼容）
    
    typealias TabType = CalendarUIStateManager.TabType
    
    // MARK: - 初始化
    
    init(
        patient: Patient,
        scheduleIdToEdit: UUID? = nil,
        trainingMenuStore: TrainingMenuStore = .shared,
        scheduleStore: TrainingScheduleStore = .shared,
        assessmentStore: AssessmentStore = .shared
    ) {
        self.patient = patient
        self.trainingMenuStore = trainingMenuStore
        self.scheduleStore = scheduleStore
        self.assessmentStore = assessmentStore
        
        // 初始化子組件 - 先初始化 uiStateManager
        let uiStateManager = CalendarUIStateManager()
        self.uiStateManager = uiStateManager
        
        // 然後初始化其他 ViewModels
        self.trainingViewModel = TrainingSchedulingViewModel(
            patient: patient,
            uiStateManager: uiStateManager,
            scheduleIdToEdit: scheduleIdToEdit,
            trainingMenuStore: trainingMenuStore,
            scheduleStore: scheduleStore
        )
        self.assessmentViewModel = AssessmentSchedulingViewModel(
            patient: patient,
            uiStateManager: uiStateManager,
            assessmentStore: assessmentStore
        )
        
        // 設置狀態同步
        setupStateBindings()
    }
    
    // MARK: - 向後兼容的計算屬性（轉發到子組件）
    
    /// 當前顯示的月份日期
    var currentDate: Date {
        get { uiStateManager.currentDate }
        set { uiStateManager.currentDate = newValue }
    }
    
    /// 當前選中的頁籤
    var selectedTab: TabType {
        get { uiStateManager.selectedTab }
        set { uiStateManager.selectedTab = newValue }
    }
    
    /// 強制刷新月曆的 ID
    var calendarViewId: UUID {
        uiStateManager.calendarViewId
    }
    
    /// 選中的訓練菜單
    var selectedMenu: TrainingMenu? {
        get { trainingViewModel.selectedMenu }
        set { trainingViewModel.selectedMenu = newValue }
    }
    
    /// 選中的日期集合
    var selectedDates: Set<Date> {
        get {
            switch selectedTab {
            case .training:
                return trainingViewModel.selectedDates
            case .assessment:
                return assessmentViewModel.selectedDates
            }
        }
        set {
            switch selectedTab {
            case .training:
                trainingViewModel.selectedDates = newValue
            case .assessment:
                assessmentViewModel.selectedDates = newValue
            }
        }
    }
    
    /// 是否正在編輯現有排程
    var isEditingExistingSchedule: Bool {
        trainingViewModel.isEditingExistingSchedule
    }
    
    /// 正在編輯的排程
    var scheduleBeingEdited: TrainingSchedule? {
        trainingViewModel.scheduleBeingEdited
    }
    
    /// 原始排程日期
    var originalScheduleDates: Set<Date> {
        trainingViewModel.originalScheduleDates
    }
    
    /// 菜單標題
    var menuTitle: String {
        trainingViewModel.menuTitle
    }
    
    /// 選中的評估量表
    var selectedAssessment: Assessment? {
        get { assessmentViewModel.selectedAssessment }
        set { assessmentViewModel.selectedAssessment = newValue }
    }
    
    /// 當前月份的原始評估日期
    var originalAssessmentDatesInCurrentMonth: Set<Date> {
        assessmentViewModel.originalAssessmentDatesInCurrentMonth
    }
    
    /// Alert 和 Dialog 狀態（轉發到 UI 狀態管理器）
    var showingDuplicateAlert: Bool {
        get { uiStateManager.showingDuplicateAlert }
        set { uiStateManager.showingDuplicateAlert = newValue }
    }
    
    var showingOverlapAlert: Bool {
        get { uiStateManager.showingOverlapAlert }
        set { uiStateManager.showingOverlapAlert = newValue }
    }
    
    var showingEditScheduleOptions: Bool {
        get { uiStateManager.showingEditScheduleOptions }
        set { uiStateManager.showingEditScheduleOptions = newValue }
    }
    
    var showingDeleteScheduleAlert: Bool {
        get { uiStateManager.showingDeleteScheduleAlert }
        set { uiStateManager.showingDeleteScheduleAlert = newValue }
    }
    
    var showingExportError: Bool {
        get { uiStateManager.showingExportError }
        set { uiStateManager.showingExportError = newValue }
    }
    
    var exportErrorMessage: String {
        get { uiStateManager.exportErrorMessage }
        set { uiStateManager.exportErrorMessage = newValue }
    }
    
    /// 重疊的排程列表
    var overlappingSchedules: [TrainingSchedule] {
        get { trainingViewModel.overlappingSchedules }
        set { trainingViewModel.overlappingSchedules = newValue }
    }
    
    /// 待處理的排程
    var pendingSchedule: TrainingSchedule? {
        get { trainingViewModel.pendingSchedule }
        set { trainingViewModel.pendingSchedule = newValue }
    }
    
    /// 要編輯的排程 ID
    var scheduleIdToEdit: UUID? {
        trainingViewModel.scheduleIdToEdit
    }
    
    /// 是否從外部進入編輯模式
    var isEnteringEditModeFromExternal: Bool {
        trainingViewModel.isEnteringEditModeFromExternal
    }
    
    /// 是否有未保存的訓練變更
    var hasTrainingChanges: Bool {
        selectedTab == .training ? trainingViewModel.hasChanges : false
    }
    
    /// 是否有未保存的評估變更
    var hasAssessmentChanges: Bool {
        selectedTab == .assessment ? assessmentViewModel.hasChanges : false
    }
    
    /// 訓練按鈕文字
    var trainingButtonText: String {
        trainingViewModel.saveButtonText
    }
    
    /// 評估按鈕文字
    var assessmentButtonText: String {
        assessmentViewModel.saveButtonText
    }
    
    /// 評估集合
    var selectedAssessmentSet: Set<Assessment> {
        assessmentViewModel.selectedAssessmentSet
    }
    
    // MARK: - 私有方法
    
    /**
     * 設置狀態綁定
     * 同步子組件的狀態變化
     */
    private func setupStateBindings() {
        // 監聽 UI 狀態變化
        uiStateManager.objectWillChange
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
        
        // 監聽訓練 ViewModel 變化
        trainingViewModel.objectWillChange
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
        
        // 監聽評估 ViewModel 變化
        assessmentViewModel.objectWillChange
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - 公開方法（保持向後兼容）
    
    /// 重置所有狀態
    func resetState() {
        // 重置子組件狀態
        trainingViewModel.resetState()
        assessmentViewModel.resetState()
        uiStateManager.resetAllUIStates()
        
        // 更新患者資料
        if let updatedPatient = PatientStore.shared.patients.first(where: { $0.id == patient.id }) {
            patient = updatedPatient
        }
    }
    
    /// 強制刷新月曆
    func refreshCalendar() {
        uiStateManager.refreshCalendar()
    }
    
    /// 處理日期範圍選擇
    func handleDateRangeSelection(_ dates: Set<Date>) {
        switch selectedTab {
        case .training:
            trainingViewModel.handleDateRangeSelection(dates)
        case .assessment:
            assessmentViewModel.handleDateRangeSelection(dates)
        }
    }
    
    /// 處理評估選擇
    func handleAssessmentSelection(_ assessment: Assessment) {
        assessmentViewModel.handleAssessmentSelection(assessment)
    }
    
    
    /// 處理選擇現有排程
    func handleExistingScheduleSelection(_ date: Date) {
        // 只在訓練菜單頁籤中啟用此功能
        guard selectedTab == .training else { return }
        trainingViewModel.handleExistingScheduleSelection(date)
    }
    
    /// 保存訓練排程
    func saveTrainingSchedule() {
        trainingViewModel.saveSchedule()
    }
    
    /// 取消編輯現有排程
    func cancelEditingExistingSchedule() {
        trainingViewModel.cancelEditingExistingSchedule()
    }
    
    /// 處理重疊訓練安排的確認
    func handleOverlapConfirmation() {
        trainingViewModel.handleOverlapConfirmation()
    }
    
    /// 刪除選中的排程
    func deleteSelectedSchedule() {
        trainingViewModel.deleteSelectedSchedule()
    }
    
    // MARK: - 評估排程業務邏輯
    
    /// 保存評估排程
    func saveAssessmentSchedule() {
        assessmentViewModel.saveSchedule()
    }
    
    // MARK: - 匯出功能
    
    /// 匯出當月安排
    func exportArrangementForMonth() {
        ClinicDataExporter.shared.exportAndShareArrangementForMonth(for: patient, month: currentDate) { [weak self] result in
            switch result {
            case .success:
                print("匯出並共享成功")
            case .failure(let error):
                print("匯出失敗: \(error.localizedDescription)")
                self?.uiStateManager.showExportError(error.localizedDescription)
            }
        }
    }
}
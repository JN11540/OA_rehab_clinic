import SwiftUI
import Foundation

/**
 * TrainingSchedulingViewModel - 訓練排程視圖模型
 *
 * 功能說明：
 * - 專注於訓練菜單的排程管理
 * - 處理訓練排程的新增、編輯、刪除等業務邏輯
 * - 管理排程衝突的檢測和解決
 *
 * 設計原則：
 * - 單一職責：只負責訓練排程相關的業務邏輯
 * - 依賴注入：通過初始化注入所需的服務和狀態管理器
 * - 響應式：使用 @Published 確保 UI 自動更新
 */
@MainActor
class TrainingSchedulingViewModel: ObservableObject {
    
    // MARK: - 訓練排程狀態
    
    /// 選中的訓練菜單
    @Published var selectedMenu: TrainingMenu?
    
    /// 選中的日期集合
    @Published var selectedDates: Set<Date> = []
    
    /// 是否正在編輯現有排程
    @Published var isEditingExistingSchedule = false
    
    /// 正在編輯的排程
    @Published var scheduleBeingEdited: TrainingSchedule?
    
    /// 原始排程日期（用於比較變更）
    @Published var originalScheduleDates: Set<Date> = []
    
    /// 菜單標題（默認值）
    @Published var menuTitle: String = "尚未新增或選擇訓練"
    
    // MARK: - 衝突處理狀態
    
    /// 重疊的排程列表
    @Published var overlappingSchedules: [TrainingSchedule] = []
    
    /// 待處理的排程（用於衝突解決）
    @Published var pendingSchedule: TrainingSchedule?
    
    // MARK: - 外部編輯模式
    
    /// 要編輯的排程 ID（從外部傳入）
    var scheduleIdToEdit: UUID?
    
    /// 是否從外部進入編輯模式
    @Published var isEnteringEditModeFromExternal = false
    
    // MARK: - 依賴注入
    
    private let patient: Patient
    private let trainingMenuStore: TrainingMenuStore
    private let scheduleStore: TrainingScheduleStore
    private let uiStateManager: CalendarUIStateManager
    private let dateService = DateRangeService.shared
    private let calendar = Calendar.current
    
    // MARK: - 常數
    
    let timeSlots = ["早", "中", "下", "晚"]
    let timeColors: [Color] = [.morning, .noon, .afternoon, .night]
    
    // MARK: - 初始化
    
    init(
        patient: Patient,
        uiStateManager: CalendarUIStateManager,
        scheduleIdToEdit: UUID? = nil,
        trainingMenuStore: TrainingMenuStore = .shared,
        scheduleStore: TrainingScheduleStore = .shared
    ) {
        self.patient = patient
        self.uiStateManager = uiStateManager
        self.scheduleIdToEdit = scheduleIdToEdit
        self.trainingMenuStore = trainingMenuStore
        self.scheduleStore = scheduleStore
        
        // 如果有要編輯的排程，設置編輯模式
        if let scheduleId = scheduleIdToEdit {
            Task {
                await setEditMode(for: scheduleId)
            }
        }
    }
    
    // MARK: - 計算屬性
    
    /// 是否有未保存的變更
    var hasChanges: Bool {
        if isEditingExistingSchedule {
            // 在編輯模式下，檢查選擇的日期是否與原始日期不同
            return selectedDates != originalScheduleDates && !selectedDates.isEmpty
        } else {
            // 在新增模式下，檢查是否選擇了菜單和日期
            return selectedMenu != nil && !selectedDates.isEmpty
        }
    }
    
    /// 按鈕文字
    var saveButtonText: String {
        isEditingExistingSchedule ? "更新訓練安排" : "儲存訓練安排"
    }
    
    // MARK: - 公開方法
    
    /**
     * 重置所有狀態
     */
    func resetState() {
        selectedDates.removeAll()
        selectedMenu = nil
        isEditingExistingSchedule = false
        scheduleBeingEdited = nil
        originalScheduleDates.removeAll()
        isEnteringEditModeFromExternal = false
        menuTitle = "尚未新增或選擇訓練"
    }
    
    /**
     * 處理日期範圍選擇
     * - Parameter dates: 選中的日期集合
     */
    func handleDateRangeSelection(_ dates: Set<Date>) {
        selectedDates = dateService.normalizeDates(dates)
    }
    
    /**
     * 處理選擇現有排程
     * - Parameter date: 選中的日期
     */
    func handleExistingScheduleSelection(_ date: Date) {
        // 如果已經在編輯模式，不再觸發編輯選項
        if isEditingExistingSchedule {
            return
        }
        
        // 找出包含所選日期的所有排程
        let schedulesForDate = scheduleStore.getSchedulesForPatient(patient.id)
            .filter { schedule in
                schedule.dates.contains { scheduleDate in
                    dateService.isSameDay(scheduleDate, date)
                }
            }
        
        // 如果找到排程，選擇最後一個（假設是最新添加的）
        if let scheduleToEdit = schedulesForDate.last {
            enterEditMode(for: scheduleToEdit)
        }
    }
    
    /**
     * 保存訓練排程
     */
    func saveSchedule() {
        if isEditingExistingSchedule {
            saveEditedSchedule()
        } else {
            saveNewSchedule()
        }
    }
    
    /**
     * 刪除選中的排程
     */
    func deleteSelectedSchedule() {
        guard let scheduleToDelete = scheduleBeingEdited else { return }
        
        // 使用當前月份作為上下文進行刪除
        scheduleStore.removeDatesFromSchedule(
            scheduleToDelete.id,
            inMonthOf: uiStateManager.currentDate
        )
        
        // 重置狀態
        resetState()
        uiStateManager.showingDeleteScheduleAlert = false
        uiStateManager.refreshCalendar()
    }
    
    /**
     * 處理重疊確認
     */
    func handleOverlapConfirmation() {
        guard let pendingSchedule = pendingSchedule else { return }
        
        // 移除所有重疊的訓練安排中的重疊日期
        for overlappingSchedule in overlappingSchedules {
            removeOverlappingDates(from: overlappingSchedule, with: pendingSchedule)
        }
        
        // 保存待處理的排程
        savePendingSchedule(pendingSchedule)
        
        // 清理狀態
        clearPendingStates()
    }
    
    /**
     * 取消編輯現有排程
     */
    func cancelEditingExistingSchedule() {
        uiStateManager.showingEditScheduleOptions = false
        resetState()
        uiStateManager.refreshCalendar()
    }
    
    // MARK: - 私有方法
    
    /**
     * 從外部設置編輯模式
     * - Parameter scheduleId: 排程 ID
     */
    private func setEditMode(for scheduleId: UUID) async {
        if let scheduleToEdit = scheduleStore.getSchedulesForPatient(patient.id)
            .first(where: { $0.id == scheduleId }) {
            
            enterEditMode(for: scheduleToEdit)
            
            // 切換到訓練菜單頁籤
            uiStateManager.switchToTab(.training)
            
            // 顯示編輯選項
            uiStateManager.showingEditScheduleOptions = true
            
            // 設置標誌
            isEnteringEditModeFromExternal = true
        }
    }
    
    /**
     * 進入編輯模式
     * - Parameter schedule: 要編輯的排程
     */
    private func enterEditMode(for schedule: TrainingSchedule) {
        guard let menu = trainingMenuStore.getMenu(by: schedule.menuId) else { return }
        
        // 標準化日期
        let normalizedDates = dateService.normalizeDates(schedule.dates)
        
        // 設置編輯狀態
        selectedMenu = menu
        originalScheduleDates = normalizedDates
        selectedDates = normalizedDates
        scheduleBeingEdited = schedule
        isEditingExistingSchedule = true
        
        // 更新 UI 狀態
        uiStateManager.showingEditScheduleOptions = true
    }
    
    /**
     * 保存編輯後的排程
     */
    private func saveEditedSchedule() {
        guard let scheduleToEdit = scheduleBeingEdited,
              let currentSelectedMenu = selectedMenu else { return }
        
        // 創建更新後的排程
        let updatedSchedule = TrainingSchedule(
            id: scheduleToEdit.id,
            menuId: currentSelectedMenu.id,
            patientId: patient.id,
            selectedDates: selectedDates,
            timeSlots: currentSelectedMenu.timeSlots
        )
        
        // 檢查與其他菜單的衝突
        if let conflicts = checkForConflicts(with: updatedSchedule, excludingMenuId: currentSelectedMenu.id) {
            handleConflicts(conflicts, pendingSchedule: updatedSchedule)
            return
        }
        
        // 執行保存
        performScheduleSave(updatedSchedule, isEditing: true)
    }
    
    /**
     * 保存新排程
     */
    private func saveNewSchedule() {
        guard let menu = selectedMenu, !selectedDates.isEmpty else { return }
        
        // 創建新排程
        let newSchedule = TrainingSchedule(
            id: UUID(),
            menuId: menu.id,
            patientId: patient.id,
            selectedDates: selectedDates,
            timeSlots: menu.timeSlots
        )
        
        // 檢查衝突
        if let conflicts = checkForConflicts(with: newSchedule, excludingMenuId: menu.id) {
            handleConflicts(conflicts, pendingSchedule: newSchedule)
            return
        }
        
        // 執行保存
        performScheduleSave(newSchedule, isEditing: false)
    }
    
    /**
     * 檢查排程衝突
     * - Parameters:
     *   - schedule: 要檢查的排程
     *   - excludingMenuId: 要排除的菜單 ID
     * - Returns: 衝突的排程列表，如果沒有衝突則返回 nil
     */
    private func checkForConflicts(with schedule: TrainingSchedule, excludingMenuId: UUID) -> [TrainingSchedule]? {
        let existingSchedules = scheduleStore.getSchedulesForPatient(patient.id)
        
        let conflicts = existingSchedules.filter { existingSchedule in
            // 排除相同菜單
            if existingSchedule.menuId == excludingMenuId {
                return false
            }
            
            // 檢查日期重疊
            return !dateService.findOverlappingDates(schedule.dates, existingSchedule.dates).isEmpty
        }
        
        return conflicts.isEmpty ? nil : conflicts
    }
    
    /**
     * 處理衝突
     * - Parameters:
     *   - conflicts: 衝突的排程列表
     *   - pendingSchedule: 待處理的排程
     */
    private func handleConflicts(_ conflicts: [TrainingSchedule], pendingSchedule: TrainingSchedule) {
        overlappingSchedules = conflicts
        self.pendingSchedule = pendingSchedule
        uiStateManager.showOverlapWarning()
    }
    
    /**
     * 執行排程保存
     * - Parameters:
     *   - schedule: 要保存的排程
     *   - isEditing: 是否為編輯模式
     */
    private func performScheduleSave(_ schedule: TrainingSchedule, isEditing: Bool) {
        // 如果是編輯模式，先移除舊排程
        if isEditing, let oldSchedule = scheduleBeingEdited {
            scheduleStore.removeSchedule(oldSchedule)
        }
        
        // 合併相同菜單的排程
        let mergedSchedule = mergeWithExistingSchedules(schedule)
        
        // 保存排程
        scheduleStore.addSchedule(mergedSchedule)
        scheduleStore.saveSchedules()
        scheduleStore.reloadSchedules()
        
        // 更新狀態以繼續編輯
        updateStateAfterSave(mergedSchedule)
    }
    
    /**
     * 合併相同菜單的排程
     * - Parameter schedule: 新排程
     * - Returns: 合併後的排程
     */
    private func mergeWithExistingSchedules(_ schedule: TrainingSchedule) -> TrainingSchedule {
        let sameMenuSchedules = scheduleStore.getSchedulesForPatient(patient.id)
            .filter { $0.menuId == schedule.menuId && $0.id != schedule.id }
        
        guard !sameMenuSchedules.isEmpty else {
            return schedule
        }
        
        // 合併日期
        var allDates = schedule.dates
        for existingSchedule in sameMenuSchedules {
            allDates.formUnion(existingSchedule.dates)
            scheduleStore.removeSchedule(existingSchedule)
        }
        
        return TrainingSchedule(
            id: schedule.id,
            menuId: schedule.menuId,
            patientId: schedule.patientId,
            selectedDates: allDates,
            timeSlots: schedule.timeSlots
        )
    }
    
    /**
     * 保存後更新狀態
     * - Parameter savedSchedule: 已保存的排程
     */
    private func updateStateAfterSave(_ savedSchedule: TrainingSchedule) {
        selectedDates = savedSchedule.dates
        isEditingExistingSchedule = true
        scheduleBeingEdited = savedSchedule
        originalScheduleDates = savedSchedule.dates
        
        uiStateManager.showingEditScheduleOptions = false
        uiStateManager.refreshCalendar()
    }
    
    /**
     * 移除重疊的日期
     * - Parameters:
     *   - overlappingSchedule: 有重疊的排程
     *   - pendingSchedule: 待處理的排程
     */
    private func removeOverlappingDates(from overlappingSchedule: TrainingSchedule, with pendingSchedule: TrainingSchedule) {
        let overlappingDates = dateService.findOverlappingDates(overlappingSchedule.dates, pendingSchedule.dates)
        let remainingDates = dateService.removeDates(overlappingDates, from: overlappingSchedule.dates)
        
        if remainingDates.isEmpty {
            scheduleStore.removeSchedule(overlappingSchedule)
        } else {
            let updatedSchedule = TrainingSchedule(
                id: overlappingSchedule.id,
                menuId: overlappingSchedule.menuId,
                patientId: overlappingSchedule.patientId,
                selectedDates: remainingDates,
                timeSlots: overlappingSchedule.timeSlots
            )
            scheduleStore.removeSchedule(overlappingSchedule)
            scheduleStore.addSchedule(updatedSchedule)
        }
    }
    
    /**
     * 保存待處理的排程
     * - Parameter pendingSchedule: 待處理的排程
     */
    private func savePendingSchedule(_ pendingSchedule: TrainingSchedule) {
        guard let currentSelectedMenu = selectedMenu,
              currentSelectedMenu.id == pendingSchedule.menuId else { return }
        
        // 合併並保存
        let mergedSchedule = mergeWithExistingSchedules(pendingSchedule)
        scheduleStore.addSchedule(mergedSchedule)
        scheduleStore.saveSchedules()
        scheduleStore.reloadSchedules()
        
        // 更新狀態
        updateStateAfterSave(mergedSchedule)
    }
    
    /**
     * 清理待處理狀態
     */
    private func clearPendingStates() {
        pendingSchedule = nil
        overlappingSchedules = []
        uiStateManager.showingOverlapAlert = false
        uiStateManager.showingEditScheduleOptions = false
    }
}
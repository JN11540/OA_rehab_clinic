import SwiftUI
import Foundation

/**
 * AssessmentSchedulingViewModel - 評估排程視圖模型
 *
 * 功能說明：
 * - 專注於評估量表的排程管理
 * - 處理評估排程的新增、編輯、刪除等業務邏輯
 * - 實施月份範圍保護機制
 *
 * 設計原則：
 * - 單一職責：只負責評估排程相關的業務邏輯
 * - 月份保護：確保只能編輯當前月份的排程
 * - 響應式：使用 @Published 確保 UI 自動更新
 */
@MainActor
class AssessmentSchedulingViewModel: ObservableObject {
    
    // MARK: - 評估排程狀態
    
    /// 選中的評估量表
    @Published var selectedAssessment: Assessment?
    
    /// 選中的日期集合
    @Published var selectedDates: Set<Date> = []
    
    /// 當前月份的原始評估日期（用於比較變更）
    @Published var originalAssessmentDatesInCurrentMonth: Set<Date> = []
    
    // MARK: - 依賴注入
    
    private var patient: Patient
    private let assessmentStore: AssessmentStore
    private let uiStateManager: CalendarUIStateManager
    private let dateService = DateRangeService.shared
    private let calendar = Calendar.current
    
    // MARK: - 初始化
    
    init(
        patient: Patient,
        uiStateManager: CalendarUIStateManager,
        assessmentStore: AssessmentStore = .shared
    ) {
        self.patient = patient
        self.uiStateManager = uiStateManager
        self.assessmentStore = assessmentStore
    }
    
    // MARK: - 計算屬性
    
    /// 是否有未保存的變更
    var hasChanges: Bool {
        if selectedAssessment != nil {
            // 比較當前選擇與原始狀態的差異
            return selectedDates != originalAssessmentDatesInCurrentMonth
        }
        return false
    }
    
    /// 按鈕文字
    var saveButtonText: String {
        if selectedAssessment != nil {
            // 檢查當前月份是否原本有安排
            if originalAssessmentDatesInCurrentMonth.isEmpty {
                return "儲存評估安排"
            } else {
                return "更新評估安排"
            }
        } else {
            return "儲存評估安排"
        }
    }
    
    /// 評估集合（用於 UnifiedCalendarContainer）
    var selectedAssessmentSet: Set<Assessment> {
        if let assessment = selectedAssessment {
            return [assessment]
        }
        return []
    }
    
    // MARK: - 公開方法
    
    /**
     * 重置所有狀態
     */
    func resetState() {
        selectedDates.removeAll()
        selectedAssessment = nil
        originalAssessmentDatesInCurrentMonth.removeAll()
    }
    
    /**
     * 更新患者資料
     * - Parameter patient: 新的患者資料
     */
    func updatePatient(_ patient: Patient) {
        self.patient = patient
        
        // 如果有選中的評估，更新其資料
        if let currentAssessment = selectedAssessment,
           let updatedAssessment = patient.assessments.first(where: { $0.id == currentAssessment.id }) {
            selectedAssessment = updatedAssessment
        }
    }
    
    /**
     * 處理日期範圍選擇
     * - Parameter dates: 選中的日期集合
     */
    func handleDateRangeSelection(_ dates: Set<Date>) {
        // 確保只能選擇當前月份的日期
        let currentMonthDates = dateService.filterDatesInMonth(dates, month: uiStateManager.currentDate)
        selectedDates = dateService.normalizeDates(currentMonthDates)
    }
    
    /**
     * 處理評估選擇
     * - Parameter assessment: 選中的評估量表
     */
    func handleAssessmentSelection(_ assessment: Assessment) {
        // 點擊不同的評估量表時切換
        if selectedAssessment?.id != assessment.id {
            // 選擇新的評估量表
            selectedAssessment = assessment
            
            // 獲取當前月份的已安排日期
            let currentMonthDates = dateService.filterDatesInMonth(
                assessment.scheduledDates,
                month: uiStateManager.currentDate
            )
            
            // 直接進入當前月份編輯模式
            selectedDates = currentMonthDates
            originalAssessmentDatesInCurrentMonth = currentMonthDates
            
            // 強制刷新月曆以顯示更新的 dots
            uiStateManager.refreshCalendar()
        }
        // 如果點擊的是已選中的評估，保持選中狀態不變
    }
    
    /**
     * 保存評估排程
     */
    func saveSchedule() {
        guard let assessment = selectedAssessment else { return }
        
        // 總是使用當前月份保護的方式保存
        saveAssessmentForCurrentMonth()
    }
    
    // MARK: - 私有方法
    
    /**
     * 保存當前月份的評估安排（月份範圍保護）
     */
    private func saveAssessmentForCurrentMonth() {
        guard let assessment = selectedAssessment else { return }
        
        // 保留其他月份的安排日期
        let otherMonthDates = dateService.filterDatesNotInMonth(
            assessment.scheduledDates,
            month: uiStateManager.currentDate
        )
        
        // 合併其他月份的日期和當前月份的新選擇
        let finalScheduledDates = otherMonthDates.union(selectedDates)
        
        // 更新評估
        var updatedAssessment = assessment
        updatedAssessment.scheduledDates = finalScheduledDates
        
        assessmentStore.updateAssessment(updatedAssessment, for: patient.id)
        
        // 重載患者資料
        reloadPatientData()
        
        // 更新狀態：保存後更新原始日期記錄，保持選中狀態
        let currentMonthDates = dateService.filterDatesInMonth(
            finalScheduledDates,
            month: uiStateManager.currentDate
        )
        
        selectedDates = currentMonthDates
        originalAssessmentDatesInCurrentMonth = currentMonthDates
        
        uiStateManager.refreshCalendar()
        
        // 發送通知
        NotificationCenter.default.post(name: .assessmentsDidUpdate, object: nil)
    }
    
    /**
     * 重新載入患者資料
     */
    private func reloadPatientData() {
        if let freshlyUpdatedPatient = PatientStore.shared.patients.first(where: { $0.id == patient.id }) {
            patient = freshlyUpdatedPatient
            
            if let currentAssessment = selectedAssessment,
               let updatedAssessment = freshlyUpdatedPatient.assessments.first(where: { $0.id == currentAssessment.id }) {
                selectedAssessment = updatedAssessment
            }
        }
    }
}
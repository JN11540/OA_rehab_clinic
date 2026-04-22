import SwiftUI

/**
 * AssessmentCalendarContainer - 評估月曆容器組件
 *
 * 功能說明：
 * - 處理評估排程相關的業務邏輯
 * - 整合 BaseCalendarView 和 AssessmentStore
 * - 支援多種評估類型的顯示和編輯
 * - 管理評估指示器（彩色小圓點）
 *
 * 設計原則：
 * - 分離關注點：UI 邏輯委託給 BaseCalendarView
 * - 業務邏輯集中：所有評估相關邏輯在此處理
 * - 靈活性：支援同時顯示多種評估類型
 *
 * 架構重構說明：
 * - 從原本的 CalendarCard 中提取評估相關邏輯
 * - 作為 BaseCalendarView 的容器，處理業務邏輯
 * - 使用指示器而非背景色來顯示評估
 */

// MARK: - Assessment Calendar View Model
class AssessmentCalendarViewModel: ObservableObject {
    @Published var selectedDates: Set<Date> = []
    @Published var selectedAssessments: Set<Assessment> = []
    
    let patient: Patient
    var onDateRangeSelected: ((Set<Date>) -> Void)?
    var allowPastDatesSelection: Bool = false
    
    private let calendar = Calendar.current
    private let assessmentStore = AssessmentStore.shared
    
    init(patient: Patient) {
        self.patient = patient
    }
    
    // MARK: - Public Methods
    func configureForAssessments(_ assessments: Set<Assessment>) {
        self.selectedAssessments = assessments
        self.selectedDates.removeAll()
    }
    
    func clearSelection() {
        self.selectedAssessments.removeAll()
        self.selectedDates.removeAll()
    }
    
    // MARK: - Assessment Helpers
    func getAssessmentsOnDate(_ date: Date) -> [Assessment] {
        assessmentStore.getAssessments(for: patient.id).filter { assessment in
            assessment.scheduledDates.contains { scheduledDate in
                calendar.isDate(scheduledDate, inSameDayAs: date)
            } || assessment.completedDates.contains { completedDate in
                calendar.isDate(completedDate, inSameDayAs: date)
            }
        }
    }
    
    func getAssessmentIndicators(for date: Date) -> [Color] {
        let isPastDate = calendar.startOfDay(for: date) < calendar.startOfDay(for: Date())
        var indicators: [Color] = []
        
        // 先加入所有已保存的評估（包括正在編輯的評估）
        for assessment in getAssessmentsOnDate(date) {
            let baseColor = assessment.type.color
            let finalColor = isPastDate ? baseColor.opacity(0.3) : baseColor
            indicators.append(finalColor)
        }
        
        // 如果正在編輯評估，檢查是否有新選中但尚未保存的日期
        if !selectedAssessments.isEmpty {
            let isDateSelected = selectedDates.contains { calendar.isDate($0, inSameDayAs: date) }
            
            // 只有當日期被選中且該評估在這個日期還沒有安排時，才添加預覽指示器
            if isDateSelected {
                for assessment in selectedAssessments {
                    let alreadyScheduled = assessment.scheduledDates.contains { scheduledDate in
                        calendar.isDate(scheduledDate, inSameDayAs: date)
                    }
                    
                    if !alreadyScheduled {
                        let baseColor = assessment.type.color
                        let previewColor = isPastDate ? baseColor.opacity(0.2) : baseColor.opacity(0.6)
                        indicators.append(previewColor)
                    }
                }
            }
        }
        
        return indicators
    }
    
    func isDateSelectable(_ date: Date) -> Bool {
        guard let normalizedDate = calendar.normalizedDate(from: date),
              let normalizedToday = calendar.normalizedDate(from: Date()) else {
            return false
        }
        
        // 如果允許選擇過去日期，則所有日期都可選擇
        if allowPastDatesSelection {
            return true
        }
        
        return normalizedDate >= normalizedToday
    }
}

// MARK: - Assessment Calendar Container
struct AssessmentCalendarContainer: View {
    @Binding var currentDate: Date
    @StateObject private var viewModel: AssessmentCalendarViewModel
    @EnvironmentObject private var assessmentStore: AssessmentStore
    @EnvironmentObject private var scheduleStore: TrainingScheduleStore
    
    let isEditable: Bool
    let selectionMode: SelectionMode
    let onDateSelected: ((Date) -> Void)?
    
    enum SelectionMode {
        case single
        case range
    }
    
    init(
        currentDate: Binding<Date>,
        patient: Patient,
        selectedAssessments: Set<Assessment> = [],
        isEditable: Bool = true,
        selectionMode: SelectionMode = .range,
        allowPastDatesSelection: Bool = false,
        onDateRangeSelected: ((Set<Date>) -> Void)? = nil,
        onDateSelected: ((Date) -> Void)? = nil
    ) {
        self._currentDate = currentDate
        self.isEditable = isEditable
        self.selectionMode = selectionMode
        self.onDateSelected = onDateSelected
        
        // 配置視圖模型
        let vm = AssessmentCalendarViewModel(patient: patient)
        vm.selectedAssessments = selectedAssessments
        vm.onDateRangeSelected = onDateRangeSelected
        vm.allowPastDatesSelection = allowPastDatesSelection
        self._viewModel = StateObject(wrappedValue: vm)
    }
    
    var body: some View {
        BaseCalendarView(
            currentDate: $currentDate,
            delegate: self
        )
    }
}

// MARK: - Base Calendar Delegate
extension AssessmentCalendarContainer: BaseCalendarDelegate {
    func calendar(_ calendar: BaseCalendarView, configureCell date: Date, day: Int) -> DateCellData {
        guard let normalizedDate = Calendar.current.normalizedDate(from: date) else {
            return DateCellData(
                date: date,
                day: day,
                isInCurrentMonth: true,
                isToday: false,
                isPast: false,
                isSelectable: false
            )
        }
        
        let isToday = Calendar.current.isDateInToday(normalizedDate)
        let isPast = Calendar.current.startOfDay(for: normalizedDate) < Calendar.current.startOfDay(for: Date())
        let isSelectable = viewModel.isDateSelectable(normalizedDate)
        
        // 檢查是否為選中日期（單日選擇模式下）
        let isSelected = selectionMode == .single && Calendar.current.isDate(normalizedDate, inSameDayAs: currentDate)
        
        var cellData = DateCellData(
            date: normalizedDate,
            day: day,
            isInCurrentMonth: true,
            isToday: isToday,
            isPast: isPast,
            isSelectable: isSelectable && isEditable
        )
        
        // 設定訓練背景色（在評估編輯模式下顯示完整排程資訊）
        if let menu = getTrainingMenuForDate(normalizedDate) {
            cellData.backgroundColor = menu.color
            cellData.opacity = isPast ? 0.3 : 0.4  // 評估編輯時訓練背景稍微淡一些
        }
        
        // 為選中日期添加視覺指示（僅在單日選擇模式下）
        if isSelected {
            if cellData.backgroundColor == nil {
                // 沒有訓練背景色：使用藍色半透明背景
                cellData.backgroundColor = .blue.opacity(0.2)
                cellData.foregroundColor = .blue
            } else {
                // 有訓練背景色：使用藍色邊框以保持訓練排程可見性
                cellData.showBorder = true
                cellData.borderColor = .blue
                cellData.borderWidth = 3
                // 保持原本的文字顏色，不強制改為白色
            }
        }
        
        // 設定評估指示器
        cellData.indicators = viewModel.getAssessmentIndicators(for: normalizedDate)
        
        return cellData
    }
    
    func calendar(_ calendar: BaseCalendarView, didSelectDate date: Date) {
        guard isEditable else { return }
        guard let normalizedDate = Calendar.current.normalizedDate(from: date) else { return }
        
        // 處理評估排程選擇
        if !viewModel.selectedAssessments.isEmpty {
            // 正在編輯評估
            if viewModel.selectedDates.contains(normalizedDate) {
                viewModel.selectedDates.remove(normalizedDate)
            } else if viewModel.isDateSelectable(normalizedDate) {
                viewModel.selectedDates.insert(normalizedDate)
            }
            
            viewModel.onDateRangeSelected?(viewModel.selectedDates)
            return
        }
        
        // 單日選擇模式
        if selectionMode == .single {
            currentDate = normalizedDate
            onDateSelected?(normalizedDate)
        }
    }
    
    func calendar(_ calendar: BaseCalendarView, didChangeToMonth month: Int, year: Int) {
        // 切換月份時清除選擇
        viewModel.selectedDates.removeAll()
        viewModel.onDateRangeSelected?(viewModel.selectedDates)
    }
}

// MARK: - Unified Calendar Container
/**
 * UnifiedCalendarContainer - 統一月曆容器
 *
 * 功能說明：
 * - 整合訓練和評估兩種月曆功能
 * - 作為原 CalendarCard 的替代品
 * - 根據參數自動選擇使用 TrainingCalendarContainer 或 AssessmentCalendarContainer
 * - 保持與原 CalendarCard 相同的接口
 */
struct UnifiedCalendarContainer: View {
    @Binding var currentDate: Date
    let patient: Patient
    var selectedMenu: TrainingMenu?
    var selectedAssessments: Set<Assessment>
    var onDateRangeSelected: ((Set<Date>) -> Void)?
    var onDateSelected: ((Date) -> Void)?
    var onExistingScheduleTap: ((Date) -> Void)?
    var selectionMode: SelectionMode = .range
    var isEditable: Bool = true
    var isEditingExistingSchedule: Bool = false
    var initialSelectedDates: Set<Date> = []
    var allowPastDatesSelection: Bool = false
    
    enum SelectionMode {
        case single
        case range
    }
    
    var body: some View {
        Group {
            if selectedMenu != nil || (!selectedAssessments.isEmpty && selectedMenu == nil) {
                // 如果有選中的訓練菜單，或者只有評估沒有訓練菜單
                if selectedMenu != nil {
                    // 訓練月曆（改進版：同時顯示評估指示器）
                    TrainingCalendarContainer(
                        currentDate: $currentDate,
                        patient: patient,
                        selectedMenu: selectedMenu,
                        isEditable: isEditable,
                        selectionMode: selectionMode == .single ? .single : .range,
                        onDateRangeSelected: onDateRangeSelected,
                        onDateSelected: onDateSelected,
                        onExistingScheduleTap: onExistingScheduleTap,
                        isEditingExistingSchedule: isEditingExistingSchedule,
                        initialSelectedDates: initialSelectedDates
                    )
                } else {
                    // 評估月曆（改進版：同時顯示訓練背景）
                    AssessmentCalendarContainer(
                        currentDate: $currentDate,
                        patient: patient,
                        selectedAssessments: selectedAssessments,
                        isEditable: isEditable,
                        selectionMode: selectionMode == .single ? .single : .range,
                        allowPastDatesSelection: allowPastDatesSelection,
                        onDateRangeSelected: onDateRangeSelected,
                        onDateSelected: onDateSelected
                    )
                }
            } else {
                // 混合顯示模式（訓練背景 + 評估指示器）
                MixedCalendarContainer(
                    currentDate: $currentDate,
                    patient: patient,
                    isEditable: isEditable,
                    selectionMode: selectionMode == .single ? .single : .range,
                    onDateSelected: onDateSelected,
                    onExistingScheduleTap: onExistingScheduleTap,
                    allowPastDatesSelection: allowPastDatesSelection
                )
            }
        }
    }
}

// MARK: - Mixed Calendar Container
/**
 * MixedCalendarContainer - 混合月曆容器
 *
 * 功能說明：
 * - 同時顯示訓練排程（背景色）和評估排程（指示器）
 * - 用於一般瀏覽模式，不進行編輯
 * - 支援點擊現有排程進入編輯
 */
struct MixedCalendarContainer: View {
    @Binding var currentDate: Date
    let patient: Patient
    let isEditable: Bool
    let selectionMode: UnifiedCalendarContainer.SelectionMode
    let onDateSelected: ((Date) -> Void)?
    let onExistingScheduleTap: ((Date) -> Void)?
    let allowPastDatesSelection: Bool
    
    @StateObject private var trainingViewModel: TrainingCalendarViewModel
    @StateObject private var assessmentViewModel: AssessmentCalendarViewModel
    @EnvironmentObject private var scheduleStore: TrainingScheduleStore
    @EnvironmentObject private var assessmentStore: AssessmentStore
    
    init(
        currentDate: Binding<Date>,
        patient: Patient,
        isEditable: Bool,
        selectionMode: UnifiedCalendarContainer.SelectionMode,
        onDateSelected: ((Date) -> Void)?,
        onExistingScheduleTap: ((Date) -> Void)?,
        allowPastDatesSelection: Bool = false
    ) {
        self._currentDate = currentDate
        self.patient = patient
        self.isEditable = isEditable
        self.selectionMode = selectionMode
        self.onDateSelected = onDateSelected
        self.onExistingScheduleTap = onExistingScheduleTap
        self.allowPastDatesSelection = allowPastDatesSelection
        
        // 配置訓練視圖模型以支援過去日期選擇
        let trainingVM = TrainingCalendarViewModel(patient: patient)
        trainingVM.allowPastDatesSelection = allowPastDatesSelection
        self._trainingViewModel = StateObject(wrappedValue: trainingVM)
        
        // 配置評估視圖模型以支援過去日期選擇  
        let assessmentVM = AssessmentCalendarViewModel(patient: patient)
        assessmentVM.allowPastDatesSelection = allowPastDatesSelection
        self._assessmentViewModel = StateObject(wrappedValue: assessmentVM)
    }
    
    var body: some View {
        BaseCalendarView(
            currentDate: $currentDate,
            delegate: self
        )
    }
}

// MARK: - Mixed Calendar Delegate
extension MixedCalendarContainer: BaseCalendarDelegate {
    func calendar(_ calendar: BaseCalendarView, configureCell date: Date, day: Int) -> DateCellData {
        guard let normalizedDate = Calendar.current.normalizedDate(from: date) else {
            return DateCellData(
                date: date,
                day: day,
                isInCurrentMonth: true,
                isToday: false,
                isPast: false,
                isSelectable: false
            )
        }
        
        let isToday = Calendar.current.isDateInToday(normalizedDate)
        let isPast = Calendar.current.startOfDay(for: normalizedDate) < Calendar.current.startOfDay(for: Date())
        let isSelectable = trainingViewModel.isDateSelectable(normalizedDate)
        
        // 檢查是否為選中日期
        // 在可編輯模式下，使用正常的選擇邏輯
        // 在非編輯模式下（如CaseManageView），只在當前月份且是今天時才選中
        let today = Date()
        let isSelected: Bool
        if isEditable {
            // 可編輯模式：正常的日期選擇邏輯
            isSelected = Calendar.current.isDate(normalizedDate, inSameDayAs: currentDate)
        } else {
            // 非編輯模式：只在當前月份且是今天時才選中
            let currentMonth = Calendar.current.component(.month, from: currentDate)
            let currentYear = Calendar.current.component(.year, from: currentDate)
            let todayMonth = Calendar.current.component(.month, from: today)
            let todayYear = Calendar.current.component(.year, from: today)
            isSelected = Calendar.current.isDateInToday(normalizedDate) && 
                        (currentMonth == todayMonth && currentYear == todayYear)
        }
        
        var cellData = DateCellData(
            date: normalizedDate,
            day: day,
            isInCurrentMonth: true,
            isToday: isToday,
            isPast: isPast,
            isSelectable: isSelectable && isEditable
        )
        
        // 設定訓練背景顏色
        if let menu = trainingViewModel.getMenuForDate(normalizedDate) {
            cellData.backgroundColor = menu.color
            cellData.opacity = isPast ? 0.3 : 0.9
        }
        
        // 為選中日期添加視覺指示
        if isSelected {
            if cellData.backgroundColor == nil {
                // 沒有訓練背景色：使用藍色半透明背景
                cellData.backgroundColor = .blue.opacity(0.2)
                cellData.foregroundColor = .blue
            } else {
                // 有訓練背景色：使用藍色邊框以保持訓練排程可見性
                cellData.showBorder = true
                cellData.borderColor = .blue
                cellData.borderWidth = 3
                // 保持原本的文字顏色，不強制改為白色
            }
        }
        
        // 添加評估指示器
        cellData.indicators = assessmentViewModel.getAssessmentIndicators(for: normalizedDate)
        
        return cellData
    }
    
    func calendar(_ calendar: BaseCalendarView, didSelectDate date: Date) {
        guard let normalizedDate = Calendar.current.normalizedDate(from: date) else { return }
        
        // 檢查是否有現有排程
        if !trainingViewModel.getSchedulesOnDate(normalizedDate).isEmpty {
            onExistingScheduleTap?(normalizedDate)
            return
        }
        
        // 單日選擇模式
        if selectionMode == .single {
            currentDate = normalizedDate
            onDateSelected?(normalizedDate)
        }
    }
    
    func calendar(_ calendar: BaseCalendarView, didChangeToMonth month: Int, year: Int) {
        // 在可編輯模式下，智能選擇合適的日期
        // 避免跨月份的日期數字混淆（例如從當月23號切換到其他月份23號）
        if isEditable {
            let today = Date()
            let currentMonth = Calendar.current.component(.month, from: today)
            let currentYear = Calendar.current.component(.year, from: today)
            
            if month == currentMonth && year == currentYear {
                // 如果切換到當前月份，選擇今天
                currentDate = today
            } else {
                // 否則選擇該月1號，避免日期選擇混淆
                if let firstDayOfMonth = Calendar.current.date(from: DateComponents(year: year, month: month, day: 1)) {
                    currentDate = firstDayOfMonth
                }
            }
        }
    }
}

// MARK: - Training Background Support
extension AssessmentCalendarContainer {
    /// 獲取訓練背景色（支援在評估編輯模式下顯示完整排程資訊）
    private func getTrainingMenuForDate(_ date: Date) -> TrainingMenu? {
        // 獲取該日期的所有訓練排程
        let schedulesOnDate = getTrainingSchedulesOnDate(date)
        
        // 如果有排程，返回第一個菜單（通常每個日期只會有一個訓練菜單）
        if let schedule = schedulesOnDate.first,
           let menu = TrainingMenuStore.shared.getMenu(by: schedule.menuId) {
            return menu
        }
        
        return nil
    }
    
    /// 獲取指定日期的訓練排程列表
    private func getTrainingSchedulesOnDate(_ date: Date) -> [TrainingSchedule] {
        return scheduleStore.getSchedulesForPatient(viewModel.patient.id)
            .filter { $0.isDateInRange(date) }
    }
}
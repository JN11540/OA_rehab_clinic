import SwiftUI
import Foundation

/**
 * TrainingCalendarContainer - 訓練月曆容器組件
 *
 * 功能說明：
 * - 處理訓練排程相關的業務邏輯
 * - 整合 BaseCalendarView 和 TrainingScheduleStore
 * - 支援新增和編輯訓練排程
 * - 管理日期選擇和拖曳操作
 *
 * 設計原則：
 * - 分離關注點：UI 邏輯委託給 BaseCalendarView
 * - 業務邏輯集中：所有訓練相關邏輯在此處理
 * - 狀態管理清晰：使用 ObservableObject 管理狀態
 *
 * 架構重構說明：
 * - 從原本的 CalendarCard 中提取訓練相關邏輯
 * - 作為 BaseCalendarView 的容器，處理業務邏輯
 * - 實現 BaseCalendarDelegate 和 DateRangeGestureDelegate
 */

// MARK: - Training Calendar View Model
class TrainingCalendarViewModel: ObservableObject {
    @Published var selectedDates: Set<Date> = []
    @Published var isDragging = false
    @Published var selectedMenu: TrainingMenu?
    @Published var isEditingExistingSchedule: Bool = false
    
    let patient: Patient
    var onDateRangeSelected: ((Set<Date>) -> Void)?
    var onExistingScheduleTap: ((Date) -> Void)?
    var allowPastDatesSelection: Bool = false
    
    private let calendar = Calendar.current
    private let scheduleStore = TrainingScheduleStore.shared
    
    init(patient: Patient) {
        self.patient = patient
    }
    
    // MARK: - Public Methods
    func configureForNewSchedule(menu: TrainingMenu) {
        self.selectedMenu = menu
        self.isEditingExistingSchedule = false
        self.selectedDates.removeAll()
    }
    
    func configureForEditingSchedule(menu: TrainingMenu, existingDates: Set<Date>) {
        self.selectedMenu = menu
        self.isEditingExistingSchedule = true
        self.selectedDates = existingDates
    }
    
    func clearSelection() {
        self.selectedMenu = nil
        self.isEditingExistingSchedule = false
        self.selectedDates.removeAll()
    }
    
    // MARK: - Date Helpers
    func getSchedulesOnDate(_ date: Date) -> [TrainingSchedule] {
        scheduleStore.getSchedulesForPatient(patient.id)
            .filter { $0.isDateInRange(date) }
    }
    
    func getMenuForDate(_ date: Date) -> TrainingMenu? {
        // 1. 如果正在選擇/編輯，優先顯示當前選中的日期
        if selectedMenu != nil && selectedDates.contains(where: { calendar.isDate($0, inSameDayAs: date) }) {
            return selectedMenu
        }
        
        // 2. 檢查該日期是否有已保存的排程
        let schedulesOnDate = getSchedulesOnDate(date)
        
        // 3. 如果有選中的菜單，優先顯示該菜單的排程
        if let selectedMenu = selectedMenu {
            let selectedMenuSchedules = schedulesOnDate.filter { $0.menuId == selectedMenu.id }
            if !selectedMenuSchedules.isEmpty {
                return selectedMenu
            }
        }
        
        // 4. 否則顯示任何已保存的排程
        if let schedule = schedulesOnDate.first,
           let menu = TrainingMenuStore.shared.getMenu(by: schedule.menuId) {
            return menu
        }
        
        return nil
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

// MARK: - Training Calendar Container
struct TrainingCalendarContainer: View {
    @Binding var currentDate: Date
    @StateObject private var viewModel: TrainingCalendarViewModel
    @EnvironmentObject private var scheduleStore: TrainingScheduleStore
    @EnvironmentObject private var assessmentStore: AssessmentStore
    @State private var calendarSize: CGSize = .zero
    
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
        selectedMenu: TrainingMenu? = nil,
        isEditable: Bool = true,
        selectionMode: SelectionMode = .range,
        onDateRangeSelected: ((Set<Date>) -> Void)? = nil,
        onDateSelected: ((Date) -> Void)? = nil,
        onExistingScheduleTap: ((Date) -> Void)? = nil,
        isEditingExistingSchedule: Bool = false,
        initialSelectedDates: Set<Date> = []
    ) {
        self._currentDate = currentDate
        self.isEditable = isEditable
        self.selectionMode = selectionMode
        self.onDateSelected = onDateSelected
        
        // 配置視圖模型
        let vm = TrainingCalendarViewModel(patient: patient)
        vm.selectedMenu = selectedMenu
        vm.isEditingExistingSchedule = isEditingExistingSchedule
        vm.selectedDates = initialSelectedDates
        vm.onDateRangeSelected = onDateRangeSelected
        vm.onExistingScheduleTap = onExistingScheduleTap
        self._viewModel = StateObject(wrappedValue: vm)
    }
    
    var body: some View {
        BaseCalendarView(
            currentDate: $currentDate,
            delegate: self
        )
        .background(
            GeometryReader { geometry in
                Color.clear
                    .onAppear { 
                        calendarSize = geometry.size
                    }
                    .onChange(of: geometry.size) { newSize in
                        calendarSize = newSize
                    }
            }
        )
        .dateRangeGesture(
            size: calendarSize,
            firstWeekday: firstWeekday,
            daysInMonth: daysInMonth,
            currentYear: currentYear,
            currentMonth: currentMonth,
            maxWeeks: 6,
            cellHeight: 40,
            delegate: isEditable && selectionMode == .range && calendarSize != .zero ? self : nil
        )
        .onAppear {
            setupInitialState()
        }
        .onChange(of: calendarSize) { _ in
            // 當尺寸變化時，確保拖曳手勢也更新
        }
        .onChange(of: viewModel.selectedMenu) { _ in
            // 當選中的菜單變化時，強制刷新視圖以更新顏色
        }
    }
    
    // MARK: - Calendar Properties
    private var calendar: Calendar { Calendar.current }
    
    private var currentYear: Int {
        calendar.component(.year, from: currentDate)
    }
    
    private var currentMonth: Int {
        calendar.component(.month, from: currentDate)
    }
    
    private var daysInMonth: Int {
        calendar.range(of: .day, in: .month, for: currentDate)?.count ?? 30
    }
    
    private var firstWeekday: Int {
        let components = DateComponents(year: currentYear, month: currentMonth)
        let firstDate = calendar.date(from: components)!
        return calendar.component(.weekday, from: firstDate) - 1
    }
    
    // MARK: - Setup
    private func setupInitialState() {
        // 如果是編輯現有排程，載入原始日期
        if viewModel.isEditingExistingSchedule && viewModel.selectedMenu != nil {
            let menuDates = scheduleStore.getSchedulesForPatient(viewModel.patient.id)
                .filter { $0.menuId == viewModel.selectedMenu!.id }
                .flatMap { $0.dates }
            
            for date in menuDates {
                if let normalizedDate = calendar.normalizedDate(from: date) {
                    viewModel.selectedDates.insert(normalizedDate)
                }
            }
            
            viewModel.onDateRangeSelected?(viewModel.selectedDates)
        }
    }
}

// MARK: - Base Calendar Delegate
extension TrainingCalendarContainer: BaseCalendarDelegate {
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
        
        // 設定背景顏色
        if let menu = viewModel.getMenuForDate(normalizedDate) {
            cellData.backgroundColor = menu.color
            
            // 正在編輯的排程顯示邊框
            if viewModel.isEditingExistingSchedule && 
               viewModel.selectedMenu?.id == menu.id &&
               viewModel.selectedDates.contains(normalizedDate) {
                cellData.showBorder = true
                cellData.borderColor = .white
                cellData.borderWidth = 2
            }
            
            // 根據狀態調整透明度
            if viewModel.selectedMenu != nil && viewModel.selectedDates.contains(normalizedDate) {
                // 正在選擇/編輯中
                cellData.opacity = viewModel.isEditingExistingSchedule ? 0.7 : 0.9
            } else if isEditable {
                // 可編輯模式下的既有排程
                cellData.opacity = 0.4
            } else {
                // 唯讀模式
                cellData.opacity = isPast ? 0.3 : 0.9
            }
        }
        
        // 添加評估指示器（在編輯模式下顯示完整排程資訊）
        cellData.indicators = getAssessmentIndicators(for: normalizedDate)
        
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
                // cellData.foregroundColor = .white  // 確保文字在有色背景上清晰可見
            }
        }
        
        return cellData
    }
    
    func calendar(_ calendar: BaseCalendarView, didSelectDate date: Date) {
        guard isEditable else { return }
        guard let normalizedDate = Calendar.current.normalizedDate(from: date) else { return }
        
        // 處理訓練排程選擇
        if viewModel.selectedMenu != nil {
            // 正在新增或編輯排程
            if viewModel.selectedDates.contains(normalizedDate) {
                // 防止刪除最後一個日期
                if viewModel.isEditingExistingSchedule && viewModel.selectedDates.count == 1 {
                    return
                }
                viewModel.selectedDates.remove(normalizedDate)
            } else if viewModel.isDateSelectable(normalizedDate) {
                viewModel.selectedDates.insert(normalizedDate)
            }
            
            viewModel.onDateRangeSelected?(viewModel.selectedDates)
            return
        }
        
        // 檢查是否點擊了現有排程
        if !viewModel.getSchedulesOnDate(normalizedDate).isEmpty {
            viewModel.onExistingScheduleTap?(normalizedDate)
            return
        }
        
        // 單日選擇模式
        if selectionMode == .single {
            currentDate = normalizedDate
            onDateSelected?(normalizedDate)
        }
    }
    
    func calendar(_ calendar: BaseCalendarView, didChangeToMonth month: Int, year: Int) {
        // 切換月份時清除選擇（除非正在編輯現有排程）
        if !viewModel.isEditingExistingSchedule {
            viewModel.selectedDates.removeAll()
            viewModel.onDateRangeSelected?(viewModel.selectedDates)
        }
    }
}

// MARK: - Date Range Gesture Delegate
extension TrainingCalendarContainer: DateRangeGestureDelegate {
    func didStartDragging(at date: Date) {
        viewModel.isDragging = true
        
        // 檢查起始日期是否已被選中
        let isInitiallySelected = viewModel.selectedDates.contains { selectedDate in
            calendar.isDate(selectedDate, inSameDayAs: date)
        }
        
        // 如果未選中，則添加
        if !isInitiallySelected && viewModel.isDateSelectable(date) {
            viewModel.selectedDates.insert(date)
            viewModel.onDateRangeSelected?(viewModel.selectedDates)
        }
    }
    
    func didUpdateDragging(from startDate: Date, to endDate: Date, dates: Set<Date>) {
        // 只保留可選擇的日期
        let selectableDates = dates.filter { viewModel.isDateSelectable($0) }
        viewModel.selectedDates = Set(selectableDates)
        viewModel.onDateRangeSelected?(viewModel.selectedDates)
    }
    
    func didEndDragging(selectedDates: Set<Date>) {
        viewModel.isDragging = false
        let selectableDates = selectedDates.filter { viewModel.isDateSelectable($0) }
        viewModel.selectedDates = Set(selectableDates)
        viewModel.onDateRangeSelected?(viewModel.selectedDates)
    }
    
    func isDateSelectable(_ date: Date) -> Bool {
        return viewModel.isDateSelectable(date)
    }
}

// MARK: - Assessment Indicators Support
extension TrainingCalendarContainer {
    /// 獲取評估指示器（支援在訓練編輯模式下顯示完整排程資訊）
    private func getAssessmentIndicators(for date: Date) -> [Color] {
        let calendar = Calendar.current
        let isPastDate = calendar.startOfDay(for: date) < calendar.startOfDay(for: Date())
        var indicators: [Color] = []
        
        // 獲取該日期的所有評估
        let assessmentsOnDate = getAssessmentsOnDate(date)
        
        // 為每個評估添加指示器
        for assessment in assessmentsOnDate {
            let baseColor = assessment.type.color
            let finalColor = isPastDate ? baseColor.opacity(0.3) : baseColor
            indicators.append(finalColor)
        }
        
        return indicators
    }
    
    /// 獲取指定日期的評估列表
    private func getAssessmentsOnDate(_ date: Date) -> [Assessment] {
        let calendar = Calendar.current
        return assessmentStore.getAssessments(for: viewModel.patient.id).filter { assessment in
            assessment.scheduledDates.contains { scheduledDate in
                calendar.isDate(scheduledDate, inSameDayAs: date)
            } || assessment.completedDates.contains { completedDate in
                calendar.isDate(completedDate, inSameDayAs: date)
            }
        }
    }
}
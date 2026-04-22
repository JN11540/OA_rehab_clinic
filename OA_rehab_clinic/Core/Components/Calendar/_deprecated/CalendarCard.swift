/*
import SwiftUI
import Foundation
#if canImport(UIKit)
import UIKit
#else
import AppKit
#endif

// RoundedRectangle 的擴展，用於設置不同角的圓角
#if canImport(UIKit)
struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}
#endif

// MARK: - Calendar Extensions
extension Calendar {
    func normalizedDate(from date: Date) -> Date? {
        let components = dateComponents([.year, .month, .day], from: date)
        return self.date(from: components)
    }
    
    func isDate(_ date1: Date, inSameMonthAs date2: Date) -> Bool {
        let components1 = dateComponents([.year, .month], from: date1)
        let components2 = dateComponents([.year, .month], from: date2)
        return components1.year == components2.year && components1.month == components2.month
    }
}

// MARK: - Color Utilities
private struct ColorUtilities {
    static func blend(_ colors: [Color], opacity: CGFloat = 1.0) -> Color {
        guard !colors.isEmpty else { return .clear }
        
        var totalRed: CGFloat = 0
        var totalGreen: CGFloat = 0
        var totalBlue: CGFloat = 0
        
        for color in colors {
            #if canImport(UIKit)
            let uiColor = UIColor(color)
            var red: CGFloat = 0
            var green: CGFloat = 0
            var blue: CGFloat = 0
            var alpha: CGFloat = 0
            
            uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
            
            totalRed += red
            totalGreen += green
            totalBlue += blue
            #else
            // Fallback for non-UIKit platforms (e.g., macOS using NSColor)
            // This is a simplified fallback. For accurate blending, you might need a more complex NSColor extension.
            let nsColor = NSColor(color)
            if let components = nsColor.cgColor.components, nsColor.cgColor.numberOfComponents >= 3 {
                totalRed += components[0]
                totalGreen += components[1]
                totalBlue += components[2]
            } else {
                // Default to a gray or skip if color components can't be read
                totalRed += 0.5; totalGreen += 0.5; totalBlue += 0.5;
            }
            #endif
        }
        
        let count = CGFloat(colors.count)
        #if canImport(UIKit)
        return Color(UIColor(
            red: totalRed / count,
            green: totalGreen / count,
            blue: totalBlue / count,
            alpha: opacity
        ))
        #else
        return Color(NSColor(
            calibratedRed: totalRed / count,
            green: totalGreen / count,
            blue: totalBlue / count,
            alpha: opacity
        ))
        #endif
    }
}

// MARK: - Date Range Handler
private struct DateRangeHandler {
    let calendar: Calendar
    let currentYear: Int
    let currentMonth: Int
    
    func calculateDateRange(from startDate: Date, to endDate: Date) -> Set<Date> {
        guard let normalizedStart = calendar.normalizedDate(from: startDate),
              let normalizedEnd = calendar.normalizedDate(from: endDate) else {
            return []
        }
        
        let rangeStart = normalizedStart <= normalizedEnd ? normalizedStart : normalizedEnd
        let rangeEnd = normalizedStart <= normalizedEnd ? normalizedEnd : normalizedStart
        
        var dates = Set<Date>()
        var currentDate = rangeStart
        
        // 添加所有日期，不限制在當月
        while currentDate <= rangeEnd {
            dates.insert(currentDate)
            
            guard let nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate) else { break }
            currentDate = nextDate
        }
        
        return dates
    }
    
    func isDateInRange(_ date: Date, start: Date, end: Date) -> Bool {
        guard let normalizedDate = calendar.normalizedDate(from: date),
              let normalizedStart = calendar.normalizedDate(from: start),
              let normalizedEnd = calendar.normalizedDate(from: end) else {
            return false
        }
        
        let (effectiveStart, effectiveEnd) = normalizedStart <= normalizedEnd ? 
            (normalizedStart, normalizedEnd) : 
            (normalizedEnd, normalizedStart)
        
        // 檢查日期是否在範圍內，不限制在當月
        return normalizedDate >= effectiveStart && normalizedDate <= effectiveEnd
    }
}

struct CalendarCard: View {
    @Binding var currentDate: Date
    let patient: Patient
    var selectedMenu: TrainingMenu?
    var selectedAssessments: Set<Assessment>  // For assessments actively being selected in UI
    @EnvironmentObject private var scheduleStore: TrainingScheduleStore
    @StateObject private var assessmentStore = AssessmentStore.shared // Directly observe AssessmentStore
    var onDateRangeSelected: ((Set<Date>) -> Void)?
    var onDateSelected: ((Date) -> Void)?
    var onExistingScheduleTap: ((Date) -> Void)?  // 新增：處理點擊現有排程的回調
    var selectionMode: SelectionMode = .range
    var isEditable: Bool = true  // 新增：控制是否可編輯
    var isEditingExistingSchedule: Bool = false  // 新增：標記是否正在編輯現有排程
    
    @State private var dragStartDate: Date?
    @State private var dragEndDate: Date?
    @State private var selectedDates: Set<Date> = []
    @State private var isDragging = false
    @State private var showingYearMonthPicker = false  // 新增：控制年月選擇器的顯示
    @State private var selectedYear: Int  // 新增：選擇的年份
    @State private var selectedMonth: Int  // 新增：選擇的月份
    @State private var lastProcessedDate: Date? = nil
    @State private var lastProcessedUpdateTime = Date()
    @State private var initialSelectionState: Bool = false
    @State private var isDraggingForward: Bool = true
    
    // Add this computed property to check if a date is within the current drag range
    private func isDateInCurrentDragRange(_ date: Date) -> Bool {
        guard isDragging, let start = dragStartDate, let end = dragEndDate else { return false }
        let (effectiveStart, effectiveEnd) = start <= end ? (start, end) : (end, start)
        return date >= effectiveStart && date <= effectiveEnd
    }

    // 選擇模式枚舉
    enum SelectionMode {
        case single    // 單日選擇
        case range     // 範圍選擇
    }
    
    // 初始化器
    init(currentDate: Binding<Date>, patient: Patient, selectedMenu: TrainingMenu? = nil,
         selectedAssessments: Set<Assessment> = [],  // 更新參數
         onDateRangeSelected: ((Set<Date>) -> Void)? = nil,
         onDateSelected: ((Date) -> Void)? = nil,
         onExistingScheduleTap: ((Date) -> Void)? = nil,  // 新增：處理點擊現有排程的回調
         selectionMode: SelectionMode = .range,
         isEditable: Bool = true,
         isEditingExistingSchedule: Bool = false,
         initialSelectedDates: Set<Date> = []) {  // 新增：初始選中的日期
        self._currentDate = currentDate
        self.patient = patient
        self.selectedMenu = selectedMenu
        self.selectedAssessments = selectedAssessments
        self.onDateRangeSelected = onDateRangeSelected
        self.onDateSelected = onDateSelected
        self.onExistingScheduleTap = onExistingScheduleTap  // 新增：設置回調
        self.selectionMode = selectionMode
        self.isEditable = isEditable  // 設置可編輯狀態
        self.isEditingExistingSchedule = isEditingExistingSchedule  // 設置編輯現有排程狀態
        
        // 初始化年月
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: currentDate.wrappedValue)
        self._selectedYear = State(initialValue: components.year ?? 2024)
        self._selectedMonth = State(initialValue: components.month ?? 1)
        
        // 設置初始選中的日期
        self._selectedDates = State(initialValue: initialSelectedDates)
    }
    
    // 新增：年份選項（前後10年）
    private var yearOptions: [Int] {
        let currentYear = calendar.component(.year, from: Date())
        return Array(currentYear - 10...currentYear + 10)
    }
    
    // 新增：月份選項
    private var monthOptions: [Int] {
        Array(1...12)
    }
    
    // 新增：年月選擇器視圖
    private var yearMonthPicker: some View {
        VStack(spacing: 0) {
            // 頂部工具列
            HStack {
                Button("取消") {
                    showingYearMonthPicker = false
                }
                .foregroundColor(.gray)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
                
                Spacer()
                
                Text("選擇日期")
                    .font(.headline)
                
                Spacer()
                
                Button("完成") {
                    if let newDate = calendar.date(from: DateComponents(year: selectedYear, month: selectedMonth)) {
                        currentDate = calendar.date(from: calendar.dateComponents([.year, .month], from: newDate)) ?? currentDate
                    }
                    showingYearMonthPicker = false
                }
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.blue)
                .cornerRadius(8)
            }
            .padding(.horizontal)
            .padding(.top, 12)
            
            HStack(spacing: 20) {
                // 年份選擇器
                Picker("", selection: $selectedYear) {
                    ForEach(yearOptions, id: \.self) { year in
                        Text("\(year)")
                            .tag(year)
                    }
                }
                #if !os(macOS) // .wheel picker style is not available on macOS
                .pickerStyle(.wheel)
                #endif
                .frame(maxWidth: .infinity)
                .clipped()
                .overlay(
                    Text("年")
                        .foregroundColor(.gray)
                        .font(.system(size: 18))
                        .padding(.trailing, 32),
                    alignment: .trailing
                )
                
                // 月份選擇器
                Picker("", selection: $selectedMonth) {
                    ForEach(monthOptions, id: \.self) { month in
                        Text("\(month)")
                            .tag(month)
                    }
                }
                #if !os(macOS) // .wheel picker style is not available on macOS
                .pickerStyle(.wheel)
                #endif
                .frame(maxWidth: .infinity)
                .clipped()
                .overlay(
                    Text("月")
                        .foregroundColor(.gray)
                        .font(.system(size: 18))
                        .padding(.trailing, 32),
                    alignment: .trailing
                )
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .background(Color.white)
    }
    
    private let calendar = Calendar.current
    private let fixedHeight: CGFloat = 365
    private let headerHeight: CGFloat = 80  // 新增：標題區域固定高度
    private let weekdayHeight: CGFloat = 30  // 新增：星期標題固定高度
    private let cellHeight: CGFloat = 40    // 新增：日期單元格固定高度
    private let maxWeeks: Int = 6           // 新增：最大周數（確保有足夠空間）
    
    // 判斷是否為編輯模式
    private var isEditMode: Bool {
        onDateRangeSelected != nil
    }
    
    private var currentYear: Int {
        calendar.component(.year, from: currentDate)
    }
    
    private var currentMonth: Int {
        calendar.component(.month, from: currentDate)
    }
    
    private var daysInMonth: Int {
        let range = calendar.range(of: .day, in: .month, for: currentDate)!
        return range.count
    }
    
    private var firstWeekday: Int {
        let components = DateComponents(year: currentYear, month: currentMonth)
        let firstDate = calendar.date(from: components)!
        return calendar.component(.weekday, from: firstDate) - 1
    }
    
    private func getDateForDay(_ day: Int) -> Date? {
        let components = DateComponents(year: currentYear, month: currentMonth, day: day)
        return calendar.date(from: components)
    }
    
    private func isDateInRange(_ date: Date, start: Date, end: Date) -> Bool {
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: date)
        let startComponents = calendar.dateComponents([.year, .month, .day], from: start)
        let endComponents = calendar.dateComponents([.year, .month, .day], from: end)
        
        guard let normalizedDate = calendar.date(from: dateComponents),
              let normalizedStart = calendar.date(from: startComponents),
              let normalizedEnd = calendar.date(from: endComponents) else {
            return false
        }
        
        // 確保日期範圍有效
        let (effectiveStart, effectiveEnd) = normalizedStart <= normalizedEnd ? 
            (normalizedStart, normalizedEnd) : 
            (normalizedEnd, normalizedStart)
        
        return normalizedDate >= effectiveStart && normalizedDate <= effectiveEnd
    }

    // Helper to determine training display info (color and opacity)
    private func getTrainingDisplayInfo(for normalizedDate: Date) -> (color: Color, opacity: CGFloat)? {
        // Priority 1: Actively selecting/dragging dates for the current `selectedMenu` (either new or editing existing)
        if let currentActiveMenu = self.selectedMenu, // Menu currently selected in parent
           (self.selectedDates.contains(normalizedDate) || isDateInCurrentDragRange(normalizedDate)) {
            
            // If we are editing an existing schedule, and this date is part of its CURRENT selection for THIS edit session:
            if self.isEditingExistingSchedule {
                return (currentActiveMenu.color, 0.7) // Active edit selection color
            } else {
                // We are selecting dates for a NEW schedule with currentActiveMenu.
                return (currentActiveMenu.color, 0.9) // New schedule selection color
            }
        }

        // Priority 2: Displaying other (potentially underlying) saved schedules from the store.
        // This applies if the date is NOT part of the active selectedDates for the current selectedMenu.
        if self.isEditingExistingSchedule && self.selectedMenu != nil {
            // If we are in edit mode for a specific schedule (selectedMenu is set to it),
            // and the current normalizedDate is NOT in selectedDates, it means the user has deselected it
            // from the current edit. So, it should have no background from *this* active edit operation.
            // We then fall through to check if there's an *underlying* schedule from the store for this date.
            // If normalizedDate is NOT in self.selectedDates for the schedule being edited, return nil for THIS menu's highlighting.
            if !self.selectedDates.contains(normalizedDate) && scheduleStore.getSchedulesForPatient(patient.id).contains(where: { $0.menuId == self.selectedMenu!.id && $0.isDateInRange(normalizedDate)}){
                 // This date WAS part of the schedule being edited, but user deselected it now.
                 // So, no color from the *active edit*. Let store logic below handle if it should show (e.g. if another menu has it).
                 // If no other menu has it, it will be clear.
                 // However, if we want to show the original schedule in a very dim way even if deselected, that's different.
                 // For now, making it clear on deselect while editing.
                return nil // Explicitly deselected during current edit session
            }
        }
        
        // Priority 3: Displaying other (non-actively-edited) saved schedules from the store.
        let schedulesOnDate = scheduleStore.getSchedulesForPatient(patient.id)
            .filter { $0.isDateInRange(normalizedDate) }
            // Exclude the schedule currently being edited if we are in edit mode for it,
            // as its display is handled by Priority 1 (if selected) or the nil above (if deselected during edit).
            .filter { schedule in
                if self.isEditingExistingSchedule && self.selectedMenu != nil {
                    return schedule.menuId != self.selectedMenu!.id
                }
                return true
            }

        if let scheduleToDisplay = schedulesOnDate.last, 
           let menuForSavedSchedule = TrainingMenuStore.shared.getMenu(by: scheduleToDisplay.menuId) {
            // It's a saved schedule, not the one being actively manipulated via selectedMenu/selectedDates.
            // If we are in an overall edit mode (e.g., parent is EditTrainingCalendarView), show dimly.
            // If parent is a view-only calendar, show normally.
            return (menuForSavedSchedule.color, self.isEditable ? 0.4 : 0.9) 
        }
        
        return nil
    }
    
    private func getBackgroundColor(for date: Date) -> Color? {
        guard let normalizedDate = calendar.normalizedDate(from: date) else { return nil }
        let isPastDate = calendar.startOfDay(for: normalizedDate) < calendar.startOfDay(for: Date())
        
        var finalDisplayColor: Color? = nil
        
        if let trainingInfo = getTrainingDisplayInfo(for: normalizedDate) {
            finalDisplayColor = trainingInfo.color.opacity(trainingInfo.opacity)
        }
        
        // Apply dimming for past dates
        if let color = finalDisplayColor, isPastDate {
            // Only dim if not part of current direct training selections for an *active* menu.
            let isActiveTrainingSelection = selectedMenu != nil && (selectedDates.contains(normalizedDate) || isDateInCurrentDragRange(normalizedDate))
            if !isActiveTrainingSelection {
                 // Dim the color to match assessment dots opacity for consistency
                return color.opacity(0.3) // Consistent with assessment indicator dimming
            }
        }
        return finalDisplayColor
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 月份選擇器和星期標題區域
            VStack(spacing: 16) {
                // 月份選擇器
                HStack {
                    Button(action: previousMonth) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.teal)
                            .imageScale(.large)
                    }
                    
                    Spacer()
                    
                    Button(action: { showingYearMonthPicker = true }) {
                        HStack(spacing: 4) {
                            Text(String(format: "%d年 %d月", currentYear, currentMonth))
                                .font(.system(size: 22, weight: .medium))
                            Image(systemName: "chevron.down")
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                        }
                    }
                    .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Button(action: nextMonth) {
                        Image(systemName: "chevron.right")
                            .foregroundColor(.teal)
                            .imageScale(.large)
                    }
                }
                .padding(.top, 20)
                
                // 星期標題
                HStack {
                    ForEach(["日", "一", "二", "三", "四", "五", "六"], id: \.self) { day in
                        Text(day)
                            .font(.system(size: 16))
                            .frame(maxWidth: .infinity)
                            .foregroundColor(.gray)
                    }
                }
            }
            .frame(height: headerHeight)
            .padding(.horizontal, 24)
            
            // 日期網格
            VStack(spacing: 0) {
                let days = Array(1...daysInMonth)
                let weeks = stride(from: 0, to: days.count + firstWeekday, by: 7).map { weekStart -> [Int?] in
                    (0..<7).map { dayOffset -> Int? in
                        let day = weekStart + dayOffset - firstWeekday + 1
                        return (day >= 1 && day <= days.count) ? day : nil
                    }
                }
                
                // 計算需要的空白周
                let remainingWeeks = maxWeeks - weeks.count
                
                ForEach(Array(weeks.enumerated()), id: \.0) { weekIndex, week in
                    weekRow(for: week)
                }
                
                // 添加空白周以保持一致的高度
                if remainingWeeks > 0 {
                    ForEach(0..<remainingWeeks, id: \.self) { _ in
                        weekRow(for: Array(repeating: nil, count: 7))
                    }
                }
            }
            .frame(height: CGFloat(maxWeeks) * cellHeight)
            .padding(.horizontal, 24)
            .padding(.bottom, 20)
            // 使用 GeometryReader 獲取精確的位置信息
            .background(
                GeometryReader { geometry in
                    Color.clear
                        .preference(key: CalendarSizePreferenceKey.self, value: geometry.size)
                        .onPreferenceChange(CalendarSizePreferenceKey.self) { size in
                            calendarSize = size
                        }
                }
            )
            // 添加整個日曆網格的手勢識別器
            .gesture(
                DragGesture(minimumDistance: 10)
                    .onChanged { gesture in
                        guard isEditable && selectionMode == .range && (selectedMenu != nil || !selectedAssessments.isEmpty) else { return }
                        
                        // 使用保存的日曆大小計算位置
                        let calendarWidth = calendarSize.width
                        let cellWidth = calendarWidth / 7
                        
                        // 計算當前觸摸位置對應的列和行
                        let locationX = gesture.location.x
                        let locationY = gesture.location.y
                        
                        // 確保位置在有效範圍內
                        guard locationX >= 0 && locationX <= calendarWidth && locationY >= 0 && locationY <= CGFloat(maxWeeks) * cellHeight else { return }
                        
                        // 計算當前列和行
                        let column = max(0, min(6, Int(locationX / cellWidth)))
                        let row = max(0, min(maxWeeks - 1, Int(locationY / cellHeight)))
                        
                        // 計算對應的日期索引
                        let dayIndex = row * 7 + column - firstWeekday
                        
                        // 確保日期索引在有效範圍內
                        guard dayIndex >= 0 && dayIndex < daysInMonth else { return }
                        
                        let day = dayIndex + 1
                        guard let date = getDateForDay(day) else { return }
                        
                        // 確保日期可選
                        guard isDateSelectable(date) else { return }
                        
                        // 檢查是否與上一次處理的日期相同，如果相同則跳過
                        if let lastDate = lastProcessedDate, calendar.isDate(lastDate, inSameDayAs: date) {
                            return
                        }
                        
                        // 更新上一次處理的日期
                        lastProcessedDate = date
                        lastProcessedUpdateTime = Date()
                        
                        // 提供觸覺反饋
                        #if canImport(UIKit)
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.impactOccurred(intensity: 0.3)
                        #endif
                        
                        // 處理拖曳
                        handleDragGesture(date: date, gesture: gesture)
                    }
                    .onEnded { _ in
                        if isDragging {
                            isDragging = false
                            dragStartDate = nil
                            dragEndDate = nil
                            lastProcessedDate = nil
                            initialSelectionState = false
                            
                            // 提供完成拖曳的觸覺反饋
                            #if canImport(UIKit)
                            let generator = UINotificationFeedbackGenerator()
                            generator.notificationOccurred(.success)
                            #endif
                        }
                    }
            )
        }
        .frame(height: fixedHeight)
        .background(Color.white)
        .cornerRadius(12)
        .sheet(isPresented: $showingYearMonthPicker) {
            yearMonthPicker
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
        .onAppear {
            // 如果是編輯現有排程，確保原始排程的日期預設被選中
            if isEditingExistingSchedule && selectedMenu != nil {
                // 獲取當前正在編輯的菜單的所有日期
                let menuDates = scheduleStore.getSchedulesForPatient(patient.id)
                    .filter { $0.menuId == selectedMenu!.id }
                    .flatMap { $0.dates }
                
                // 將這些日期添加到選中的日期中
                var hasAddedDates = false
                for menuDate in menuDates {
                    // 使用 calendar.isDate 進行日期比較，避免時間部分的差異
                    let alreadyContains = selectedDates.contains { selectedDate in
                        calendar.isDate(selectedDate, inSameDayAs: menuDate)
                    }
                    
                    if !alreadyContains {
                        // 標準化日期，只保留年月日部分
                        if let normalizedDate = calendar.normalizedDate(from: menuDate) {
                            selectedDates.insert(normalizedDate)
                            hasAddedDates = true
                        } else {
                            selectedDates.insert(menuDate)
                            hasAddedDates = true
                        }
                    }
                }
                
                // 只有在添加了新日期時才通知外部
                if hasAddedDates && onDateRangeSelected != nil {
                    onDateRangeSelected?(selectedDates)
                }
            }
        }
    }
    
    // 新增：保存日曆大小的屬性
    @State private var calendarSize: CGSize = .zero
    
    // 新增：日曆大小的 PreferenceKey
    private struct CalendarSizePreferenceKey: PreferenceKey {
        static var defaultValue: CGSize = .zero
        static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
            value = nextValue()
        }
    }
    
    // 完全重寫拖曳手勢處理邏輯，修復向後拖曳取消選擇的問題
    private func handleDragGesture(date: Date, gesture: DragGesture.Value) {
        // 如果是第一次拖曳，記錄起始日期和初始選擇狀態
        if !isDragging {
            isDragging = true
            dragStartDate = date
            
            // 檢查起始日期的選擇狀態
            initialSelectionState = selectedDates.contains { selectedDate in
                calendar.isDate(selectedDate, inSameDayAs: date)
            }
            
            // 如果起始日期未被選中，則添加它
            if !initialSelectionState {
                selectedDates.insert(date)
                onDateRangeSelected?(selectedDates)
            }
            
            return
        }
        
        // 保存拖曳結束日期
        dragEndDate = date
        
        // 確定拖曳的方向和範圍
        if let startDate = dragStartDate {
            // 標準化日期，只保留年月日部分
            guard let normalizedStartDate = calendar.normalizedDate(from: startDate),
                  let normalizedEndDate = calendar.normalizedDate(from: date) else {
                return
            }
            
            // 判斷拖曳方向 - 使用手勢的位置而不是日期來判斷方向
            let startLocation = gesture.startLocation
            let currentLocation = gesture.location
            
            // 水平方向的拖曳判斷（左右）
            let isMovingRight = currentLocation.x > startLocation.x
            // 垂直方向的拖曳判斷（上下）
            let isMovingDown = currentLocation.y > startLocation.y
            
            // 根據日曆的佈局（一週七天，從左到右），判斷拖曳方向
            // 向右或向下拖曳通常意味著選擇更多日期（向前）
            // 向左或向上拖曳通常意味著取消選擇日期（向後）
            let isDraggingForward: Bool
            
            // 如果水平移動距離大於垂直移動距離，優先考慮水平方向
            if abs(currentLocation.x - startLocation.x) > abs(currentLocation.y - startLocation.y) {
                isDraggingForward = isMovingRight
            } else {
                isDraggingForward = isMovingDown
            }
            
            // 創建一個臨時集合來存儲當前選擇的日期
            var newSelectedDates = selectedDates
            
            // 計算拖曳範圍內的日期
            let dateRange: [Date]
            if normalizedStartDate <= normalizedEndDate {
                // 從起始日期到結束日期
                dateRange = getDatesInRange(from: normalizedStartDate, to: normalizedEndDate)
            } else {
                // 從結束日期到起始日期
                dateRange = getDatesInRange(from: normalizedEndDate, to: normalizedStartDate)
            }
            
            // 根據拖曳方向處理日期選擇
            if isDraggingForward {
                // 向前拖曳：添加範圍內的日期
                for date in dateRange {
                    if isDateSelectable(date) {
                        newSelectedDates.insert(date)
                    }
                }
            } else {
                // 向後拖曳：移除範圍內的日期（除了起始日期，如果它最初是選中的）
                for date in dateRange {
                    // 如果是起始日期且最初是選中的，則保留
                    if calendar.isDate(date, inSameDayAs: startDate) && initialSelectionState {
                        continue
                    }
                    
                    // 否則移除日期
                    if isDateSelectable(date) {
                        newSelectedDates.remove(date)
                    }
                }
            }
            
            // 更新選中的日期
            selectedDates = newSelectedDates
            
            // 通知外部選擇變化
            onDateRangeSelected?(selectedDates)
        }
    }
    
    // 輔助方法：獲取日期範圍內的所有日期
    private func getDatesInRange(from startDate: Date, to endDate: Date) -> [Date] {
        var dates: [Date] = []
        var currentDate = startDate
        
        // 收集範圍內的所有日期
        while currentDate <= endDate {
            dates.append(currentDate)
            
            guard let nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate) else { break }
            currentDate = nextDate
        }
        
        return dates
    }
    
    // 新增：檢查日期是否可選（不能選擇今天之前的日期）
    private func isDateSelectable(_ date: Date) -> Bool {
        guard let normalizedDate = calendar.normalizedDate(from: date),
              let normalizedToday = calendar.normalizedDate(from: Date()) else {
            return false
        }
        return normalizedDate >= normalizedToday
    }

    // Modified DateCell struct
    private struct DateCell: View {
        let day: Int
        let date: Date
        let cellHeight: CGFloat
        let isEditMode: Bool
        let isDraggingCellVisualEffect: Bool 
        let bgColor: Color?
        let isPrevSelectedForBg: Bool
        let isNextSelectedForBg: Bool
        let assessmentIndicatorColors: [Color]
        let isSelectable: Bool
        let isEditingExistingSchedule: Bool
        let isSelectedForStroke: Bool
        let onTapAction: () -> Void
        
        var body: some View {
            VStack(spacing: 0) {
                // Top part for Day Number and Training Background
                ZStack {
                    // Background for training menu selection (bgColor)
                    if let color = bgColor {
                            GeometryReader { geometry in
                                Rectangle()
                                .fill(color)
                                    .frame(
                                    width: geometry.size.width + (isPrevSelectedForBg && isNextSelectedForBg ? 0 : (isPrevSelectedForBg || isNextSelectedForBg ? geometry.size.width / 2 : 0)),
                                        height: geometry.size.height
                                    )
                                    .position(
                                    x: geometry.size.width / 2 + (isPrevSelectedForBg ? 0 : (isNextSelectedForBg ? -geometry.size.width / 4 : 0)),
                                    y: geometry.size.height / 2
                                    )
                                .clipShape(RoundedRectangle(cornerRadius: isPrevSelectedForBg || isNextSelectedForBg ? 0 : 6, style: .continuous))
                        }
                    }

                    Text("\(day)")
                        .font(.system(size: 18))
                        .foregroundColor(isEditMode && !isSelectable ? .gray.opacity(0.5) : .primary)
                        .padding(.top, 2)
                }
                .frame(height: cellHeight * 0.7)
                .clipShape(RoundedRectangle(cornerRadius:6, style: .continuous))

                // Bottom strip for Assessment Dots
                HStack(spacing: 3) {
                    if !assessmentIndicatorColors.isEmpty {
                        ForEach(Array(assessmentIndicatorColors.prefix(4).enumerated()), id: \.0) { _, color in
                            Circle()
                                .fill(color)
                                .frame(width: 5, height: 5)
                        }
                    } else {
                        Spacer()
                            .frame(height: 5)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: cellHeight * 0.3)
                .padding(.bottom, 1)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
                .overlay(
                    Group {
                    if isEditingExistingSchedule && isSelectedForStroke {
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.white, lineWidth: 2)
                        }
                    }
                )
                .contentShape(Rectangle())
                .onTapGesture {
                    if isSelectable {
                        onTapAction()
                    }
                }
            .scaleEffect(isDraggingCellVisualEffect ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: isDraggingCellVisualEffect)
        }
    }

    // 新增：空白單元格視圖
    private struct EmptyCell: View {
        let cellHeight: CGFloat
        
        var body: some View {
            Text("")
                .frame(maxWidth: .infinity)
                .frame(height: cellHeight)
        }
    }

    private func weekRow(for week: [Int?]) -> some View {
        HStack(spacing: 0) {
            ForEach(Array(week.enumerated()), id: \.0) { dayIndex, day in
                if let day = day,
                   let date = getDateForDay(day) {
                    let bgColor = getBackgroundColor(for: date)
                    let prevDay = calendar.date(byAdding: .day, value: -1, to: date)
                    let nextDay = calendar.date(byAdding: .day, value: 1, to: date)
                    
                    // For background partial coloring on ranges
                    let isPrevSelectedForBg = prevDay.map { isDateSelected($0) } ?? false
                    let isNextSelectedForBg = nextDay.map { isDateSelected($0) } ?? false
                    
                    let indicatorColors = getAssessmentIndicatorColors(for: date)
                    let isDateCurrentlySelectable = isDateSelectable(date)
                    
                    // For the white stroke when editing an existing schedule
                    let isSelectedForStroke = selectedDates.contains { selectedDate in
                        calendar.isDate(selectedDate, inSameDayAs: date)
                    }
                    
                    // For visual effect like cell shrinking on drag
                    let isDraggingThisCellVisualEffect = isDragging && dragStartDate != nil && dragEndDate != nil &&
                        isDateInRange(date, start: dragStartDate!, end: dragEndDate!)
                    
                    DateCell(
                        day: day,
                        date: date,
                        cellHeight: cellHeight,
                        isEditMode: isEditMode,
                        isDraggingCellVisualEffect: isDraggingThisCellVisualEffect,
                        bgColor: bgColor,
                        isPrevSelectedForBg: isPrevSelectedForBg,
                        isNextSelectedForBg: isNextSelectedForBg,
                        assessmentIndicatorColors: indicatorColors,
                        isSelectable: isDateCurrentlySelectable && canSelectDate(),
                        isEditingExistingSchedule: isEditingExistingSchedule,
                        isSelectedForStroke: isSelectedForStroke,
                        onTapAction: {
                            handleTap(date: date)
                        }
                    )
                } else {
                    EmptyCell(cellHeight: cellHeight)
                }
            }
        }
        .background(Color.clear.contentShape(Rectangle()))
    }

    // This is the new method, ensure it's correctly placed 
    // relative to other private helper methods.
    private func getAssessmentIndicatorColors(for date: Date) -> [Color] {
        guard let normalizedDate = calendar.normalizedDate(from: date) else { return [] }
        var indicatorColors: [Color] = []
        
        // Check if this is a past date for dimming effect
        let isPastDate = calendar.startOfDay(for: normalizedDate) < calendar.startOfDay(for: Date())

        // Determine if we are in an active assessment editing context for the CalendarCard.
        // This means the calendar is generally editable, and there are specific assessments
        // being targeted for the current UI interactions (add/remove dates).
        let isActiveAssessmentContext = self.isEditable && !self.selectedAssessments.isEmpty

        if isActiveAssessmentContext {
            // --- Active Assessment Editing Mode ---

            // Check if the date is currently selected in the UI
            let isDateSelectedInUI = self.selectedDates.contains { calendar.isDate($0, inSameDayAs: normalizedDate) }
            
            // For the assessments that are actively being edited:
            for activeAssessment in self.selectedAssessments {
                // If this date is selected in the UI, show a dot for this assessment
                if isDateSelectedInUI {
                    let baseColor = activeAssessment.type.color
                    // Apply dimming for past dates, but not as much as training backgrounds
                    let finalColor = isPastDate ? baseColor.opacity(0.3) : baseColor
                    indicatorColors.append(finalColor)
                }
            }
            
            // For all OTHER assessments (not the ones being actively edited):
            // Show dots based on their saved schedules from the store
            let otherAssessmentsWithDotsHere = assessmentStore.getAssessments(for: patient.id).filter { assessmentInStore in
                // Skip if this is one of the assessments being actively edited
                if self.selectedAssessments.contains(where: { $0.id == assessmentInStore.id }) {
                    return false
                }
                
                // Check if this non-active assessment has this date scheduled
                return assessmentInStore.scheduledDates.contains { scheduledDate in
                    calendar.isDate(scheduledDate, inSameDayAs: normalizedDate)
                } || assessmentInStore.completedDates.contains { completedDate in
                    calendar.isDate(completedDate, inSameDayAs: normalizedDate)
                }
            }
            
            // Add dots for other assessments with dimming for past dates
            for assessment in otherAssessmentsWithDotsHere {
                let baseColor = assessment.type.color
                let finalColor = isPastDate ? baseColor.opacity(0.3) : baseColor
                indicatorColors.append(finalColor)
            }

        } else {
            // --- Not in Active Assessment Editing Mode ---
            // Show dots for ALL assessments from the store
            let assessmentsOnDate = assessmentStore.getAssessments(for: patient.id).filter { assessment in
                assessment.scheduledDates.contains { scheduledDate in
                    calendar.isDate(scheduledDate, inSameDayAs: normalizedDate)
                } || assessment.completedDates.contains { completedDate in
                    calendar.isDate(completedDate, inSameDayAs: normalizedDate)
                }
            }
            
            // Apply dimming for past dates to assessment dots
            for assessment in assessmentsOnDate {
                let baseColor = assessment.type.color
                let finalColor = isPastDate ? baseColor.opacity(0.3) : baseColor
                indicatorColors.append(finalColor)
            }
        }
        
        return indicatorColors // Return colors (may include duplicates with different opacities)
    }

    private func handleTap(date: Date) {
        guard isEditable else { return }
        // Normalize the tapped date once at the beginning for consistent use.
        guard let normalizedTappedDate = calendar.normalizedDate(from: date) else { return }

        // --- Intent 1: Active Scheduling Mode (for a new or currently being edited item) ---
        // This mode is active if parent has provided a selectedMenu or non-empty selectedAssessments.
        if selectedMenu != nil || !selectedAssessments.isEmpty {
            // For assessment editing, ensure immediate visual feedback
            let isAssessmentEditing = selectedMenu == nil && !selectedAssessments.isEmpty
            
            // Prevent deselection of the last date if specifically editing an existing schedule's dates
            // and it's NOT an assessment (for assessments, we allow full deselection for flexibility)
            if !isAssessmentEditing && isEditingExistingSchedule && selectedDates.count == 1 && 
               selectedDates.contains(normalizedTappedDate) {
                // Don't allow deselecting the very last date when actively modifying an existing training schedule
                return
            }
            
            // Add or remove the normalized date from the current selection set.
            if selectedDates.contains(normalizedTappedDate) {
                selectedDates.remove(normalizedTappedDate)
            } else {
                // Only add if the date is generally selectable (e.g., not in the past).
                if isDateSelectable(normalizedTappedDate) { // isDateSelectable should also use normalized dates internally
                    selectedDates.insert(normalizedTappedDate)
                } else {
                    return // Date not selectable (e.g., in the past), so do nothing further.
                }
            }

            // Notify the parent view about the change in the set of selected dates.
            // It's generally better to use onDateRangeSelected for this mode, even if only one date is involved,
            // as it passes the whole set, which is usually what the parent needs to manage pending schedules.
            if selectionMode == .single && onDateSelected != nil{
                 // If strictly single selection mode AND active scheduling, this path might be ambiguous.
                 // Typically, active scheduling (menu/assessments) implies range or multi-select concept.
                 // For now, let's assume onDateRangeSelected is the primary callback for this active mode.
                 onDateRangeSelected?(selectedDates) // Preferred callback for this intent
            } else {
                 onDateRangeSelected?(selectedDates)
            }
            return // Active scheduling intent has been handled.
        }

        // --- Intent 2: Interacting with an Existing Schedule on the Calendar ---
        // This applies if not in active scheduling mode (selectedMenu is nil AND selectedAssessments is empty).
        let hasExistingTrainingSchedule = scheduleStore.getSchedulesForPatient(patient.id)
            .contains { schedule in
                schedule.dates.contains { scheduleDate in
                    calendar.isDate(scheduleDate, inSameDayAs: normalizedTappedDate)
                }
            }
        
        if hasExistingTrainingSchedule && onExistingScheduleTap != nil {
            // User tapped on a date that has an existing training schedule, and a callback is provided.
            // This allows the parent to, for example, initiate an edit flow for that existing schedule.
            onExistingScheduleTap?(normalizedTappedDate)
            return // Interaction with existing schedule handled.
        }
        
        // --- Intent 3: Simple Single Date Selection (e.g., just choosing a day) ---
        // This applies if not in active scheduling mode, and no existing schedule was tapped (or no callback for it),
        // AND selectionMode is .single.
        if selectionMode == .single {
            if isDateSelectable(normalizedTappedDate) { // Ensure the date is generally selectable
                currentDate = normalizedTappedDate // Update the calendar's main displayed/highlighted date.
                onDateSelected?(normalizedTappedDate) // Notify parent of the simple date selection.
            }
            return
        }
        
        // If in .range mode but not actively scheduling anything (selectedMenu/Assessments are not set),
        // single taps on empty dates typically do nothing by default. The drag gesture handles range creation.
    }
    
    // 新增：檢查日期是否有訓練安排
    private func hasTrainingSchedule(for date: Date) -> Bool {
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: date)
        guard let normalizedDate = calendar.date(from: dateComponents) else { return false }
        
        return scheduleStore.getSchedulesForPatient(patient.id)
            .contains { schedule in
                schedule.isDateInRange(normalizedDate)
        }
    }
    
    // 修改 previousMonth 和 nextMonth 方法，在月份變更時清除選擇的日期
    private func previousMonth() {
        if let newDate = calendar.date(byAdding: .month, value: -1, to: currentDate) {
            currentDate = newDate
            // 清除選中的日期，讓用戶專注於當月安排
            if !isEditingExistingSchedule {
                selectedDates.removeAll()
                if let onDateRangeSelected = onDateRangeSelected {
                    onDateRangeSelected(selectedDates)
                }
            }
        }
    }
    
    private func nextMonth() {
        if let newDate = calendar.date(byAdding: .month, value: 1, to: currentDate) {
            currentDate = newDate
            // 清除選中的日期，讓用戶專注於當月安排
            if !isEditingExistingSchedule {
                selectedDates.removeAll()
                if let onDateRangeSelected = onDateRangeSelected {
                    onDateRangeSelected(selectedDates)
                }
            }
        }
    }
    
    // 新增：檢查日期是否被選中的輔助方法
    private func isDateSelected(_ date: Date) -> Bool {
        guard let normalizedDate = calendar.normalizedDate(from: date) else { return false }
        // A date is considered "selected" for background effect if getTrainingDisplayInfo returns non-nil.
        // This means it's either part of an active training selection or an existing schedule.
        return getTrainingDisplayInfo(for: normalizedDate) != nil
    }
    
    private func canSelectDate() -> Bool {
        isEditable && (selectedMenu != nil || !selectedAssessments.isEmpty)
    }
}

struct CalendarCard_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            CalendarCard(
                currentDate: .constant(Date()),
                patient: Patient.sample,
                selectedMenu: nil,
                selectedAssessments: [],
                onDateRangeSelected: nil,
                selectionMode: .single
            )
            .environmentObject(TrainingScheduleStore.shared)
            .frame(width: 400)
        }
        .padding()
        .background(Color(white: 0.9))
    }
}
*/


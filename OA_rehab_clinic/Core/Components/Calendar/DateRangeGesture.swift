import SwiftUI

/**
 * DateRangeGesture - 日期範圍拖曳手勢處理器
 *
 * 功能說明：
 * - 處理月曆上的拖曳手勢，實現日期範圍選擇
 * - 支援前向和後向拖曳
 * - 提供觸覺反饋（iOS）
 * - 計算拖曳經過的日期
 *
 * 設計原則：
 * - 單一職責：只負責手勢識別和日期計算
 * - 可重用：不依賴特定的月曆實現
 * - 高性能：避免重複計算和過度更新
 *
 * 架構重構說明：
 * - 從原本的 CalendarCard 中提取手勢處理邏輯
 * - 使用 ViewModifier 模式方便應用到任何視圖
 */

// MARK: - Date Range Gesture Delegate
protocol DateRangeGestureDelegate {
    /// 開始拖曳
    func didStartDragging(at date: Date)
    
    /// 拖曳更新
    func didUpdateDragging(from startDate: Date, to endDate: Date, dates: Set<Date>)
    
    /// 結束拖曳
    func didEndDragging(selectedDates: Set<Date>)
    
    /// 檢查日期是否可選
    func isDateSelectable(_ date: Date) -> Bool
}

// MARK: - Date Range Gesture Modifier
struct DateRangeGestureModifier: ViewModifier {
    let calendarSize: CGSize
    let cellsPerRow: Int = 7
    let firstWeekday: Int
    let daysInMonth: Int
    let currentYear: Int
    let currentMonth: Int
    let maxWeeks: Int
    let cellHeight: CGFloat
    
    var delegate: DateRangeGestureDelegate?
    
    @State private var dragStartDate: Date?
    @State private var dragEndDate: Date?
    @State private var isDragging = false
    @State private var lastProcessedDate: Date?
    
    private let calendar = Calendar.current
    
    func body(content: Content) -> some View {
        content
            .gesture(
                DragGesture(minimumDistance: 10)
                    .onChanged { gesture in
                        handleDragChange(gesture)
                    }
                    .onEnded { _ in
                        handleDragEnd()
                    }
            )
    }
    
    // MARK: - Gesture Handling
    private func handleDragChange(_ gesture: DragGesture.Value) {
        guard let date = calculateDateFromLocation(gesture.location) else { return }
        guard let delegate = delegate, delegate.isDateSelectable(date) else { return }
        
        // 避免重複處理相同日期
        if let lastDate = lastProcessedDate, calendar.isDate(lastDate, inSameDayAs: date) {
            return
        }
        
        lastProcessedDate = date
        
        #if canImport(UIKit)
        // 提供觸覺反饋
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred(intensity: 0.3)
        #endif
        
        if !isDragging {
            // 開始拖曳
            isDragging = true
            dragStartDate = date
            delegate.didStartDragging(at: date)
        } else {
            // 更新拖曳
            dragEndDate = date
            
            if let startDate = dragStartDate {
                let selectedDates = calculateDateRange(from: startDate, to: date)
                delegate.didUpdateDragging(from: startDate, to: date, dates: selectedDates)
            }
        }
    }
    
    private func handleDragEnd() {
        guard isDragging else { return }
        
        isDragging = false
        
        #if canImport(UIKit)
        // 結束拖曳的觸覺反饋
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        #endif
        
        if let startDate = dragStartDate, let endDate = dragEndDate {
            let selectedDates = calculateDateRange(from: startDate, to: endDate)
            delegate?.didEndDragging(selectedDates: selectedDates)
        } else if let startDate = dragStartDate {
            // 只有起始日期（點擊而非拖曳）
            delegate?.didEndDragging(selectedDates: [startDate])
        }
        
        // 重置狀態
        dragStartDate = nil
        dragEndDate = nil
        lastProcessedDate = nil
    }
    
    // MARK: - Date Calculation
    private func calculateDateFromLocation(_ location: CGPoint) -> Date? {
        // 計算月曆標題區域的高度（月份導航 + 星期標題）
        let headerHeight: CGFloat = 80  // 與 BaseCalendarView 的 headerHeight 相同
        let horizontalPadding: CGFloat = 24  // 與 BaseCalendarView 的 horizontalPadding 相同
        
        // 調整座標：減去標題高度，並考慮水平邊距
        let adjustedX = location.x - horizontalPadding
        let adjustedY = location.y - headerHeight
        
        // 計算實際的日期網格區域寬度（減去左右邊距）
        let gridWidth = calendarSize.width - (horizontalPadding * 2)
        let cellWidth = gridWidth / CGFloat(cellsPerRow)
        
        // 確保位置在有效的日期網格範圍內
        guard adjustedX >= 0 && adjustedX <= gridWidth &&
              adjustedY >= 0 && adjustedY <= CGFloat(maxWeeks) * cellHeight else {
            return nil
        }
        
        // 計算列和行
        let column = max(0, min(cellsPerRow - 1, Int(adjustedX / cellWidth)))
        let row = max(0, min(maxWeeks - 1, Int(adjustedY / cellHeight)))
        
        // 計算日期索引
        let dayIndex = row * cellsPerRow + column - firstWeekday
        
        // 確保日期索引有效
        guard dayIndex >= 0 && dayIndex < daysInMonth else { return nil }
        
        let day = dayIndex + 1
        let components = DateComponents(year: currentYear, month: currentMonth, day: day)
        return calendar.date(from: components)
    }
    
    private func calculateDateRange(from startDate: Date, to endDate: Date) -> Set<Date> {
        var dates = Set<Date>()
        
        let (rangeStart, rangeEnd) = startDate <= endDate ? 
            (startDate, endDate) : 
            (endDate, startDate)
        
        var currentDate = rangeStart
        
        while currentDate <= rangeEnd {
            if let delegate = delegate, delegate.isDateSelectable(currentDate) {
                dates.insert(currentDate)
            }
            
            guard let nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate) else { break }
            currentDate = nextDate
        }
        
        return dates
    }
}

// MARK: - View Extension
extension View {
    /// 添加日期範圍拖曳手勢
    func dateRangeGesture(
        size: CGSize,
        firstWeekday: Int,
        daysInMonth: Int,
        currentYear: Int,
        currentMonth: Int,
        maxWeeks: Int,
        cellHeight: CGFloat,
        delegate: DateRangeGestureDelegate?
    ) -> some View {
        self.modifier(
            DateRangeGestureModifier(
                calendarSize: size,
                firstWeekday: firstWeekday,
                daysInMonth: daysInMonth,
                currentYear: currentYear,
                currentMonth: currentMonth,
                maxWeeks: maxWeeks,
                cellHeight: cellHeight,
                delegate: delegate
            )
        )
    }
}

// MARK: - Drag Direction Helper
/// 拖曳方向輔助結構
struct DragDirection {
    let isForward: Bool
    let isHorizontal: Bool
    
    static func calculate(from startLocation: CGPoint, to currentLocation: CGPoint) -> DragDirection {
        let deltaX = currentLocation.x - startLocation.x
        let deltaY = currentLocation.y - startLocation.y
        
        let isHorizontal = abs(deltaX) > abs(deltaY)
        let isForward = isHorizontal ? deltaX > 0 : deltaY > 0
        
        return DragDirection(isForward: isForward, isHorizontal: isHorizontal)
    }
}
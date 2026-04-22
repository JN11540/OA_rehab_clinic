import SwiftUI

/**
 * BaseCalendarView - 基礎月曆視圖組件
 *
 * 功能說明：
 * - 純 UI 組件，不包含任何業務邏輯
 * - 提供月曆的基本呈現功能
 * - 支援自定義日期樣式和點擊事件
 * - 可作為其他專業月曆組件的基礎
 *
 * 設計原則：
 * - 單一職責：只負責月曆 UI 的呈現
 * - 高度可自定義：通過 Configuration 和 Delegate 支援各種使用場景
 * - 低耦合：不依賴任何業務模型或 Store
 *
 * 架構重構說明：
 * - 從原本的 CalendarCard 中提取純 UI 部分
 * - 移除所有業務邏輯和 Store 依賴
 * - 使用 Protocol 和 Delegate 模式實現可擴展性
 */

// MARK: - Calendar Configuration
/// 月曆配置結構，定義月曆的基本設定
struct CalendarConfiguration {
    var fixedHeight: CGFloat = 365
    var headerHeight: CGFloat = 80
    var weekdayHeight: CGFloat = 30
    var cellHeight: CGFloat = 40
    var maxWeeks: Int = 6
    var horizontalPadding: CGFloat = 24
    var verticalPadding: CGFloat = 20
    var cornerRadius: CGFloat = 12
    var backgroundColor: Color = .white
}

// MARK: - Date Cell Data
/// 日期單元格的數據模型
struct DateCellData {
    let date: Date
    let day: Int
    let isInCurrentMonth: Bool
    let isToday: Bool
    let isPast: Bool
    let isSelectable: Bool
    
    // 自定義樣式
    var backgroundColor: Color?
    var foregroundColor: Color = .primary
    var opacity: CGFloat = 1.0
    var showBorder: Bool = false
    var borderColor: Color = .white
    var borderWidth: CGFloat = 2
    var indicators: [Color] = []  // 底部指示器顏色
}

// MARK: - Calendar Delegate
/// 月曆代理協議，處理月曆事件
protocol BaseCalendarDelegate {
    /// 配置日期單元格的外觀
    func calendar(_ calendar: BaseCalendarView, configureCell date: Date, day: Int) -> DateCellData
    
    /// 處理日期點擊事件
    func calendar(_ calendar: BaseCalendarView, didSelectDate date: Date)
    
    /// 處理月份變更事件
    func calendar(_ calendar: BaseCalendarView, didChangeToMonth month: Int, year: Int)
}

// MARK: - Base Calendar View
struct BaseCalendarView: View {
    @Binding var currentDate: Date
    let configuration: CalendarConfiguration
    var delegate: BaseCalendarDelegate?
    
    @State private var showingYearMonthPicker = false
    @State private var selectedYear: Int
    @State private var selectedMonth: Int
    
    private let calendar = Calendar.current
    
    init(currentDate: Binding<Date>, 
         configuration: CalendarConfiguration = CalendarConfiguration(),
         delegate: BaseCalendarDelegate? = nil) {
        self._currentDate = currentDate
        self.configuration = configuration
        self.delegate = delegate
        
        let components = Calendar.current.dateComponents([.year, .month], from: currentDate.wrappedValue)
        self._selectedYear = State(initialValue: components.year ?? 2024)
        self._selectedMonth = State(initialValue: components.month ?? 1)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 月份導航標題
            monthNavigator
                .frame(height: configuration.headerHeight)
                .padding(.horizontal, configuration.horizontalPadding)
            
            // 日曆網格
            calendarGrid
                .frame(height: CGFloat(configuration.maxWeeks) * configuration.cellHeight)
                .padding(.horizontal, configuration.horizontalPadding)
                .padding(.top, 8)  // 增加頂部間距以分離星期標題和日期
                .padding(.bottom, configuration.verticalPadding - 8)  // 相應減少底部間距
        }
        .frame(height: configuration.fixedHeight)
        .background(configuration.backgroundColor)
        .cornerRadius(configuration.cornerRadius)
        .sheet(isPresented: $showingYearMonthPicker) {
            YearMonthPicker(
                selectedYear: $selectedYear,
                selectedMonth: $selectedMonth,
                onConfirm: { year, month in
                    updateCurrentDate(year: year, month: month)
                }
            )
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
    }
    
    // MARK: - Subviews
    private var monthNavigator: some View {
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
    }
    
    private var calendarGrid: some View {
        VStack(spacing: 0) {
            let days = Array(1...daysInMonth)
            let weeks = createWeeks(days: days)
            
            ForEach(Array(weeks.enumerated()), id: \.0) { _, week in
                weekRow(for: week)
            }
            
            // 填充空白週以保持固定高度
            ForEach(weeks.count..<configuration.maxWeeks, id: \.self) { _ in
                weekRow(for: Array(repeating: nil, count: 7))
            }
        }
    }
    
    private func weekRow(for week: [Int?]) -> some View {
        HStack(spacing: 0) {
            ForEach(Array(week.enumerated()), id: \.0) { _, day in
                if let day = day,
                   let date = getDateForDay(day) {
                    let cellData = delegate?.calendar(self, configureCell: date, day: day) ?? createDefaultCellData(date: date, day: day)
                    
                    DateCellView(
                        data: cellData,
                        height: configuration.cellHeight,
                        onTap: {
                            if cellData.isSelectable {
                                delegate?.calendar(self, didSelectDate: date)
                            }
                        }
                    )
                } else {
                    EmptyCellView(height: configuration.cellHeight)
                }
            }
        }
    }
    
    // MARK: - Helper Methods
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
    
    private func getDateForDay(_ day: Int) -> Date? {
        let components = DateComponents(year: currentYear, month: currentMonth, day: day)
        return calendar.date(from: components)
    }
    
    private func createWeeks(days: [Int]) -> [[Int?]] {
        stride(from: 0, to: days.count + firstWeekday, by: 7).map { weekStart in
            (0..<7).map { dayOffset in
                let day = weekStart + dayOffset - firstWeekday + 1
                return (day >= 1 && day <= days.count) ? day : nil
            }
        }
    }
    
    private func createDefaultCellData(date: Date, day: Int) -> DateCellData {
        let isToday = calendar.isDateInToday(date)
        let isPast = calendar.startOfDay(for: date) < calendar.startOfDay(for: Date())
        
        return DateCellData(
            date: date,
            day: day,
            isInCurrentMonth: true,
            isToday: isToday,
            isPast: isPast,
            isSelectable: !isPast
        )
    }
    
    private func previousMonth() {
        if let newDate = calendar.date(byAdding: .month, value: -1, to: currentDate) {
            currentDate = newDate
            let components = calendar.dateComponents([.year, .month], from: newDate)
            delegate?.calendar(self, didChangeToMonth: components.month ?? 1, year: components.year ?? 2024)
        }
    }
    
    private func nextMonth() {
        if let newDate = calendar.date(byAdding: .month, value: 1, to: currentDate) {
            currentDate = newDate
            let components = calendar.dateComponents([.year, .month], from: newDate)
            delegate?.calendar(self, didChangeToMonth: components.month ?? 1, year: components.year ?? 2024)
        }
    }
    
    private func updateCurrentDate(year: Int, month: Int) {
        if let newDate = calendar.date(from: DateComponents(year: year, month: month)) {
            currentDate = newDate
            delegate?.calendar(self, didChangeToMonth: month, year: year)
        }
    }
}

// MARK: - Date Cell View
/// 日期單元格視圖
struct DateCellView: View {
    let data: DateCellData
    let height: CGFloat
    let onTap: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // 上半部分：日期數字和背景
            ZStack {
                if let bgColor = data.backgroundColor {
                    Rectangle()
                        .fill(bgColor.opacity(data.opacity))
                }
                
                Text("\(data.day)")
                    .font(.system(size: 18))
                    .foregroundColor(data.foregroundColor.opacity(data.isSelectable ? 1 : 0.5))
                    .padding(.top, 2)
            }
            .frame(height: height * 0.7)
            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
            .overlay(
                Group {
                    if data.showBorder {
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .stroke(data.borderColor, lineWidth: data.borderWidth)
                    }
                }
            )
            
            // 下半部分：指示器
            HStack(spacing: 3) {
                if !data.indicators.isEmpty {
                    ForEach(Array(data.indicators.prefix(4).enumerated()), id: \.0) { _, color in
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
            .frame(height: height * 0.3)
            .padding(.bottom, 1)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
    }
}

// MARK: - Empty Cell View
/// 空白單元格視圖
struct EmptyCellView: View {
    let height: CGFloat
    
    var body: some View {
        Text("")
            .frame(maxWidth: .infinity)
            .frame(height: height)
    }
}

// MARK: - Year Month Picker
/// 年月選擇器視圖
struct YearMonthPicker: View {
    @Binding var selectedYear: Int
    @Binding var selectedMonth: Int
    let onConfirm: (Int, Int) -> Void
    @Environment(\.dismiss) var dismiss
    
    private var yearOptions: [Int] {
        let currentYear = Calendar.current.component(.year, from: Date())
        return Array(currentYear - 10...currentYear + 10)
    }
    
    private var monthOptions: [Int] {
        Array(1...12)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 頂部工具列
            HStack {
                Button("取消") {
                    dismiss()
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
                    onConfirm(selectedYear, selectedMonth)
                    dismiss()
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
                #if !os(macOS)
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
                #if !os(macOS)
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
}
import Foundation

/**
 * DateRangeService - 日期範圍處理服務
 *
 * 功能說明：
 * - 提供統一的日期處理邏輯
 * - 處理日期標準化、範圍計算、月份篩選等功能
 * - 減少重複的日期處理代碼
 *
 * 設計原則：
 * - 純函數設計：所有方法都是無副作用的純函數
 * - 單一職責：只負責日期相關的計算和處理
 * - 可測試性：所有邏輯都可以單獨測試
 */
final class DateRangeService {
    
    // MARK: - Singleton
    
    /// 共享實例
    static let shared = DateRangeService()
    
    // MARK: - Properties
    
    /// 日曆實例
    private let calendar = Calendar.current
    
    // MARK: - Initialization
    
    private init() {}
    
    // MARK: - 日期標準化
    
    /**
     * 標準化日期（只保留年月日）
     * - Parameter date: 原始日期
     * - Returns: 標準化後的日期（時分秒為 0）
     */
    func normalizeDate(_ date: Date) -> Date {
        return calendar.startOfDay(for: date)
    }
    
    /**
     * 標準化日期集合
     * - Parameter dates: 原始日期集合
     * - Returns: 標準化後的日期集合
     */
    func normalizeDates(_ dates: Set<Date>) -> Set<Date> {
        return Set(dates.map { normalizeDate($0) })
    }
    
    // MARK: - 月份處理
    
    /**
     * 獲取指定日期所在月份的日期範圍
     * - Parameter date: 指定日期
     * - Returns: 該月份的開始和結束日期
     */
    func monthRange(for date: Date) -> (start: Date, end: Date)? {
        guard let monthInterval = calendar.dateInterval(of: .month, for: date) else {
            return nil
        }
        
        // 結束日期需要減去一秒，以獲得該月最後一天的 23:59:59
        let endDate = calendar.date(byAdding: .second, value: -1, to: monthInterval.end) ?? monthInterval.end
        
        return (monthInterval.start, endDate)
    }
    
    /**
     * 篩選指定月份的日期
     * - Parameters:
     *   - dates: 原始日期集合
     *   - month: 指定月份的任意日期
     * - Returns: 屬於指定月份的日期集合
     */
    func filterDatesInMonth(_ dates: Set<Date>, month: Date) -> Set<Date> {
        let monthComponents = calendar.dateComponents([.year, .month], from: month)
        
        return dates.filter { date in
            let dateComponents = calendar.dateComponents([.year, .month], from: date)
            return dateComponents.year == monthComponents.year &&
                   dateComponents.month == monthComponents.month
        }
    }
    
    /**
     * 篩選不在指定月份的日期
     * - Parameters:
     *   - dates: 原始日期集合
     *   - month: 指定月份的任意日期
     * - Returns: 不屬於指定月份的日期集合
     */
    func filterDatesNotInMonth(_ dates: Set<Date>, month: Date) -> Set<Date> {
        let monthComponents = calendar.dateComponents([.year, .month], from: month)
        
        return dates.filter { date in
            let dateComponents = calendar.dateComponents([.year, .month], from: date)
            return !(dateComponents.year == monthComponents.year &&
                    dateComponents.month == monthComponents.month)
        }
    }
    
    // MARK: - 日期比較
    
    /**
     * 檢查兩個日期是否在同一天
     * - Parameters:
     *   - date1: 第一個日期
     *   - date2: 第二個日期
     * - Returns: 是否在同一天
     */
    func isSameDay(_ date1: Date, _ date2: Date) -> Bool {
        return calendar.isDate(date1, inSameDayAs: date2)
    }
    
    /**
     * 檢查兩個日期是否在同一月份
     * - Parameters:
     *   - date1: 第一個日期
     *   - date2: 第二個日期
     * - Returns: 是否在同一月份
     */
    func isSameMonth(_ date1: Date, _ date2: Date) -> Bool {
        let components1 = calendar.dateComponents([.year, .month], from: date1)
        let components2 = calendar.dateComponents([.year, .month], from: date2)
        
        return components1.year == components2.year &&
               components1.month == components2.month
    }
    
    // MARK: - 日期集合操作
    
    /**
     * 找出兩個日期集合中的重疊日期
     * - Parameters:
     *   - dates1: 第一個日期集合
     *   - dates2: 第二個日期集合
     * - Returns: 重疊的日期集合
     */
    func findOverlappingDates(_ dates1: Set<Date>, _ dates2: Set<Date>) -> Set<Date> {
        return dates1.filter { date1 in
            dates2.contains { date2 in
                isSameDay(date1, date2)
            }
        }
    }
    
    /**
     * 移除日期集合中的指定日期
     * - Parameters:
     *   - dates: 原始日期集合
     *   - datesToRemove: 要移除的日期集合
     * - Returns: 移除後的日期集合
     */
    func removeDates(_ datesToRemove: Set<Date>, from dates: Set<Date>) -> Set<Date> {
        return dates.filter { date in
            !datesToRemove.contains { dateToRemove in
                isSameDay(date, dateToRemove)
            }
        }
    }
    
    // MARK: - 日期範圍生成
    
    /**
     * 生成指定日期範圍內的所有日期
     * - Parameters:
     *   - start: 開始日期
     *   - end: 結束日期
     * - Returns: 日期陣列
     */
    func generateDateRange(from start: Date, to end: Date) -> [Date] {
        var dates: [Date] = []
        var currentDate = normalizeDate(start)
        let endDate = normalizeDate(end)
        
        while currentDate <= endDate {
            dates.append(currentDate)
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }
        
        return dates
    }
    
    // MARK: - 月份導航
    
    /**
     * 獲取上一個月份
     * - Parameter date: 當前日期
     * - Returns: 上一個月份的日期
     */
    func previousMonth(from date: Date) -> Date? {
        return calendar.date(byAdding: .month, value: -1, to: date)
    }
    
    /**
     * 獲取下一個月份
     * - Parameter date: 當前日期
     * - Returns: 下一個月份的日期
     */
    func nextMonth(from date: Date) -> Date? {
        return calendar.date(byAdding: .month, value: 1, to: date)
    }
}
import Foundation
import SwiftUI
#if canImport(UIKit)
import UIKit
#else
import AppKit
#endif

/**
 * Calendar Extensions - 日曆擴展工具
 *
 * 功能說明：
 * - 提供日期標準化方法
 * - 確保日期比較的一致性
 * - 移除時間組件，只保留日期部分
 *
 * 使用場景：
 * - 月曆視圖中的日期比較
 * - 排程衝突檢測
 * - 日期選擇和標準化
 *
 * 重構說明：
 * - 從 CalendarCard.swift 提取通用的日曆擴展
 * - 供整個應用程式使用，確保日期處理的一致性
 */
extension Calendar {
    
    /**
     * 標準化日期 - 移除時間組件，只保留年月日
     *
     * @param date 原始日期
     * @return 標準化後的日期（時間為 00:00:00）
     */
    func normalizedDate(from date: Date) -> Date? {
        let components = dateComponents([.year, .month, .day], from: date)
        return self.date(from: components)
    }
    
    /**
     * 檢查兩個日期是否在同一個月
     *
     * @param date1 第一個日期
     * @param date2 第二個日期
     * @return 是否在同一個月
     */
    func isDate(_ date1: Date, inSameMonthAs date2: Date) -> Bool {
        let components1 = dateComponents([.year, .month], from: date1)
        let components2 = dateComponents([.year, .month], from: date2)
        return components1.year == components2.year && components1.month == components2.month
    }
    
    /**
     * 批量標準化日期集合
     *
     * @param dates 原始日期集合
     * @return 標準化後的日期集合
     */
    func normalizedDates(from dates: Set<Date>) -> Set<Date> {
        var normalizedDates = Set<Date>()
        for date in dates {
            if let normalizedDate = normalizedDate(from: date) {
                normalizedDates.insert(normalizedDate)
            }
        }
        return normalizedDates
    }
    
    /**
     * 檢查兩個日期是否為同一天（忽略時間）
     *
     * @param date1 第一個日期
     * @param date2 第二個日期
     * @return 是否為同一天
     */
    func isSameDay(_ date1: Date, _ date2: Date) -> Bool {
        guard let normalized1 = normalizedDate(from: date1),
              let normalized2 = normalizedDate(from: date2) else {
            return false
        }
        return normalized1 == normalized2
    }
}

// MARK: - View Extensions for Custom Corner Radius

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
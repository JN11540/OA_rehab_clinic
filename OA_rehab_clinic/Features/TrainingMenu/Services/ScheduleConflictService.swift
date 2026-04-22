import Foundation
import SwiftUI

/**
 * ScheduleConflictService - 排程衝突服務
 *
 * 功能說明：
 * - 檢測排程之間的日期衝突
 * - 提供衝突解決策略
 * - 驗證排程的有效性
 * - 處理日期標準化和比較
 *
 * 設計原則：
 * - 純函數設計：不依賴外部狀態
 * - 可測試性：所有方法都是純函數
 * - 明確的錯誤處理：使用 Result 類型
 *
 * 重構說明：
 * - 從 EditTrainingCalendarView 提取衝突檢測邏輯
 * - 集中處理所有排程衝突相關邏輯
 * - 提供清晰的 API 介面
 */
struct ScheduleConflictService {
    
    // MARK: - 類型定義
    
    /// 排程衝突資訊
    struct ScheduleConflict {
        let existingSchedule: TrainingSchedule
        let conflictingDates: Set<Date>
        let menuInfo: MenuInfo?
        
        struct MenuInfo {
            let title: String
            let color: Color
        }
    }
    
    /// 衝突解決方案
    enum ConflictResolution {
        case overwrite    // 覆蓋現有排程
        case merge       // 合併排程
        case cancel      // 取消操作
    }
    
    /// 排程錯誤類型
    enum ScheduleError: LocalizedError {
        case invalidDates
        case noConflicts
        case resolutionFailed(String)
        
        var errorDescription: String? {
            switch self {
            case .invalidDates:
                return "選擇的日期無效"
            case .noConflicts:
                return "沒有發現衝突"
            case .resolutionFailed(let reason):
                return "衝突解決失敗：\(reason)"
            }
        }
    }
    
    // MARK: - 私有屬性
    
    private let calendar = Calendar.current
    
    // MARK: - 公開方法
    
    /**
     * 檢測排程衝突
     *
     * - Parameters:
     *   - newSchedule: 新的排程
     *   - existingSchedules: 現有的排程列表
     *   - excludeSameMenu: 是否排除相同菜單的排程
     * - Returns: 衝突列表
     */
    func detectConflicts(
        newSchedule: TrainingSchedule,
        existingSchedules: [TrainingSchedule],
        excludeSameMenu: Bool = true
    ) -> [ScheduleConflict] {
        
        var conflicts: [ScheduleConflict] = []
        
        for existingSchedule in existingSchedules {
            // 如果設定排除相同菜單，則跳過
            if excludeSameMenu && existingSchedule.menuId == newSchedule.menuId {
                continue
            }
            
            // 檢查日期重疊
            let conflictingDates = findConflictingDates(
                between: newSchedule.dates,
                and: existingSchedule.dates
            )
            
            if !conflictingDates.isEmpty {
                // 嘗試獲取菜單資訊（用於顯示）
                let menuInfo = getMenuInfo(for: existingSchedule.menuId)
                
                conflicts.append(ScheduleConflict(
                    existingSchedule: existingSchedule,
                    conflictingDates: conflictingDates,
                    menuInfo: menuInfo
                ))
            }
        }
        
        return conflicts
    }
    
    /**
     * 解決排程衝突
     *
     * - Parameters:
     *   - conflicts: 衝突列表
     *   - resolution: 解決方案
     *   - newSchedule: 新的排程
     * - Returns: 處理後的排程列表
     */
    func resolveConflicts(
        _ conflicts: [ScheduleConflict],
        resolution: ConflictResolution,
        newSchedule: TrainingSchedule
    ) -> Result<[TrainingSchedule], ScheduleError> {
        
        switch resolution {
        case .cancel:
            // 取消操作，返回空列表
            return .success([])
            
        case .overwrite:
            // 覆蓋模式：移除衝突日期，保留非衝突日期
            return resolveByOverwriting(conflicts: conflicts)
            
        case .merge:
            // 合併模式：將新排程與現有排程合併
            return resolveByMerging(conflicts: conflicts, newSchedule: newSchedule)
        }
    }
    
    /**
     * 驗證排程日期
     *
     * - Parameter dates: 要驗證的日期集合
     * - Returns: 是否有效
     */
    func validateScheduleDates(_ dates: Set<Date>) -> Bool {
        // 檢查是否為空
        guard !dates.isEmpty else { return false }
        
        // 檢查是否所有日期都是未來日期
        let today = calendar.startOfDay(for: Date())
        
        for date in dates {
            let normalizedDate = calendar.startOfDay(for: date)
            if normalizedDate < today {
                return false
            }
        }
        
        return true
    }
    
    /**
     * 合併相同菜單的排程
     *
     * - Parameters:
     *   - schedules: 要合併的排程列表
     *   - menuId: 菜單 ID
     * - Returns: 合併後的排程
     */
    func mergeSchedulesForSameMenu(
        _ schedules: [TrainingSchedule],
        menuId: UUID
    ) -> TrainingSchedule? {
        
        // 過濾出相同菜單的排程
        let sameMenuSchedules = schedules.filter { $0.menuId == menuId }
        
        guard !sameMenuSchedules.isEmpty else { return nil }
        
        // 合併所有日期
        var allDates = Set<Date>()
        var timeSlots = Set<String>()
        
        for schedule in sameMenuSchedules {
            allDates.formUnion(schedule.dates)
            timeSlots.formUnion(schedule.timeSlots)
        }
        
        // 使用第一個排程的 ID 和患者 ID
        guard let firstSchedule = sameMenuSchedules.first else { return nil }
        let scheduleId = firstSchedule.id
        let patientId = firstSchedule.patientId
        
        return TrainingSchedule(
            id: scheduleId,
            menuId: menuId,
            patientId: patientId,
            selectedDates: allDates,
            timeSlots: timeSlots
        )
    }
    
    // MARK: - 私有方法
    
    /**
     * 查找衝突的日期
     */
    private func findConflictingDates(
        between dates1: Set<Date>,
        and dates2: Set<Date>
    ) -> Set<Date> {
        
        var conflictingDates = Set<Date>()
        
        for date1 in dates1 {
            for date2 in dates2 {
                if calendar.isDate(date1, inSameDayAs: date2) {
                    conflictingDates.insert(date1)
                    break
                }
            }
        }
        
        return conflictingDates
    }
    
    /**
     * 獲取菜單資訊（用於顯示）
     */
    private func getMenuInfo(for menuId: UUID) -> ScheduleConflict.MenuInfo? {
        // 從 TrainingMenuStore 獲取菜單資訊
        if let menu = TrainingMenuStore.shared.getMenu(by: menuId) {
            return ScheduleConflict.MenuInfo(
                title: menu.title,
                color: menu.color
            )
        }
        return nil
    }
    
    /**
     * 覆蓋解決方案
     */
    private func resolveByOverwriting(
        conflicts: [ScheduleConflict]
    ) -> Result<[TrainingSchedule], ScheduleError> {
        
        var updatedSchedules: [TrainingSchedule] = []
        
        for conflict in conflicts {
            let remainingDates = conflict.existingSchedule.dates.subtracting(conflict.conflictingDates)
            
            // 如果還有剩餘日期，創建更新的排程
            if !remainingDates.isEmpty {
                let updatedSchedule = TrainingSchedule(
                    id: conflict.existingSchedule.id,
                    menuId: conflict.existingSchedule.menuId,
                    patientId: conflict.existingSchedule.patientId,
                    selectedDates: remainingDates,
                    timeSlots: conflict.existingSchedule.timeSlots
                )
                updatedSchedules.append(updatedSchedule)
            }
            // 如果沒有剩餘日期，該排程將被完全移除
        }
        
        return .success(updatedSchedules)
    }
    
    /**
     * 合併解決方案
     */
    private func resolveByMerging(
        conflicts: [ScheduleConflict],
        newSchedule: TrainingSchedule
    ) -> Result<[TrainingSchedule], ScheduleError> {
        
        // 在合併模式下，保持所有現有排程不變
        // 只調整新排程的日期，移除衝突部分
        
        var nonConflictingDates = newSchedule.dates
        
        for conflict in conflicts {
            nonConflictingDates.subtract(conflict.conflictingDates)
        }
        
        if nonConflictingDates.isEmpty {
            return .failure(.resolutionFailed("新排程的所有日期都與現有排程衝突"))
        }
        
        let adjustedSchedule = TrainingSchedule(
            id: newSchedule.id,
            menuId: newSchedule.menuId,
            patientId: newSchedule.patientId,
            selectedDates: nonConflictingDates,
            timeSlots: newSchedule.timeSlots
        )
        
        return .success([adjustedSchedule])
    }
    
    // MARK: - 日期處理輔助方法
    
    /**
     * 標準化日期集合
     */
    func normalizeDates(_ dates: Set<Date>) -> Set<Date> {
        var normalizedDates = Set<Date>()
        
        for date in dates {
            if let normalizedDate = calendar.dateComponents([.year, .month, .day], from: date).date {
                normalizedDates.insert(normalizedDate)
            }
        }
        
        return normalizedDates
    }
    
    /**
     * 檢查日期是否在範圍內
     */
    func isDatesInMonth(_ dates: Set<Date>, month: Date) -> Bool {
        guard let monthStart = calendar.dateInterval(of: .month, for: month)?.start,
              let monthEnd = calendar.dateInterval(of: .month, for: month)?.end else {
            return false
        }
        
        for date in dates {
            if date < monthStart || date >= monthEnd {
                return false
            }
        }
        
        return true
    }
}

// MARK: - Calendar Extension
// Note: 這個 extension 已經在其他地方定義了，所以這裡移除避免重複宣告
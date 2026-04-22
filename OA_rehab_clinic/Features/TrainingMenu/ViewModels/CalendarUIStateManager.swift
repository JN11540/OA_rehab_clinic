import SwiftUI
import Foundation

/**
 * CalendarUIStateManager - 月曆 UI 狀態管理器
 *
 * 功能說明：
 * - 管理月曆界面的所有 UI 狀態
 * - 處理警告、對話框、錯誤訊息等 UI 元素的顯示狀態
 * - 與具體業務邏輯分離，專注於 UI 狀態管理
 *
 * 設計原則：
 * - 單一職責：只負責 UI 狀態管理
 * - 可重用性：可被多個 ViewModel 共享使用
 * - 響應式：使用 @Published 確保 UI 自動更新
 */
@MainActor
class CalendarUIStateManager: ObservableObject {
    
    // MARK: - 基礎 UI 狀態
    
    /// 當前顯示的月份日期
    @Published var currentDate = Date()
    
    /// 當前選中的頁籤
    @Published var selectedTab: TabType = .training
    
    /// 強制刷新月曆的 ID
    @Published var calendarViewId = UUID()
    
    // MARK: - Alert 和 Dialog 狀態
    
    /// 顯示重複提醒
    @Published var showingDuplicateAlert = false
    
    /// 顯示重疊提醒
    @Published var showingOverlapAlert = false
    
    /// 顯示編輯排程選項
    @Published var showingEditScheduleOptions = false
    
    /// 顯示刪除排程確認
    @Published var showingDeleteScheduleAlert = false
    
    /// 顯示匯出錯誤
    @Published var showingExportError = false
    
    /// 匯出錯誤訊息
    @Published var exportErrorMessage = ""
    
    // MARK: - 頁籤類型
    
    enum TabType {
        case training    // 訓練菜單
        case assessment  // 評估量表
    }
    
    // MARK: - Public Methods
    
    /**
     * 強制刷新月曆
     * 通過更新 calendarViewId 來觸發月曆重繪
     */
    func refreshCalendar() {
        calendarViewId = UUID()
    }
    
    /**
     * 切換到指定頁籤
     * - Parameter tab: 目標頁籤
     */
    func switchToTab(_ tab: TabType) {
        selectedTab = tab
    }
    
    /**
     * 更新當前月份
     * - Parameter date: 新的月份日期
     */
    func updateCurrentMonth(_ date: Date) {
        currentDate = date
        refreshCalendar()
    }
    
    /**
     * 顯示重疊警告
     * - Parameter message: 警告訊息（可選）
     */
    func showOverlapWarning(message: String? = nil) {
        showingOverlapAlert = true
        if let message = message {
            // 可以在這裡處理自定義訊息
        }
    }
    
    /**
     * 顯示匯出錯誤
     * - Parameter error: 錯誤訊息
     */
    func showExportError(_ error: String) {
        exportErrorMessage = error
        showingExportError = true
    }
    
    /**
     * 重置所有警告和對話框狀態
     */
    func resetAlertStates() {
        showingDuplicateAlert = false
        showingOverlapAlert = false
        showingEditScheduleOptions = false
        showingDeleteScheduleAlert = false
        showingExportError = false
        exportErrorMessage = ""
    }
    
    /**
     * 重置所有 UI 狀態
     */
    func resetAllUIStates() {
        resetAlertStates()
        selectedTab = .training
        refreshCalendar()
    }
}
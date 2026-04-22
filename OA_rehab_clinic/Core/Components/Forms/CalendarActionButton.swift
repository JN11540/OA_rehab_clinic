import SwiftUI

/**
 * CalendarActionButton - 訓練月曆動作按鈕組件
 *
 * 功能說明：
 * - 提供訓練月曆的編輯/儲存模式切換功能
 * - 自動變更按鈕文字和圖示根據編輯狀態
 * - 支援自定義按鈕文字覆蓋預設文字
 * - 根據是否有更改來控制按鈕可用性和顏色
 *
 * 狀態管理：
 * - isEditing: false -> 顯示「編輯訓練月曆」 + pencil 圖示
 * - isEditing: true + hasChanges -> 顯示「儲存訓練安排」 + 下載圖示
 * - isEditing: true + !hasChanges -> 禁用狀態，灰色背景
 *
 * UI 設計：
 * - 橙色作為主色調，符合訓練功能的視覺設計
 * - 全寬按鈕設計適合行動裝置操作
 *
 * 架構重構說明：
 * - 從原本 Core/Components/Buttons/ActionButtonsCard.swift 中提取
 * - 移動到 Core/Components/Forms/ 符合表單相關組件分類
 * - 保持在 Core 中因為是通用 UI 組件，無業務邏輯
 */
struct CalendarActionButton: View {
    let isEditing: Bool
    let hasChanges: Bool
    var buttonText: String? = nil
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: isEditing ? "square.and.arrow.down" : "square.and.pencil")
                Text(buttonText ?? (isEditing ? "儲存訓練安排" : "編輯訓練月曆"))
            }
            .font(.system(size: 18, weight: .medium))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(isEditing && !hasChanges ? Color.gray : Color.orange)
            .cornerRadius(8)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 20)
        .disabled(isEditing && !hasChanges)
    }
}
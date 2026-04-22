import SwiftUI

/**
 * TrainingMenuEditSheet - 訓練菜單編輯表單
 *
 * 功能說明：
 * - 編輯菜單基本資訊（名稱、顏色、時段、類型）
 * - 提供直觀的顏色選擇器
 * - 支援時段多選
 * - 區分專屬/共通菜單類型
 *
 * 設計原則：
 * - 表單式布局，清晰明瞭
 * - 即時預覽選擇效果
 * - 驗證輸入有效性
 *
 * 重構說明：
 * - 從 EditTrainingCalendarView 提取
 * - 獨立的表單組件，可重用
 * - 改進了顏色選擇的視覺效果
 */
struct TrainingMenuEditSheet: View {
    // MARK: - 屬性
    
    /// 環境變數
    @Environment(\.dismiss) private var dismiss
    
    /// 要編輯的菜單
    let menu: TrainingMenu?
    
    /// 儲存回調
    let onSave: (TrainingMenu) -> Void
    
    /// 表單狀態
    @State private var title: String
    @State private var isExclusive: Bool
    @State private var selectedColor: Color
    @State private var selectedTimeSlots: Set<String>
    
    /// 常數
    private let timeSlots = ["早", "中", "下", "晚"]
    private let timeColors: [Color] = [.morning, .noon, .afternoon, .night]
    
    /// 顏色選項
    private let colorOptions: [Color] = [
        Color(red: 1.0, green: 0.8, blue: 0.4).opacity(0.3),  // 黃色
        Color(red: 1.0, green: 0.6, blue: 0.4).opacity(0.3),  // 橙色
        Color(red: 0.4, green: 0.6, blue: 1.0).opacity(0.3),  // 藍色
        Color(red: 0.5, green: 0.5, blue: 0.7).opacity(0.3),  // 紫色
        Color(red: 0.4, green: 0.8, blue: 0.4).opacity(0.3),  // 綠色
        Color(red: 1.0, green: 0.4, blue: 0.4).opacity(0.3),  // 紅色
        Color(red: 0.4, green: 0.8, blue: 0.8).opacity(0.3),  // 青色
        Color(red: 0.8, green: 0.4, blue: 0.8).opacity(0.3),  // 粉紫色
        Color(red: 0.6, green: 0.4, blue: 0.2).opacity(0.3),  // 棕色
        Color(red: 0.5, green: 0.5, blue: 0.5).opacity(0.3)   // 灰色
    ]
    
    // MARK: - 初始化
    
    init(menu: TrainingMenu?, onSave: @escaping (TrainingMenu) -> Void) {
        self.menu = menu
        self.onSave = onSave
        _title = State(initialValue: menu?.title ?? "")
        _isExclusive = State(initialValue: menu?.isExclusive ?? true)
        // 預設選擇第一個顏色（如果使用者沒選的話）
        _selectedColor = State(initialValue: menu?.color ?? colorOptions[0])
        // 預設全選訓練時段（早中下晚）- 只有當 menu 存在且有時段時才使用原有時段，否則預設全選
        if let menu = menu, !menu.timeSlots.isEmpty {
            _selectedTimeSlots = State(initialValue: menu.timeSlots)
        } else {
            _selectedTimeSlots = State(initialValue: Set(["早", "中", "下", "晚"]))
        }
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 0) {
            // 標題列
            headerView
            
            // 表單內容
            ScrollView {
                formContent
            }
            
            // 底部按鈕
            bottomButtons
        }
    }
    
    // MARK: - 子視圖
    
    /// 標題視圖
    private var headerView: some View {
        HStack {
            Image(systemName: "doc.text")
                .font(.system(size: 24))
                .foregroundColor(.gray)
            Text("編輯菜單資訊")
                .font(.system(size: 20, weight: .medium))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
    }
    
    /// 表單內容
    private var formContent: some View {
        VStack(alignment: .leading, spacing: 24) {
            // 訓練菜單名稱
            nameSection
            
            // 選擇菜單標示顏色
            colorSection
            
            // 重複訓練
            timeSlotsSection
            
            // 菜單類型
            menuTypeSection
        }
        .padding(.vertical, 24)
    }
    
    /// 名稱輸入區
    private var nameSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("訓練菜單名稱")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.gray)
            
            TextField("", text: $title)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .font(.system(size: 16))
        }
        .padding(.horizontal, 24)
    }
    
    /// 顏色選擇區
    private var colorSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("選擇菜單標示顏色")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.gray)
            
            colorGrid
        }
        .padding(.horizontal, 24)
    }
    
    /// 顏色網格
    private var colorGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 5), spacing: 12) {
            ForEach(colorOptions, id: \.self) { color in
                ColorOption(
                    color: color,
                    isSelected: color == selectedColor,
                    action: { selectedColor = color }
                )
            }
        }
    }
    
    /// 時段選擇區
    private var timeSlotsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("重複訓練")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.gray)
            
            HStack(spacing: 8) {
                ForEach(Array(zip(timeSlots.indices, timeSlots)), id: \.0) { index, slot in
                    TimeSlotButton(
                        text: slot,
                        isSelected: selectedTimeSlots.contains(slot),
                        color: timeColors[index],
                        action: { toggleTimeSlot(slot) }
                    )
                }
            }
        }
        .padding(.horizontal, 24)
    }
    
    /// 菜單類型選擇區
    private var menuTypeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("菜單類型")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.gray)
            
            HStack(spacing: 12) {
                MenuTypeButton(
                    title: "專屬菜單",
                    isSelected: isExclusive,
                    action: { isExclusive = true }
                )
                
                MenuTypeButton(
                    title: "共通菜單",
                    isSelected: !isExclusive,
                    action: { isExclusive = false }
                )
            }
        }
        .padding(.horizontal, 24)
    }
    
    /// 底部按鈕
    private var bottomButtons: some View {
        HStack(spacing: 16) {
            // 取消按鈕
            Button(action: { dismiss() }) {
                Text("取消編輯")
                    .font(.system(size: 16))
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
            }
            
            // 儲存按鈕
            Button(action: saveChanges) {
                Text("儲存變更")
                    .font(.system(size: 16))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(canSave ? Color.blue : Color.gray)
                    .cornerRadius(8)
            }
            .disabled(!canSave)
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 24)
    }
    
    // MARK: - 計算屬性
    
    /// 是否可以儲存
    private var canSave: Bool {
        // 基本驗證：標題不能為空，至少選擇一個時段
        guard !title.isEmpty && !selectedTimeSlots.isEmpty else {
            return false
        }
        
        // 檢查是否有任何變更
        guard let originalMenu = menu else {
            return true // 新增菜單的情況
        }
        
        let hasChanges = title != originalMenu.title ||
                        isExclusive != originalMenu.isExclusive ||
                        selectedColor != originalMenu.color ||
                        selectedTimeSlots != originalMenu.timeSlots
        
        return hasChanges
    }
    
    // MARK: - 私有方法
    
    /// 切換時段選擇
    private func toggleTimeSlot(_ slot: String) {
        if selectedTimeSlots.contains(slot) {
            selectedTimeSlots.remove(slot)
        } else {
            selectedTimeSlots.insert(slot)
        }
    }
    
    /// 儲存變更
    private func saveChanges() {
        guard let menu = menu else { return }
        
        let updatedMenu = TrainingMenu(
            id: menu.id,
            title: title,
            isExclusive: isExclusive,
            color: selectedColor,
            exercises: menu.exercises,
            timeSlots: Set(selectedTimeSlots),
            patientId: menu.patientId,
            createdAt: menu.createdAt,
            updatedAt: Date()
        )
        
        onSave(updatedMenu)
        dismiss()
    }
}

// MARK: - 輔助組件

/// 顏色選項
private struct ColorOption: View {
    let color: Color
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Circle()
            .fill(color)
            .frame(width: 40, height: 40)
            .overlay(
                Circle()
                    .strokeBorder(isSelected ? Color.blue : Color.gray.opacity(0.3), lineWidth: 2)
            )
            .overlay(
                Image(systemName: "checkmark")
                    .foregroundColor(.white)
                    .opacity(isSelected ? 1 : 0)
            )
            .onTapGesture(perform: action)
    }
}

/// 時段選擇按鈕
private struct TimeSlotButton: View {
    let text: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(text)
                .font(.system(size: 14))
                .foregroundColor(isSelected ? .white : .gray)
                .frame(width: 60, height: 32)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isSelected ? color : Color.gray.opacity(0.1))
                )
        }
    }
}

/// 菜單類型按鈕
private struct MenuTypeButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .blue : .gray)
                Text(title)
                    .foregroundColor(isSelected ? .blue : .gray)
            }
        }
    }
}

// MARK: - Preview

struct TrainingMenuEditSheet_Previews: PreviewProvider {
    static var previews: some View {
        let sampleMenu = TrainingMenu(
            id: UUID(),
            title: "範例訓練菜單",
            isExclusive: true,
            color: .blue.opacity(0.3),
            exercises: [],
            timeSlots: Set(["早", "中"]),
            patientId: nil
        )
        
        TrainingMenuEditSheet(
            menu: sampleMenu,
            onSave: { _ in }
        )
        .frame(width: 500, height: 600)
    }
}
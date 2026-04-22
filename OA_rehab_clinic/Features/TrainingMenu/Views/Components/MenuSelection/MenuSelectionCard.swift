import SwiftUI

/**
 * MenuSelectionCard - 菜單選擇卡片
 *
 * 功能說明：
 * - 顯示患者的專屬菜單和共通菜單列表
 * - 支援菜單選擇和刪除操作
 * - 提供即時的視覺反饋
 *
 * 設計原則：
 * - 清晰的分類展示（專屬/共通）
 * - 直觀的選擇和刪除交互
 * - 響應式的狀態更新
 *
 * 重構說明：
 * - 從 EditTrainingCalendarView 提取
 * - 保持原有的功能和介面設計
 * - 改進了代碼結構和可讀性
 */
struct MenuSelectionCard: View {
    // MARK: - 屬性
    
    /// 訓練菜單資料存儲
    @State private var menuStore = TrainingMenuStore.shared
    
    /// 當前選擇的菜單
    @Binding var selectedMenu: TrainingMenu?
    
    /// 刪除確認狀態
    @State private var showingDeleteAlert = false
    @State private var menuToDelete: TrainingMenu?
    
    /// 患者資訊
    let patient: Patient
    
    /// 月曆更新回調
    let onCalendarUpdate: () -> Void
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            // 背景點擊區域（用於取消選擇）
            backgroundLayer
            
            // 主要內容
            contentView
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.white)
        .cornerRadius(12)
        .alert("確認刪除", isPresented: $showingDeleteAlert) {
            deleteAlert
        } message: {
            deleteAlertMessage
        }
    }
    
    // MARK: - 子視圖
    
    /// 背景層
    private var backgroundLayer: some View {
        Color.white
            .contentShape(Rectangle())
            .onTapGesture {
                selectedMenu = nil
            }
    }
    
    /// 內容視圖
    private var contentView: some View {
        VStack(alignment: .leading, spacing: 20) {
            // 專屬菜單區塊
            exclusiveMenuSection
            
            Divider()
            
            // 共通菜單區塊
            commonMenuSection
        }
        .padding(20)
    }
    
    /// 專屬菜單區塊
    private var exclusiveMenuSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("專屬菜單")
                .font(.headline)
            
            if menuStore.getExclusiveMenus(for: patient.id).isEmpty {
                emptyStateView
            } else {
                menuList(menus: menuStore.getExclusiveMenus(for: patient.id))
            }
        }
    }
    
    /// 共通菜單區塊
    private var commonMenuSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("共通菜單")
                .font(.headline)
            
            if menuStore.getCommonMenus().isEmpty {
                emptyStateView
            } else {
                menuList(menus: menuStore.getCommonMenus())
            }
        }
    }
    
    /// 空狀態視圖
    private var emptyStateView: some View {
        Text("尚未加入")
            .foregroundColor(.gray)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
    
    /// 菜單列表
    private func menuList(menus: [TrainingMenu]) -> some View {
        List {
            ForEach(menus) { menu in
                MenuListItem(
                    menu: menu,
                    isSelected: selectedMenu?.id == menu.id,
                    onSelect: {
                        handleMenuSelection(menu)
                    },
                    onDelete: {
                        menuToDelete = menu
                        showingDeleteAlert = true
                    }
                )
                .listRowInsets(EdgeInsets())
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
            }
        }
        .listStyle(.plain)
        .frame(maxHeight: .infinity)
    }
    
    /// 刪除確認對話框
    private var deleteAlert: some View {
        Group {
            Button("取消", role: .cancel) {}
            Button("刪除", role: .destructive) {
                deleteMenu()
            }
        }
    }
    
    /// 刪除確認訊息
    private var deleteAlertMessage: some View {
        Group {
            if let menu = menuToDelete {
                Text("確定要刪除「\(menu.title)」嗎？")
            }
        }
    }
    
    // MARK: - 私有方法
    
    /// 處理菜單選擇
    private func handleMenuSelection(_ menu: TrainingMenu) {
        withAnimation {
            if selectedMenu?.id == menu.id {
                selectedMenu = nil
            } else {
                selectedMenu = menu
            }
            // 強制更新月曆以反映菜單選擇變化
            onCalendarUpdate()
        }
    }
    
    /// 刪除菜單
    private func deleteMenu() {
        if let menu = menuToDelete {
            menuStore.deleteMenu(menu)
            if selectedMenu?.id == menu.id {
                selectedMenu = nil
            }
        }
    }
}

// MARK: - MenuListItem

/**
 * MenuListItem - 菜單列表項目
 *
 * 功能說明：
 * - 顯示單個菜單項目
 * - 支援選擇和刪除操作
 * - 提供滑動刪除手勢
 */
private struct MenuListItem: View {
    let menu: TrainingMenu
    let isSelected: Bool
    let onSelect: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        HStack {
            // 菜單標題
            Text(menu.title)
                .foregroundColor(AppColors.text)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // 刪除按鈕
            Image(systemName: "trash")
                .foregroundColor(AppColors.text.opacity(0.5))
                .onTapGesture {
                    onDelete()
                }
                .padding(.leading, 8)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isSelected ? AppColors.accent.opacity(0.1) : Color.clear)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            onSelect()
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("刪除", systemImage: "trash")
            }
        }
    }
}

// MARK: - Preview

struct MenuSelectionCard_Previews: PreviewProvider {
    static var previews: some View {
        MenuSelectionCard(
            selectedMenu: .constant(nil),
            patient: Patient.sample,
            onCalendarUpdate: {}
        )
        .frame(width: 300, height: 400)
        .padding()
        .background(Color.gray.opacity(0.1))
    }
}
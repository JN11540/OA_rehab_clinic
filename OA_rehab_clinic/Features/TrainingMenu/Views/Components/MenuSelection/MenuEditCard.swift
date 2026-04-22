import SwiftUI

/**
 * MenuEditCard - 菜單編輯卡片
 *
 * 功能說明：
 * - 顯示選定菜單的詳細資訊
 * - 提供菜單資訊編輯功能
 * - 展示菜單內容（運動項目列表）
 *
 * 設計原則：
 * - 清晰的資訊層次結構
 * - 直觀的編輯入口
 * - 完整的菜單資訊展示
 *
 * 重構說明：
 * - 從 EditTrainingCalendarView 提取
 * - 保持原有的功能和介面設計
 * - 優化了組件結構
 */
struct MenuEditCard: View {
    // MARK: - 屬性
    
    /// 患者資訊
    let patient: Patient
    
    /// 菜單標題（預設值）
    @Binding var menuTitle: String
    
    /// 時段選項
    let timeSlots: [String]
    let timeColors: [Color]
    
    /// 選定的菜單
    @Binding var selectedMenu: TrainingMenu?
    
    /// 編輯表單顯示狀態
    @State private var showingEditSheet = false
    
    /// 環境注入
    let userModel: UserModel
    let scheduleStore: TrainingScheduleStore
    let menuStore: TrainingMenuStore
    
    /// 菜單更新回調
    let onMenuUpdated: () -> Void
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 0) {
            // 上半部分：標題和時段標籤
            headerSection
            
            Divider()
            
            // 下半部分：菜單內容
            contentSection
        }
        .cornerRadius(12)
        .sheet(isPresented: $showingEditSheet) {
            editSheet
        }
    }
    
    // MARK: - 子視圖
    
    /// 標題區域
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 專屬/共通菜單標籤
            menuTypeLabel
            
            VStack(alignment: .leading, spacing: 16) {
                // 菜單名稱和編輯按鈕
                menuHeaderRow
                
                // 時段標籤
                timeSlotsView
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.white)
    }
    
    /// 菜單類型標籤
    private var menuTypeLabel: some View {
        Text(selectedMenu?.isExclusive ?? true ? "專屬菜單" : "共通菜單")
            .font(.system(size: 14))
            .foregroundColor(selectedMenu != nil ? .gray : .gray.opacity(0.6))
    }
    
    /// 菜單標題行
    private var menuHeaderRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                // 顏色指示器
                Circle()
                    .fill(selectedMenu?.color ?? Color.gray.opacity(0.3))
                    .frame(width: 20, height: 20)
                    .overlay(
                        Image(systemName: "paintbrush.fill")
                            .font(.system(size: 12))
                            .foregroundColor(selectedMenu != nil ? .white : .gray)
                    )
                
                // 菜單標題
                Text(selectedMenu?.title ?? menuTitle)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(selectedMenu != nil ? AppColors.text : .gray)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Spacer()
                
                // 編輯按鈕
                editButton
            }
        }
    }
    
    /// 編輯按鈕
    private var editButton: some View {
        Button(action: {
            showingEditSheet = true
        }) {
            HStack {
                Image(systemName: "square.and.pencil")
                Text("編輯")
            }
            .font(.system(size: 16))
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(selectedMenu != nil ? Color.orange : Color.gray.opacity(0.6))
            .cornerRadius(20)
        }
        .disabled(selectedMenu == nil)
    }
    
    /// 時段標籤視圖
    private var timeSlotsView: some View {
        HStack(spacing: 8) {
            ForEach(Array(zip(timeSlots.indices, timeSlots)), id: \.0) { index, slot in
                let isSelected = selectedMenu?.timeSlots.contains(slot) ?? false
                TimeSlotLabel(
                    text: slot,
                    isSelected: isSelected,
                    color: timeColors[index]
                )
            }
        }
    }
    
    /// 內容區域
    private var contentSection: some View {
        VStack(alignment: .leading) {
            // 標題行
            contentHeader
            
            // 內容列表
            if let menu = selectedMenu {
                exercisesList(menu: menu)
            } else {
                emptyStateView
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white)
    }
    
    /// 內容標題
    private var contentHeader: some View {
        HStack {
            Text("菜單內容")
                .font(.headline)
            
            Spacer()
            
            // 編輯菜單內容按鈕
            NavigationLink {
                EditTrainingMenuView(
                    patient: patient,
                    existingMenu: selectedMenu,
                    selectedMenu: $selectedMenu,
                    isCommonMenu: false  // 從個案頁面進入，顯示 PatientInfoCard
                )
                .environmentObject(userModel)
                .environmentObject(scheduleStore)
                .environmentObject(menuStore)
            } label: {
                HStack {
                    Image(systemName: "square.and.pencil")
                    Text("編輯")
                }
                .font(.system(size: 16))
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.orange)
                .cornerRadius(20)
            }
        }
    }
    
    /// 運動列表
    private func exercisesList(menu: TrainingMenu) -> some View {
        ScrollView {
            VStack(spacing: 2) {
                ForEach(menu.exercises) { exercise in
                    CompactExerciseListItem(parameters: exercise)
                }
            }
            .padding(.vertical, 2)
        }
    }
    
    /// 空狀態視圖
    private var emptyStateView: some View {
        VStack {
            Spacer()
            Text("尚未加入")
                .foregroundColor(.gray)
                .frame(maxWidth: .infinity, alignment: .center)
            Spacer()
        }
    }
    
    /// 編輯表單
    private var editSheet: some View {
        TrainingMenuEditSheet(menu: selectedMenu) { updatedMenu in
            handleMenuUpdate(updatedMenu)
        }
    }
    
    // MARK: - 私有方法
    
    /// 處理菜單更新
    private func handleMenuUpdate(_ updatedMenu: TrainingMenu) {
        if var menu = selectedMenu {
            menu.title = updatedMenu.title
            menu.color = updatedMenu.color
            menu.isExclusive = updatedMenu.isExclusive
            menu.timeSlots = updatedMenu.timeSlots
            selectedMenu = menu
            
            // 保存菜單到全局 store
            TrainingMenuStore.shared.saveMenu(menu)
            
            // 同步更新所有相關的 TrainingSchedule 的時段信息
            updateRelatedSchedulesTimeSlots(menuId: menu.id, newTimeSlots: updatedMenu.timeSlots)
            
            // 調用回調函數通知月曆更新
            onMenuUpdated()
        }
    }
    
    /// 更新相關排程的時段信息
    private func updateRelatedSchedulesTimeSlots(menuId: UUID, newTimeSlots: Set<String>) {
        // 獲取所有與此菜單相關的排程
        let allSchedules = scheduleStore.schedules
        let relatedSchedules = allSchedules.filter { $0.menuId == menuId }
        
        // 更新每個相關排程的時段信息
        for schedule in relatedSchedules {
            var updatedSchedule = schedule
            updatedSchedule = TrainingSchedule(
                id: schedule.id,
                menuId: schedule.menuId,
                patientId: schedule.patientId,
                selectedDates: schedule.dates,
                timeSlots: newTimeSlots  // 使用新的時段信息
            )
            
            // 先移除舊的排程，再添加更新後的排程
            scheduleStore.removeSchedule(schedule)
            scheduleStore.addSchedule(updatedSchedule)
        }
        
        // 保存所有變更並重新載入
        scheduleStore.saveSchedules()
        scheduleStore.reloadSchedules()
    }
}

// MARK: - TimeSlotLabel

/**
 * TimeSlotLabel - 時段標籤
 *
 * 功能說明：
 * - 顯示單個時段標籤
 * - 根據選擇狀態改變外觀
 */
private struct TimeSlotLabel: View {
    let text: String
    let isSelected: Bool
    let color: Color
    
    var body: some View {
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

// MARK: - Preview

struct MenuEditCard_Previews: PreviewProvider {
    static var previews: some View {
        MenuEditCard(
            patient: Patient.sample,
            menuTitle: .constant("尚未新增或選擇訓練"),
            timeSlots: ["早", "中", "下", "晚"],
            timeColors: [.morning, .noon, .afternoon, .night],
            selectedMenu: .constant(nil),
            userModel: UserModel.shared,
            scheduleStore: TrainingScheduleStore.shared,
            menuStore: TrainingMenuStore.shared,
            onMenuUpdated: {}
        )
        .frame(width: 400, height: 500)
        .padding()
        .background(Color.gray.opacity(0.1))
    }
}
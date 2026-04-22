import SwiftUI

/**
 * TrainingSchedulingView - 訓練排程視圖
 *
 * 功能說明：
 * - 專門處理訓練菜單的排程介面
 * - 包含菜單選擇、編輯和月曆互動
 * - 整合訓練相關的所有 UI 組件
 *
 * 設計原則：
 * - 單一職責：只處理訓練排程相關 UI
 * - 組件化：重用現有的 UI 組件
 * - 響應式：通過 ViewModel 響應狀態變化
 *
 * 重構說明：
 * - 從 EditTrainingCalendarView 提取訓練相關 UI
 * - 保持原有的版面配置和功能
 * - 簡化條件判斷邏輯
 */
struct TrainingSchedulingView: View {
    // MARK: - 屬性
    
    /// 共享的視圖模型
    @ObservedObject var viewModel: CalendarSchedulingViewModel
    
    /// 環境注入
    @EnvironmentObject private var userModel: UserModel
    @EnvironmentObject private var trainingMenuStore: TrainingMenuStore
    @EnvironmentObject private var scheduleStore: TrainingScheduleStore
    
    // MARK: - Body
    
    var body: some View {
        Grid(alignment: .leading, horizontalSpacing: 15, verticalSpacing: 15) {
            GridRow {
                // 左側：菜單選擇區域（1格）
                menuSelectionSection
                    .gridCellColumns(1)
                
                // 中間：菜單編輯區域（2格）
                menuEditSection
                    .gridCellColumns(2)
                
                // 右側：月曆和操作區域（2格）
                calendarSection
                    .gridCellColumns(2)
            }
        }
    }
    
    // MARK: - 子視圖
    
    /// 菜單選擇區域
    private var menuSelectionSection: some View {
        MenuSelectionCard(
            selectedMenu: $viewModel.selectedMenu,
            patient: viewModel.patient,
            onCalendarUpdate: viewModel.refreshCalendar
        )
    }
    
    /// 菜單編輯區域
    private var menuEditSection: some View {
        MenuEditCard(
            patient: viewModel.patient,
            menuTitle: .constant(viewModel.trainingViewModel.menuTitle),
            timeSlots: viewModel.timeSlots,
            timeColors: viewModel.timeColors,
            selectedMenu: $viewModel.selectedMenu,
            userModel: userModel,
            scheduleStore: scheduleStore,
            menuStore: trainingMenuStore,
            onMenuUpdated: viewModel.refreshCalendar
        )
    }
    
    /// 月曆和操作區域
    private var calendarSection: some View {
        VStack(spacing: 0) {
            // 編輯模式提示
            if viewModel.isEditingExistingSchedule {
                editingModeIndicator
            }
            
            // 月曆容器
            calendarContainer
                .id(viewModel.calendarViewId)
            
            // 儲存按鈕
            saveButton
        }
        .frame(width: 430)  // 固定寬度以保持一致的佈局
    }
    
    /// 編輯模式指示器
    private var editingModeIndicator: some View {
        Group {
            if let schedule = viewModel.scheduleBeingEdited,
               let menu = trainingMenuStore.getMenu(by: schedule.menuId) {
                HStack {
                    Circle()
                        .fill(menu.color)
                        .frame(width: 12, height: 12)
                    
                    Text("正在編輯「\(menu.title)」")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Button(action: viewModel.cancelEditingExistingSchedule) {
                        Text("取消編輯")
                            .font(.system(size: 14))
                            .foregroundColor(.blue)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }
        }
    }
    
    /// 月曆容器
    private var calendarContainer: some View {
        UnifiedCalendarContainer(
            currentDate: $viewModel.currentDate,
            patient: viewModel.patient,
            selectedMenu: viewModel.selectedMenu,
            selectedAssessments: [],
            onDateRangeSelected: viewModel.handleDateRangeSelection,
            onExistingScheduleTap: viewModel.handleExistingScheduleSelection,
            selectionMode: .range,
            isEditable: true,
            isEditingExistingSchedule: viewModel.isEditingExistingSchedule,
            initialSelectedDates: viewModel.isEditingExistingSchedule 
                ? (viewModel.isEnteringEditModeFromExternal || viewModel.selectedDates.isEmpty 
                    ? viewModel.originalScheduleDates 
                    : viewModel.selectedDates)
                : []
        )
        .environmentObject(scheduleStore)
        .environmentObject(AssessmentStore.shared)
    }
    
    /// 儲存按鈕
    private var saveButton: some View {
        CalendarActionButton(
            isEditing: true,
            hasChanges: viewModel.hasTrainingChanges,
            buttonText: viewModel.trainingButtonText,
            action: viewModel.saveTrainingSchedule
        )
    }
}

// MARK: - Preview

struct TrainingSchedulingView_Previews: PreviewProvider {
    static var previews: some View {
        let samplePatient = Patient(
            id: "K123456789",
            name: "範例患者",
            gender: .male,
            birthDate: Date(),
            height: 170.0,
            weight: 65.0,
            affectedSide: .right,
            acceptsElectricity: 0,
            equipment: Equipment(
                smartKnee: .none,
                homeEquipment: [],
                stimulator: false
            ),
            assessments: []
        )
        
        TrainingSchedulingView(
            viewModel: CalendarSchedulingViewModel(
                patient: samplePatient
            )
        )
        .environmentObject(UserModel.shared)
        .environmentObject(TrainingMenuStore.shared)
        .environmentObject(TrainingScheduleStore.shared)
        .previewLayout(.sizeThatFits)
    }
}

/*
import SwiftUI
import Foundation
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
// For NSColor, if needed, but we'll try to avoid direct NSColor use for this simple case
#endif
import UniformTypeIdentifiers

struct EditTrainingCalendarView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.presentationMode) private var presentationMode
    @EnvironmentObject private var userModel: UserModel
    @EnvironmentObject private var trainingMenuStore: TrainingMenuStore
    @StateObject private var assessmentStore = AssessmentStore.shared
    @State private var patient: Patient  // 改為 @State
    @State private var currentDate = Date()
    @State private var menuTitle: String
    @State private var selectedMenu: TrainingMenu?
    @State private var selectedAssessment: Assessment? // Changed from Set to single optional Assessment
    @EnvironmentObject private var scheduleStore: TrainingScheduleStore
    @State private var selectedDates: Set<Date> = []
    @State private var showingDuplicateAlert = false
    @State private var selectedTab: TabType = .training
    
    // 新增：處理重疊日期的狀態變數
    @State private var showingOverlapAlert = false
    @State private var overlappingSchedules: [TrainingSchedule] = []
    @State private var pendingSchedule: TrainingSchedule?
    
    // 新增：編輯現有排程的狀態變數
    @State private var isEditingExistingSchedule = false
    @State private var scheduleBeingEdited: TrainingSchedule?
    @State private var originalScheduleDates: Set<Date> = []
    @State private var showingEditScheduleOptions = false
    @State private var showingDeleteScheduleAlert = false
    
    // 新增：編輯評估排程的狀態變數
    @State private var isEditingAssessmentSchedule = false
    
    // 匯出相關狀態
    @State private var showingExportError = false
    @State private var exportErrorMessage = ""
    
    // 新增：用於強制刷新 CalendarCard 的 ID
    @State private var calendarViewId = UUID()
    
    // 新增：頁籤類型
    enum TabType {
        case training
        case assessment
    }
    
    private let timeSlots = ["早", "中", "下", "晚"]
    private let timeColors: [Color] = [.morning, .noon, .afternoon, .night]
    private let fixedHeight: CGFloat = 450  // 與 NotesCard 相同的高度
    private let calendar = Calendar.current
    
    // 新增：要編輯的排程ID
    @State private var scheduleIdToEdit: UUID?
    
    // 新增：標記是否從外部進入編輯模式
    @State private var isEnteringEditModeFromExternal = false
    
    init(patient: Patient, scheduleIdToEdit: UUID? = nil) {
        self.patient = patient
        let defaultTitle = "尚未新增或選擇訓練"
        _menuTitle = State(initialValue: defaultTitle)
        self._scheduleIdToEdit = State(initialValue: scheduleIdToEdit)
    }
    
    private var hasChanges: Bool {
        if selectedTab == .training {
            if isEditingExistingSchedule {
                // 在編輯模式下，檢查選擇的日期是否與原始日期不同
                return selectedDates != originalScheduleDates && !selectedDates.isEmpty
            } else {
                // 在新增模式下，檢查是否選擇了菜單和日期
                return selectedMenu != nil && !selectedDates.isEmpty
            }
        } else {
            return selectedAssessment != nil && !selectedDates.isEmpty
        }
    }
    
    private func resetState() {
        selectedDates.removeAll()
        selectedAssessment = nil // Changed from Set.removeAll()
        selectedMenu = nil
        isEditingExistingSchedule = false
        scheduleBeingEdited = nil
        originalScheduleDates.removeAll()
        isEnteringEditModeFromExternal = false
        isEditingAssessmentSchedule = false // Reset assessment editing state
        if let updatedPatient = PatientStore.shared.patients.first(where: { $0.id == patient.id }) {
            patient = updatedPatient
        }
        calendarViewId = UUID() // 強制刷新 CalendarCard
    }
    
    // 修改：處理選擇現有排程
    private func handleExistingScheduleSelection(_ date: Date) {
        // 只在訓練菜單頁籤中啟用此功能
        guard selectedTab == .training else { return }
        
        // 如果已經在編輯模式，不再觸發編輯選項
        if isEditingExistingSchedule {
            return
        }
        
        // 找出包含所選日期的所有排程
        let schedulesForDate = scheduleStore.getSchedulesForPatient(patient.id)
            .filter { schedule in
                schedule.dates.contains { scheduleDate in
                    calendar.isDate(scheduleDate, inSameDayAs: date)
                }
            }
        
        // 如果找到排程，選擇最後一個（假設是最新添加的）
        if let scheduleToEdit = schedulesForDate.last {
            // 獲取對應的菜單
            if let menu = trainingMenuStore.getMenu(by: scheduleToEdit.menuId) {
                // 先設置菜單和原始日期，確保這些值在顯示編輯選項之前已經設置好
                selectedMenu = menu
                
                // 深拷貝日期集合，避免引用同一個集合
                // 標準化日期，只保留年月日部分
                var normalizedDates = Set<Date>()
                for date in scheduleToEdit.dates {
                    if let normalizedDate = calendar.normalizedDate(from: date) {
                        normalizedDates.insert(normalizedDate)
                    } else {
                        normalizedDates.insert(date)
                    }
                }
                
                originalScheduleDates = normalizedDates
                selectedDates = normalizedDates  // 確保selectedDates包含所有原始日期
                
                // 設置編輯狀態
                scheduleBeingEdited = scheduleToEdit
                isEditingExistingSchedule = true
                
                // 設置標誌，表示不是從外部進入編輯模式
                isEnteringEditModeFromExternal = false
                
                // 顯示編輯選項
                showingEditScheduleOptions = true
            }
        }
    }
    
    // 修改：取消編輯現有排程
    private func cancelEditingExistingSchedule() {
        // 關閉編輯選項對話框
        showingEditScheduleOptions = false
        
        // 重置編輯狀態
        isEditingExistingSchedule = false
        scheduleBeingEdited = nil
        originalScheduleDates.removeAll()
        selectedDates.removeAll()
        isEnteringEditModeFromExternal = false
        
        // 關鍵修改：清除選定的菜單，確保完全退出編輯模式
        selectedMenu = nil
        
        // 強制刷新日曆
        calendarViewId = UUID()
    }
    
    // 修改：保存編輯後的排程
    private func saveEditedSchedule() {
        guard let scheduleToEdit = scheduleBeingEdited,
              let currentSelectedMenu = selectedMenu else { return } // Ensure selectedMenu is used

        // Create the desired state of the schedule being edited with current self.selectedDates
        let updatedSchedulePortion = TrainingSchedule(
            id: scheduleToEdit.id,
            menuId: currentSelectedMenu.id, 
            patientId: patient.id,
            selectedDates: self.selectedDates, // Dates from the UI
            timeSlots: currentSelectedMenu.timeSlots
        )

        // Check for overlaps with OTHER menus
        let otherMenuSchedules = scheduleStore.getSchedulesForPatient(patient.id)
            .filter { $0.menuId != currentSelectedMenu.id } // Only different menus

        let newOverlappingSchedules = otherMenuSchedules.filter { schedule in
            updatedSchedulePortion.dates.contains { selectedDate in
                schedule.dates.contains { scheduleDate in
                    calendar.isDate(selectedDate, inSameDayAs: scheduleDate)
                }
            }
        }

        if !newOverlappingSchedules.isEmpty {
            self.overlappingSchedules = newOverlappingSchedules
            self.pendingSchedule = updatedSchedulePortion // This is what we intend to save after overlap resolution
            showingOverlapAlert = true
            return
        }
        
        // No overlap with other menus. Proceed to save/update the schedule for the current menu.
        // Remove the old version of the schedule being edited first.
        scheduleStore.removeSchedule(scheduleToEdit) 
        
        // Now, merge updatedSchedulePortion with any *other* existing schedules for the *same* menu.
        let otherSchedulesForSameMenu = scheduleStore.getSchedulesForPatient(patient.id)
            .filter { $0.menuId == currentSelectedMenu.id } // $0.id != scheduleToEdit.id is implicitly handled by prior removal

        var finalDates = updatedSchedulePortion.dates
        let finalId = updatedSchedulePortion.id

        if !otherSchedulesForSameMenu.isEmpty {
            for schedule in otherSchedulesForSameMenu {
                finalDates.formUnion(schedule.dates)
                // If scheduleToEdit was one of these (it shouldn't be if removed), this logic is fine.
                // If we prefer to keep an existing ID from a merge, this could be adjusted.
                scheduleStore.removeSchedule(schedule)
            }
            // If there were other schedules for the same menu, and we merged, 
            // we might prefer to use an ID from one of those, e.g., the first one.
            // For simplicity, we'll use the ID of the schedule we started editing or a new one if it was merged from new.
        }

        let finalScheduleToSave = TrainingSchedule(
            id: finalId, // Use the ID from scheduleToEdit
            menuId: currentSelectedMenu.id,
            patientId: patient.id,
            selectedDates: finalDates,
            timeSlots: currentSelectedMenu.timeSlots
        )

        scheduleStore.addSchedule(finalScheduleToSave)
        scheduleStore.saveSchedules()
        scheduleStore.reloadSchedules()

        // Update state for continued editing
        self.selectedMenu = currentSelectedMenu // Keep menu selected
        self.selectedDates = finalScheduleToSave.dates // Update selectedDates to reflect the saved state
        self.isEditingExistingSchedule = true
        self.scheduleBeingEdited = finalScheduleToSave
        self.originalScheduleDates = finalScheduleToSave.dates

        if let updatedPatient = PatientStore.shared.patients.first(where: { $0.id == self.patient.id }) {
            self.patient = updatedPatient
        }
        self.calendarViewId = UUID()
        showingEditScheduleOptions = false
    }
    
    // 新增：刪除選中的排程
    private func deleteSelectedSchedule() {
        guard let scheduleToDelete = scheduleBeingEdited else { return }
        
        // scheduleStore.removeSchedule(scheduleToDelete) // OLD
        // Use the EditTrainingCalendarView's current month context for deletion
        scheduleStore.removeDatesFromSchedule(scheduleToDelete.id, inMonthOf: self.currentDate)
        
        // scheduleStore.saveSchedules() // Already handled by removeDatesFromSchedule
        // scheduleStore.reloadSchedules() // Already handled by removeDatesFromSchedule
        
        // 重置編輯狀態
        isEditingExistingSchedule = false
        scheduleBeingEdited = nil
        originalScheduleDates.removeAll()
        selectedDates.removeAll()
        isEnteringEditModeFromExternal = false
        showingEditScheduleOptions = false  // 確保關閉編輯選項對話框
        
        // 關閉刪除確認對話框
        showingDeleteScheduleAlert = false
        calendarViewId = UUID() // 強制刷新 CalendarCard
    }
    
    // 新增：從外部設置編輯模式
    func setEditMode(for scheduleId: UUID) {
        // 查找對應的排程
        if let scheduleToEdit = scheduleStore.getSchedulesForPatient(patient.id)
            .first(where: { $0.id == scheduleId }) {
            
            // 獲取對應的菜單
            if let menu = trainingMenuStore.getMenu(by: scheduleToEdit.menuId) {
                // 標準化日期，只保留年月日部分
                var normalizedDates = Set<Date>()
                for date in scheduleToEdit.dates {
                    if let normalizedDate = calendar.normalizedDate(from: date) {
                        normalizedDates.insert(normalizedDate)
                    } else {
                        normalizedDates.insert(date)
                    }
                }
                
                // 先設置原始日期和選中的日期，確保在設置編輯狀態前已經有正確的日期
                originalScheduleDates = normalizedDates
                selectedDates = normalizedDates
                
                // 設置菜單
                selectedMenu = menu
                
                // 設置編輯狀態
                scheduleBeingEdited = scheduleToEdit
                isEditingExistingSchedule = true
                
                // 切換到訓練菜單頁籤
                selectedTab = .training
                
                // 顯示編輯選項
                showingEditScheduleOptions = true
                
                // 設置標誌，表示是從外部進入編輯模式
                isEnteringEditModeFromExternal = true
            }
        }
    }
    
    var body: some View {
        ZStack {
            // Background gradient
            GradientBackground(
                startColor: Color(red: 0.47, green: 0.84, blue: 0.98),
                endColor: Color(red: 0.72, green: 0.89, blue: 0.59)
            )
            .ignoresSafeArea(edges: .all)

            VStack(spacing: 30) {  // 使用固定間距
                // Navigation header
                NavigationHeader(
                    patient: patient,
                    pageTitle: "編輯訓練月曆"
                )
                
                // Content Grid
                Grid(alignment: .leading, horizontalSpacing: 15, verticalSpacing: 15) {
                    // Patient info section
                    GridRow {
                        PatientInfoCard(patient: patient)
                            .gridCellColumns(5)
                    }
                    #if canImport(UIKit)
                    .frame(height: UIScreen.main.bounds.height / 5)
                    #else
                    .frame(height: 200) // Fallback height for non-UIKit
                    #endif
                    
                    // Tab buttons
                    GridRow {
                        HStack(spacing: 5) {  // 使用很小的間距
                            TabButton(
                                title: "訓練菜單",
                                isSelected: selectedTab == .training,
                                action: { selectedTab = .training }
                            )            
                            
                            TabButton(
                                title: "評估量表",
                                isSelected: selectedTab == .assessment,
                                action: { selectedTab = .assessment }
                            )
                        }
                        .gridCellColumns(2)  // 只佔用前兩格

                        Spacer()
                            .gridCellColumns(2)
                        
                        // 匯出按鈕
                        Button(action: {
                            // 使用按月份匯出功能，只匯出當前顯示月份的數據
                            ClinicDataExporter.shared.exportAndShareArrangementForMonth(for: patient, month: currentDate) { result in
                                switch result {
                                case .success:
                                    print("匯出並共享成功")
                                case .failure(let error):
                                    print("匯出失敗: \(error.localizedDescription)")
                                    self.exportErrorMessage = error.localizedDescription
                                    self.showingExportError = true
                                }
                            }
                        }) {
                            HStack(spacing: 5) {
                                Image(systemName: "square.and.arrow.up")
                                    .font(.system(size: 14))
                                Text("匯出安排")
                                    .font(.system(size: 14))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.blue)
                            .cornerRadius(16)
                        }
                        .gridCellColumns(1)
                    }
                    .frame(height: 32)  // 調整高度以配合按鈕
                    .padding(.horizontal, 10)

                    // Content section
                    GridRow {
                        if selectedTab == .training {
                            // 訓練菜單視圖
                            MenuSelectionCard(
                                selectedMenu: $selectedMenu, 
                                patient: patient,
                                onCalendarUpdate: {
                                    // 當菜單選擇變化時，強制刷新月曆
                                    calendarViewId = UUID()
                                }
                            )
                                .gridCellColumns(1)
                                #if canImport(UIKit)
                                .frame(height: UIScreen.main.bounds.height / 1.85)
                                #else
                                .frame(height: 400) // Fallback height for non-UIKit
                                #endif
                                .onChange(of: selectedMenu) { newMenu in
                                    // If we were editing a schedule, and the user selects a different menu,
                                    // reset the editing state to start fresh with the new menu.
                                    if isEditingExistingSchedule {
                                        if let currentlyEditingMenuId = scheduleBeingEdited?.menuId {
                                            if newMenu?.id != currentlyEditingMenuId {
                                                // User selected a DIFFERENT menu while in edit mode for another.
                                                // Reset to "new schedule" mode for the newMenu.
                                                isEditingExistingSchedule = false
                                                scheduleBeingEdited = nil
                                                selectedDates.removeAll()
                                                originalScheduleDates.removeAll()
                                                // selectedMenu is already newMenu
                                                calendarViewId = UUID() // Refresh calendar
                                            }
                                            // If newMenu?.id == currentlyEditingMenuid, do nothing, we are still "editing" it.
                                            // If newMenu is nil (deselected), the existing edit mode also implicitly ends.
                                        }
                                    } else if newMenu != nil {
                                        // If not previously editing, but a new menu is selected,
                                        // check if this new menu has existing schedules and potentially auto-load them.
                                        // For now, just ensure selectedDates are clear for a new selection.
                                        // More sophisticated auto-load could be added here if desired.
                                        // selectedDates.removeAll() // This might be too aggressive if we want to merge.
                                        // calendarViewId = UUID()
                                    }

                                    // If the selected menu becomes nil (deselected from the list),
                                    // ensure we are not in editing mode anymore.
                                    if newMenu == nil && isEditingExistingSchedule {
                                        isEditingExistingSchedule = false
                                        scheduleBeingEdited = nil
                                        selectedDates.removeAll()
                                        originalScheduleDates.removeAll()
                                        calendarViewId = UUID()
                                    }
                                }
                                
                            MenuEditCard(
                                patient: patient,
                                menuTitle: $menuTitle,
                                timeSlots: timeSlots,
                                timeColors: timeColors,
                                selectedMenu: $selectedMenu,
                                userModel: userModel,
                                scheduleStore: scheduleStore,
                                menuStore: trainingMenuStore,
                                onMenuUpdated: {
                                    // 當菜單被更新時，強制刷新月曆
                                    calendarViewId = UUID()
                                }
                            )
                            .gridCellColumns(2)
                            #if canImport(UIKit)
                            .frame(height: UIScreen.main.bounds.height / 1.85)
                            #else
                            .frame(height: 400) // Fallback height for non-UIKit
                            #endif
                            
                        } else {
                            // 評估量表視圖
                            AssessmentSelectionCard(
                                assessments: patient.assessments,
                                selectedAssessment: $selectedAssessment, // Changed from selectedAssessments
                                onSelect: { assessment in
                                    // 點擊不同的評估量表時切換
                                    if selectedAssessment?.id != assessment.id {
                                        // 選擇新的評估量表
                                        selectedAssessment = assessment
                                        
                                        // 載入該評估的已安排日期
                                        selectedDates = Set(assessment.scheduledDates)
                                        
                                        // 如果已有安排，進入編輯模式
                                        isEditingAssessmentSchedule = !assessment.scheduledDates.isEmpty
                                        
                                        // 強制刷新月曆以顯示更新的 dots
                                        calendarViewId = UUID()
                                    }
                                    // 如果點擊的是已選中的評估，保持選中狀態不變
                                }
                            )
                            .gridCellColumns(3)
                        }
                        
                        // 右側月曆
                        VStack(spacing: 0) {
                            if isEditingExistingSchedule, let schedule = scheduleBeingEdited, let menu = trainingMenuStore.getMenu(by: schedule.menuId) {
                                HStack {
                                    Circle()
                                        .fill(menu.color)
                                        .frame(width: 12, height: 12)
                                    
                                    Text("正在編輯「\(menu.title)」")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.primary)
                                    
                                    Spacer()
                                    
                                    Button(action: {
                                        cancelEditingExistingSchedule()
                                    }) {
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
                            
                            if selectedTab == .assessment && isEditingAssessmentSchedule && selectedAssessment != nil {
                                HStack {
                                    Circle()
                                        .fill(selectedAssessment!.type.color)
                                        .frame(width: 12, height: 12)
                                    
                                    Text("正在編輯「\(selectedAssessment!.title)」評估排程")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.primary)
                                    
                                    Spacer()
                                    
                                    Button(action: {
                                        // Reset assessment editing state
                                        isEditingAssessmentSchedule = false
                                        selectedDates.removeAll()
                                        selectedAssessment = nil
                                        calendarViewId = UUID() // Force refresh
                                    }) {
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
                            
                            UnifiedCalendarContainer(
                                currentDate: $currentDate,
                                patient: patient,
                                selectedMenu: selectedTab == .training ? selectedMenu : nil,
                                selectedAssessments: selectedTab == .assessment && selectedAssessment != nil ? [selectedAssessment!] : [],
                                onDateRangeSelected: { dates in
                                    selectedDates = dates
                                },
                                onExistingScheduleTap: { date in
                                    // 只在訓練菜單頁籤中啟用此功能
                                    if selectedTab == .training {
                                        handleExistingScheduleSelection(date)
                                    }
                                },
                                selectionMode: .range,
                                isEditable: true,
                                isEditingExistingSchedule: isEditingExistingSchedule,
                                initialSelectedDates: selectedTab == .training 
                                    ? (isEditingExistingSchedule ? (isEnteringEditModeFromExternal || selectedDates.isEmpty ? originalScheduleDates : selectedDates) : [])
                                    : selectedDates
                            )
                            .environmentObject(scheduleStore)
                            .environmentObject(assessmentStore)
                            .id(calendarViewId)

                            // 使用已存在的 CalendarActionButton
                            CalendarActionButton(
                                isEditing: true,
                                hasChanges: hasChanges,
                                buttonText: selectedTab == .assessment ? (isEditingAssessmentSchedule ? "更新評估安排" : "儲存評估安排") : (isEditingExistingSchedule ? "更新訓練安排" : "儲存訓練安排"),
                                action: {
                                    if selectedTab == .training {
                                        if isEditingExistingSchedule {
                                            saveEditedSchedule()
                                        } else {
                                            handleTrainingScheduleSave()
                                        }
                                    } else {
                                        handleAssessmentScheduleSave()
                                    }
                                }
                            )
                        }
                        .frame(width: 430)
                        .gridCellColumns(2)
                    }
                    .frame(height: fixedHeight)
                }
                .padding(.horizontal, 30)
            }
            .padding(.vertical, 0)
        }
        .alert("重複的訓練安排", isPresented: $showingDuplicateAlert) {
            Button("確定", role: .cancel) { }
        } message: {
            Text("選擇的日期已經安排了相同的訓練菜單")
        }
        .alert("日期重疊確認", isPresented: $showingOverlapAlert) {
            Button("取消", role: .cancel) {
                // 用戶選擇取消，不做任何更改
                overlappingSchedules = []
                pendingSchedule = nil
            }
            Button("確定覆蓋", role: .destructive) {
                // 用戶確認覆蓋，處理重疊的訓練安排
                handleOverlapConfirmation()
            }
        } message: {
            let menuNames = overlappingSchedules.compactMap { schedule in
                trainingMenuStore.getMenu(by: schedule.menuId)?.title
            }.joined(separator: "、")
            
            Text("選擇的日期涵蓋舊的訓練安排（\(menuNames)），確定要覆蓋嗎？")
        }
        .alert("編輯訓練安排", isPresented: $showingEditScheduleOptions) {
            Button("取消", role: .cancel) {
                cancelEditingExistingSchedule()
            }
            Button("編輯日期", role: .none) {
                // 保持編輯狀態，讓用戶可以修改日期
                showingEditScheduleOptions = false
            }
            Button("刪除安排", role: .destructive) {
                showingDeleteScheduleAlert = true
            }
        } message: {
            if let schedule = scheduleBeingEdited,
               let menu = trainingMenuStore.getMenu(by: schedule.menuId) {
                Text("您正在編輯「\(menu.title)」的訓練安排。")
            } else {
                Text("您正在編輯訓練安排。")
            }
        }
        .alert("確認刪除", isPresented: $showingDeleteScheduleAlert) {
            Button("取消", role: .cancel) {
                showingDeleteScheduleAlert = false
            }
            Button("刪除", role: .destructive) {
                deleteSelectedSchedule()
            }
        } message: {
            if let schedule = scheduleBeingEdited,
               let menu = trainingMenuStore.getMenu(by: schedule.menuId) {
                Text("確定要刪除「\(menu.title)」的訓練安排嗎？此操作無法撤銷。")
            } else {
                Text("確定要刪除此訓練安排嗎？此操作無法撤銷。")
            }
        }
        .onAppear {
            // 只有在非編輯模式下才重置狀態
            if !isEditingExistingSchedule {
                resetState()  // 在視圖出現時重置狀態
            }
            
            // 如果有要編輯的排程ID，設置編輯模式
            if let scheduleId = scheduleIdToEdit {
                setEditMode(for: scheduleId)
                // 清空scheduleIdToEdit，避免重複設置
                scheduleIdToEdit = nil
            }
            
            // 添加通知觀察者
            NotificationCenter.default.addObserver(
                forName: .assessmentsDidUpdate,
                object: nil,
                queue: .main
            ) { _ in
                if let updatedPatient = PatientStore.shared.patients.first(where: { $0.id == self.patient.id }) {
                    self.patient = updatedPatient
                    self.calendarViewId = UUID() // Force CalendarCard to refresh
                }
            }
            
            // 延遲重置標誌，確保 CalendarCard 已經完成初始化
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isEnteringEditModeFromExternal = false
            }
        }
        .onChange(of: selectedTab) { newTab in
            // When switching tabs, we need to handle state transitions properly
            if newTab == .training {
                // If switching to training tab:
                // 1. Clear assessment selection and state
                selectedAssessment = nil
                isEditingAssessmentSchedule = false
                
                // 2. Clear dates selected for assessments
                if !isEditingExistingSchedule {
                    selectedDates.removeAll()
                }
                
                // Note: The training menu state (selectedMenu, isEditingExistingSchedule)
                // is preserved if it was set before
            } else if newTab == .assessment {
                // If switching to assessment tab:
                // 1. Clear training menu selection and state
                if isEditingExistingSchedule {
                    isEditingExistingSchedule = false
                    scheduleBeingEdited = nil
                    originalScheduleDates.removeAll()
                }
                
                // 2. Clear selected dates if not in assessment editing mode
                if !isEditingAssessmentSchedule {
                    selectedDates.removeAll()
                }
                
                // 3. Ensure we have fresh patient data for assessments
                if let updatedPatient = PatientStore.shared.patients.first(where: { $0.id == patient.id }) {
                    patient = updatedPatient
                }
            }
            
            // Always refresh the calendar when switching tabs
            calendarViewId = UUID()
        }
        .alert("匯出失敗", isPresented: $showingExportError) {
            Button("確定", role: .cancel) {}
        } message: {
            Text(exportErrorMessage)
        }
    }
    
    private func handleTrainingScheduleSave() {
        guard let menu = selectedMenu, !selectedDates.isEmpty else { return }
        
        // 檢查是否有日期重疊的訓練安排
        let existingSchedules = scheduleStore.getSchedulesForPatient(patient.id)
        
        // 找出所有與選擇日期重疊的訓練安排（排除當前選擇的菜單）
        let overlappingSchedules = existingSchedules.filter { schedule in
            // 如果是同一個菜單，不視為重疊
            if schedule.menuId == menu.id {
                return false
            }
            
            // 檢查是否有日期重疊
            return selectedDates.contains { selectedDate in
                schedule.dates.contains { scheduleDate in
                    calendar.isDate(selectedDate, inSameDayAs: scheduleDate)
                }
            }
        }
        
        if !overlappingSchedules.isEmpty {
            // 有重疊的訓練安排，顯示確認對話框
            self.overlappingSchedules = overlappingSchedules
            
            // 創建待處理的訓練安排
            let newSchedule = TrainingSchedule(
                id: UUID(),
                menuId: menu.id,
                patientId: patient.id,
                selectedDates: selectedDates,
                timeSlots: menu.timeSlots
            )
            self.pendingSchedule = newSchedule
            
            // 顯示確認對話框
            showingOverlapAlert = true
            return
        }
        
        // 沒有重疊，直接處理現有的相同菜單安排
        handleExistingMenuSchedule(menu: menu)
    }
    
    // 修改：處理現有的相同菜單安排
    private func handleExistingMenuSchedule(menu: TrainingMenu) {
        // 檢查是否有相同菜單的訓練安排
        let existingSchedules = scheduleStore.getSchedulesForPatient(patient.id)
            .filter { schedule in
                schedule.menuId == menu.id
            }
        
        var finalSchedule: TrainingSchedule
        
        // 如果沒有找到相同菜單的訓練安排，則建立新的訓練安排
        if existingSchedules.isEmpty {
            finalSchedule = TrainingSchedule(
                id: UUID(),
                menuId: menu.id,
                patientId: patient.id,
                selectedDates: selectedDates, // Use current UI selection
                timeSlots: menu.timeSlots
            )
            scheduleStore.addSchedule(finalSchedule)
        } else {
            // 如果找到相同菜單的訓練安排，直接合併它們
            var allExistingDates = Set<Date>()
            for schedule in existingSchedules {
                allExistingDates = allExistingDates.union(schedule.dates)
            }
            let combinedDates = allExistingDates.union(selectedDates) // Add current UI selection
            
            let firstScheduleId = existingSchedules.first?.id ?? UUID()
            for schedule in existingSchedules {
                scheduleStore.removeSchedule(schedule)
            }
            
            finalSchedule = TrainingSchedule(
                id: firstScheduleId,
                menuId: menu.id,
                patientId: patient.id,
                selectedDates: combinedDates,
                timeSlots: menu.timeSlots
            )
            scheduleStore.addSchedule(finalSchedule)
        }
        
        scheduleStore.saveSchedules()
        scheduleStore.reloadSchedules()
        
        // Update state for continued editing, instead of resetState()
        self.selectedMenu = menu // Keep the menu selected
        self.selectedDates = finalSchedule.dates // Update selectedDates to reflect the saved schedule
        self.isEditingExistingSchedule = true
        self.scheduleBeingEdited = finalSchedule
        self.originalScheduleDates = finalSchedule.dates // Original dates are now the saved dates
        
        if let updatedPatient = PatientStore.shared.patients.first(where: { $0.id == self.patient.id }) {
            self.patient = updatedPatient // Reload patient data
        }
        self.calendarViewId = UUID() // Refresh CalendarCard
        
        showingEditScheduleOptions = false // Ensure this is closed if it was open
    }
    
    // 修改：處理重疊訓練安排的確認
    private func handleOverlapConfirmation() {
        guard let pendingSchedule = pendingSchedule else { return }
        
        // 移除所有重疊的訓練安排中的重疊日期
        for overlappingSchedule in overlappingSchedules {
            let overlappingDates = overlappingSchedule.dates.filter { scheduleDate in
                pendingSchedule.dates.contains { selectedDate in
                    calendar.isDate(selectedDate, inSameDayAs: scheduleDate)
                }
            }
            let remainingDates = overlappingSchedule.dates.filter { date in
                !overlappingDates.contains { calendar.isDate($0, inSameDayAs: date) }
            }
            if remainingDates.isEmpty {
                scheduleStore.removeSchedule(overlappingSchedule)
            } else {
                let updatedSchedule = TrainingSchedule(
                    id: overlappingSchedule.id,
                    menuId: overlappingSchedule.menuId,
                    patientId: overlappingSchedule.patientId,
                    selectedDates: Set(remainingDates),
                    timeSlots: overlappingSchedule.timeSlots
                )
                scheduleStore.removeSchedule(overlappingSchedule)
                scheduleStore.addSchedule(updatedSchedule)
            }
        }
        
        // After handling overlaps, proceed to effectively save the pendingSchedule
        // by calling a modified version of handleExistingMenuSchedule or by direct save logic here.
        
        // This logic assumes pendingSchedule.menuId is valid and menu is self.selectedMenu
        guard let currentSelectedMenu = self.selectedMenu, currentSelectedMenu.id == pendingSchedule.menuId else {
            // This shouldn't happen if pendingSchedule was created from selectedMenu
            resetState() // Fallback to reset if something is wrong
            return
        }
        
        // Now, merge pendingSchedule with any other existing schedules for the SAME menu
        let otherSchedulesForSameMenu = scheduleStore.getSchedulesForPatient(patient.id)
            .filter { $0.menuId == pendingSchedule.menuId && $0.id != pendingSchedule.id }

        var finalDatesForPending = pendingSchedule.dates
        var finalIdForPending = pendingSchedule.id
        
        if !otherSchedulesForSameMenu.isEmpty {
            for schedule in otherSchedulesForSameMenu {
                finalDatesForPending.formUnion(schedule.dates)
                // Potentially take the ID of the first existing one if preferred
                if finalIdForPending == pendingSchedule.id { // If still using the new UUID from pending
                    finalIdForPending = schedule.id
                }
                scheduleStore.removeSchedule(schedule)
            }
        }
        
        let finalScheduleToSave = TrainingSchedule(
            id: finalIdForPending, // Use potentially existing ID or new one
            menuId: pendingSchedule.menuId,
            patientId: pendingSchedule.patientId,
            selectedDates: finalDatesForPending,
            timeSlots: pendingSchedule.timeSlots
        )
        
        scheduleStore.addSchedule(finalScheduleToSave)
        scheduleStore.saveSchedules()
        scheduleStore.reloadSchedules()
        
        // Update state for continued editing
        self.selectedMenu = currentSelectedMenu // Keep current menu selected
        self.selectedDates = finalScheduleToSave.dates // Update selectedDates to reflect the saved schedule
        self.isEditingExistingSchedule = true
        self.scheduleBeingEdited = finalScheduleToSave
        self.originalScheduleDates = finalScheduleToSave.dates
        
        if let updatedPatient = PatientStore.shared.patients.first(where: { $0.id == self.patient.id }) {
            self.patient = updatedPatient
        }
        self.calendarViewId = UUID()
        
        // Clear pending states
        self.pendingSchedule = nil
        self.overlappingSchedules = []
        self.showingOverlapAlert = false
        self.showingEditScheduleOptions = false
    }
    
    private func handleAssessmentScheduleSave() {
        guard let assessment = selectedAssessment, !selectedDates.isEmpty else { return }
        
        // Step 1: Save the current UI selection as the new schedule
        let newScheduledDates = Set(self.selectedDates) // Make a copy
        
        // Step 2: Update assessment in the store
        var updatedAssessment = assessment
        
        // IMPORTANT CHANGE: Replace the scheduled dates with the current selection
        // instead of merging. This enables removing dates by deselecting them.
        updatedAssessment.scheduledDates = newScheduledDates
        
        AssessmentStore.shared.updateAssessment(updatedAssessment, for: patient.id)
        
        // Step 3: Explicitly reload the patient data for THIS view
        if let freshlyUpdatedPatient = PatientStore.shared.patients.first(where: { $0.id == self.patient.id }) {
            self.patient = freshlyUpdatedPatient
            
            // Also update our selectedAssessment to point to the freshly loaded assessment
            if let updatedAssessment = freshlyUpdatedPatient.assessments.first(where: { $0.id == assessment.id }) {
                self.selectedAssessment = updatedAssessment
            }
        } else {
            print("Error: Could not reload patient after assessment save.")
        }
        
        // Step 4: UX改進 - 儲存後取消選擇評估，讓用戶看到已儲存的安排
        self.selectedAssessment = nil
        self.selectedDates.removeAll()
        self.isEditingAssessmentSchedule = false
        
        // Step 5: Force CalendarCard refresh to show updated dots in mixed mode
        self.calendarViewId = UUID()
            
        // Step 6: Post notification for other views
        NotificationCenter.default.post(name: .assessmentsDidUpdate, object: nil)
    }
    
    private func handleDeleteAssessmentForCurrentMonth(_ assessment: Assessment, monthContext: Date) {
        var modifiedAssessment = assessment // Create a mutable copy

        let calendar = Calendar.current
        let yearMonthToClear = calendar.dateComponents([.year, .month], from: monthContext)

        // Filter out scheduledDates that are in the specified month
        modifiedAssessment.scheduledDates = modifiedAssessment.scheduledDates.filter { dateInSchedule in
            let dateComponents = calendar.dateComponents([.year, .month], from: dateInSchedule)
            return !(dateComponents.year == yearMonthToClear.year && dateComponents.month == yearMonthToClear.month)
        }

        AssessmentStore.shared.updateAssessment(modifiedAssessment, for: self.patient.id)
        // The .assessmentsDidUpdate notification observer in onAppear should handle patient refresh
        // and calendarViewId update, ensuring UI consistency.
    }
}

// 儲存按鈕
private struct SaveButton: View {
    let hasChanges: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack {
                Image(systemName: "square.and.arrow.down")
                    .font(.system(size: 24))
                Text("儲存訓練安排")
                    .font(.system(size: 16))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(hasChanges ? Color.orange : Color.gray)
            .cornerRadius(12)
        }
        .disabled(!hasChanges)
    }
}

// 菜單選擇卡片
private struct MenuSelectionCard: View {
    @State private var menuStore = TrainingMenuStore.shared
    @Binding var selectedMenu: TrainingMenu?
    @State private var showingDeleteAlert = false
    @State private var menuToDelete: TrainingMenu?
    let patient: Patient
    let onCalendarUpdate: () -> Void  // 新增回調函數用於更新月曆
    
    var body: some View {
        ZStack {
            // 背景點擊區域
            Color.white
                .contentShape(Rectangle())
                .onTapGesture {
                    selectedMenu = nil
                }
            
            VStack(alignment: .leading, spacing: 20) {
                // 專屬菜單
                VStack(alignment: .leading, spacing: 15) {
                    Text("專屬菜單")
                        .font(.headline)
                    if menuStore.getExclusiveMenus(for: patient.id).isEmpty {
                        Text("尚未加入")
                            .foregroundColor(.gray)
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    } else {
                        List {
                            ForEach(menuStore.getExclusiveMenus(for: patient.id)) { menu in
                                MenuListItem(
                                    menu: menu,
                                    isSelected: selectedMenu?.id == menu.id,
                                    onSelect: {
                                        withAnimation {
                                            if selectedMenu?.id == menu.id {
                                                selectedMenu = nil
                                            } else {
                                                selectedMenu = menu
                                            }
                                            // 強制更新月曆以反映菜單選擇變化
                                            onCalendarUpdate()
                                        }
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
                }
                
                Divider()
                
                // 共通菜單
                VStack(alignment: .leading, spacing: 15) {
                    Text("共通菜單")
                        .font(.headline)
                    if menuStore.getCommonMenus().isEmpty {
                        Text("尚未加入")
                            .foregroundColor(.gray)
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    } else {
                        List {
                            ForEach(menuStore.getCommonMenus()) { menu in
                                MenuListItem(
                                    menu: menu,
                                    isSelected: selectedMenu?.id == menu.id,
                                    onSelect: {
                                        withAnimation {
                                            if selectedMenu?.id == menu.id {
                                                selectedMenu = nil
                                            } else {
                                                selectedMenu = menu
                                            }
                                            // 強制更新月曆以反映菜單選擇變化
                                            onCalendarUpdate()
                                        }
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
                }
            }
            .padding(20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.white)
        .cornerRadius(12)
        .alert("確認刪除", isPresented: $showingDeleteAlert) {
            Button("取消", role: .cancel) {}
            Button("刪除", role: .destructive) {
                if let menu = menuToDelete {
                    menuStore.deleteMenu(menu)
                    if selectedMenu?.id == menu.id {
                        selectedMenu = nil
                    }
                }
            }
        } message: {
            if let menu = menuToDelete {
                Text("確定要刪除「\(menu.title)」嗎？")
            }
        }
    }
}

// 菜單列表項目
private struct MenuListItem: View {
    let menu: TrainingMenu
    let isSelected: Bool
    let onSelect: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        HStack {
            Text(menu.title)
                .foregroundColor(AppColors.text)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
            
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

// 菜單編輯卡片
private struct MenuEditCard: View {
    let patient: Patient
    @Binding var menuTitle: String
    let timeSlots: [String]
    let timeColors: [Color]
    @Binding var selectedMenu: TrainingMenu?
    @State private var showingEditSheet = false
    let userModel: UserModel
    let scheduleStore: TrainingScheduleStore
    let menuStore: TrainingMenuStore
    let onMenuUpdated: () -> Void  // 新增回調函數
    
    var body: some View {
        VStack(spacing: 0) {
            // 上半部分（標題和時段標籤）
            VStack(alignment: .leading, spacing: 8) {
                // 專屬/共通菜單標籤
                Text(selectedMenu?.isExclusive ?? true ? "專屬菜單" : "共通菜單")
                    .font(.system(size: 14))
                    .foregroundColor(selectedMenu != nil ? .gray : .gray.opacity(0.6))
                
                VStack(alignment: .leading, spacing: 16) {
                    // 菜單名稱和顏色
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 8) {
                            Circle()
                                .fill(selectedMenu?.color ?? Color.gray.opacity(0.3))
                                .frame(width: 20, height: 20)
                                .overlay(
                                    Image(systemName: "paintbrush.fill")
                                        .font(.system(size: 12))
                                        .foregroundColor(selectedMenu != nil ? .white : .gray)
                                )
                            Text(selectedMenu?.title ?? menuTitle)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(selectedMenu != nil ? AppColors.text : .gray)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            Spacer()
                            
                            // 編輯按鈕
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
                        
                        // 時段標籤（只顯示，不可編輯）
                        HStack(spacing: 8) {
                            ForEach(Array(zip(timeSlots.indices, timeSlots)), id: \.0) { index, slot in
                                let isSelected = selectedMenu?.timeSlots.contains(slot) ?? false
                                Text(slot)
                                    .font(.system(size: 14))
                                    .foregroundColor(isSelected ? .white : .gray)
                                    .frame(width: 60, height: 32)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(isSelected ? timeColors[index] : Color.gray.opacity(0.1))
                                    )
                            }
                        }
                    }
                }
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.white)
            
            Divider()
            
            // 下半部分（菜單內容）
            VStack(alignment: .leading) {
                HStack {
                    Text("菜單內容")
                        .font(.headline)
                    Spacer()
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
                
                if let menu = selectedMenu {
                    ScrollView {
                        VStack(spacing: 2) {
                            ForEach(menu.exercises) { exercise in
                                CompactExerciseListItem(parameters: exercise)
                            }
                        }
                        .padding(.vertical, 2)
                    }
                } else {
                    Spacer()
                    Text("尚未加入")
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity, alignment: .center)
                    Spacer()
                }
            }
            .padding(20)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.white)
        }
        .cornerRadius(12)
        .sheet(isPresented: $showingEditSheet) {
            TrainingMenuEditSheet(menu: selectedMenu) { updatedMenu in
                if var menu = selectedMenu {
                    menu.title = updatedMenu.title
                    menu.color = updatedMenu.color
                    menu.isExclusive = updatedMenu.isExclusive
                    menu.timeSlots = updatedMenu.timeSlots
                    selectedMenu = menu
                    TrainingMenuStore.shared.saveMenu(menu)
                    // 調用回調函數通知月曆更新
                    onMenuUpdated()
                }
            }
        }
    }
}

// 菜單編輯表單
private struct TrainingMenuEditSheet: View {
    @Environment(\.dismiss) private var dismiss
    let menu: TrainingMenu?
    let onSave: (TrainingMenu) -> Void
    
    @State private var title: String
    @State private var isExclusive: Bool
    @State private var selectedColor: Color
    @State private var selectedTimeSlots: Set<String>
    
    private let timeSlots = ["早", "中", "下", "晚"]
    private let timeColors: [Color] = [.morning, .noon, .afternoon, .night]
    
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
    
    init(menu: TrainingMenu?, onSave: @escaping (TrainingMenu) -> Void) {
        self.menu = menu
        self.onSave = onSave
        _title = State(initialValue: menu?.title ?? "")
        _isExclusive = State(initialValue: menu?.isExclusive ?? true)
        _selectedColor = State(initialValue: menu?.color ?? .pink.opacity(0.3))
        _selectedTimeSlots = State(initialValue: Set(menu?.timeSlots ?? []))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 標題列
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
            
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // 訓練菜單名稱
                    VStack(alignment: .leading, spacing: 8) {
                        Text("訓練菜單名稱")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.gray)
                        
                        TextField("", text: $title)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .font(.system(size: 16))
                    }
                    .padding(.horizontal, 24)
                    
                    // 選擇菜單標示顏色
                    VStack(alignment: .leading, spacing: 12) {
                        Text("選擇菜單標示顏色")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.gray)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 5), spacing: 12) {
                            ForEach(colorOptions, id: \.self) { color in
                                Circle()
                                    .fill(color)
                                    .frame(width: 40, height: 40)
                                    .overlay(
                                        Circle()
                                            .strokeBorder(color == selectedColor ? Color.blue : Color.gray.opacity(0.3), lineWidth: 2)
                                    )
                                    .overlay(
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.white)
                                            .opacity(color == selectedColor ? 1 : 0)
                                    )
                                    .onTapGesture {
                                        selectedColor = color
                                    }
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    
                    // 重複訓練
                    VStack(alignment: .leading, spacing: 12) {
                        Text("重複訓練")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.gray)
                        
                        HStack(spacing: 8) {
                            ForEach(Array(zip(timeSlots.indices, timeSlots)), id: \.0) { index, slot in
                                let isSelected = selectedTimeSlots.contains(slot)
                                Button(action: {
                                    if isSelected {
                                        selectedTimeSlots.remove(slot)
                                    } else {
                                        selectedTimeSlots.insert(slot)
                                    }
                                }) {
                                    Text(slot)
                                        .font(.system(size: 14))
                                        .foregroundColor(isSelected ? .white : .gray)
                                        .frame(width: 60, height: 32)
                                        .background(
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(isSelected ? timeColors[index] : Color.gray.opacity(0.1))
                                        )
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    
                    // 菜單類型
                    VStack(alignment: .leading, spacing: 12) {
                        Text("菜單類型")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.gray)
                        
                        HStack(spacing: 12) {
                            Button(action: { isExclusive = true }) {
                                HStack(spacing: 8) {
                                    Image(systemName: isExclusive ? "checkmark.circle.fill" : "circle")
                                        .foregroundColor(isExclusive ? .blue : .gray)
                                    Text("專屬菜單")
                                        .foregroundColor(isExclusive ? .blue : .gray)
                                }
                            }
                            
                            Button(action: { isExclusive = false }) {
                                HStack(spacing: 8) {
                                    Image(systemName: !isExclusive ? "checkmark.circle.fill" : "circle")
                                        .foregroundColor(!isExclusive ? .blue : .gray)
                                    Text("共通菜單")
                                        .foregroundColor(!isExclusive ? .blue : .gray)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                }
                .padding(.vertical, 24)
            }
            
            // 底部按鈕
            HStack(spacing: 16) {
                Button(action: {
                    dismiss()
                }) {
                    Text("取消編輯")
                        .font(.system(size: 16))
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                }
                
                Button(action: {
                    let updatedMenu = TrainingMenu(
                        id: menu?.id ?? UUID(),
                        title: title,
                        isExclusive: isExclusive,
                        color: selectedColor,
                        exercises: menu?.exercises ?? [],
                        timeSlots: selectedTimeSlots  // 直接使用 Set<String>
                    )
                    onSave(updatedMenu)
                    dismiss()
                }) {
                    Text("儲存編輯")
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(Color.orange)
                        .cornerRadius(8)
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background(Color.white)
            .shadow(color: .black.opacity(0.05), radius: 8, y: -4)
        }
        #if canImport(UIKit)
        .background(Color(UIColor.systemGroupedBackground))
        #else
        .background(Color.gray.opacity(0.1)) // Generic fallback background
        #endif
    }
}

// 時段選擇按鈕
private struct TimeSlotButton: View {
    let title: String
    let isSelected: Bool
    let color: Color
    let isEnabled: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14))
                .foregroundColor(isEnabled ? (isSelected ? .white : .gray) : .gray.opacity(0.5))
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isEnabled ? (isSelected ? color : Color.gray.opacity(0.1)) : Color.gray.opacity(0.05))
                )
        }
        .disabled(!isEnabled)
    }
}

struct EditTrainingCalendarView_Previews: PreviewProvider {
    static var previews: some View {
        // 使用預設的預覽 store
        let patientStore = PatientStore.preview
        let scheduleStore = TrainingScheduleStore.preview
        let menuStore = TrainingMenuStore.preview
        let userModel = UserModel.preview
        
        
        EditTrainingCalendarView(patient: patientStore.patients[0])
            .environmentObject(scheduleStore)
            .environmentObject(menuStore)
            .environmentObject(userModel)
            .environmentObject(patientStore)
    }
}
 */

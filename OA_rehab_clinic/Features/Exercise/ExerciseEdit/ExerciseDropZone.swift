import SwiftUI
import Foundation
#if canImport(UIKit)
import UIKit
#endif


// MARK: - Exercise Drop Zone
public struct ExerciseDropZone: View {
    @Environment(\.dismiss) private var dismiss: DismissAction
    @Binding var exerciseParameters: [ExerciseParameters]
    @State private var menuTitle: String
    @State private var isExclusive: Bool
    @State private var selectedColor: Color
    @State private var showColorPicker: Bool = false
    @Binding var showingParameterCard: Bool
    @Binding var editingExercise: ExerciseParameters?
    @Binding var selectedExerciseForParameter: ExerciseModule.Exercise?
    @State private var showingLimitAlert = false
    @State private var showingDuplicateAlert = false

    @State private var isTargeted = false
    @State private var menuStore = TrainingMenuStore.shared
    @Binding var selectedMenu: TrainingMenu?
    private let existingMenuId: UUID?
    private let patient: Patient
    private let hideExclusiveToggle: Bool  // 新增屬性
    
    // 拖曳相關狀態 - 完全重構
    @State private var draggedItem: ExerciseParameters?
    @State private var draggedItemIndex: Int?
    @State private var isDragging = false
    @State private var dragOperationCount = 0
    
    // 生成不重複的預設菜單名稱
    private static func generateUniqueMenuTitle(for patient: Patient) -> String {
        let menuStore = TrainingMenuStore.shared
        let baseTitle = "新增菜單"
        let chineseNumbers = ["一", "二", "三", "四", "五", "六", "七", "八", "九", "十"]
        
        // 只檢查當前病患的專屬菜單名稱
        var usedNumbers = Set<Int>()
        
        // 獲取當前病患的專屬菜單
        let patientMenus = menuStore.menus.filter { menu in
            menu.patientId == patient.id && menu.title.starts(with: baseTitle)
        }
        
        for menu in patientMenus {
            if let startIndex = menu.title.firstIndex(of: "("),
               let endIndex = menu.title.firstIndex(of: ")"),
               startIndex < endIndex {
                let start = menu.title.index(after: startIndex)
                let numberStr = String(menu.title[start..<endIndex]).trimmingCharacters(in: .whitespaces)
                
                if let index = chineseNumbers.firstIndex(of: numberStr) {
                    usedNumbers.insert(index + 1)
                } else if let number = Int(numberStr) {
                    usedNumbers.insert(number)
                }
            }
        }
        
        // 如果當前病患沒有任何菜單，從一開始
        if usedNumbers.isEmpty {
            return "\(baseTitle) (一)"
        }
        
        // 找到第一個未使用的數字
        for i in 1...chineseNumbers.count {
            if !usedNumbers.contains(i) {
                return "\(baseTitle) (\(chineseNumbers[i-1]))"
            }
        }
        
        // 如果中文數字都用完了，使用阿拉伯數字
        var counter = chineseNumbers.count + 1
        while usedNumbers.contains(counter) {
            counter += 1
        }
        return "\(baseTitle) (\(counter))"
    }
    
    // 改進 hasChanges 計算邏輯
    private var hasChanges: Bool {
        if let menuId = existingMenuId,
           let existingMenu = menuStore.menus.first(where: { $0.id == menuId }) {
            // 比較所有可能變更的屬性
            let titleChanged = existingMenu.title.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines) != menuTitle.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            let exclusiveChanged = existingMenu.isExclusive != isExclusive
            let colorChanged = existingMenu.color != selectedColor
            let exercisesChanged = existingMenu.exercises != exerciseParameters
            
            return titleChanged || exclusiveChanged || colorChanged || exercisesChanged
        }
        // 新菜單：只有當有運動項目或標題不是預設值時才視為有更改
        let hasNonDefaultTitle = !menuTitle.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).isEmpty && 
                                !menuTitle.contains("新增菜單")
        return !exerciseParameters.isEmpty || hasNonDefaultTitle
    }
    
    private func checkDuplicateTitle(_ title: String) -> Bool {
        // 檢查是否有相同名稱的菜單（排除當前正在編輯的菜單）
        return menuStore.menus.contains { existingMenu in
            // 只檢查同一個病患的菜單
            let isSamePatient = existingMenu.patientId == patient.id
            
            // 如果是編輯現有菜單，排除自己
            if let currentMenuId = existingMenuId {
                return existingMenu.title == title && 
                       existingMenu.id != currentMenuId && 
                       isSamePatient
            }
            // 如果是新增菜單，只檢查同一個病患的菜單名稱
            return existingMenu.title == title && isSamePatient
        }
    }
    
    init(
        exerciseParameters: Binding<[ExerciseParameters]>,
        showingParameterCard: Binding<Bool>,
        editingExercise: Binding<ExerciseParameters?>,
        selectedExerciseForParameter: Binding<ExerciseModule.Exercise?>,
        menuTitle: String? = nil,
        isExclusive: Bool = true,
        selectedColor: Color = ExerciseConstants.Colors.menuColors[0], // 預設使用第一個顏色
        existingMenu: TrainingMenu? = nil,
        selectedMenu: Binding<TrainingMenu?>,
        patient: Patient,
        hideExclusiveToggle: Bool = false  // 新增參數控制是否隱藏適用對象選擇
    ) {
        self._exerciseParameters = exerciseParameters
        self._showingParameterCard = showingParameterCard
        self._editingExercise = editingExercise
        self._selectedExerciseForParameter = selectedExerciseForParameter
        // 如果是編輯現有菜單，使用現有菜單的標題
        self._menuTitle = State(initialValue: existingMenu?.title ?? menuTitle ?? Self.generateUniqueMenuTitle(for: patient))
        self._isExclusive = State(initialValue: existingMenu?.isExclusive ?? isExclusive)
        // 預設使用第一個顏色，現有菜單保持原有顏色
        self._selectedColor = State(initialValue: existingMenu?.color ?? ExerciseConstants.Colors.menuColors[0])
        self.existingMenuId = existingMenu?.id
        self._selectedMenu = selectedMenu
        self.patient = patient
        self.hideExclusiveToggle = hideExclusiveToggle
    }
    
    // 處理拖曳項目的移動 - 完全重寫並加強錯誤處理
    private func moveItem(fromIndex: Int, toIndex: Int) {
        // 基本邊界檢查
        guard fromIndex >= 0, fromIndex < exerciseParameters.count,
              !exerciseParameters.isEmpty else { 
            resetDragState()
            return 
        }
        
        // 計算有效的目標索引
        let validToIndex: Int
        if toIndex < 0 {
            validToIndex = 0
        } else if toIndex > exerciseParameters.count {
            validToIndex = exerciseParameters.count
        } else {
            validToIndex = toIndex
        }
        
        // 如果移動到同一位置，不做任何事
        if fromIndex == validToIndex {
            resetDragState()
            return
        }
        
        // 在主線程上執行移動操作
        DispatchQueue.main.async {
            // 再次檢查邊界，防止競態條件
            guard fromIndex >= 0, fromIndex < self.exerciseParameters.count,
                  !self.exerciseParameters.isEmpty else {
                self.resetDragState()
                return
            }
            
            // 執行移動
            let movedItem = self.exerciseParameters[fromIndex]
            self.exerciseParameters.remove(at: fromIndex)
        
            // 重新計算插入位置（因為移除了一個元素）
            var finalInsertIndex = validToIndex
            if validToIndex > fromIndex {
                finalInsertIndex = validToIndex - 1
            }
            finalInsertIndex = min(finalInsertIndex, self.exerciseParameters.count)
            
            self.exerciseParameters.insert(movedItem, at: finalInsertIndex)
        
            // 重置拖曳狀態
            self.resetDragState()
            
            // 增加操作計數
            self.dragOperationCount += 1
        }
    }
    
    // 統一的拖曳狀態重置函數
    private func resetDragState() {
        DispatchQueue.main.async {
        withAnimation(.easeOut(duration: 0.2)) {
            self.isDragging = false
            self.draggedItem = nil
            self.draggedItemIndex = nil
        }
        }
    }
    
    // 處理開始拖曳 - 完全重寫並加強錯誤處理
    private func handleDragStarted(exercise: ExerciseParameters, index: Int) -> NSItemProvider {
        // 邊界檢查
        guard index >= 0, index < exerciseParameters.count,
              exerciseParameters[index].id == exercise.id else {
            // 如果索引不正確，返回空的 provider
            return NSItemProvider()
        }
        
        // 在主線程上設置拖曳狀態
        DispatchQueue.main.async {
        withAnimation(.easeIn(duration: 0.2)) {
            self.draggedItem = exercise
            self.draggedItemIndex = index
            self.isDragging = true
            }
        }
        
        // 創建一個唯一的識別符
        let dragID = "drag-\(exercise.id.uuidString)-\(index)"
        let provider = NSItemProvider(object: dragID as NSString)
        
        return provider
    }
    

    
    // 處理拖曳取消 - 使用統一的重置函數
    private func handleDragCancelled() {
        resetDragState()
    }
    
    // MARK: - View Builders
    
    // 1. 頂部編輯區域
    @ViewBuilder
    private func headerSection() -> some View {
        VStack(spacing: 16) {
            HStack(alignment: .center, spacing: 40) {
                // 菜單名稱輸入框
                HStack(spacing: 12) {
                    Text("訓練菜單名稱")
                        .lineLimit(1)
                        .fixedSize()
                    TextField("", text: $menuTitle)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 200)
                }
                .frame(minWidth: 200, alignment: .leading)
                .padding(.leading, 20)
                
                // 適用對象選擇 - 條件性顯示
                if !hideExclusiveToggle {
                HStack(spacing: 8) {
                    Text("適用對象")
                        .foregroundColor(.gray)
                    Toggle("", isOn: $isExclusive)
                        .labelsHidden()
                    Text(isExclusive ? "專屬" : "通用")
                        .foregroundColor(isExclusive ? .blue : .gray)
                    }
                }
                
                // 顏色選擇
                HStack(spacing: 8) {
                    Text("菜單代表顏色")
                        .foregroundColor(.gray)
                    Button(action: {
                        showColorPicker.toggle()
                    }) {
                        Circle()
                            .fill(selectedColor)
                            .frame(width: 24, height: 24)
                            .overlay(
                                Circle()
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                    }
                    .popover(isPresented: $showColorPicker, arrowEdge: .bottom) {
                        colorPickerView()
                    }
                }
                Spacer()
            }
        }
        .padding(.vertical)
        .background(ExerciseConstants.Colors.cardBackground)
    }
    
    // 2. 顏色選擇器彈出視圖
    @ViewBuilder
    private func colorPickerView() -> some View {
        VStack(spacing: 12) {
            Text("選擇菜單代表顏色")
                .font(.system(size: 14))
                .foregroundColor(.gray)
                .padding(.top, 8)
            
            LazyVGrid(columns: [
                GridItem(.adaptive(minimum: 40))
            ], spacing: 12) {
                ForEach(ExerciseConstants.Colors.menuColors, id: \.self) { color in
                    Circle()
                        .fill(color)
                        .frame(width: 24, height: 24)
                        .overlay(
                            Circle()
                                .stroke(color == selectedColor ? Color.blue : Color.clear, lineWidth: 4)
                        )
                        .onTapGesture {
                            selectedColor = color
                            showColorPicker = false
                        }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .frame(width: 280, height: 150)
        .background(Color.white)
    }
    
    // 3. 空的拖放區域
    @ViewBuilder
    private func emptyDropZoneView() -> some View {
        VStack {
            Image(systemName: "arrow.down.circle")
                .font(.system(size: 40))
                .foregroundColor(.gray)
            Text("尚無訓練按排")
                .font(.title3)
                .foregroundColor(.gray)
            Text("從左側選擇訓練項目")
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(isTargeted ? ExerciseConstants.Colors.dropZoneActive : ExerciseConstants.Colors.dropZoneInactive)
        .animation(.easeInOut, value: isTargeted)
    }
    
    // 4.1 單個運動卡片視圖 - 完全重寫
    @ViewBuilder
    private func exerciseCardView(exercise: ExerciseParameters, index: Int, geometry: GeometryProxy) -> some View {
        // 計算狀態 - 使用更嚴格的條件
        let isDraggingThisItem = isDragging && draggedItem?.id == exercise.id
        let isDropTarget = isDragging && draggedItem != nil && draggedItem?.id != exercise.id
        
        ExerciseParameterListItem(
            parameters: exercise,
            isDragging: isDraggingThisItem,
            isDropTarget: isDropTarget,
            onEdit: {
                editingExercise = exercise
                selectedExerciseForParameter = exercise.exercise
                showingParameterCard = true
            },
            onDelete: {
                if let index = exerciseParameters.firstIndex(where: { $0.id == exercise.id }) {
                    exerciseParameters.remove(at: index)
                }
            }
        )
        // 添加拖曳手勢
        .onDrag {
            handleDragStarted(exercise: exercise, index: index)
        }
        // 添加放置目標
        .onDrop(of: [.text], isTargeted: nil) { providers, location in
            // 確保我們有有效的拖曳狀態
            guard let draggedItemIndex = self.draggedItemIndex,
                  self.isDragging,
                  draggedItemIndex >= 0, draggedItemIndex < self.exerciseParameters.count else {
                self.handleDragCancelled()
                return false
            }
            
            // 如果拖曳到自己，不做任何事
            if draggedItemIndex == index {
                self.handleDragCancelled()
            return false
            }
            
            // 根據拖曳位置決定插入位置
            // 如果拖曳到卡片的右半部分，插入到該卡片之後
            // 如果拖曳到卡片的左半部分，插入到該卡片之前
            let cardWidth: CGFloat = 200 // 假設卡片寬度
            let insertAfter = location.x > cardWidth / 2
            
            let targetIndex: Int
            if insertAfter {
                // 插入到該卡片之後
                targetIndex = min(index + 1, self.exerciseParameters.count)
            } else {
                // 插入到該卡片之前
                targetIndex = index
            }
            
            self.moveItem(fromIndex: draggedItemIndex, toIndex: targetIndex)
            return true
        }
    }
    
    // 4.2 運動卡片列表容器 - 修改動畫處理
    @ViewBuilder
    private func exerciseCardsContainer(geometry: GeometryProxy) -> some View {
        HStack(spacing: 15) {
            Spacer()
            // 使用 indices 來確保索引的正確性
            ForEach(exerciseParameters.indices, id: \.self) { index in
                exerciseCardView(exercise: exerciseParameters[index], index: index, geometry: geometry)
            }
            
            // 添加一個不可見的拖放區域來處理拖曳到末尾的情況
            if isDragging && !exerciseParameters.isEmpty {
                Rectangle()
                    .fill(Color.clear)
                    .frame(width: 50, height: geometry.size.height)
                    .onDrop(of: [.text], isTargeted: nil) { providers, location in
                        guard let draggedItemIndex = self.draggedItemIndex,
                              self.isDragging,
                              draggedItemIndex >= 0, draggedItemIndex < self.exerciseParameters.count else {
                            self.handleDragCancelled()
                            return false
                        }
                        
                        // 移動到最後
                        let targetIndex = self.exerciseParameters.count
                        self.moveItem(fromIndex: draggedItemIndex, toIndex: targetIndex)
                        return true
                    }
            }
            
            Spacer()
        }
        .frame(height: geometry.size.height)
        .padding(.horizontal, 15)
        // 移除可能導致問題的動畫修飾符
        // .animation(.spring(response: 0.3), value: exerciseParameters)
        // 添加 onDisappear 修飾符，確保視圖消失時重置拖曳狀態
        .onDisappear {
            resetDragState()
        }
    }
    
    // 4. 有內容的拖放區域 - 簡化版本
    @ViewBuilder
    private func exerciseListView() -> some View {
        GeometryReader { geometry in
            exerciseCardsContainer(geometry: geometry)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(isTargeted ? ExerciseConstants.Colors.dropZoneActive : ExerciseConstants.Colors.dropZoneInactive)
        .animation(.easeInOut, value: isTargeted)
        // 添加全局拖放處理，作為後備方案
        .onDrop(of: [.text], isTargeted: nil) { providers, location in
            guard let draggedItemIndex = self.draggedItemIndex,
                  self.isDragging,
                  draggedItemIndex >= 0, draggedItemIndex < self.exerciseParameters.count else {
                self.handleDragCancelled()
                return false
            }
            
            // 如果拖曳到背景區域，移動到最後
            let targetIndex = self.exerciseParameters.count
            self.moveItem(fromIndex: draggedItemIndex, toIndex: targetIndex)
            return true
        }
    }
    
    // 5. 中間拖放區域
    @ViewBuilder
    private func dropZoneSection() -> some View {
        ZStack {
            if exerciseParameters.isEmpty {
                emptyDropZoneView()
            } else {
                exerciseListView()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .dropDestination(for: ExerciseModule.Exercise.self) { exercises, _ in
            guard let exercise = exercises.first else { return false }
            
            if exerciseParameters.count >= 4 {
                showingLimitAlert = true
                return false
            }
            
            let parameters = ExerciseParameters(
                exercise: exercise,
                rightLeg: LegParameters(
                    sets: 3,
                    repetitions: 10,
                    restTime: 30,
                    duration: 30,
                    kneeAngleStart: 0,
                    kneeAngleEnd: 90,
                    hipAngleStart: 0,
                    hipAngleEnd: 40,
                    weight: 0,
                    mvic: 60,
                    stimulation: false,
                    stimulationIntensity: 5,
                    stimulationFrequency: 5,
                    stimulationPulseWidth: 5
                ),
                leftLeg: nil
            )
            
            exerciseParameters.append(parameters)
            return true
        } isTargeted: { targeted in
            isTargeted = targeted
        }
    }
    
    // 6. 底部儲存按鈕
    @ViewBuilder
    private func saveButtonSection() -> some View {
        VStack(spacing: 8) {
            // 添加拖曳提示文字 - 靠右對齊
            if !exerciseParameters.isEmpty {
                HStack {
                    Spacer()
                    Text("提示：可以按住並拖曳訓練卡片到左側或右側來調整順序")
                        .font(.footnote)
                        .foregroundColor(.gray)
                        .padding(.trailing, 16)
                }
            }
            
            // 儲存按鈕
            Button(action: {
                // 如果沒有變更，直接返回
                if !hasChanges {
                    dismiss()
                    return
                }
                
                let trimmedTitle = menuTitle.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                if checkDuplicateTitle(trimmedTitle) {
                    showingDuplicateAlert = true
                    return
                }
                
                let updatedMenu = TrainingMenu(
                    id: existingMenuId ?? UUID(),
                    title: trimmedTitle,
                    isExclusive: isExclusive,
                    color: selectedColor,
                    exercises: exerciseParameters,
                    // 新菜單預設全選訓練時段，現有菜單保持原有時段
                    timeSlots: menuStore.menus.first(where: { $0.id == existingMenuId })?.timeSlots ?? Set(["早", "中", "下", "晚"]),
                    patientId: isExclusive ? patient.id : nil
                )
                menuStore.saveMenu(updatedMenu)
                selectedMenu = updatedMenu
                
                // 保存後直接返回，不需要額外確認
                dismiss()
            }) {
                HStack {
                    Image(systemName: hasChanges ? "checkmark.circle.fill" : "arrow.left")
                        .font(.system(size: 18))
                    Text(hasChanges ? "儲存菜單" : "返回")
                        .font(.system(size: 18, weight: .medium))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    !exerciseParameters.isEmpty ? 
                        (hasChanges ? Color.orange : Color.gray) : 
                        Color.gray.opacity(0.3)
                )
                .cornerRadius(8)
            }
            .disabled(exerciseParameters.isEmpty)
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
        .background(Color.gray.opacity(0.1))
    }
    
    // MARK: - Main Body
    public var body: some View {
        VStack(spacing: 0) {
            // 1. 頂部編輯區域
            headerSection()
            
            Divider()
                .background(ExerciseConstants.Colors.divider)
            
            // 2. 中間拖放區域
            dropZoneSection()
            
            // 3. 底部儲存按鈕
            saveButtonSection()
        }
        .background(ExerciseConstants.Colors.cardBackground)
        .cornerRadius(12)
        .alert("已達訓練項目數量上限", isPresented: $showingLimitAlert) {
            Button("確定", role: .cancel) { }
        } message: {
            Text("每個菜單最多可新增4個訓練項目")
        }
        .alert("菜單名稱重複", isPresented: $showingDuplicateAlert) {
            Button("確定", role: .cancel) { }
        } message: {
            Text("已存在相同名稱的訓練菜單，請更改名稱後再試。")
        }

        // 添加 onDisappear 修飾符，確保視圖消失時重置拖曳狀態
        .onDisappear {
            resetDragState()
        }
        // 添加 onAppear 修飾符，確保視圖出現時重置拖曳狀態
        .onAppear {
            resetDragState()
        }
    }
}

// MARK: - Exercise Parameter List Item
private struct ExerciseParameterListItem: View {
    let parameters: ExerciseParameters
    var isDragging: Bool = false  // 是否正在被拖曳
    var isDropTarget: Bool = false  // 新增：是否是放置目標
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    // 拆分視圖以減少複雜度
    @ViewBuilder
    private func imageSection() -> some View {
        if let image = UIImage(named: parameters.exercise.imageName) {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .frame(height: ExerciseConstants.Layout.cardImageHeight)
                .cornerRadius(ExerciseConstants.Layout.cardCornerRadius)
        }
    }
    
    @ViewBuilder
    private func titleSection() -> some View {
        VStack(alignment: .leading, spacing: ExerciseConstants.Layout.defaultSpacing / 2) {
            Text(parameters.exercise.name)
                .font(.system(size: 16, weight: .medium))
                .lineLimit(1)
                .foregroundColor(ExerciseConstants.Colors.textPrimary)
            ScrollView(.horizontal, showsIndicators: false) {
                Text(parameters.exercise.englishName)
                    .font(.system(size: 14))
                    .foregroundColor(ExerciseConstants.Colors.textSecondary)
            }
            .frame(height: ExerciseConstants.Layout.englishNameHeight)
        }
    }
    
    @ViewBuilder
    private func parametersSection() -> some View {
        VStack(alignment: .leading, spacing: ExerciseConstants.Layout.defaultSpacing / 2) {
            if let rightLeg = parameters.rightLeg {
                Text("右腳: \(rightLeg.sets)組\(rightLeg.repetitions)下")
                    .font(.system(size: 14))
                    .foregroundColor(.blue)
            }
            
            if let leftLeg = parameters.leftLeg {
                Text("左腳: \(leftLeg.sets)組\(leftLeg.repetitions)下")
                    .font(.system(size: 14))
                    .foregroundColor(.blue)
            }
            
            // 統一顯示電刺激狀態
            let stimulationEnabled = (parameters.rightLeg?.stimulation ?? false) || 
                                  (parameters.leftLeg?.stimulation ?? false)
            if parameters.rightLeg != nil || parameters.leftLeg != nil {
                Text("電刺激: \(stimulationEnabled ? "ON" : "OFF")")
                    .font(.system(size: 14))
                    .foregroundColor(stimulationEnabled ? .green : .gray)
            }
        }
        .frame(height: ExerciseConstants.Layout.parametersHeight)
    }
    
    @ViewBuilder
    private func buttonsSection() -> some View {
        HStack {
            // 修改：拖曳提示圖標從上下箭頭改為左右箭頭
            Image(systemName: "arrow.left.arrow.right")
                .foregroundColor(.gray)
                .opacity(0.7)
            
            Spacer()
            
            Button(action: onEdit) {
                Image(systemName: "pencil")
                    .foregroundColor(.blue)
            }
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .foregroundColor(.red)
            }
        }
    }
    
    var body: some View {
        VStack(spacing: ExerciseConstants.Layout.defaultSpacing) {
            // 圖片區域
            imageSection()
            
            // 文字和按鈕區域
            VStack(alignment: .leading, spacing: ExerciseConstants.Layout.defaultSpacing) {
                // 標題
                titleSection()
                
                // 參數資訊
                parametersSection()
                
                // 按鈕區域
                buttonsSection()
            }
            .padding(.horizontal, ExerciseConstants.Layout.defaultPadding)
        }
        .padding(.vertical, ExerciseConstants.Layout.defaultPadding)
        .frame(width: ExerciseConstants.Layout.cardWidth)
        .background(ExerciseConstants.Colors.cardBackground)
        .cornerRadius(ExerciseConstants.Layout.cardCornerRadius)
        .shadow(radius: isDragging ? 5 : (isDropTarget ? 4 : 2))  // 拖曳時或作為放置目標時增加陰影效果
        // 視覺反饋 - 修改為使用 Group 和 id 來強制更新
        .overlay(
            Group {
                RoundedRectangle(cornerRadius: ExerciseConstants.Layout.cardCornerRadius)
                    .stroke(
                        isDragging ? Color.blue : 
                        (isDropTarget ? Color.orange : Color.clear), 
                        lineWidth: isDragging || isDropTarget ? 2 : 0
                    )
            }
            .id("border-\(isDragging)-\(isDropTarget)-\(parameters.id.uuidString)")
        )
        // 當作為放置目標時添加輕微放大效果
        .scaleEffect(isDropTarget ? 1.01 : 1.0)
        // 確保視覺效果能夠立即響應狀態變化
        .animation(.spring(response: 0.2), value: isDragging)
        .animation(.spring(response: 0.2), value: isDropTarget)
        // 添加 id 修飾符，確保視圖在狀態變化時能夠完全重建
        .id("card-\(isDragging)-\(isDropTarget)-\(parameters.id.uuidString)")
    }
}
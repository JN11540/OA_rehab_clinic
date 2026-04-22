import SwiftUI
#if canImport(UIKit)
import UIKit
#endif
import Foundation

struct MenuManagementView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var userModel: UserModel
    @EnvironmentObject private var menuStore: TrainingMenuStore
    @EnvironmentObject private var patientStore: PatientStore
    
    @State private var selectedTab: TrainingMenuTab = .common
    @State private var searchText: String = ""
    @State private var sortOrder: SortOrder = .newestFirst
    @State private var selectedPatient: Patient? = nil
    @State private var selectedMenu: TrainingMenu? = nil
    @State private var showingAddMenu = false
    @State private var editingMenu: TrainingMenu? = nil
    @State private var editingPatient: Patient? = nil
    @State private var showingEditMenu = false
    
    enum TrainingMenuTab {
        case common
        case personal
    }
    
    enum SortOrder {
        case newestFirst
        case oldestFirst
        case byName
    }
    
    var body: some View {
            VStack(spacing: 0) {
                // Header with tabs
                headerView
                
                // Main content area
                ZStack {
                // Background - 簡潔的透明灰色背景
                Color(red: 0.95, green: 0.97, blue: 0.98)
                    .ignoresSafeArea(edges: .all)
                    
                    VStack(spacing: 20) {
                        // Subtabs and search/sort options
                        HStack {
                            // Tab buttons
                            HStack(spacing: 15) {
                                TabButton(
                                    title: "共通訓練菜單", 
                                    isSelected: selectedTab == .common,
                                    action: { selectedTab = .common }
                                )
                                
                                TabButton(
                                    title: "個人專屬訓練菜單", 
                                    isSelected: selectedTab == .personal,
                                    action: { selectedTab = .personal }
                                )
                            }
                            
                            Spacer()
                            
                            // Search field (only for personal tab)
                            if selectedTab == .personal {
                                HStack {
                                    Image(systemName: "magnifyingglass")
                                        .foregroundColor(.gray)
                                    TextField("搜尋個案", text: $searchText)
                                        .textFieldStyle(PlainTextFieldStyle())
                                }
                                .padding(8)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.gray.opacity(0.1))
                                )
                                .frame(width: 200)
                            }
                            
                            // Sort button
                            Menu {
                                Button(action: { sortOrder = .newestFirst }) {
                                    Label("新到舊", systemImage: "arrow.down.circle")
                                    if sortOrder == .newestFirst {
                                        Image(systemName: "checkmark")
                                    }
                                }
                                
                                Button(action: { sortOrder = .oldestFirst }) {
                                    Label("舊到新", systemImage: "arrow.up.circle")
                                    if sortOrder == .oldestFirst {
                                        Image(systemName: "checkmark")
                                    }
                                }
                                
                                Button(action: { sortOrder = .byName }) {
                                    Label("依名稱", systemImage: "textformat.abc")
                                    if sortOrder == .byName {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            } label: {
                                HStack {
                                    Image(systemName: "arrow.up.arrow.down")
                                    Text("排序")
                                }
                                .foregroundColor(.gray)
                                .padding(8)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.gray.opacity(0.1))
                                )
                            }
                            
                            // Add menu button
                            Button(action: {
                                // If in personal tab, we need a patient selected
                                if selectedTab == .personal && selectedPatient == nil {
                                    // Show alert that a patient needs to be selected
                                    return
                                }
                                showingAddMenu = true
                            }) {
                                HStack {
                                    Image(systemName: "plus.circle.fill")
                                    Text("新增訓練菜單")
                                }
                                .foregroundColor(.white)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 12)
                                .background(Color.orange)
                                .cornerRadius(8)
                            }
                        }
                        .padding(.horizontal, 30)
                        .padding(.vertical, 10)
                        
                        // Content based on selected tab
                        if selectedTab == .common {
                            CommonMenusView(
                                menus: sortedMenus(menuStore.getCommonMenus()),
                            sortOrder: sortOrder,
                            onEditMenu: { menu in
                                editingMenu = menu
                                editingPatient = nil // 共通菜單不需要患者
                                showingEditMenu = true
                            }
                            )
                        } else {
                            PersonalMenusView(
                                patients: filteredPatients,
                                selectedPatient: $selectedPatient,
                                searchText: searchText,
                            sortOrder: sortOrder,
                            onEditMenu: { menu, patient in
                                editingMenu = menu
                                editingPatient = patient
                                showingEditMenu = true
                            }
                            )
                        }
                    }
                    .padding(.top, 20)
                }
            }
            .navigationDestination(isPresented: $showingAddMenu) {
                EditTrainingMenuView(
                    patient: selectedTab == .personal ? selectedPatient ?? Patient.sample : Patient.sample,
                selectedMenu: $selectedMenu,
                isCommonMenu: selectedTab == .common  // 共通菜單不顯示 PatientInfoCard
            )
            .environmentObject(userModel)
            .environmentObject(menuStore)
            .environmentObject(TrainingScheduleStore.shared)
        }
        .navigationDestination(isPresented: $showingEditMenu) {
            if let menu = editingMenu {
                EditTrainingMenuView(
                    patient: editingPatient ?? Patient.sample,
                    existingMenu: menu,
                    selectedMenu: $selectedMenu,
                    isCommonMenu: editingPatient == nil  // 沒有患者表示是共通菜單
                )
                .environmentObject(userModel)
                .environmentObject(menuStore)
                .environmentObject(TrainingScheduleStore.shared)
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var filteredPatients: [Patient] {
        if searchText.isEmpty {
            return patientStore.patients
        } else {
            return patientStore.patients.filter { 
                $0.id.localizedCaseInsensitiveContains(searchText) ||
                $0.name.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    // MARK: - Helper Functions
    
    private func sortedMenus(_ menus: [TrainingMenu]) -> [TrainingMenu] {
        switch sortOrder {
        case .newestFirst:
            // Assuming newer menus are at the end of the array
            return menus.reversed()
        case .oldestFirst:
            return menus
        case .byName:
            return menus.sorted { $0.title < $1.title }
        }
    }
    
    // MARK: - View Components
    
    private var headerView: some View {
        HStack {
            // App logo
            Image("AppIcon-Standard")
                .resizable()
                .frame(width: 40, height: 40)
                .cornerRadius(10)
                .padding(.leading, 30)
            
            Spacer()
            
            // Tab navigation
            HStack(spacing: 30) {
                Button(action: {
                    dismiss()
                }) {
                    Text("個案管理")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.gray)
                }
                
                Text("菜單管理")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.orange)
                    .padding(.bottom, 5)
                    .overlay(
                        Rectangle()
                            .frame(height: 2)
                            .foregroundColor(.orange),
                        alignment: .bottom
                    )
            }
            
            Spacer()
            
            // User info
            HStack(spacing: 12) {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .frame(width: 32, height: 32)
                    .foregroundColor(.gray)
                Text("\(userModel.name) \(userModel.role.rawValue)")
                    .foregroundColor(.gray)
                Text(userModel.department)
                    .foregroundColor(.gray)
            }
            .padding(.trailing, 30)
        }
        .padding(.vertical, 15)
        .background(Color.white)
        .shadow(color: .black.opacity(0.05), radius: 5, y: 2)
    }
}

// MARK: - Common Menus View
struct CommonMenusView: View {
    let menus: [TrainingMenu]
    let sortOrder: MenuManagementView.SortOrder
    let onEditMenu: (TrainingMenu) -> Void
    @State private var showingDeleteAlert = false
    @State private var menuToDelete: TrainingMenu? = nil
    @EnvironmentObject private var menuStore: TrainingMenuStore
    
    // 計算網格列數
    private let columns = [
        GridItem(.flexible(), spacing: 20),
        GridItem(.flexible(), spacing: 20)
    ]
    
    var body: some View {
        ScrollView {
                if menus.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "doc.text")
                        .font(.system(size: 60))
                        .foregroundColor(.gray.opacity(0.5))
                    
                    Text("沒有共通訓練菜單")
                        .font(.title3)
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity)
                        .padding(.top, 100)
                } else {
                LazyVGrid(columns: columns, spacing: 20) {
                    ForEach(menus) { menu in
                        MenuCard(
                            menu: menu,
                            onEdit: {
                                onEditMenu(menu)
                            },
                            onDelete: {
                                menuToDelete = menu
                                showingDeleteAlert = true
                            }
                        )
                    }
                }
                .padding(.horizontal, 30)
                .padding(.vertical, 20)
            }
        }
        .alert("確認刪除", isPresented: $showingDeleteAlert) {
            Button("取消", role: .cancel) {}
            Button("刪除", role: .destructive) {
                if let menu = menuToDelete {
                    menuStore.deleteMenu(menu)
                }
            }
        } message: {
            if let menu = menuToDelete {
                Text("確定要刪除 \(menu.title) 訓練菜單嗎？")
            } else {
                Text("確定要刪除此訓練菜單嗎？")
            }
        }

    }
}

// MARK: - Personal Menus View
struct PersonalMenusView: View {
    let patients: [Patient]
    @Binding var selectedPatient: Patient?
    let searchText: String
    let sortOrder: MenuManagementView.SortOrder
    let onEditMenu: (TrainingMenu, Patient) -> Void
    @EnvironmentObject private var menuStore: TrainingMenuStore
    @State private var showingDeleteAlert = false
    @State private var menuToDelete: TrainingMenu? = nil
    
    var body: some View {
        VStack(spacing: 20) {
            if patients.isEmpty && !searchText.isEmpty {
                Text("沒有符合搜尋條件的個案")
                    .font(.title3)
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 50)
            } else {
                // Patient selection
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 15) {
                        ForEach(patients) { patient in
                            PatientSelectCard(
                                patient: patient,
                                isSelected: selectedPatient?.id == patient.id,
                                onSelect: {
                                    selectedPatient = patient
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 30)
                }
                
                // Menus for selected patient
                if let patient = selectedPatient {
                    let patientMenus = sortedMenus(menuStore.getExclusiveMenus(for: patient.id))
                    
                    ScrollView {
                            if patientMenus.isEmpty {
                            VStack(spacing: 20) {
                                Image(systemName: "person.crop.circle.badge.questionmark")
                                    .font(.system(size: 60))
                                    .foregroundColor(.gray.opacity(0.5))
                                
                                Text("\(patient.name) 沒有專屬訓練菜單")
                                    .font(.title3)
                                    .foregroundColor(.gray)
                            }
                                    .frame(maxWidth: .infinity)
                                    .padding(.top, 50)
                            } else {
                            LazyVGrid(columns: [
                                GridItem(.flexible(), spacing: 20),
                                GridItem(.flexible(), spacing: 20)
                            ], spacing: 20) {
                                ForEach(patientMenus) { menu in
                                    MenuCard(
                                        menu: menu,
                                        onEdit: {
                                            onEditMenu(menu, patient)
                                        },
                                        onDelete: {
                                            menuToDelete = menu
                                            showingDeleteAlert = true
                                        }
                                    )
                                }
                            }
                            .padding(.horizontal, 30)
                            .padding(.vertical, 20)
                        }
                    }
                } else {

                    Text("請選擇個案以查看專屬訓練菜單")
                        .font(.title3)
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 50)

                    Spacer()
                }
            }
        }
        .alert("確認刪除", isPresented: $showingDeleteAlert) {
            Button("取消", role: .cancel) {}
            Button("刪除", role: .destructive) {
                if let menu = menuToDelete {
                    menuStore.deleteMenu(menu)
                }
            }
        } message: {
            if let menu = menuToDelete {
                Text("確定要刪除 \(menu.title) 訓練菜單嗎？")
            } else {
                Text("確定要刪除此訓練菜單嗎？")
            }
        }

    }
    
    private func sortedMenus(_ menus: [TrainingMenu]) -> [TrainingMenu] {
        switch sortOrder {
        case .newestFirst:
            return menus.reversed()
        case .oldestFirst:
            return menus
        case .byName:
            return menus.sorted { $0.title < $1.title }
        }
    }
}

// MARK: - Menu Card
struct MenuCard: View {
    let menu: TrainingMenu
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    // 固定卡片高度以確保一致性
    private let cardHeight: CGFloat = 320
    private let maxExerciseRows: Int = 4
    
    // 日期格式化函數
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy.MM.dd"
        return formatter.string(from: date)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header section with title and date
            VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(menu.title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                
                Spacer()
                
                    // Status badge
                Text(menu.isExclusive ? "專屬" : "通用")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(menu.isExclusive ? 
                                     Color(red: 0.2, green: 0.6, blue: 0.9) : 
                                     Color(red: 0.5, green: 0.7, blue: 0.8))
                        )
                }
                
                // 實際創建日期
                Text(formatDate(menu.createdAt))
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 12)
            
            // Divider
            Rectangle()
                .fill(Color.gray.opacity(0.2))
                .frame(height: 1)
                .padding(.horizontal, 16)
            
            // Exercise list section with fixed height
            VStack(alignment: .leading, spacing: 0) {
                // Header row
                HStack {
                    Text("訓練動作")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Text("次數")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.gray)
                        .frame(width: 40, alignment: .center)
                    
                    Text("秒數")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.gray)
                        .frame(width: 40, alignment: .center)
                    
                    Text("組數")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.gray)
                        .frame(width: 40, alignment: .center)
                    
                    Text("角度")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.gray)
                        .frame(width: 40, alignment: .center)
                    
                    Text("電刺激強度")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.gray)
                        .frame(width: 60, alignment: .center)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.gray.opacity(0.05))
                
                // Exercise rows with fixed height
                ScrollView {
                    LazyVStack(spacing: 4) {
                        ForEach(Array(menu.exercises.prefix(maxExerciseRows).enumerated()), id: \.element.id) { index, exercise in
                            ExerciseRowView(exercise: exercise)
                        }
                        
                        // Fill remaining space if needed
                        if menu.exercises.count < maxExerciseRows {
                            ForEach(0..<(maxExerciseRows - menu.exercises.count), id: \.self) { _ in
                                EmptyExerciseRowView()
                            }
                        }
                    }
                }
                .frame(height: 160) // Fixed height for exercise list
                .padding(.horizontal, 16)
                }
            
            Spacer()
            
            // Action buttons
            HStack(spacing: 12) {
                Spacer()
                
                Button(action: onDelete) {
                    HStack(spacing: 4) {
                        Image(systemName: "trash")
                            .font(.system(size: 14))
                        Text("刪除")
                            .font(.system(size: 14))
                    }
                    .foregroundColor(.red)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.red.opacity(0.3), lineWidth: 1)
                    )
                }
                
                Button(action: onEdit) {
                    HStack(spacing: 4) {
                        Image(systemName: "pencil")
                            .font(.system(size: 14))
                        Text("編輯菜單")
                            .font(.system(size: 14))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.orange)
                    )
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .frame(height: cardHeight)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.1), lineWidth: 1)
        )
    }
}

// MARK: - Exercise Row View
struct ExerciseRowView: View {
    let exercise: ExerciseParameters
    
    // 獲取運動配置以判斷應該顯示哪些參數
    private var config: ExerciseModule.ParameterConfiguration {
        ExerciseModule.ParameterConfiguration.forExercise(exercise.exercise)
    }
    
    // 格式化時間顯示（優先顯示維持時間，沒有維持時間時顯示0）
    private var timeDisplay: String {
        if let rightLeg = exercise.rightLeg {
            // 優先顯示維持時間
            if config.showMantainTime {
                return "\(rightLeg.duration ?? 0)"
            } else if config.showRestTime {
                return "\(rightLeg.restTime)"
            }
        }
        return "0"
    }
    
    // 格式化電刺激強度顯示
    private var stimulationDisplay: String {
        if let rightLeg = exercise.rightLeg {
            // 檢查是否允許電刺激且已開啟
            if config.allowStimulation && rightLeg.stimulation {
                return "\(rightLeg.stimulationIntensity ?? 0)"
            } else if config.allowStimulation {
                return "OFF"
            }
        }
        return "-"
    }
    
    var body: some View {
        HStack {
            Text(exercise.exercise.name)
                .font(.system(size: 13))
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .lineLimit(1)
            
            Text("\(exercise.rightLeg?.repetitions ?? 0)")
                .font(.system(size: 13))
                .foregroundColor(.primary)
                .frame(width: 40, alignment: .center)
            
            Text(timeDisplay)
                .font(.system(size: 13))
                .foregroundColor(.primary)
                .frame(width: 40, alignment: .center)
            
            Text("\(exercise.rightLeg?.sets ?? 0)")
                .font(.system(size: 13))
                .foregroundColor(.primary)
                .frame(width: 40, alignment: .center)
            
            Text("\(exercise.rightLeg?.kneeAngleEnd ?? 0)")
                .font(.system(size: 13))
                .foregroundColor(.primary)
                .frame(width: 40, alignment: .center)
            
            Text(stimulationDisplay)
                .font(.system(size: 13))
                .foregroundColor(.primary)
                .frame(width: 60, alignment: .center)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Empty Exercise Row View
struct EmptyExerciseRowView: View {
    var body: some View {
        HStack {
            Text("訓練動作")
                .font(.system(size: 13))
                .foregroundColor(.gray.opacity(0.3))
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Text("次數")
                .font(.system(size: 13))
                .foregroundColor(.gray.opacity(0.3))
                .frame(width: 40, alignment: .center)
            
            Text("秒數")
                .font(.system(size: 13))
                .foregroundColor(.gray.opacity(0.3))
                .frame(width: 40, alignment: .center)
            
            Text("組數")
                .font(.system(size: 13))
                .foregroundColor(.gray.opacity(0.3))
                .frame(width: 40, alignment: .center)
            
            Text("角度")
                .font(.system(size: 13))
                .foregroundColor(.gray.opacity(0.3))
                .frame(width: 40, alignment: .center)
            
            Text("電刺激強度")
                .font(.system(size: 13))
                .foregroundColor(.gray.opacity(0.3))
                .frame(width: 60, alignment: .center)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Patient Select Card
struct PatientSelectCard: View {
    let patient: Patient
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 8) {
                // Patient avatar with blue-green theme
                Circle()
                    .fill(isSelected ? 
                          LinearGradient(
                            colors: [Color(red: 0.2, green: 0.6, blue: 0.9), Color(red: 0.3, green: 0.7, blue: 0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                          ) :
                          LinearGradient(
                            colors: [Color.gray.opacity(0.2), Color.gray.opacity(0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                          )
                    )
                    .frame(width: 50, height: 50)
                    .overlay(
                        Image(systemName: "person.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.white)
                    )
                
                VStack(spacing: 2) {
                    Text("病歷號")
                        .font(.system(size: 10))
                        .foregroundColor(.gray)
                    
                    Text(patient.id)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.primary)
                    
                    Text("患者名字")
                        .font(.system(size: 10))
                        .foregroundColor(.gray)
                        .padding(.top, 2)
                    
                    Text(patient.name)
                        .font(.system(size: 12, weight: isSelected ? .semibold : .medium))
                        .foregroundColor(isSelected ? Color(red: 0.2, green: 0.6, blue: 0.9) : .primary)
                }
            }
            .frame(width: 100, height: 120)
            .background(Color.white)
            .cornerRadius(8)
            .shadow(color: .black.opacity(0.06), radius: 3, x: 0, y: 1)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color(red: 0.2, green: 0.6, blue: 0.9) : Color.gray.opacity(0.1), lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    MenuManagementView()
        .environmentObject(UserModel.preview)
        .environmentObject(TrainingMenuStore.preview)
        .environmentObject(PatientStore.preview)
} 
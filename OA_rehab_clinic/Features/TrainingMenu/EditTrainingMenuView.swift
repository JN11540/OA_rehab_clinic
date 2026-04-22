import SwiftUI
import Foundation
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Main View
struct EditTrainingMenuView: View {
    // MARK: Properties
    @Environment(\.dismiss) private var dismiss
    let patient: Patient
    let existingMenu: TrainingMenu?
    @EnvironmentObject private var userModel: UserModel
    @EnvironmentObject private var trainingScheduleStore: TrainingScheduleStore
    @EnvironmentObject private var trainingMenuStore: TrainingMenuStore
    @State private var selectedCategory: ExerciseModule.TrainingCategory = .all
    @State private var showingParameterCard = false
    @State private var selectedExerciseForParameter: ExerciseModule.Exercise?
    @State private var exerciseParameters: [ExerciseParameters]
    @State private var showingLimitAlert = false
    @State private var editingExercise: ExerciseParameters?
    @Binding var selectedMenu: TrainingMenu?
    private let isCommonMenu: Bool
    private let fixedHeight: CGFloat = 450  // 與其他卡片保持一致
    
    // MARK: Initialization
    init(patient: Patient, existingMenu: TrainingMenu? = nil, selectedMenu: Binding<TrainingMenu?>, isCommonMenu: Bool = false) {
        self.patient = patient
        self.existingMenu = existingMenu
        self._selectedMenu = selectedMenu
        self.isCommonMenu = isCommonMenu
        _exerciseParameters = State(initialValue: existingMenu?.exercises ?? [])
    }
    
    // MARK: Body
    var body: some View {
            ZStack {
                // Background
                GradientBackground(
                    startColor: Color(red: 0.47, green: 0.84, blue: 0.98),
                    endColor: Color(red: 0.72, green: 0.89, blue: 0.59)
                )
                .ignoresSafeArea(edges: .all)
                
                // Content
                VStack(spacing: 30) {
                    // Header
                    if isCommonMenu {
                        // 共通菜單使用較簡單的標題
                        HStack {
                            Button(action: {
                                dismiss()
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "chevron.left")
                                Text("返回菜單管理")
                                }
                                .foregroundColor(.gray)
                            }
                            Spacer()
                            Text(existingMenu?.title ?? "新增共通訓練菜單")
                                .font(.title3)
                                .fontWeight(.medium)
                            Spacer()
                        }
                        .padding(.horizontal, 30)
                    } else {
                        // 專屬菜單使用完整的患者標題
                        NavigationHeader(
                            patient: patient,
                            pageTitle: "編輯訓練月曆 > \(existingMenu?.title ?? "新增訓練菜單")"
                        )
                    }
                    
                    // Main Content Grid
                    Grid(alignment: .leading, horizontalSpacing: 15, verticalSpacing: 30) {
                        // Patient Info Row - 只有專屬菜單才顯示
                        if !isCommonMenu {
                            GridRow {
                                PatientInfoCard(patient: patient)
                                    .gridCellColumns(5)
                            }
                            .frame(height: UIScreen.main.bounds.height / 5)
                        }
                        
                        // Exercise Selection Row
                        GridRow {
                            // Exercise List
                            ExerciseListCard(
                                selectedCategory: $selectedCategory,
                                onExerciseSelected: { exercise in
                                    if exerciseParameters.count >= 4 {
                                        showingLimitAlert = true
                                        return
                                    }
                                    selectedExerciseForParameter = exercise
                                    editingExercise = nil  // 確保是新增模式
                                    showingParameterCard = true
                                }
                            )
                            .gridCellColumns(1)
                            .frame(height: fixedHeight)
                            
                            // Drop Zone - 支援拖曳重新排序功能（已優化性能與編譯效率）
                            ExerciseDropZone(
                                exerciseParameters: $exerciseParameters,
                                showingParameterCard: $showingParameterCard,
                                editingExercise: $editingExercise,
                                selectedExerciseForParameter: $selectedExerciseForParameter,
                                isExclusive: !isCommonMenu, // 根據當前是否為共通菜單設置適當的值
                                existingMenu: existingMenu,
                                selectedMenu: $selectedMenu,
                            patient: patient,
                            hideExclusiveToggle: isCommonMenu  // 共通菜單時隱藏適用對象選擇
                            )
                                .gridCellColumns(4)
                                .frame(height: fixedHeight)
                        }
                    }
                    .padding(.horizontal, 30)
                }
            }
            .overlay {
                if showingParameterCard, let exercise = selectedExerciseForParameter {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                        .onTapGesture {
                            showingParameterCard = false
                        }
                    
                    ExerciseParameterCard(
                        exercise: exercise,
                        isPresented: $showingParameterCard,
                        selectedExercises: $exerciseParameters,
                        editingExercise: editingExercise
                    )
                    .transition(.scale)
                }
            }
            .onChange(of: exerciseParameters, perform: { newParameters in
                // 當運動參數改變時（包括拖曳重新排序後），立即更新 selectedMenu
                if var updatedMenu = selectedMenu {
                    updatedMenu.exercises = newParameters
                    selectedMenu = updatedMenu
                } else if let existingMenu = existingMenu {
                    // 如果是第一次修改，創建新的 menu
                    var newMenu = existingMenu
                    newMenu.exercises = newParameters
                    selectedMenu = newMenu
                }
            })
            .animation(.spring(response: 0.3), value: showingParameterCard)
            .alert("已達訓練項目數量上限", isPresented: $showingLimitAlert) {
                Button("確定", role: .cancel) { }
            } message: {
                Text("每個菜單最多可新增4個訓練項目")
        }
    }
}

// MARK: - Preview
struct EditTrainingMenuView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            EditTrainingMenuView(
                patient: Patient.sample,
                selectedMenu: .constant(nil),
                isCommonMenu: false
            )
            .environmentObject(UserModel.preview)
            .environmentObject(TrainingScheduleStore.preview)
            .environmentObject(TrainingMenuStore.preview)
        }
    }
}

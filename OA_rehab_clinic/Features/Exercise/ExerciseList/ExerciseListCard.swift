import SwiftUI

// MARK: - Exercise List Card
public struct ExerciseListCard: View {
    @Binding var selectedCategory: ExerciseModule.TrainingCategory
    var selectedExercise: ExerciseModule.Exercise?
    var onExerciseSelected: ((ExerciseModule.Exercise) -> Void)?
    
    public init(
        selectedCategory: Binding<ExerciseModule.TrainingCategory>,
        selectedExercise: ExerciseModule.Exercise? = nil,
        onExerciseSelected: ((ExerciseModule.Exercise) -> Void)? = nil
    ) {
        self._selectedCategory = selectedCategory
        self.selectedExercise = selectedExercise
        self.onExerciseSelected = onExerciseSelected
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            CategoryMenu(selectedCategory: $selectedCategory)
            ExerciseList(
                selectedCategory: selectedCategory,
                selectedExercise: selectedExercise,
                onExerciseSelected: onExerciseSelected
            )
        }
        .background(Color.white)
        .cornerRadius(12)
    }
}

// MARK: - Exercise List
public struct ExerciseList: View {
    let selectedCategory: ExerciseModule.TrainingCategory
    let selectedExercise: ExerciseModule.Exercise?
    var onExerciseSelected: ((ExerciseModule.Exercise) -> Void)?
    @State private var showingAddExercise = false
    
    public init(
        selectedCategory: ExerciseModule.TrainingCategory,
        selectedExercise: ExerciseModule.Exercise? = nil,
        onExerciseSelected: ((ExerciseModule.Exercise) -> Void)? = nil
    ) {
        self.selectedCategory = selectedCategory
        self.selectedExercise = selectedExercise
        self.onExerciseSelected = onExerciseSelected
    }
    
    public var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 20) {
                ForEach(ExerciseModule.getExercisesForCategory(selectedCategory)) { section in
                    VStack(alignment: .leading, spacing: 12) {
                        Text(section.name)
                            .font(.headline)
                            .padding(.horizontal, ExerciseConstants.Layout.defaultPadding)
                        
                        ForEach(section.subcategories, id: \.name) { subcategory in
                            VStack(alignment: .leading, spacing: 8) {
                                Text(subcategory.name)
                                    .font(.subheadline)
                                    .foregroundColor(AppColors.text)
                                    .padding(.horizontal, ExerciseConstants.Layout.defaultPadding)
                                
                                LazyVGrid(
                                    columns: [GridItem(.adaptive(minimum: ExerciseConstants.Layout.cardWidth))],
                                    alignment: .center,
                                    spacing: ExerciseConstants.Layout.defaultSpacing
                                ) {
                                    ForEach(subcategory.exercises) { exercise in
                                        ExerciseCard(
                                            exercise: exercise,
                                            isSelected: selectedExercise?.id == exercise.id
                                        )
                                        .onTapGesture { onExerciseSelected?(exercise) }
                                        .draggable(exercise) {
                                            ExerciseCard(exercise: exercise)
                                                .frame(width: ExerciseConstants.Layout.cardWidth)
                                        }
                                    }
                                }
                                .padding(.horizontal, ExerciseConstants.Layout.defaultPadding)
                            }
                        }
                    }
                }
                
                // Add Exercise Card
                VStack(alignment: .leading, spacing: 8) {
                    Text("新增動作")
                        .font(.subheadline)
                        .foregroundColor(AppColors.text)
                        .padding(.horizontal, ExerciseConstants.Layout.defaultPadding)
                    
                    LazyVGrid(
                        columns: [GridItem(.adaptive(minimum: ExerciseConstants.Layout.cardWidth))],
                        alignment: .center,
                        spacing: ExerciseConstants.Layout.defaultSpacing
                    ) {
                        Button(action: {
                            showingAddExercise = true
                        }) {
                            VStack(spacing: 12) {
                                Circle()
                                    .fill(Color.orange.opacity(0.1))
                                    .frame(width: 60, height: 60)
                                    .overlay(
                                        Image(systemName: "plus")
                                            .font(.system(size: 30))
                                            .foregroundColor(.orange)
                                    )
                                Text("新增動作")
                                    .font(.system(size: 16))
                                    .foregroundColor(.orange)
                            }
                            .frame(width: ExerciseConstants.Layout.cardWidth)
                            .frame(height: ExerciseConstants.Layout.cardImageHeight + 80)
                            .background(Color.white)
                            .cornerRadius(ExerciseConstants.Layout.cardCornerRadius)
                            .shadow(radius: 2)
                        }
                    }
                    .padding(.horizontal, ExerciseConstants.Layout.defaultPadding)
                }
            }
            .padding(.vertical, ExerciseConstants.Layout.defaultPadding)
        }
        .sheet(isPresented: $showingAddExercise) {
            AddExerciseView(isPresented: $showingAddExercise)
        }
    }
} 
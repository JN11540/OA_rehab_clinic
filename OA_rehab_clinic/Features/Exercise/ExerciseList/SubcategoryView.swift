import SwiftUI

// MARK: - Subcategory View
public struct SubcategoryView: View {
    let subcategory: ExerciseModule.ExerciseSubcategory
    var onExerciseSelected: ((ExerciseModule.Exercise) -> Void)?
    
    public init(
        subcategory: ExerciseModule.ExerciseSubcategory,
        onExerciseSelected: ((ExerciseModule.Exercise) -> Void)? = nil
    ) {
        self.subcategory = subcategory
        self.onExerciseSelected = onExerciseSelected
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(subcategory.name)
                .font(.subheadline)
                .foregroundColor(AppColors.text)
                .padding(.leading, ExerciseConstants.Layout.defaultPadding)
            
            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: ExerciseConstants.Layout.cardWidth))],
                alignment: .leading,
                spacing: ExerciseConstants.Layout.defaultSpacing
            ) {
                ForEach(subcategory.exercises) { exercise in
                    ExerciseCard(exercise: exercise)
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
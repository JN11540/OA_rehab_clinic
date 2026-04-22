import SwiftUI

// MARK: - Exercise Section View
public struct ExerciseSectionView: View {
    let section: ExerciseModule.ExerciseCategory
    var onExerciseSelected: ((ExerciseModule.Exercise) -> Void)?
    
    public init(
        section: ExerciseModule.ExerciseCategory,
        onExerciseSelected: ((ExerciseModule.Exercise) -> Void)? = nil
    ) {
        self.section = section
        self.onExerciseSelected = onExerciseSelected
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(section.name)
                .font(.headline)
            
            ForEach(section.subcategories, id: \.name) { subcategory in
                SubcategoryView(
                    subcategory: subcategory,
                    onExerciseSelected: onExerciseSelected
                )
            }
        }
    }
} 
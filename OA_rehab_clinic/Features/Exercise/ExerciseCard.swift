import SwiftUI

// MARK: - Exercise Card
public struct ExerciseCard: View {
    let exercise: ExerciseModule.Exercise
    let isSelected: Bool
    
    public init(exercise: ExerciseModule.Exercise, isSelected: Bool = false) {
        self.exercise = exercise
        self.isSelected = isSelected
    }
    
    public var body: some View {
        VStack(spacing: ExerciseConstants.Layout.defaultSpacing) {
            // 圖片
            if let image = UIImage(named: exercise.imageName) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(height: ExerciseConstants.Layout.cardImageHeight)
                    .cornerRadius(ExerciseConstants.Layout.cardCornerRadius)
            }
            
            // 文字說明
            VStack(alignment: .leading, spacing: ExerciseConstants.Layout.defaultSpacing / 2) {
                Text(exercise.name)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(ExerciseConstants.Colors.textPrimary)
                Text(exercise.englishName)
                    .font(.system(size: 14))
                    .foregroundColor(ExerciseConstants.Colors.textSecondary)
            }
        }
        .padding(ExerciseConstants.Layout.defaultPadding)
        .frame(width: ExerciseConstants.Layout.cardWidth)
        .background(ExerciseConstants.Colors.cardBackground)
        .cornerRadius(ExerciseConstants.Layout.cardCornerRadius)
        .overlay(
            // 選中狀態的藍色邊框
            RoundedRectangle(cornerRadius: ExerciseConstants.Layout.cardCornerRadius)
                .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 3)
        )
        .shadow(radius: isSelected ? 4 : 2)
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

// MARK: - Previews
#Preview {
    ExerciseCard(
        exercise: ExerciseModule.Exercise.quadricepsBasic[0]
    )
    .padding()
    .background(Color.gray.opacity(0.1))
} 
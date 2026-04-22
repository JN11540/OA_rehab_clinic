import SwiftUI

// MARK: - Category Menu
public struct CategoryMenu: View {
    @Binding var selectedCategory: ExerciseModule.TrainingCategory
    
    public init(selectedCategory: Binding<ExerciseModule.TrainingCategory>) {
        self._selectedCategory = selectedCategory
    }
    
    public var body: some View {
        Menu {
            ForEach(ExerciseModule.TrainingCategory.allCases, id: \.self) { category in
                Button(action: { selectedCategory = category }) {
                    Text(category.rawValue)
                }
            }
        } label: {
            HStack {
                Text("訓練類別")
                Spacer()
                Image(systemName: "chevron.down")
            }
            .padding()
            .background(Color.white)
            .cornerRadius(8)
        }
    }
} 
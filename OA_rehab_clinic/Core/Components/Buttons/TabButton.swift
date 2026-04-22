import SwiftUI

struct TabButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(isSelected ? .white : .gray)
                .padding(.horizontal, 16)
                .frame(height: 36)
                .background(isSelected ? Color.orange : Color.white)
                .cornerRadius(18)
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(isSelected ? Color.orange : Color.gray.opacity(0.3), lineWidth: 1)
                )
        }
    }
}

#Preview {
    HStack(spacing: 20) {
        TabButton(title: "選項一", isSelected: true, action: {})
        TabButton(title: "選項二", isSelected: false, action: {})
    }
    .padding()
    .background(Color.gray.opacity(0.1))
} 

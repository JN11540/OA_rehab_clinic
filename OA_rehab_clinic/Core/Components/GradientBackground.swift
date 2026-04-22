import SwiftUI

struct GradientBackground: View {
    let startColor: Color
    let endColor: Color
    let opacity: Double
    
    init(
        startColor: Color = Color.blue,
        endColor: Color = Color.green,
        opacity: Double = 0.2
    ) {
        self.startColor = startColor
        self.endColor = endColor
        self.opacity = opacity
    }
    
    var body: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                startColor.opacity(opacity),
                endColor.opacity(opacity)
            ]),
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

#Preview {
    GradientBackground()
}



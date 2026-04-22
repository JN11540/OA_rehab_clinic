import SwiftUI

struct AppColors {
    static let background = Color("Background")
    static let cardBackground = Color("CardBackground")
    static let secondaryBackground = Color("SecondaryBackground")
    static let text = Color("Text")
    static let secondaryText = Color("SecondaryText")
    static let accent = Color("Accent")
    
    // 預設的十種訓練菜單顏色
    static let menuColors: [Color] = [
        Color("MenuColor1"),
        Color("MenuColor2"),
        Color("MenuColor3"),
        Color("MenuColor4"),
        Color("MenuColor5"),
        Color("MenuColor6"),
        Color("MenuColor7"),
        Color("MenuColor8"),
        Color("MenuColor9"),
        Color("MenuColor10")
    ]
} 

// 定義時段顏色
public extension Color {
    static let morning = Color(red: 1.0, green: 0.8, blue: 0.4)     // 黃色
    static let noon = Color(red: 1.0, green: 0.6, blue: 0.4)        // 橙色
    static let afternoon = Color(red: 0.4, green: 0.6, blue: 1.0)   // 藍色
    static let night = Color(red: 0.5, green: 0.5, blue: 0.7)       // 紫色
    static let customTeal = Color(red: 0.2, green: 0.6, blue: 0.6)  // 水鴨藍
} 
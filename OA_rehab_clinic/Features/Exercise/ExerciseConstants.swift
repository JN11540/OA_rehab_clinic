import SwiftUI

// MARK: - Constants
public enum ExerciseConstants {
    public enum Layout {
        public static let cardWidth: CGFloat = 200
        public static let cardImageHeight: CGFloat = 120
        public static let cardCornerRadius: CGFloat = 12
        public static let defaultSpacing: CGFloat = 8
        public static let defaultPadding: CGFloat = 16
        public static let englishNameHeight: CGFloat = 20
        public static let parametersHeight: CGFloat = 50
    }
    
    public enum Limits {
        public static let maxExercisesPerMenu = 4
    }
    
    public enum Colors {
        public static let dropZoneActive = Color.blue.opacity(0.1)
        public static let dropZoneInactive = Color(UIColor.systemGray6)
        public static let buttonDisabled = Color(UIColor.systemGray4)
        public static let cardBackground = Color(UIColor.systemBackground)
        public static let textPrimary = Color(UIColor.label)
        public static let textSecondary = Color(UIColor.secondaryLabel)
        public static let divider = Color(UIColor.separator)
        
        public static let menuColors: [Color] = [
            Color(red: 1.0, green: 0.8, blue: 0.4).opacity(0.3),  // 黃色
            Color(red: 1.0, green: 0.6, blue: 0.4).opacity(0.3),  // 橙色
            Color(red: 0.4, green: 0.6, blue: 1.0).opacity(0.3),  // 藍色
            Color(red: 0.5, green: 0.5, blue: 0.7).opacity(0.3),  // 紫色
            Color(red: 0.4, green: 0.8, blue: 0.4).opacity(0.3),  // 綠色
            Color(red: 1.0, green: 0.4, blue: 0.4).opacity(0.3),  // 紅色
            Color(red: 0.4, green: 0.8, blue: 0.8).opacity(0.3),  // 青色
            Color(red: 0.8, green: 0.4, blue: 0.8).opacity(0.3),  // 粉紫色
            Color(red: 0.6, green: 0.4, blue: 0.2).opacity(0.3),  // 棕色
            Color(red: 0.5, green: 0.5, blue: 0.5).opacity(0.3)   // 灰色
        ]
    }
} 
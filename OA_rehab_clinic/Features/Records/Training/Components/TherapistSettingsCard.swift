import SwiftUI

/**
 * TherapistSettingsCard.swift - 治療師設定參數顯示組件
 * 
 * 功能：
 * - 顯示治療師為特定動作設定的所有參數
 * - 智能顯示：根據動作類型只顯示相關參數
 * - 美觀的卡片式設計，用於訓練表現視圖頂部
 */

struct TherapistSettingsCard: View {
    let settings: TherapistSettings
    let exerciseType: SupportedExerciseType
    let displayMode: DisplayMode
    
    enum DisplayMode {
        case full    // 完整模式：顯示標題、圖標、完整卡片樣式
        case compact // 緊湊模式：簡化標題、更小間距、適合嵌入其他視圖
    }
    
    // 為了保持向後兼容，提供預設為full模式的初始化方法
    init(settings: TherapistSettings, exerciseType: SupportedExerciseType, displayMode: DisplayMode = .full) {
        self.settings = settings
        self.exerciseType = exerciseType
        self.displayMode = displayMode
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: displayMode == .full ? 16 : 8) {
            // 標題（compact模式簡化）
            if displayMode == .full {
                fullModeHeader
            } else {
                compactModeHeader
            }
            
            // 參數網格
            LazyVGrid(
                columns: createAdaptiveColumns(),
                spacing: displayMode == .full ? 12 : 8
            ) {
                ForEach(settings.displayParameters, id: \.label) { parameter in
                    ParameterItemView(
                        parameter: parameter,
                        displayMode: displayMode == .full ? .full : .compact
                    )
                }
            }
        }
        .padding(displayMode == .full ? 20 : 12)
        .background(Color.white)
        .cornerRadius(displayMode == .full ? 16 : 12)
        .shadow(
            color: Color.black.opacity(displayMode == .full ? 0.08 : 0.05),
            radius: displayMode == .full ? 8 : 4,
            x: 0,
            y: displayMode == .full ? 4 : 2
        )
    }
    
    // MARK: - 子視圖
    
    @ViewBuilder
    private var fullModeHeader: some View {
        HStack {
            Image(systemName: "gearshape.2.fill")
                .foregroundColor(.blue)
                .font(.title2)
            
            Text("治療師設定參數")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            Spacer()
            
            // 動作名稱標籤
            Text(settings.exerciseName)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.blue)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
        }
    }
    
    @ViewBuilder
    private var compactModeHeader: some View {
        HStack {
            Image(systemName: "gearshape.fill")
                .foregroundColor(.blue)
                .font(.subheadline)
            
            Text("設定參數")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            Spacer()
            
            // 簡化的動作標籤
            Text(settings.exerciseName)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.blue)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(6)
        }
    }
    
    // 創建自適應網格列
    private func createAdaptiveColumns() -> [GridItem] {
        let parameterCount = settings.displayParameters.count
        let columnCount = min(4, max(2, parameterCount)) // 2-4列
        return Array(repeating: GridItem(.flexible(), spacing: 8), count: columnCount)
    }
}

// MARK: - 參數項目視圖

struct ParameterItemView: View {
    let parameter: ParameterDisplayItem
    let displayMode: TherapistSettingsCard.DisplayMode
    
    init(parameter: ParameterDisplayItem, displayMode: TherapistSettingsCard.DisplayMode = .full) {
        self.parameter = parameter
        self.displayMode = displayMode
    }
    
    var body: some View {
        if displayMode == .full {
            fullModeView
        } else {
            compactModeView
        }
    }
    
    @ViewBuilder
    private var fullModeView: some View {
        VStack(spacing: 8) {
            // 圖標和數值
            HStack(spacing: 6) {
                Image(systemName: parameter.icon)
                    .foregroundColor(parameter.color)
                    .font(.system(size: 16, weight: .semibold))
                    .frame(width: 20)
                
                Text(parameter.value)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                Spacer(minLength: 0)
            }
            
            // 標籤
            HStack {
                Text(parameter.label)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                Spacer(minLength: 0)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(parameter.color.opacity(0.08))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(parameter.color.opacity(0.2), lineWidth: 1)
        )
    }
    
    @ViewBuilder
    private var compactModeView: some View {
        HStack(spacing: 6) {
            // 簡化圖標
            Image(systemName: parameter.icon)
                .foregroundColor(parameter.color)
                .font(.system(size: 12, weight: .semibold))
                .frame(width: 14)
            
            // 標籤
            Text(parameter.label)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.secondary)
                .lineLimit(1)
            
            Spacer(minLength: 2)
            
            // 數值
            Text(parameter.value)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.primary)
                .lineLimit(1)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(parameter.color.opacity(0.06))
        .cornerRadius(6)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(parameter.color.opacity(0.15), lineWidth: 0.5)
        )
    }
}


// MARK: - 純文字版本（用於空間受限區域）

struct TextOnlyParameterView: View {
    let settings: TherapistSettings
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // 標題
            Text("治療師參數")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .fontWeight(.medium)
            
            // 參數內容
            HStack(spacing: 12) {
                Text(compactTextDescription)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false) // 允許橫向擴展避免截斷
                
                // 電刺激圖標（如果啟用）
                if settings.stimulation {
                    Image(systemName: "bolt.fill")
                        .font(.caption)
                        .foregroundColor(.yellow)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 2)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
    
    private var compactTextDescription: String {
        var components: [String] = []
        
        // 基本參數：組數 × 次數
        components.append("\(settings.sets)組 × \(settings.repetitions)次")
        
        // 休息時間
        components.append("休息\(settings.restTime)s")
        
        // 維持時間（如果有）
        if let maintainTime = settings.maintainTime {
            components.append("維持\(maintainTime)s")
        }
        
        // 角度參數（如果有）
        if let kneeStart = settings.kneeAngleStart, let kneeEnd = settings.kneeAngleEnd {
            components.append("膝\(kneeStart)°-\(kneeEnd)°")
        }
        
        if let hipStart = settings.hipAngleStart, let hipEnd = settings.hipAngleEnd {
            components.append("髖\(hipStart)°-\(hipEnd)°")
        }
        
        // 重量（如果有）
        if let weight = settings.weight, weight > 0 {
            components.append("\(String(format: "%.1f", weight))kg")
        }
        
        // MVIC（如果有）
        if let mvic = settings.mvic {
            components.append("MVIC\(mvic)%")
        }
        
        return components.joined(separator: " • ")
    }
}



// MARK: - Preview

struct TherapistSettingsCard_Previews: PreviewProvider {
    static var previews: some View {
        Text("TherapistSettingsCard Preview")
            .padding()
    }
}
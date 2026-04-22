import SwiftUI
import UIKit

/**
 * ExerciseToggleGrid.swift - 動作選擇Toggle網格組件
 * 
 * 功能：
 * - 顯示單日訓練中的所有動作
 * - 支援單選Toggle模式
 * - 自適應網格布局（最多2列）
 * - 清楚的選中狀態視覺回饋
 * - 支援動作圖片和名稱顯示
 */

struct ExerciseToggleGrid: View {
    let exercises: [ExerciseToggleItem]
    @Binding var selectedExerciseId: String?
    
    // 自適應列數（最多2列，適合iPad橫屏）
    private var gridColumns: [GridItem] {
        let columnCount = min(exercises.count, 2)
        return Array(repeating: GridItem(.flexible(), spacing: 12), count: columnCount)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 標題
            HStack {
                Image(systemName: "list.bullet.rectangle")
                    .foregroundColor(.blue)
                    .font(.title3)
                
                Text("動作選擇")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                // 選中指示
                if selectedExerciseId != nil {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 8, height: 8)
                        
                        Text("已選擇")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
            }
            
            // 動作網格或空狀態
            if !exercises.isEmpty {
                LazyVGrid(columns: gridColumns, spacing: 12) {
                    ForEach(exercises, id: \.id) { exercise in
                        ExerciseToggleCard(
                            exercise: exercise,
                            isSelected: selectedExerciseId == exercise.id,
                            onTap: {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    if selectedExerciseId == exercise.id {
                                        selectedExerciseId = nil // 再次點擊取消選擇
                                    } else {
                                        selectedExerciseId = exercise.id
                                    }
                                }
                            }
                        )
                    }
                }
            } else {
                // 空狀態提示
                VStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.title2)
                        .foregroundColor(.orange)
                    
                    Text("暫無動作數據")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(height: 80)
                .frame(maxWidth: .infinity)
                .background(Color.orange.opacity(0.05))
                .cornerRadius(8)
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        .onAppear {
            // 組件初始化完成
        }
        .onChange(of: exercises.count) { count in
            // 動作數量變化時，組件會自動更新
        }
    }
}

/**
 * ExerciseToggleItem - 動作Toggle項目數據模型
 */
struct ExerciseToggleItem: Identifiable, Equatable {
    let id: String
    let name: String
    let englishName: String
    let imageName: String?
    let hasData: Bool // 是否有訓練數據
    
    init(id: String, name: String, englishName: String = "", imageName: String? = nil, hasData: Bool = true) {
        self.id = id
        self.name = name
        self.englishName = englishName
        self.imageName = imageName
        self.hasData = hasData
    }
}

/**
 * ExerciseToggleCard - 單個動作Toggle卡片
 */
struct ExerciseToggleCard: View {
    let exercise: ExerciseToggleItem
    let isSelected: Bool
    let onTap: () -> Void
    
    private var borderColor: Color {
        if isSelected {
            return .blue
        } else if exercise.hasData {
            return .gray.opacity(0.3)
        } else {
            return .orange.opacity(0.5)
        }
    }
    
    private var backgroundColor: Color {
        if isSelected {
            return .blue.opacity(0.08)
        } else if !exercise.hasData {
            return .orange.opacity(0.05)
        } else {
            return .white
        }
    }
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                // 動作圖片或佔位符
                Group {
                    if let imageName = exercise.imageName,
                       let image = UIImage(named: imageName) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                    } else {
                        // 佔位符圖標
                        Circle()
                            .fill(Color.gray.opacity(0.2))
                            .overlay(
                                Image(systemName: "figure.strengthtraining.traditional")
                                    .foregroundColor(.gray)
                                    .font(.title2)
                            )
                    }
                }
                .frame(height: 60)
                .cornerRadius(8)
                
                // 動作名稱
                VStack(spacing: 2) {
                    Text(exercise.name)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                    
                    if !exercise.englishName.isEmpty {
                        Text(exercise.englishName)
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .lineLimit(1)
                    }
                }
                
                // 數據狀態指示
                HStack(spacing: 4) {
                    Circle()
                        .fill(exercise.hasData ? .green : .orange)
                        .frame(width: 6, height: 6)
                    
                    Text(exercise.hasData ? "有數據" : "無數據")
                        .font(.system(size: 10))
                        .foregroundColor(exercise.hasData ? .green : .orange)
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity)
            .frame(height: 140)
            .background(backgroundColor)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(borderColor, lineWidth: isSelected ? 2 : 1)
            )
            .cornerRadius(12)
            .scaleEffect(isSelected ? 1.02 : 1.0)
            .shadow(color: isSelected ? .blue.opacity(0.3) : .black.opacity(0.05), 
                   radius: isSelected ? 4 : 2, 
                   x: 0, 
                   y: isSelected ? 2 : 1)
        }
        .buttonStyle(PlainButtonStyle())
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

// MARK: - Preview

#Preview("多個動作") {
    let exercises = [
        ExerciseToggleItem(
            id: "1",
            name: "股四頭肌終端伸展",
            englishName: "Terminal Knee Extension",
            imageName: "2",
            hasData: true
        ),
        ExerciseToggleItem(
            id: "2", 
            name: "部分蹲",
            englishName: "Partial Squat",
            imageName: "9",
            hasData: true
        ),
        ExerciseToggleItem(
            id: "3",
            name: "登階運動",
            englishName: "Step Training", 
            imageName: "12",
            hasData: false
        ),
        ExerciseToggleItem(
            id: "4",
            name: "橋式",
            englishName: "Bridge",
            imageName: "10",
            hasData: true
        )
    ]
    
    @State var selectedId: String? = "1"
    
    return ExerciseToggleGrid(
        exercises: exercises,
        selectedExerciseId: $selectedId
    )
    .padding()
    .background(Color.gray.opacity(0.1))
}

#Preview("兩個動作") {
    let exercises = [
        ExerciseToggleItem(
            id: "1",
            name: "股四頭肌終端伸展",
            englishName: "Terminal Knee Extension",
            hasData: true
        ),
        ExerciseToggleItem(
            id: "2",
            name: "部分蹲", 
            englishName: "Partial Squat",
            hasData: false
        )
    ]
    
    @State var selectedId: String? = nil
    
    return ExerciseToggleGrid(
        exercises: exercises,
        selectedExerciseId: $selectedId
    )
    .padding()
    .background(Color.gray.opacity(0.1))
}
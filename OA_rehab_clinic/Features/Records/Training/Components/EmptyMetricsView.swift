import SwiftUI

/**
 * EmptyMetricsView.swift - 統一的空白指標視圖組件
 * 
 * 功能：
 * - 為所有動作提供一致的空數據狀態展示
 * - 支援自定義指標配置
 * - 可重用於 DetailedPerformanceView 和 EmptyChartsView
 * - 保持視覺風格統一
 */

struct EmptyMetricsView: View {
    let exerciseName: String
    let metrics: [MetricConfig]
    let showTitle: Bool
    
    init(exerciseName: String, metrics: [MetricConfig], showTitle: Bool = true) {
        self.exerciseName = exerciseName
        self.metrics = metrics
        self.showTitle = showTitle
    }
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: true) {
            VStack(spacing: 16) {
                // 數據狀態提示
                HStack {
                    Spacer()
                    Text("尚無數據")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(6)
                }
                .padding(.horizontal)
                
                // 指標圖表
                VStack(alignment: .leading, spacing: 12) {
                    if showTitle {
                        Text("表現指標結構")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .padding(.horizontal)
                    }
                    
                    VStack(spacing: 16) {
                        ForEach(metrics, id: \.id) { metric in
                            PerformanceChartCard(
                                title: metric.title,
                                data: [], // 空數據
                                color: metric.color,
                                unit: metric.unit,
                                isLowerBetter: metric.isLowerBetter
                            )
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.bottom, 20)
        }
    }
}

/**
 * MetricConfig - 指標配置結構
 */
struct MetricConfig: Identifiable {
    let id = UUID()
    let title: String
    let color: Color
    let unit: String
    let isLowerBetter: Bool
    
    init(title: String, color: Color, unit: String, isLowerBetter: Bool = false) {
        self.title = title
        self.color = color
        self.unit = unit
        self.isLowerBetter = isLowerBetter
    }
}

// MARK: - 預定義指標配置

extension MetricConfig {
    
    /**
     * 五個核心指標 - 用於三個重點動作
     */
    static let coreMetrics: [MetricConfig] = [
        MetricConfig(title: "肌力", color: .red, unit: "分"),
        MetricConfig(title: "穩定度", color: .blue, unit: "分"),
        MetricConfig(title: "規律性", color: .green, unit: "分"),
        MetricConfig(title: "反應時間", color: .orange, unit: "分"),
        MetricConfig(title: "完成度", color: .purple, unit: "分")
    ]

    static let allSevenMetrics: [MetricConfig] = [
        MetricConfig(title: "肌力",   color: .red,    unit: "分"),
        MetricConfig(title: "穩定度", color: .blue,   unit: "分"),
        MetricConfig(title: "規律性", color: .green,  unit: "分"),
        MetricConfig(title: "反應時間", color: .orange, unit: "分"),
        MetricConfig(title: "完成度", color: .purple, unit: "分"),
        MetricConfig(title: "柔軟度", color: .mint,   unit: "分"),
        MetricConfig(title: "平衡性", color: .indigo, unit: "分")
    ]
    
    /**
     * 根據動作名稱獲取對應的指標配置
     * 這個方法會尋找 AllExerciseType 對應的配置，如果找不到則使用基本配置
     */
    static func metricsForExercise(_ exerciseName: String) -> [MetricConfig] {
        // 先嘗試找到對應的動作配置
        if let metrics = findExerciseType(by: exerciseName) {
            return metrics
        }
        
        // 如果找不到，根據動作名稱提供基本配置
        return getBasicMetricsForExercise(exerciseName)
    }
    
    /**
     * 嘗試通過動作名稱找到對應的動作配置
     */
    private static func findExerciseType(by exerciseName: String) -> [MetricConfig]? {
        // 定義所有動作類型和它們的指標
        let exerciseConfigs: [String: [MetricConfig]] = [
            // 股四頭肌肌力訓練 - 初階
            "股四頭肌等長收縮": [
                MetricConfig(title: "肌力", color: .red, unit: "分"),
                MetricConfig(title: "穩定度", color: .blue, unit: "分"),
                MetricConfig(title: "完成度", color: .purple, unit: "分"),
                MetricConfig(title: "反應時間", color: .orange, unit: "秒", isLowerBetter: true)
            ],
            "膝關節終端伸展": coreMetrics,
            "股四頭肌終端伸展": coreMetrics,
            "躺姿抬腿": [
                MetricConfig(title: "肌力", color: .red, unit: "分"),
                MetricConfig(title: "穩定度", color: .blue, unit: "分"),
                MetricConfig(title: "完成度", color: .purple, unit: "分")
            ],
            "俯臥抬腿": [
                MetricConfig(title: "肌力", color: .red, unit: "分"),
                MetricConfig(title: "穩定度", color: .blue, unit: "分"),
                MetricConfig(title: "完成度", color: .purple, unit: "分")
            ],
            "側躺抬腿（外展）": [
                MetricConfig(title: "肌力", color: .red, unit: "分"),
                MetricConfig(title: "穩定度", color: .blue, unit: "分"),
                MetricConfig(title: "完成度", color: .purple, unit: "分")
            ],
            "側躺抬腿（內收）": [
                MetricConfig(title: "肌力", color: .red, unit: "分"),
                MetricConfig(title: "穩定度", color: .blue, unit: "分"),
                MetricConfig(title: "完成度", color: .purple, unit: "分")
            ],
            
            // 股四頭肌肌力訓練 - 中階
            "負重膝關節終端伸展": coreMetrics,
            "站立膝關節終端伸展": [
                MetricConfig(title: "肌力", color: .red, unit: "分"),
                MetricConfig(title: "穩定度", color: .blue, unit: "分"),
                MetricConfig(title: "規律性", color: .green, unit: "分"),
                MetricConfig(title: "完成度", color: .purple, unit: "分")
            ],
            "部分蹲": coreMetrics,
            "橋式": [
                MetricConfig(title: "肌力", color: .red, unit: "分"),
                MetricConfig(title: "穩定度", color: .blue, unit: "分"),
                MetricConfig(title: "完成度", color: .purple, unit: "分"),
                MetricConfig(title: "反應時間", color: .orange, unit: "秒", isLowerBetter: true)
            ],
            "大腿內夾運動": [
                MetricConfig(title: "肌力", color: .red, unit: "分"),
                MetricConfig(title: "穩定度", color: .blue, unit: "分"),
                MetricConfig(title: "完成度", color: .purple, unit: "分")
            ],
            
            // 股四頭肌肌力訓練 - 高階
            "登階運動": coreMetrics,
            "靠牆深蹲": coreMetrics,
            
            // 柔軟度訓練
            "大腿後側肌群伸展（一）": [
                MetricConfig(title: "柔軟度", color: .mint, unit: "分"),
                MetricConfig(title: "完成度", color: .purple, unit: "分"),
                MetricConfig(title: "反應時間", color: .orange, unit: "秒", isLowerBetter: true)
            ],
            "大腿後側肌群伸展（二）": [
                MetricConfig(title: "柔軟度", color: .mint, unit: "分"),
                MetricConfig(title: "完成度", color: .purple, unit: "分"),
                MetricConfig(title: "反應時間", color: .orange, unit: "秒", isLowerBetter: true)
            ],
            "股四頭肌伸展（一）": [
                MetricConfig(title: "柔軟度", color: .mint, unit: "分"),
                MetricConfig(title: "完成度", color: .purple, unit: "分"),
                MetricConfig(title: "反應時間", color: .orange, unit: "秒", isLowerBetter: true)
            ],
            "股四頭肌伸展（二）": [
                MetricConfig(title: "柔軟度", color: .mint, unit: "分"),
                MetricConfig(title: "完成度", color: .purple, unit: "分"),
                MetricConfig(title: "反應時間", color: .orange, unit: "秒", isLowerBetter: true)
            ],
            "小腿後肌肉伸展（一）": [
                MetricConfig(title: "柔軟度", color: .mint, unit: "分"),
                MetricConfig(title: "完成度", color: .purple, unit: "分")
            ],
            "小腿後肌肉伸展（二）": [
                MetricConfig(title: "柔軟度", color: .mint, unit: "分"),
                MetricConfig(title: "完成度", color: .purple, unit: "分")
            ],
            
            // 膝關節本體感覺訓練
            "前後滑行運動": [
                MetricConfig(title: "穩定度", color: .blue, unit: "分"),
                MetricConfig(title: "規律性", color: .green, unit: "分"),
                MetricConfig(title: "反應時間", color: .orange, unit: "分"),
                MetricConfig(title: "完成度", color: .purple, unit: "分"),
                MetricConfig(title: "平衡性", color: .indigo, unit: "分")
            ],
            "側向滑行運動": [
                MetricConfig(title: "穩定度", color: .blue, unit: "分"),
                MetricConfig(title: "規律性", color: .green, unit: "分"),
                MetricConfig(title: "反應時間", color: .orange, unit: "分"),
                MetricConfig(title: "完成度", color: .purple, unit: "分"),
                MetricConfig(title: "平衡性", color: .indigo, unit: "分")
            ],
            "前跨步弓步蹲": [
                MetricConfig(title: "肌力", color: .red, unit: "分"),
                MetricConfig(title: "穩定度", color: .blue, unit: "分"),
                MetricConfig(title: "平衡性", color: .indigo, unit: "分"),
                MetricConfig(title: "反應時間", color: .orange, unit: "分"),
                MetricConfig(title: "完成度", color: .purple, unit: "分")
            ]
        ]
        
        // 尋找完全匹配的動作名稱
        if let metrics = exerciseConfigs[exerciseName] {
            return metrics
        }
        
        // 嘗試部分匹配
        for (key, metrics) in exerciseConfigs {
            if exerciseName.contains(key) || key.contains(exerciseName.trimmingCharacters(in: .whitespacesAndNewlines)) {
                return metrics
            }
        }
        
        return nil
    }
    
    /**
     * 當找不到特定配置時的基本指標
     */
    private static func getBasicMetricsForExercise(_ exerciseName: String) -> [MetricConfig] {
        // 根據動作名稱推測類型
        if exerciseName.contains("伸展") || exerciseName.contains("柔軟") {
            return [
                MetricConfig(title: "柔軟度", color: .mint, unit: "分"),
                MetricConfig(title: "完成度", color: .purple, unit: "分")
            ]
        } else if exerciseName.contains("滑行") || exerciseName.contains("平衡") || exerciseName.contains("本體") {
            return [
                MetricConfig(title: "穩定度", color: .blue, unit: "分"),
                MetricConfig(title: "平衡性", color: .indigo, unit: "分"),
                MetricConfig(title: "完成度", color: .purple, unit: "分")
            ]
        } else {
            // 預設的肌力訓練指標
            return [
                MetricConfig(title: "肌力", color: .red, unit: "分"),
                MetricConfig(title: "穩定度", color: .blue, unit: "分"),
                MetricConfig(title: "完成度", color: .purple, unit: "分")
            ]
        }
    }
}

// MARK: - Preview

#Preview("Core Metrics") {
    EmptyMetricsView(
        exerciseName: "股四頭肌終端伸展",
        metrics: MetricConfig.coreMetrics
    )
    .frame(width: 500, height: 600)
    .background(Color.gray.opacity(0.1))
}

#Preview("Flexibility Metrics") {
    EmptyMetricsView(
        exerciseName: "大腿後側肌群伸展",
        metrics: MetricConfig.metricsForExercise("大腿後側肌群伸展（一）")
    )
    .frame(width: 500, height: 400)
    .background(Color.gray.opacity(0.1))
}
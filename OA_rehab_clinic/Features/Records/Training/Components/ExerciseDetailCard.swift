import SwiftUI

/**
 * ExerciseDetailCard.swift - 動作詳細資訊卡片組件
 * 
 * 功能：
 * - 折疊式設計：預設顯示治療師設定參數
 * - 展開後顯示該動作的表現指標分析
 * - 支援不同動作的指標配置（3-5個指標）
 * - 優雅的展開/折疊動畫效果
 * - 整合數據源和空狀態處理
 */

struct ExerciseDetailCard: View {
    let exerciseId: String
    let exerciseName: String
    let therapistSettings: TherapistSettings?
    let metricsData: [MetricData]?
    @State private var isExpanded: Bool = false
    
    private var exerciseMetrics: [MetricConfig] {
        MetricConfig.metricsForExercise(exerciseName)
    }
    
    private var hasData: Bool {
        metricsData != nil && !metricsData!.isEmpty
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 頭部：動作名稱和展開按鈕
            headerSection
            
            // 治療師設定（總是顯示）
            if let settings = therapistSettings {
                therapistSettingsSection(settings)
            }
            
            // 展開的表現指標區域
            if isExpanded {
                metricsSection
            }
        }
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
    }
    
    // MARK: - 子視圖
    
    @ViewBuilder
    private var headerSection: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.3)) {
                isExpanded.toggle()
            }
        }) {
            HStack {
                // 動作資訊
                VStack(alignment: .leading, spacing: 4) {
                    Text(exerciseName)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                    
                    HStack(spacing: 8) {
                        // 數據狀態指示
                        Circle()
                            .fill(hasData ? .green : .orange)
                            .frame(width: 8, height: 8)
                        
                        Text(hasData ? "有表現數據" : "無表現數據")
                            .font(.caption)
                            .foregroundColor(hasData ? .green : .orange)
                        
                        if !exerciseMetrics.isEmpty {
                            Text("・")
                                .foregroundColor(.secondary)
                                .font(.caption)
                            
                            Text("\(exerciseMetrics.count)個指標")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Spacer()
                
                // 展開/折疊指示
                VStack(spacing: 4) {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.blue)
                        .font(.system(size: 16, weight: .semibold))
                    
                    Text(isExpanded ? "收起" : "展開")
                        .font(.caption2)
                        .foregroundColor(.blue)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    @ViewBuilder
    private func therapistSettingsSection(_ settings: TherapistSettings) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // 分隔線
            Divider()
                .padding(.horizontal, 20)
            
            // 緊湊版治療師設定
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "gearshape.fill")
                        .foregroundColor(.blue)
                        .font(.subheadline)
                    
                    Text("治療師設定")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Spacer()
                }
                
                // 參數網格（緊湊模式）
                LazyVGrid(
                    columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ],
                    spacing: 8
                ) {
                    ForEach(settings.displayParameters.prefix(6), id: \.label) { parameter in
                        CompactParameterView(parameter: parameter)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 16)
        }
    }
    
    @ViewBuilder
    private var metricsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 分隔線
            Divider()
                .padding(.horizontal, 20)
            
            // 表現指標標題
            HStack {
                Image(systemName: "chart.bar.fill")
                    .foregroundColor(.green)
                    .font(.subheadline)
                
                Text("表現指標")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                if !hasData {
                    Text("模擬數據")
                        .font(.caption)
                        .foregroundColor(.orange)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(6)
                }
            }
            .padding(.horizontal, 20)
            
            // 指標內容
            if hasData, let metrics = metricsData {
                // 有真實數據：顯示實際指標
                realMetricsView(metrics)
            } else {
                // 無數據：顯示指標結構
                emptyMetricsView
            }
        }
        .padding(.bottom, 20)
    }
    
    @ViewBuilder
    private func realMetricsView(_ metrics: [MetricData]) -> some View {
        LazyVGrid(
            columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ],
            spacing: 12
        ) {
            ForEach(metrics, id: \.type) { metric in
                MetricItemView(metric: metric)
            }
        }
        .padding(.horizontal, 20)
    }
    
    @ViewBuilder
    private var emptyMetricsView: some View {
        LazyVGrid(
            columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ],
            spacing: 12
        ) {
            ForEach(exerciseMetrics, id: \.title) { metricConfig in
                EmptyMetricItemView(config: metricConfig)
            }
        }
        .padding(.horizontal, 20)
    }
}

// MARK: - 輔助組件

/**
 * CompactParameterView - 緊湊參數顯示組件
 */
struct CompactParameterView: View {
    let parameter: ParameterDisplayItem
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: parameter.icon)
                .foregroundColor(parameter.color)
                .font(.system(size: 12, weight: .semibold))
                .frame(width: 16)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(parameter.label)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                Text(parameter.value)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.primary)
                    .lineLimit(1)
            }
            
            Spacer()
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(parameter.color.opacity(0.06))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(parameter.color.opacity(0.15), lineWidth: 0.5)
        )
    }
}

/**
 * MetricItemView - 表現指標項目顯示組件
 */
struct MetricItemView: View {
    let metric: MetricData
    
    private var scoreColor: Color {
        switch metric.score {
        case 0..<40:
            return .red
        case 40..<70:
            return .orange
        case 70..<85:
            return .yellow
        case 85...100:
            return .green
        default:
            return .gray
        }
    }
    
    private var scoreGrade: String {
        switch metric.score {
        case 0..<40:
            return "待改善"
        case 40..<70:
            return "普通"
        case 70..<85:
            return "良好"
        case 85...100:
            return "優秀"
        default:
            return "無評級"
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 指標名稱和分數
            HStack {
                Text(metric.type)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text("\(Int(metric.score))")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(scoreColor)
            }
            
            // 進度條
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // 背景
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 6)
                    
                    // 進度
                    RoundedRectangle(cornerRadius: 3)
                        .fill(scoreColor)
                        .frame(width: geometry.size.width * (metric.score / 100), height: 6)
                }
            }
            .frame(height: 6)
            
            // 評級
            Text(scoreGrade)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(scoreColor)
        }
        .padding(12)
        .background(Color.white)
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(scoreColor.opacity(0.3), lineWidth: 1)
        )
    }
}

/**
 * EmptyMetricItemView - 空指標項目顯示組件
 */
struct EmptyMetricItemView: View {
    let config: MetricConfig
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 指標名稱
            HStack {
                Text(config.title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text("--")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.gray)
            }
            
            // 空進度條
            RoundedRectangle(cornerRadius: 3)
                .fill(Color.gray.opacity(0.15))
                .frame(height: 6)
            
            // 無數據提示
            Text("等待數據")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.gray)
        }
        .padding(12)
        .background(Color.gray.opacity(0.03))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - 數據模型

/**
 * MetricData - 表現指標數據
 */
struct MetricData {
    let type: String      // 指標類型（如"肌力"、"穩定度"）
    let score: Double     // 分數 (0-100)
    let unit: String      // 單位
    let timestamp: Date   // 測量時間
}

// MARK: - Preview

#Preview("有數據") {
    let settings = TherapistSettings(
        exerciseName: "股四頭肌終端伸展",
        sets: 3,
        repetitions: 10,
        restTime: 30,
        mvic: 60,
        maintainTime: 5,
        kneeAngleStart: 0,
        kneeAngleEnd: 90
    )
    
    let metrics = [
        MetricData(type: "肌力", score: 85, unit: "分", timestamp: Date()),
        MetricData(type: "穩定度", score: 72, unit: "分", timestamp: Date()),
        MetricData(type: "規律性", score: 68, unit: "分", timestamp: Date()),
        MetricData(type: "完成度", score: 92, unit: "%", timestamp: Date())
    ]
    
    return ExerciseDetailCard(
        exerciseId: "1",
        exerciseName: "股四頭肌終端伸展",
        therapistSettings: settings,
        metricsData: metrics
    )
    .padding()
    .background(Color.gray.opacity(0.1))
}

#Preview("無數據") {
    let settings = TherapistSettings(
        exerciseName: "部分蹲",
        sets: 3,
        repetitions: 15,
        restTime: 45
    )
    
    return ExerciseDetailCard(
        exerciseId: "2",
        exerciseName: "部分蹲",
        therapistSettings: settings,
        metricsData: nil
    )
    .padding()
    .background(Color.gray.opacity(0.1))
}
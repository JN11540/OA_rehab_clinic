import SwiftUI
import Charts
import Foundation

/**
 * PerformanceChangeView.swift - 訓練表現變化趨勢圖表視圖
 * 
 * 功能：
 * - 左側：運動項目列表，支援依類別篩選
 * - 右側：選中運動的表現變化圖表
 * - 支援多種時間範圍（一週/一月/三月）
 * - 顯示運動的中文名稱和英文名稱
 * - 智能切換：支援動作顯示詳細分析視圖
 * 
 * 重構說明：
 * 從 TrainingContentViews.swift 中提取的 PerformanceChangeContent
 * 重命名為 PerformanceChangeView 以保持命名一致性
 * 新增：整合詳細分析視圖以支援三個重點動作的詳細分析
 */

enum DateRange {
    case week
    case month
    case threeMonths
    case sixMonths
    
    var title: String {
        switch self {
        case .week: return "過去一週"
        case .month: return "過去一個月"
        case .threeMonths: return "過去三個月"
        case .sixMonths: return "過去六個月"
        }
    }
    
    var days: Int {
        switch self {
        case .week: return 7
        case .month: return 30
        case .threeMonths: return 90
        case .sixMonths: return 180
        }
    }
}

struct PerformanceChangeView: View {
    let patient: Patient
    @StateObject private var recordStore = RecordStore.shared
    @State private var selectedCategory: ExerciseModule.TrainingCategory = .all
    @State private var selectedExercise: ExerciseModule.Exercise?
    @State private var dateRange: DateRange = .week
    @State private var records: [TrainingRecord.ExerciseRecord] = []
    
    var body: some View {
        HStack(spacing: 0) {
            // 左側運動列表
            ExerciseListCard(
                selectedCategory: $selectedCategory,
                selectedExercise: selectedExercise,
                onExerciseSelected: { exercise in
                    selectedExercise = exercise
                    updateRecords()
                }
            )
            .frame(width: 240)
            
            // 分隔線
            Divider()
                .background(Color.gray.opacity(0.2))
            
            // 右側圖表區域
            VStack(alignment: .leading, spacing: 0) {
                // 上方固定資訊區
                VStack(spacing: 12) {
                    // 動作資訊 + 治療師參數 + 時間選擇器
                    HStack(alignment: .center, spacing: 16) {
                        // 動作資訊
                        VStack(alignment: .leading, spacing: 4) {
                            Text("動作名稱")
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                            if let exercise = selectedExercise {
                                Text(exercise.name)
                                    .font(.headline)
                                Text(exercise.englishName)
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            } else {
                                Text("請選擇動作")
                                    .font(.headline)
                                    .foregroundColor(.gray)
                            }
                        }

                        Spacer()

                        // 時間選擇器
                        Menu {
                            ForEach([DateRange.week, .month, .threeMonths, .sixMonths], id: \.self) { range in
                                Button(range.title) {
                                    dateRange = range
                                    updateRecords()
                                }
                            }
                        } label: {
                            HStack {
                                Text(dateRange.title)
                                    .frame(minWidth: 90, alignment: .leading)
                                Image(systemName: "chevron.down")
                            }
                            .foregroundColor(.gray)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 12)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                            .frame(width: 120)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Color.white)
                
                Divider()
                    .background(Color.gray.opacity(0.2))
                
                // 圖表區域
                VStack(spacing: 12) {
                    if let exercise = selectedExercise {
                        GenericPerformanceChartView(
                            patient: patient,
                            exerciseName: exercise.name,
                            parentDateRange: dateRange
                        )
                    }
                }
                .background(Color.white)
            }
        }
        .background(Color.white)
        .onAppear {
            // 預設選擇第一個動作
            if selectedExercise == nil {
                selectFirstExercise()
            }
        }
        .onChange(of: selectedCategory) { _ in
            // 分類改變時重新選擇第一個動作
            selectFirstExercise()
        }
    }
    
    // MARK: - 預設選擇邏輯
    
    private func selectFirstExercise() {
        let exercises = ExerciseModule.getExercisesForCategory(selectedCategory)
        
        // 找到第一個有動作的分組和子分組
        for section in exercises {
            for subcategory in section.subcategories {
                if let firstExercise = subcategory.exercises.first {
                    selectedExercise = firstExercise
                    updateRecords()
                    return
                }
            }
        }
    }
    
    private func updateRecords() {
        guard let exercise = selectedExercise else { return }
        
        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -dateRange.days, to: endDate) ?? endDate
        
        records = recordStore.getExerciseProgress(
            patientId: patient.id,
            exerciseId: exercise.id.uuidString,
            startDate: startDate,
            endDate: endDate
        )
    }
}

/// 通用表現趨勢圖表視圖 — 支援所有 22 種動作
struct GenericPerformanceChartView: View {
    let patient: Patient
    let exerciseName: String
    let parentDateRange: DateRange

    @StateObject private var dataManager = TrainingDataManager.shared
    @State private var trainingResults: [TrainingVisualizationData] = []

    var body: some View {
        ScrollView(.vertical, showsIndicators: true) {
            VStack(spacing: 16) {
                if !trainingResults.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("表現指標趨勢")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .padding(.horizontal)

                        VStack(spacing: 16) {
                            PerformanceChartCard(
                                title: "肌力",
                                data: trainingResults.map { ($0.date, $0.performance.muscleStrength) },
                                color: .red, unit: "分"
                            )
                            PerformanceChartCard(
                                title: "穩定度",
                                data: trainingResults.map { ($0.date, $0.performance.stability) },
                                color: .blue, unit: "分"
                            )
                            PerformanceChartCard(
                                title: "規律性",
                                data: trainingResults.map { ($0.date, $0.performance.regularity) },
                                color: .green, unit: "分"
                            )
                            PerformanceChartCard(
                                title: "反應時間",
                                data: trainingResults.map { ($0.date, $0.performance.reactionTime) },
                                color: .orange, unit: "分"
                            )
                            PerformanceChartCard(
                                title: "完成度",
                                data: trainingResults.map { ($0.date, $0.performance.completionRate) },
                                color: .purple, unit: "分"
                            )
                        }
                        .padding(.horizontal)
                    }
                } else {
                    EmptyMetricsView(
                        exerciseName: exerciseName,
                        metrics: MetricConfig.coreMetrics,
                        showTitle: true
                    )
                }
            }
            .padding(.bottom, 20)
        }
        .onAppear { updateTrainingResults() }
        .onChange(of: parentDateRange) { _ in updateTrainingResults() }
        .onChange(of: exerciseName) { _ in updateTrainingResults() }
    }

    private func updateTrainingResults() {
        let endDate = Date()
        let startDate = Calendar.current.date(
            byAdding: .day, value: -parentDateRange.days, to: endDate) ?? endDate
        
        print("🔍 exerciseName: '\(exerciseName)'")
        
        trainingResults = dataManager.getTrainingResults(
            for: patient.id,
            exerciseName: exerciseName,
            startDate: startDate,
            endDate: endDate
        )
    }
}

/**
 * PerformanceChart - 訓練表現數據的圖表顯示組件
 * 
 * 功能：
 * - 使用Swift Charts顯示訓練表現變化
 * - 每個訓練紀錄的多組數據為線圖+點圖
 * - Y軸為1-5的表現評分
 */
struct PerformanceChart: View {
    let records: [TrainingRecord.ExerciseRecord]
    
    private var chartData: [(String, Double)] {
        records.flatMap { record in
            record.sets.enumerated().map { index, set in
                ("Set \(index + 1)", Double(set.performance))
            }
        }
    }
    
    var body: some View {
        Chart {
            ForEach(Array(chartData.enumerated()), id: \.offset) { _, data in
                LineMark(
                    x: .value("Set", data.0),
                    y: .value("Performance", data.1)
                )
                .foregroundStyle(.blue)
                
                PointMark(
                    x: .value("Set", data.0),
                    y: .value("Performance", data.1)
                )
                .foregroundStyle(.blue)
            }
        }
        .chartYScale(domain: 1...5)
        .chartYAxis {
            AxisMarks(values: [1, 2, 3, 4, 5])
        }
        .frame(height: 200)
    }
}

// MARK: - Supporting Components
// ParameterTag moved to TherapistSettingsCard.swift for reusability

// MARK: - Preview
#Preview {
    PerformanceChangeView(patient: Patient.sample)
        .environmentObject(RecordStore.shared)
        .frame(width: 1000, height: 600)
        .background(Color.gray.opacity(0.1))
}
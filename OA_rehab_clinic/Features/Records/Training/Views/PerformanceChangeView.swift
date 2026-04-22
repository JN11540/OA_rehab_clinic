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
    
    // 檢查選中的動作是否為支援的詳細分析動作
    private var supportedExerciseType: SupportedExerciseType? {
        guard let exercise = selectedExercise else { return nil }
        return SupportedExerciseType.from(exerciseName: exercise.name)
    }
    
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

                        // 中間：治療師參數（僅支援的動作顯示）
                        if let exerciseType = supportedExerciseType {
                            TextOnlyParameterView(settings: exerciseType.defaultTherapistSettings)
                        }
                        
                        
                        
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
                
                // 圖表區域 - 智能切換到詳細分析視圖或空白圖表
                VStack(spacing: 12) {
                    if let exercise = selectedExercise {
                        if let exerciseType = supportedExerciseType {
                            // 支援的動作：顯示詳細分析視圖
                            DetailedPerformanceView(
                                patient: patient,
                                exerciseType: exerciseType,
                                parentDateRange: dateRange
                            )
                        } else {
                            // 不支援詳細分析的動作：顯示空白圖表
                            EmptyChartsView(
                                exerciseName: exercise.name,
                                dateRange: dateRange
                            )
                        }
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

/**
 * DetailedPerformanceView - 嵌入式詳細表現分析視圖
 * 
 * 功能：
 * - 針對支援的三個動作顯示完整的五指標分析
 * - 嵌入在 PerformanceChangeView 中，不需要導航
 * - 包含滑動窗口控制和治療師參數顯示
 */
struct DetailedPerformanceView: View {
    let patient: Patient
    let exerciseType: SupportedExerciseType
    let parentDateRange: DateRange
    
    @StateObject private var dataManager = TrainingDataManager.shared
    @StateObject private var mockDataManager = RecordsMockDataManager.shared
    @State private var trainingResults: [TrainingVisualizationData] = []
    @State private var isUsingMockData: Bool = false // 穩定的狀態追蹤
    
    // 將父級的 DateRange 轉換為 TrainingDateRange
    private var dateRange: TrainingDateRange {
        switch parentDateRange {
        case .week: return .oneWeek
        case .month: return .oneMonth
        case .threeMonths: return .threeMonths
        case .sixMonths: return .sixMonths
        }
    }
    
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: true) {
            VStack(spacing: 16) {
                // 數據來源指示
                if isUsingMockData {
                    HStack {
                        Spacer()
                        Text("模擬數據")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(6)
                    }
                    .padding(.horizontal)
                }
                
                // 五個表現指標圖表
                if !trainingResults.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("表現指標趨勢")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .padding(.horizontal)
                        
                        VStack(spacing: 16) {
                            // 五個圖表直向排列
                            PerformanceChartCard(
                                title: "肌力",
                                data: trainingResults.map { ($0.date, $0.performance.muscleStrength) },
                                color: exerciseType.colorTheme.strength,
                                unit: "分"
                            )
                            
                            PerformanceChartCard(
                                title: "穩定度",
                                data: trainingResults.map { ($0.date, $0.performance.stability) },
                                color: exerciseType.colorTheme.stability,
                                unit: "分"
                            )
                            
                            PerformanceChartCard(
                                title: "規律性",
                                data: trainingResults.map { ($0.date, $0.performance.regularity) },
                                color: exerciseType.colorTheme.regularity,
                                unit: "分"
                            )
                            
                            PerformanceChartCard(
                                title: "反應時間",
                                data: trainingResults.map { ($0.date, $0.performance.reactionTime) },
                                color: exerciseType.colorTheme.reaction,
                                unit: "分",
                                isLowerBetter: false // 使用標準化分數，越高越好
                            )
                            
                            PerformanceChartCard(
                                title: "完成度",
                                data: trainingResults.map { ($0.date, $0.performance.completionRate) },
                                color: exerciseType.colorTheme.completion,
                                unit: "分"
                            )
                        }
                        .padding(.horizontal)
                    }
                } else {
                    // 統一的空狀態視圖 - 顯示五個核心指標的空白圖表
                    EmptyMetricsView(
                        exerciseName: exerciseType.displayName,
                        metrics: MetricConfig.coreMetrics,
                        showTitle: true
                    )
                }
                
            }
            .padding(.bottom, 20)
        }
        .onAppear {
            // 設置當前患者到全局管理器
            mockDataManager.currentPatient = patient
            updateTrainingResults()
        }
        .onChange(of: parentDateRange) { _ in
            updateTrainingResults()
        }
        .onReceive(NotificationCenter.default.publisher(for: .recordsMockDataSettingChanged)) { _ in
            // 響應全局設置變更
            updateTrainingResults()
        }
    }
    
    // MARK: - 私有方法
    
    /**
     * 穩定的數據更新邏輯
     * 確保 isUsingMockData 狀態與 trainingResults 內容完全同步
     */
    private func updateTrainingResults() {
        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -dateRange.days, to: endDate) ?? endDate
        
        print("🔄 DetailedPerformanceView: 開始更新 \(exerciseType.displayName) 數據，時間範圍: \(dateRange.days) 天")
        
        // 先檢查真實數據
        let realData = dataManager.getTrainingResults(
            for: patient.id,
            exerciseType: exerciseType,
            startDate: startDate,
            endDate: endDate,
            useMockData: false
        )
        
        if !realData.isEmpty {
            // 有真實數據，使用真實數據
            trainingResults = realData
            isUsingMockData = false
            print("✅ DetailedPerformanceView: 使用真實數據 - \(realData.count) 條記錄")
        } else {
            // 沒有真實數據，檢查全局管理器決策
            let shouldUseMock = mockDataManager.shouldUseTrainingMockData()
            if shouldUseMock {
                let mockData = dataManager.getTrainingResults(
                    for: patient.id,
                    exerciseType: exerciseType,
                    startDate: startDate,
                    endDate: endDate,
                    useMockData: true
                )
                trainingResults = mockData
                isUsingMockData = true
                print("🎲 DetailedPerformanceView: 使用模擬數據 - \(mockData.count) 條記錄")
            } else {
                // 全局禁用模擬數據
                trainingResults = []
                isUsingMockData = false
                print("⏹️ DetailedPerformanceView: 全局禁用模擬數據")
            }
        }
        
        // 驗證邏輯一致性
        let hasData = !trainingResults.isEmpty
        let shouldShowMockTag = isUsingMockData
        print("📊 DetailedPerformanceView: 狀態驗證 - hasData: \(hasData), showMockTag: \(shouldShowMockTag)")
        
        if hasData != shouldShowMockTag && hasData {
            print("⚠️ 檢測到狀態不一致：有數據但不顯示模擬標籤")
        }
    }
    
}

/**
 * EmptyChartsView - 顯示空白圖表的視圖組件
 * 
 * 功能：
 * - 根據動作名稱確定應該顯示的指標類型
 * - 使用統一的EmptyMetricsView組件
 * - 保持與DetailedPerformanceView一致的視覺風格
 */
struct EmptyChartsView: View {
    let exerciseName: String
    let dateRange: DateRange
    
    var body: some View {
        EmptyMetricsView(
            exerciseName: exerciseName,
            metrics: MetricConfig.metricsForExercise(exerciseName),
            showTitle: true
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
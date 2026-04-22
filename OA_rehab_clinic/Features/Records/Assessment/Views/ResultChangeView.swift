import SwiftUI
import Charts
import Foundation

/**
 * ResultChangeView.swift - 評量結果變化趨勢圖表視圖
 * 
 * 功能：
 * - 上方：評量類型選擇（全部6種評估類型）和時間範圍選擇
 * - 下方：總分變化趨勢圖和分項趨勢圖
 * - 支援臨床量表的分項切換顯示
 * - 模擬數據展示功能預覽
 * 
 * 更新說明：
 * - 支援 WOMAC、KOOS、SF-36、椅子坐站測試、原地站立抬膝、開眼單足站立
 * - 加入分項趨勢圖切換功能
 * - 整合模擬數據生成器
 */

struct ResultChangeView: View {
    let patient: Patient
    @StateObject private var recordStore = RecordStore.shared
    @StateObject private var mockDataManager = RecordsMockDataManager.shared
    @State private var selectedType: AssessmentType = .womac
    @State private var dateRange: DateRange = .oneMonth
    @State private var records: [AssessmentRecord] = []
    @State private var showSubcategories: Bool = false // 是否顯示分項趨勢
    @State private var cachedMockData: [AssessmentType: [AssessmentRecord]] = [:] // 緩存模擬數據
    
    // 整合全局管理器的評估數據決策
    private var shouldUseMockData: Bool {
        let realData = recordStore.getAssessmentProgress(
            patientId: patient.id,
            type: selectedType,
            startDate: Calendar.current.date(byAdding: .day, value: -dateRange.days, to: Date()) ?? Date(),
            endDate: Date()
        )
        
        // 有真實數據時不使用模擬數據
        if !realData.isEmpty {
            return false
        }
        
        // 沒有真實數據時，使用全局管理器決策
        return mockDataManager.shouldUseAssessmentMockData()
    }
    
    // 評估類型分組
    private let clinicalAssessments: [AssessmentType] = [.womac, .koos, .sf36]
    private let functionalAssessments: [AssessmentType] = [.chairTest, .kneeRaise, .singleLegStand]
    
    // 判斷當前選擇的評估是否為臨床量表
    private var isClinicalAssessment: Bool {
        clinicalAssessments.contains(selectedType)
    }
    
    enum DateRange {
        case oneMonth
        case threeMonths
        case sixMonths
        case oneYear
        
        var title: String {
            switch self {
            case .oneMonth: return "過去一個月"
            case .threeMonths: return "過去三個月"
            case .sixMonths: return "過去六個月"
            case .oneYear: return "過去一年"
            }
        }
        
        var days: Int {
            switch self {
            case .oneMonth: return 30
            case .threeMonths: return 90
            case .sixMonths: return 180
            case .oneYear: return 365
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 上方控制區
            VStack(spacing: 12) {
                // 第一行：評量類型選擇
                HStack {
                    Text("評量類型")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    // 臨床量表
                    HStack(spacing: 8) {
                        ForEach(clinicalAssessments, id: \.self) { type in
                            assessmentTypeButton(type: type)
                        }
                    }
                    
                    Divider()
                        .frame(height: 20)
                    
                    // 功能性評估
                    HStack(spacing: 8) {
                        ForEach(functionalAssessments, id: \.self) { type in
                            assessmentTypeButton(type: type)
                        }
                    }
                }
                
                // 第二行：時間範圍和分項切換
                HStack {
                    // 時間範圍選擇
                    Menu {
                        ForEach([DateRange.oneMonth, .threeMonths, .sixMonths, .oneYear], id: \.self) { range in
                            Button(range.title) {
                                dateRange = range
                                updateRecords()
                            }
                        }
                    } label: {
                        HStack {
                            Text(dateRange.title)
                            Image(systemName: "chevron.down")
                        }
                        .foregroundColor(.gray)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                    }
                    
                    Spacer()
                    
                    // 數據來源指示
                    if shouldUseMockData {
                        Text("模擬數據")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(6)
                    }
                    
                    // 分項趨勢切換（僅限臨床量表）
                    if isClinicalAssessment {
                        Button(action: {
                            showSubcategories.toggle()
                        }) {
                            HStack {
                                Image(systemName: showSubcategories ? "chart.line.uptrend.xyaxis" : "chart.bar")
                                Text(showSubcategories ? "總分趨勢" : "分項趨勢")
                            }
                            .foregroundColor(selectedType.color)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(selectedType.color.opacity(0.1))
                            .cornerRadius(8)
                        }
                    }
                }
            }
            .padding()
            .background(Color.white)
            
            Divider()
            
            // 圖表區域
            if records.isEmpty {
                // 空數據展示
                emptyDataView
            } else {
                // 數據展示
                realDataDisplayView
            }
        }
        .onChange(of: selectedType) { _ in
            showSubcategories = false // 切換評估類型時重置分項顯示
            updateRecords() // 切換評估類型時使用緩存數據
        }
        .onChange(of: dateRange) { _ in
            updateRecords() // 僅更新時間過濾，不重新生成數據
        }
        .onChange(of: shouldUseMockData) { newValue in
            if newValue && !mockDataManager.isProduction {
                // 只在開發環境且啟用模擬數據時才生成緩存
                generateAllMockDataIfNeeded()
            }
            updateRecords()
        }
        .onReceive(NotificationCenter.default.publisher(for: .recordsMockDataSettingChanged)) { _ in
            // 響應全局設置變更
            updateRecords()
        }
        .onAppear {
            // 設置當前患者到全局管理器
            mockDataManager.currentPatient = patient
            
            // 只在開發環境且沒有真實數據時才生成模擬數據
            if !mockDataManager.isProduction && !hasRealData {
                generateAllMockDataIfNeeded()
            }
            updateRecords()
        }
    }
    
    // MARK: - 私有方法
    
    /**
     * 穩定的數據更新邏輯
     * 模擬數據只生成一次並緩存，確保一致性
     */
    private func updateRecords() {
        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -dateRange.days, to: endDate) ?? endDate
        
        if shouldUseMockData {
            // 使用穩定的模擬數據
            if let cachedData = cachedMockData[selectedType] {
                // 使用已緩存的數據，僅按時間範圍過濾
                records = cachedData.filter { record in
                    record.date >= startDate && record.date <= endDate
                }
                print("✅ ResultChangeView: 使用緩存的\(selectedType.title)模擬數據 - \(records.count) 條記錄")
            } else {
                // 第一次生成，緩存完整數據
                let fullMockData = recordStore.getMockAssessmentProgress(
                    patientId: patient.id,
                    type: selectedType,
                    startDate: Calendar.current.date(byAdding: .year, value: -1, to: endDate) ?? endDate, // 生成一年數據
                    endDate: endDate
                )
                cachedMockData[selectedType] = fullMockData
                
                // 按時間範圍過濾
                records = fullMockData.filter { record in
                    record.date >= startDate && record.date <= endDate
                }
                print("🎲 ResultChangeView: 生成新的\(selectedType.title)模擬數據 - 緩存\(fullMockData.count)條，顯示\(records.count)條")
            }
        } else {
            // 使用真實數據（來自 UserDefaults 或數據庫）
            records = recordStore.getAssessmentProgress(
                patientId: patient.id,
                type: selectedType,
                startDate: startDate,
                endDate: endDate
            )
        }
    }
    
    @ViewBuilder
    private func assessmentTypeButton(type: AssessmentType) -> some View {
        Button(action: {
            selectedType = type
            showSubcategories = false // 切換評估類型時重置分項顯示
            updateRecords()
        }) {
            Text(type.title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(selectedType == type ? .white : type.color)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(selectedType == type ? type.color : Color.clear)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(type.color, lineWidth: 1)
                )
                .cornerRadius(6)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - 視圖組件
    
    @ViewBuilder
    private var emptyDataView: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 說明文字
                VStack(spacing: 12) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 48))
                        .foregroundColor(selectedType.color.opacity(0.6))
                    
                    Text("暫無評量數據")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text("目前沒有\(selectedType.title)的評量記錄")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                    
                    Text("患者完成評量後，此處將顯示評量結果變化趨勢")
                        .font(.caption)
                        .foregroundColor(.gray.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                    
                    // 模擬數據指示
                    Text("模擬數據預覽")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                        .padding(.top, 12)
                }
                .padding(.vertical, 30)
                
                // 模擬圖表背景
                VStack(spacing: 20) {
                    mockChartPlaceholder
                    
                    if isClinicalAssessment {
                        mockSubcategoryPlaceholder
                    }
                }
                .padding(.horizontal)
            }
            .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    @ViewBuilder
    private var realDataDisplayView: some View {
        ScrollView {
            VStack(spacing: 20) {
                if showSubcategories && isClinicalAssessment {
                    // 分項趨勢圖
                    SubcategoryTrendView(records: records, assessmentType: selectedType)
                } else {
                    // 總分趨勢圖 - 使用 PerformanceChartCard
                    PerformanceChartCard(
                        title: "\(selectedType.title) 總分趨勢",
                        data: records.map { ($0.date, $0.totalScore) },
                        color: selectedType.color,
                        unit: getScoreUnit(),
                        yRange: getYAxisRange(),
                        isLowerBetter: isLowerBetterForAssessment()
                    )
                    .padding(.horizontal)
                }
                
                // 詳細分項列表
                VStack(alignment: .leading, spacing: 8) {
                    Text("評量記錄")
                        .font(.headline)
                    ForEach(records.sorted(by: { $0.date > $1.date })) { record in
                        AssessmentDetailView(record: record)
                    }
                }
                .padding()
            }
            .padding()
        }
    }
    
    @ViewBuilder
    private var mockChartPlaceholder: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("\(selectedType.title) 總分趨勢")
                .font(.headline)
                .foregroundColor(.primary)
            
            // 模擬圖表框架
            RoundedRectangle(cornerRadius: 8)
                .fill(selectedType.color.opacity(0.1))
                .frame(height: 200)
                .overlay(
                    VStack {
                        Image(systemName: "chart.xyaxis.line")
                            .font(.system(size: 32))
                            .foregroundColor(selectedType.color.opacity(0.5))
                        Text("趨勢圖預覽")
                            .font(.subheadline)
                            .foregroundColor(selectedType.color.opacity(0.7))
                    }
                )
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
    }
    
    @ViewBuilder
    private var mockSubcategoryPlaceholder: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("分項趨勢")
                .font(.headline)
                .foregroundColor(.primary)
            
            // 模擬分項圖表框架
            RoundedRectangle(cornerRadius: 8)
                .fill(selectedType.color.opacity(0.05))
                .frame(height: 150)
                .overlay(
                    VStack {
                        Image(systemName: "chart.bar")
                            .font(.system(size: 24))
                            .foregroundColor(selectedType.color.opacity(0.5))
                        Text("分項趨勢預覽")
                            .font(.caption)
                            .foregroundColor(selectedType.color.opacity(0.7))
                    }
                )
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
    }
    
    private func getScoreInterpretation() -> String {
        switch selectedType {
        case .womac:
            return "分數越低表示症狀改善"
        case .koos, .sf36:
            return "分數越高表示功能改善"
        case .chairTest, .kneeRaise:
            return "次數越多表示肌力提升"
        case .singleLegStand:
            return "時間越長表示平衡改善"
        }
    }
    
    private func getScoreUnit() -> String {
        switch selectedType {
        case .womac, .koos, .sf36:
            return "分"
        case .chairTest, .kneeRaise:
            return "次"
        case .singleLegStand:
            return "秒"
        }
    }
    
    private func getYAxisRange() -> ClosedRange<Double>? {
        switch selectedType {
        case .womac:
            return 0...96
        case .koos, .sf36:
            return 0...100
        case .chairTest:
            return 0...30
        case .kneeRaise:
            return 0...60
        case .singleLegStand:
            return 0...120
        }
    }
    
    private func isLowerBetterForAssessment() -> Bool {
        switch selectedType {
        case .womac:
            return true // WOMAC 分數越低越好
        case .koos, .sf36, .chairTest, .kneeRaise, .singleLegStand:
            return false // 其他評估分數越高越好
        }
    }
    
    // 檢查是否有真實數據
    private var hasRealData: Bool {
        // 檢查是否有任何評估記錄
        let allTypes: [AssessmentType] = [.womac, .koos, .sf36, .chairTest, .kneeRaise, .singleLegStand]
        return allTypes.contains { type in
            let records = recordStore.getAssessmentProgress(
                patientId: patient.id,
                type: type,
                startDate: Calendar.current.date(byAdding: .year, value: -1, to: Date()) ?? Date(),
                endDate: Date()
            )
            return !records.isEmpty
        }
    }
    
    /**
     * 預先生成所有評估類型的模擬數據
     * 參考 DailyPerformanceView 的穩定數據生成策略
     * 只在開發環境執行
     */
    private func generateAllMockDataIfNeeded() {
        // 生產環境不生成模擬數據
        guard !mockDataManager.isProduction else {
            print("🔒 生產環境跳過模擬數據生成")
            return
        }
        
        let assessmentTypes: [AssessmentType] = [.womac, .koos, .sf36, .chairTest, .kneeRaise, .singleLegStand]
        
        for type in assessmentTypes {
            if cachedMockData[type] == nil {
                let endDate = Date()
                let startDate = Calendar.current.date(byAdding: .year, value: -1, to: endDate) ?? endDate
                
                let mockData = recordStore.getMockAssessmentProgress(
                    patientId: patient.id,
                    type: type,
                    startDate: startDate,
                    endDate: endDate
                )
                cachedMockData[type] = mockData
                print("🎲 ResultChangeView: 預生成 \(type.title) 模擬數據 - \(mockData.count) 條記錄")
            }
        }
    }
}

// MARK: - 圖表組件


/**
 * SubcategoryTrendView - 分項趨勢圖表組件
 * 
 * 功能：
 * - 顯示臨床量表的各分項趨勢
 * - 支援WOMAC、KOOS、SF-36的分項顯示
 * - 多條線圖同時顯示不同分項
 */
struct SubcategoryTrendView: View {
    let records: [AssessmentRecord]
    let assessmentType: AssessmentType
    
    private var subcategoryData: [(String, [AssessmentChartDataPoint])] {
        guard !records.isEmpty else { return [] }
        
        let subcategoryKeys = getSubcategoryKeys()
        var result: [(String, [AssessmentChartDataPoint])] = []
        
        for key in subcategoryKeys {
            let dataPoints = records.compactMap { record -> AssessmentChartDataPoint? in
                guard let score = record.scores[key] else { return nil }
                return AssessmentChartDataPoint(date: record.date, value: score, category: key)
            }
            if !dataPoints.isEmpty {
                result.append((key, dataPoints))
            }
        }
        
        return result
    }
    
    private func getSubcategoryKeys() -> [String] {
        switch assessmentType {
        case .womac:
            return ["關節疼痛程度", "關節僵硬程度", "身體功能"]
        case .koos:
            return ["疼痛", "症狀", "日常生活活動", "運動與休閒功能", "生活品質"]
        case .sf36:
            return ["身體功能", "身體角色功能", "身體疼痛", "一般健康", "活力", "社會功能", "情緒角色功能", "心理健康"]
        default:
            return []
        }
    }
    
    private func getSubcategoryColor(for category: String, index: Int) -> Color {
        let colors: [Color] = [
            .red, .blue, .green, .orange, .purple, .pink, .cyan, .yellow
        ]
        return colors[index % colors.count]
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("\(assessmentType.title) 分項趨勢")
                .font(.headline)
            
            Chart {
                ForEach(Array(subcategoryData.enumerated()), id: \.0) { index, categoryData in
                    let (categoryName, dataPoints) = categoryData
                    let color = getSubcategoryColor(for: categoryName, index: index)
                    
                    ForEach(dataPoints, id: \.id) { point in
                        LineMark(
                            x: .value("日期", point.date),
                            y: .value("分數", point.value),
                            series: .value("分類", categoryName)
                        )
                        .foregroundStyle(color)
                        .lineStyle(StrokeStyle(lineWidth: 2))
                        .interpolationMethod(.catmullRom)
                        
                        PointMark(
                            x: .value("日期", point.date),
                            y: .value("分數", point.value)
                        )
                        .foregroundStyle(color)
                        .symbolSize(40)
                    }
                }
            }
            .frame(height: 300)
            .chartXAxis {
                AxisMarks(values: .automatic) { _ in
                    AxisGridLine()
                    AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                }
            }
            .chartYAxis {
                AxisMarks { _ in
                    AxisGridLine()
                    AxisValueLabel()
                }
            }
            
            // 圖例
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                ForEach(Array(subcategoryData.enumerated()), id: \.0) { index, categoryData in
                    let (categoryName, _) = categoryData
                    let color = getSubcategoryColor(for: categoryName, index: index)
                    
                    HStack(spacing: 6) {
                        Circle()
                            .fill(color)
                            .frame(width: 8, height: 8)
                        Text(categoryName)
                            .font(.caption)
                            .foregroundColor(.primary)
                        Spacer()
                    }
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
    }
}

// MARK: - 數據模型

struct AssessmentChartDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let value: Double
    let category: String
}

// MARK: - Preview
// Preview 將會在實際環境中使用，目前依賴其他模組
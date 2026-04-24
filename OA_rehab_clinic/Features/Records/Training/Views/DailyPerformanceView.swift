import SwiftUI

/**
 * DailyPerformanceView.swift - 每日訓練詳細資料視圖
 * 
 * 功能：
 * - 左側：選中日期的訓練詳細資料
 * - 右側：CalendarCard日曆組件，顯示訓練排程和完成狀態
 * - 支援日期選擇和訓練紀錄查看
 * 
 * 重構說明：
 * 從 TrainingContentViews.swift 中提取的 DailyPerformanceContent
 * 重命名為 DailyPerformanceView 以保持命名一致性
 * 
 * 注意：使用CalendarCard而非原生DatePicker，以維持與DailyResultView一致的UI風格
 */

struct DailyPerformanceView: View {
    let patient: Patient
    @StateObject private var recordStore = RecordStore.shared
    @StateObject private var mockDataManager = RecordsMockDataManager.shared
    @EnvironmentObject private var scheduleStore: TrainingScheduleStore
    @EnvironmentObject private var menuStore: TrainingMenuStore
    @EnvironmentObject private var userModel: UserModel
    @State private var selectedDate = Date()
    @State private var selectedExerciseId: String? = nil
    @State private var useMockData: Bool = false // 保持現有邏輯
    @State private var lastValidExerciseItems: [ExerciseToggleItem] = []
    @State private var mockTrainingSessions: [MockTrainingDisplayData] = []
    
    // 整合全局管理器的決策，移除局部覆蓋以確保統一控制
    private var effectiveUseMockData: Bool {
        // 如果全局管理器禁用模擬數據，完全不使用
        if !mockDataManager.globalMockDataEnabled {
            return false
        }
        
        // 否則使用全局管理器的智能決策
        return mockDataManager.shouldUseTrainingMockData()
    }
    
    // 獲取選中日期的訓練記錄和菜單（統一接口）
    private var dailyTrainingData: DailyTrainingData? {
        if effectiveUseMockData {
            // 使用模擬數據
            return mockDailyTrainingData
        } else {
            // 使用真實數據
            if let record = recordStore.getTrainingRecords(for: patient.id)
                .first(where: { Calendar.current.isDate($0.date, inSameDayAs: selectedDate) }),
               let menu = menuStore.getMenu(by: record.menuId) {
                return DailyTrainingData(record: record, menu: menu)
            }
        }
        return nil
    }
    
    // 模擬數據的 DailyTrainingData 轉換
    private var mockDailyTrainingData: DailyTrainingData? {
        guard let mockSession = mockTrainingSessions.first(where: { 
            Calendar.current.isDate($0.date, inSameDayAs: selectedDate) 
        }) else { return nil }
        
        // 創建虛擬的 TrainingRecord 和 TrainingMenu 用於顯示
        let mockRecord = TrainingRecord(
            id: UUID(),
            patientId: patient.id,
            date: mockSession.date,
            menuId: mockSession.menuId,
            exercises: mockSession.exercises.map { mockExercise in
                TrainingRecord.ExerciseRecord(
                    id: UUID(),
                    exerciseId: mockExercise.id,
                    sets: mockExercise.hasData ? [
                        TrainingRecord.ExerciseRecord.SetRecord(
                            repetitions: 10,
                            weight: 0,
                            duration: 300,
                            performance: 4,
                            notes: nil
                        )
                    ] : [],
                    targetRestTime: nil,
                    targetDuration: nil,
                    targetKneeAngleStart: nil,
                    targetKneeAngleEnd: nil,
                    targetHipAngleStart: nil,
                    targetHipAngleEnd: nil,
                    targetMVIC: nil,
                    stimulationEnabled: nil,
                    stimulationIntensity: nil,
                    muscleStrength: nil,
                    stability: nil,
                    regularity: nil,
                    reactionTime: nil,
                    completionRate: nil
                )
            },
            totalDuration: nil,
            avgPainScore: nil
        )
        
        let mockMenu = TrainingMenu(
            id: mockSession.menuId,
            title: mockSession.menuTitle,
            isExclusive: true,
            color: .blue,
            exercises: [],
            patientId: patient.id
        )
        
        return DailyTrainingData(record: mockRecord, menu: mockMenu)
    }
    
    // 獲取當日的動作列表（穩定版本）
    private var exerciseToggleItems: [ExerciseToggleItem] {
        let currentItems = calculateExerciseToggleItems()
        
        // 如果當前計算結果為空，但之前有有效數據，則暫時保留之前的數據
        // 這能防止UI在狀態轉換過程中意外變空
        if currentItems.isEmpty && !lastValidExerciseItems.isEmpty {
            print("🔄 DailyPerformanceView: 使用上次有效的動作列表 (\(lastValidExerciseItems.count) 個動作)")
            return lastValidExerciseItems
        }
        
        return currentItems
    }
    
    // 計算動作列表的核心邏輯
    private func calculateExerciseToggleItems() -> [ExerciseToggleItem] {
        let items: [ExerciseToggleItem]
        
        if effectiveUseMockData {
            // 使用模擬數據
            print("🔍 calculateExerciseToggleItems: 使用模擬數據")
            print("   - mockTrainingSessions 數量: \(mockTrainingSessions.count)")
            print("   - 選中日期: \(selectedDate)")
            
            if let mockSession = mockTrainingSessions.first(where: { 
                Calendar.current.isDate($0.date, inSameDayAs: selectedDate) 
            }) {
                print("   - 找到匹配的會話: \(mockSession.exercises.count) 個動作")
                items = mockSession.exercises.map { mockExercise in
                    ExerciseToggleItem(
                        id: mockExercise.id,
                        name: mockExercise.name,
                        englishName: mockExercise.englishName,
                        imageName: mockExercise.imageName,
                        hasData: mockExercise.hasData
                    )
                }
            } else {
                print("   - 未找到匹配的會話")
                // 輸出所有可用日期進行比較
                if !mockTrainingSessions.isEmpty {
                    let availableDates = mockTrainingSessions.map { session in
                        let formatter = DateFormatter()
                        formatter.dateFormat = "yyyy-MM-dd"
                        return formatter.string(from: session.date)
                    }.joined(separator: ", ")
                    let selectedDateStr = DateFormatter().string(from: selectedDate)
                    print("   - 可用的模擬數據日期: \(availableDates)")
                    print("   - 選中的日期: \(selectedDateStr)")
                }
                items = []
            }
        } else {
            // 使用真實數據
            print("🔍 calculateExerciseToggleItems: 使用真實數據")
            if let data = dailyTrainingData {
                items = data.record.exercises.compactMap { exerciseRecord in
                    ExerciseToggleItem(
                        id: exerciseRecord.exerciseId,
                        name: exerciseRecord.exerciseId,
                        englishName: "",
                        imageName: nil,
                        hasData: !exerciseRecord.sets.isEmpty
                    )
                }
            } else {
                items = []
            }
        }
        
        // 調試輸出
        if items.isEmpty {
            print("⚠️ DailyPerformanceView: 計算出的動作列表為空")
            print("   - effectiveUseMockData: \(effectiveUseMockData)")
            print("   - selectedDate: \(selectedDate)")
            print("   - mockTrainingSessions.count: \(mockTrainingSessions.count)")
        } else {
            print("✅ DailyPerformanceView: 計算出 \(items.count) 個動作")
        }
        
        return items
    }
    
    // 檢查是否有真實數據
    private var hasRealData: Bool {
        !recordStore.getTrainingRecords(for: patient.id).isEmpty
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            // Left Side: 新的詳細內容區域
            ScrollView {
                VStack(spacing: 16) {
                    if let data = dailyTrainingData {
                        // 1. 單日訓練概況標題
                        VStack(spacing: 0) {
                            // 模擬數據指示器
                            if effectiveUseMockData {
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
                                .padding(.horizontal, 20)
                                .padding(.bottom, 8)
                            }
                            
                            DailySessionHeaderCard(
                                date: selectedDate,
                                menuTitle: data.menu.title,
                                totalDuration: effectiveUseMockData ? getMockSessionDuration() : calculateTotalDuration(data.record),
                                vasScore: effectiveUseMockData ? getMockVASScore() : data.record.avgPainScore
                            )
                        }
                        
                        // 2. 動作選擇Toggle網格
                        if !exerciseToggleItems.isEmpty {
                            ExerciseToggleGrid(
                                exercises: exerciseToggleItems,
                                selectedExerciseId: $selectedExerciseId
                            )
                        }
                        
                        // 3. 選中動作的詳細資訊
                        if let selectedId = selectedExerciseId {
                            if effectiveUseMockData {
                                // 使用模擬數據
                                if let mockSession = mockTrainingSessions.first(where: { 
                                    Calendar.current.isDate($0.date, inSameDayAs: selectedDate) 
                                }),
                                   let mockExercise = mockSession.exercises.first(where: { $0.id == selectedId }) {
                                    ExerciseDetailCard(
                                        exerciseId: selectedId,
                                        exerciseName: mockExercise.name,
                                        therapistSettings: mockExercise.therapistSettings,
                                        metricsData: mockExercise.metricsData
                                    )
                                }
                            } else {
                                // 使用真實數據
                                if let exerciseRecord = data.record.exercises.first(where: { $0.exerciseId == selectedId }) {
                                    ExerciseDetailCard(
                                        exerciseId: selectedId,
                                        exerciseName: selectedId, // 應該是真實的動作名稱
                                        therapistSettings: createTherapistSettings(for: exerciseRecord),
                                        metricsData: createMetricsData(for: exerciseRecord)
                                    )
                                }
                            }
                        }
                    } else {
                        // 無訓練記錄的空狀態
                        VStack(spacing: 16) {
                            EmptyDayView(date: selectedDate)
                            
                            // 在生產環境不顯示模擬數據切換提示
                            if !hasRealData && !mockDataManager.isProduction {
                                Text("無訓練數據")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                    .padding(.top, 8)
                            }
                        }
                    }
                }
                .padding(20)
            }
            .frame(maxWidth: .infinity)
            
            // Right Side: 保持現有的日曆
            UnifiedCalendarContainer(
                currentDate: $selectedDate,
                patient: patient,
                selectedMenu: nil,
                selectedAssessments: [],
                onDateSelected: { date in
                    selectedDate = date
                    selectedExerciseId = nil // 重置選中的動作
                },
                onExistingScheduleTap: { date in
                    // 有訓練底色的日期也應該可以選擇，執行相同的邏輯
                    selectedDate = date
                    selectedExerciseId = nil // 重置選中的動作
                },
                selectionMode: .single,
                isEditable: true,
                allowPastDatesSelection: true  // 允許選擇過去日期以查看歷史結果
            )
            .environmentObject(scheduleStore)
            .environmentObject(AssessmentStore.shared)
            .frame(width: 430)
        }
        .background(Color.white)
        .onAppear {
            scheduleStore.reloadSchedules()
            selectedDate = Date()
        }
        .onChange(of: calculateExerciseToggleItems().map { $0.id }) { newIds in
            let currentItems = calculateExerciseToggleItems()
            
            // 更新有效數據緩存
            if !currentItems.isEmpty {
                lastValidExerciseItems = currentItems
            }
            
            // 智能選擇邏輯
            if let currentId = selectedExerciseId {
                // 檢查當前選中是否仍然有效
                if !currentItems.contains(where: { $0.id == currentId }) {
                    // 當前選中不存在，重新選擇
                    selectedExerciseId = currentItems.first(where: { $0.hasData })?.id ?? currentItems.first?.id
                }
            } else if !currentItems.isEmpty {
                // 沒有選中時，自動選擇第一個有數據的動作
                selectedExerciseId = currentItems.first(where: { $0.hasData })?.id ?? currentItems.first?.id
            }
        }
        .onChange(of: useMockData) { _ in
            // 數據源切換時，重置選中狀態，讓動作列表變化監聽器處理
            selectedExerciseId = nil
        }
        .onReceive(NotificationCenter.default.publisher(for: .recordsMockDataSettingChanged)) { _ in
            // 響應全局設置變更，強制更新UI
            // effectiveUseMockData 會自動處理全局設置變化
        }
        .onChange(of: selectedDate) { _ in
            // 日期變化時，重置選中狀態，讓動作列表變化監聽器處理
            selectedExerciseId = nil
        }
    }
    
    // MARK: - 輔助方法
    
    /**
     * 一次性生成穩定的模擬數據
     * 只有當 mockTrainingSessions 為空時才生成，確保數據穩定性
     */
    private func generateMockDataIfNeeded() {
        print("🔧 generateMockDataIfNeeded() 被調用")
        
        // 如果已經有模擬數據，不重新生成
        guard mockTrainingSessions.isEmpty else { 
            print("✅ DailyPerformanceView: 模擬數據已存在，跳過生成 (當前有 \(mockTrainingSessions.count) 個會話)")
            return 
        }
        
        print("🎲 DailyPerformanceView: 開始生成模擬數據...")
        print("   - 患者ID: \(patient.id)")
        print("   - 患者姓名: \(patient.name)")
        
        // 調用 MockTrainingData 生成數據
        print("📞 調用 MockTrainingData.generateMockTrainingSessions...")
        mockTrainingSessions = MockTrainingData.generateMockTrainingSessions(for: patient.id)
        print("🎲 DailyPerformanceView: MockTrainingData 返回 \(mockTrainingSessions.count) 個訓練會話")
        
        if mockTrainingSessions.isEmpty {
            print("⚠️ DailyPerformanceView: 生成的模擬數據為空，這是問題所在！")
            print("🔍 正在進行緊急修復：手動創建測試數據...")
            
            // 緊急修復：手動創建至少一個測試會話
            let testSession = MockTrainingDisplayData(
                date: Date(),
                menuTitle: "測試訓練菜單",
                exercises: [
                    MockExerciseData(
                        id: "quadriceps_strength_1",
                        name: "股四頭肌肌力訓練",
                        englishName: "Quadriceps Strength Training",
                        imageName: "quadriceps_strength_1",
                        hasData: true,
                        therapistSettings: TherapistSettings(
                            exerciseName: "股四頭肌肌力訓練",
                            sets: 3,
                            repetitions: 10,
                            restTime: 30
                        ),
                        metricsData: [
                            MetricData(type: "肌力", score: 75.0, unit: "分", timestamp: Date())
                        ]
                    )
                ],
                totalDuration: 1800,
                vasScore: 3.0
            )
            mockTrainingSessions = [testSession]
            print("🚨 緊急修復完成：手動創建了 1 個測試會話")
        } else {
            // 輸出生成的日期以便調試
            let sessionDates = mockTrainingSessions.map { session in
                let formatter = DateFormatter()
                formatter.dateFormat = "MM/dd HH:mm"
                return formatter.string(from: session.date)
            }.joined(separator: ", ")
            print("📅 模擬數據日期: \(sessionDates)")
            
            // 輸出每個會話的動作數量
            for (index, session) in mockTrainingSessions.enumerated() {
                print("   會話 \(index): \(session.exercises.count) 個動作")
            }
        }
    }
    
    private func calculateTotalDuration(_ record: TrainingRecord) -> TimeInterval? {
        return record.totalDuration
    }
    
    private func getMockSessionDuration() -> TimeInterval? {
        guard let mockSession = mockTrainingSessions.first(where: { 
            Calendar.current.isDate($0.date, inSameDayAs: selectedDate) 
        }) else { return nil }
        return mockSession.totalDuration
    }
    
    private func getMockVASScore() -> Double? {
        guard let mockSession = mockTrainingSessions.first(where: { 
            Calendar.current.isDate($0.date, inSameDayAs: selectedDate) 
        }) else { return nil }
        return mockSession.vasScore
    }
    
    private func createTherapistSettings(for exerciseRecord: TrainingRecord.ExerciseRecord) -> TherapistSettings? {
        return TherapistSettings(
            exerciseName: exerciseRecord.exerciseId,
            sets: exerciseRecord.sets.count,
            repetitions: exerciseRecord.sets.first?.repetitions ?? 0,
            restTime: exerciseRecord.targetRestTime ?? 30,
            mvic: exerciseRecord.targetMVIC,
            maintainTime: exerciseRecord.targetDuration,
            kneeAngleStart: exerciseRecord.targetKneeAngleStart,
            kneeAngleEnd: exerciseRecord.targetKneeAngleEnd,
            hipAngleStart: exerciseRecord.targetHipAngleStart,
            hipAngleEnd: exerciseRecord.targetHipAngleEnd,
            stimulation: exerciseRecord.stimulationEnabled ?? false,
            stimulationIntensity: exerciseRecord.stimulationIntensity
        )
    }
    
    private func createMetricsData(for exerciseRecord: TrainingRecord.ExerciseRecord) -> [MetricData]? {
        guard !exerciseRecord.sets.isEmpty else { return nil }

        // 優先使用從 JSON 匯入的真實指標
        if let strength = exerciseRecord.muscleStrength {
            var metrics: [MetricData] = []
            metrics.append(MetricData(type: "肌力", score: strength, unit: "分", timestamp: Date()))
            if let v = exerciseRecord.stability {
                metrics.append(MetricData(type: "穩定度", score: v, unit: "分", timestamp: Date()))
            }
            if let v = exerciseRecord.regularity {
                metrics.append(MetricData(type: "規律性", score: v, unit: "分", timestamp: Date()))
            }
            if let v = exerciseRecord.reactionTime {
                metrics.append(MetricData(type: "反應時間", score: v, unit: "分", timestamp: Date()))
            }
            if let v = exerciseRecord.completionRate {
                metrics.append(MetricData(type: "完成度", score: v, unit: "分", timestamp: Date()))
            }
            return metrics
        }

        // fallback：舊資料無指標時，用粗略換算
        let avgPerformance = exerciseRecord.sets.reduce(0.0) { $0 + Double($1.performance) } / Double(exerciseRecord.sets.count)
        return [
            MetricData(type: "表現評分", score: avgPerformance * 20, unit: "分", timestamp: Date())
        ]
    }
}

// MARK: - 數據模型

/**
 * DailyTrainingData - 單日訓練數據結構
 */
struct DailyTrainingData {
    let record: TrainingRecord
    let menu: TrainingMenu
}

/**
 * EmptyDayView - 無訓練記錄的空狀態視圖
 */
struct EmptyDayView: View {
    let date: Date
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年MM月dd日"
        formatter.locale = Locale(identifier: "zh_TW")
        return formatter
    }
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.system(size: 48))
                .foregroundColor(.gray.opacity(0.6))
            
            VStack(spacing: 8) {
                Text("該日無訓練安排")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text(dateFormatter.string(from: date))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text("請選擇其他有訓練記錄的日期")
                    .font(.body)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 300)
        .padding(40)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
}


// MARK: - Preview
#Preview {
    DailyPerformanceView(patient: Patient.sample)
        .environmentObject(TrainingScheduleStore.shared)
        .environmentObject(TrainingMenuStore.shared)
        .environmentObject(UserModel.shared)
        .environmentObject(RecordStore.shared)
        .onAppear {
            TrainingScheduleStore.shared.reloadSchedules()
        }
        .frame(width: 1000, height: 600)
        .background(Color.gray.opacity(0.1))
}

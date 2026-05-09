import Foundation
import SwiftUI

// MARK: - DateFormatter Extension
extension DateFormatter {
    static let shortDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd"
        formatter.locale = Locale(identifier: "zh_TW")
        return formatter
    }()
}

/**
 * MockTrainingData.swift - 訓練表現模擬數據生成器
 * 
 * 功能：
 * - 為三個重要動作生成符合邏輯的訓練結果數據
 * - 模擬復健進步趨勢（各指標漸進改善）
 * - 支援不同時間範圍的數據生成
 * - 為詳細分析視圖提供預覽數據
 * - 生成 DailyPerformanceView 的顯示數據（不影響 TrainingRecord）
 */

// MARK: - Mock Display Data Models

/**
 * MockTrainingDisplayData - 模擬訓練顯示數據
 * 專門用於 DailyPerformanceView，不污染真實的 TrainingRecord 數據
 */
struct MockTrainingDisplayData {
    let date: Date
    let menuTitle: String
    let menuId: UUID
    let exercises: [MockExerciseData]
    let totalDuration: TimeInterval?
    let vasScore: Double?
    
    init(date: Date, menuTitle: String, exercises: [MockExerciseData], totalDuration: TimeInterval? = nil, vasScore: Double? = nil) {
        self.date = date
        self.menuTitle = menuTitle
        self.menuId = UUID() // 生成虛擬ID
        self.exercises = exercises
        self.totalDuration = totalDuration
        self.vasScore = vasScore
    }
}

/**
 * MockExerciseData - 模擬動作數據
 */
struct MockExerciseData: Identifiable, Equatable {
    let id: String
    let name: String
    let englishName: String
    let imageName: String?
    let hasData: Bool
    let therapistSettings: TherapistSettings?
    let metricsData: [MetricData]?
    
    static func == (lhs: MockExerciseData, rhs: MockExerciseData) -> Bool {
        return lhs.id == rhs.id
    }
}

struct MockTrainingData {
    
    // MARK: - DailyPerformanceView Mock Data Generation
    
    /**
     * 生成 DailyPerformanceView 的模擬訓練會話
     * 基於真實的菜單架構，生成過去7天的3-4個訓練會話
     */
    static func generateMockTrainingSessions(for patientId: String) -> [MockTrainingDisplayData] {
        print("🏭 MockTrainingData.generateMockTrainingSessions 開始")
        print("   - 目標患者ID: \(patientId)")
        
        let calendar = Calendar.current
        let endDate = Date()
        let startDate = calendar.date(byAdding: .day, value: -7, to: endDate) ?? endDate
        
        print("   - 日期範圍: \(DateFormatter.shortDateFormatter.string(from: startDate)) 到 \(DateFormatter.shortDateFormatter.string(from: endDate))")
        
        // 生成3-4個隨機訓練日期
        let sessionCount = Int.random(in: 3...4)
        print("   - 預計生成 \(sessionCount) 個訓練會話")
        
        let sessionDates = generateRandomSessionDates(from: startDate, to: endDate, count: sessionCount)
        print("   - 實際生成 \(sessionDates.count) 個日期")
        
        if sessionDates.isEmpty {
            print("⚠️ MockTrainingData: generateRandomSessionDates 返回空陣列！")
            return []
        }
        
        var sessions: [MockTrainingDisplayData] = []
        
        for (index, date) in sessionDates.enumerated() {
            print("   - 正在生成第 \(index + 1) 個會話 (日期: \(DateFormatter.shortDateFormatter.string(from: date)))")
            let progressRatio = sessionCount > 1 ? Double(index) / Double(sessionCount - 1) : 0.0 // 防止除零
            let session = generateMockTrainingSession(
                for: patientId,
                date: date,
                progressRatio: progressRatio
            )
            sessions.append(session)
            print("     ✅ 會話生成成功，包含 \(session.exercises.count) 個動作")
        }
        
        let sortedSessions = sessions.sorted { $0.date < $1.date }
        print("🏭 MockTrainingData.generateMockTrainingSessions 完成：返回 \(sortedSessions.count) 個會話")
        
        return sortedSessions
    }
    
    /**
     * 生成單個模擬訓練會話
     */
    private static func generateMockTrainingSession(
        for patientId: String,
        date: Date,
        progressRatio: Double
    ) -> MockTrainingDisplayData {
        
        let menuTitle = "股四頭肌訓練菜單"
        
        // 生成三個目標動作
        let exercises = [
            generateMockExercise(
                id: "knee_extension",
                name: "股四頭肌終端伸展",
                englishName: "Terminal Knee Extension",
                imageName: "2",
                progressRatio: progressRatio
            ),
            generateMockExercise(
                id: "step_up",
                name: "登階運動",
                englishName: "Step Training",
                imageName: "12",
                progressRatio: progressRatio
            ),
            generateMockExercise(
                id: "partial_squat",
                name: "部分蹲",
                englishName: "Partial Squat",
                imageName: "9",
                progressRatio: progressRatio
            )
        ]
        
        // 生成會話級別數據
        let totalDuration = generateTotalSessionDuration()
        let vasScore = generateVASScore(progressRatio: progressRatio)
        
        return MockTrainingDisplayData(
            date: date,
            menuTitle: menuTitle,
            exercises: exercises,
            totalDuration: totalDuration,
            vasScore: vasScore
        )
    }
    
    /**
     * 生成模擬動作數據
     */
    private static func generateMockExercise(
        id: String,
        name: String,
        englishName: String,
        imageName: String?,
        progressRatio: Double
    ) -> MockExerciseData {
        
        // 85% 的動作有數據，15% 沒有（模擬真實情況）
        let hasData = Double.random(in: 0...1) > 0.15
        
        let therapistSettings = generateMockTherapistSettings(
            for: name,
            progressRatio: progressRatio
        )
        
        let metricsData = hasData ? generateMockMetrics(
            for: name,
            progressRatio: progressRatio
        ) : nil
        
        return MockExerciseData(
            id: id,
            name: name,
            englishName: englishName,
            imageName: imageName,
            hasData: hasData,
            therapistSettings: therapistSettings,
            metricsData: metricsData
        )
    }
    
    /**
     * 生成模擬治療師設定
     */
    private static func generateMockTherapistSettings(
        for exerciseName: String,
        progressRatio: Double
    ) -> TherapistSettings {
        
        switch exerciseName {
        case "股四頭肌終端伸展":
            let maintainTime = 5 + Int(progressRatio * 5) // 5-10秒
            let kneeEnd = 70 + Int(progressRatio * 20) // 70-90度
            let stimulation = progressRatio > 0.3 ? Bool.random() : false // 進階時可能開啟電刺激
            
            return TherapistSettings(
                exerciseName: exerciseName,
                sets: 3,
                repetitions: 10,
                restTime: 30,
                mvic: nil,  // 移除MVIC參數
                maintainTime: maintainTime,
                kneeAngleStart: 0,
                kneeAngleEnd: kneeEnd,
                stimulation: stimulation,
                stimulationIntensity: stimulation ? Int.random(in: 3...7) : nil
            )
            
        case "登階運動":
            let reps = 8 + Int(progressRatio * 12) // 8-20次
            let rest = max(40, 80 - Int(progressRatio * 30)) // 80-40秒
            let stimulation = progressRatio > 0.5 ? Bool.random() : false // 進階時可能開啟電刺激
            
            return TherapistSettings(
                exerciseName: exerciseName,
                sets: 3,
                repetitions: reps,
                restTime: rest,
                weight: nil,  // 登階運動不需要重量參數
                stimulation: stimulation,
                stimulationIntensity: stimulation ? Int.random(in: 3...7) : nil
            )
            
        case "部分蹲":
            let reps = 10 + Int(progressRatio * 15) // 10-25次
            let rest = max(30, 60 - Int(progressRatio * 20)) // 60-30秒
            let maintainTime = 6 + Int(progressRatio * 6) // 6-12秒
            let kneeEnd = 45 + Int(progressRatio * 30) // 45-75度
            let stimulation = progressRatio > 0.4 ? Bool.random() : false // 進階時可能開啟電刺激
            
            return TherapistSettings(
                exerciseName: exerciseName,
                sets: 3,
                repetitions: reps,
                restTime: rest,
                maintainTime: maintainTime,
                kneeAngleStart: 0,
                kneeAngleEnd: kneeEnd,
                stimulation: stimulation,
                stimulationIntensity: stimulation ? Int.random(in: 3...7) : nil
            )
            
        default:
            return TherapistSettings(
                exerciseName: exerciseName,
                sets: 3,
                repetitions: 10,
                restTime: 30
            )
        }
    }
    
    /**
     * 生成模擬表現指標
     * 根據 AllExerciseTypes.swift 中的 chartMetrics 配置生成對應指標
     */
    private static func generateMockMetrics(
        for exerciseName: String,
        progressRatio: Double
    ) -> [MetricData] {
        
        let baseScore = 30.0 + progressRatio * 50.0 // 30-80分的進步
        let variation = 10.0 // 隨機變動
        
        switch exerciseName {
        case "股四頭肌終端伸展":
            // terminalKneeExtension: [.muscleStrength, .stability, .regularity, .completionRate, .reactionTime]
            return [
                MetricData(
                    type: "肌力",
                    score: baseScore + Double.random(in: -variation...variation),
                    unit: "分",
                    timestamp: Date()
                ),
                MetricData(
                    type: "穩定度",
                    score: baseScore + Double.random(in: -variation...variation),
                    unit: "分",
                    timestamp: Date()
                ),
                MetricData(
                    type: "規律性",
                    score: baseScore + Double.random(in: -variation...variation),
                    unit: "分",
                    timestamp: Date()
                ),
                MetricData(
                    type: "完成度",
                    score: baseScore + Double.random(in: -variation...variation),
                    unit: "分",
                    timestamp: Date()
                ),
                MetricData(
                    type: "反應時間",
                    score: convertReactionTimeToScore(baseTime: 1500.0 - progressRatio * 800.0, variation: 200), // 標準化為100分
                    unit: "分",
                    timestamp: Date()
                )
            ]
            
        case "部分蹲":
            // partialSquat: [.muscleStrength, .stability, .regularity, .completionRate, .reactionTime]
            return [
                MetricData(
                    type: "肌力",
                    score: baseScore + Double.random(in: -variation...variation),
                    unit: "分",
                    timestamp: Date()
                ),
                MetricData(
                    type: "穩定度",
                    score: baseScore + Double.random(in: -variation...variation),
                    unit: "分",
                    timestamp: Date()
                ),
                MetricData(
                    type: "規律性",
                    score: baseScore + Double.random(in: -variation...variation),
                    unit: "分",
                    timestamp: Date()
                ),
                MetricData(
                    type: "完成度",
                    score: baseScore + Double.random(in: -variation...variation),
                    unit: "分",
                    timestamp: Date()
                ),
                MetricData(
                    type: "反應時間",
                    score: convertReactionTimeToScore(baseTime: 1500.0 - progressRatio * 800.0, variation: 200), // 標準化為100分
                    unit: "分",
                    timestamp: Date()
                )
            ]
            
        case "登階運動":
            // stepTraining: [.muscleStrength, .stability, .regularity, .reactionTime, .completionRate]
            return [
                MetricData(
                    type: "肌力",
                    score: baseScore + Double.random(in: -variation...variation),
                    unit: "分",
                    timestamp: Date()
                ),
                MetricData(
                    type: "穩定度",
                    score: baseScore + Double.random(in: -variation...variation),
                    unit: "分",
                    timestamp: Date()
                ),
                MetricData(
                    type: "規律性",
                    score: baseScore + Double.random(in: -variation...variation),
                    unit: "分",
                    timestamp: Date()
                ),
                MetricData(
                    type: "反應時間",
                    score: convertReactionTimeToScore(baseTime: 1500.0 - progressRatio * 800.0, variation: 200), // 標準化為100分
                    unit: "分",
                    timestamp: Date()
                ),
                MetricData(
                    type: "完成度",
                    score: baseScore + Double.random(in: -variation...variation),
                    unit: "分",
                    timestamp: Date()
                )
            ]
            
        default:
            return [
                MetricData(
                    type: "表現評分",
                    score: baseScore + Double.random(in: -variation...variation),
                    unit: "分",
                    timestamp: Date()
                )
            ]
        }
    }
    
    // MARK: - 輔助方法
    
    /**
     * 將反應時間（毫秒）轉換為標準化分數（0-100分）
     * 反應時間越短分數越高，使用反比例關係
     */
    private static func convertReactionTimeToScore(baseTime: Double, variation: Double) -> Double {
        // 加入隨機變動
        let reactionTime = baseTime + Double.random(in: -variation...variation)
        
        // 設定反應時間範圍：300ms-2000ms
        let minTime: Double = 300.0  // 最快反應時間（對應100分）
        let maxTime: Double = 2000.0 // 最慢反應時間（對應0分）
        
        // 限制反應時間在合理範圍內
        let clampedTime = max(minTime, min(maxTime, reactionTime))
        
        // 使用反比例公式：分數 = 100 * (maxTime - currentTime) / (maxTime - minTime)
        let score = 100.0 * (maxTime - clampedTime) / (maxTime - minTime)
        
        return max(0, min(100, score))
    }
    
    /**
     * 生成隨機訓練會話日期
     */
    private static func generateRandomSessionDates(from startDate: Date, to endDate: Date, count: Int) -> [Date] {
        let timeInterval = endDate.timeIntervalSince(startDate)
        var dates: [Date] = []
        let calendar = Calendar.current
        
        // 防止除零錯誤和確保至少有一個日期
        guard count > 0, timeInterval > 0 else {
            print("⚠️ generateRandomSessionDates: 無效參數 - count: \(count), timeInterval: \(timeInterval)")
            return [calendar.startOfDay(for: Date())] // 返回今天作為後備
        }
        
        var attempts = 0
        let maxAttempts = count * 3 // 最多嘗試3倍次數
        
        while dates.count < count && attempts < maxAttempts {
            let date: Date
            
            if count == 1 {
                // 單個日期時，選擇中間點避免除零
                date = startDate.addingTimeInterval(timeInterval / 2)
            } else {
                // 多個日期時，均勻分佈
                let progress = Double(dates.count) / Double(count - 1)
                let baseInterval = timeInterval * progress
                let randomOffset = Double.random(in: -timeInterval/20...timeInterval/20) // 減少隨機偏移範圍
                let finalInterval = max(0, min(timeInterval, baseInterval + randomOffset))
                date = startDate.addingTimeInterval(finalInterval)
            }
            
            // 確保是不同的日期
            let normalizedDate = calendar.startOfDay(for: date)
            if !dates.contains(where: { calendar.isDate($0, inSameDayAs: normalizedDate) }) {
                dates.append(normalizedDate)
                print("✅ 生成訓練日期: \(DateFormatter.shortDateFormatter.string(from: normalizedDate))")
            }
            
            attempts += 1
        }
        
        // 確保至少有一個日期
        if dates.isEmpty {
            let fallbackDate = calendar.startOfDay(for: startDate.addingTimeInterval(timeInterval / 2))
            dates.append(fallbackDate)
            print("🔄 使用後備日期: \(DateFormatter.shortDateFormatter.string(from: fallbackDate))")
        }
        
        let sortedDates = dates.sorted()
        print("📅 生成的訓練日期列表: \(sortedDates.map { DateFormatter.shortDateFormatter.string(from: $0) }.joined(separator: ", "))")
        
        return sortedDates
    }
    
    /**
     * 生成總訓練時長
     */
    private static func generateTotalSessionDuration() -> TimeInterval {
        return TimeInterval.random(in: 1800...3600) // 30-60分鐘
    }
    
    /**
     * 生成VAS疼痛分數（隨進步改善）
     */
    private static func generateVASScore(progressRatio: Double) -> Double {
        let basePain = 7.0 - progressRatio * 5.0 // 7分降到2分
        let variation = Double.random(in: -1.0...1.0)
        return max(0.0, min(10.0, basePain + variation))
    }
    
    // MARK: - 主要生成方法（原有的 TrainingVisualizationData 方法）
    
    /**
     * 為指定患者和動作類型生成模擬訓練記錄
     * - 生成過去 6 個月內 15-25 次隨機分佈的訓練記錄
     * - 體現復健效果的漸進改善趨勢
     * - 確保任何時間範圍都有足夠的數據點
     */
    static func generateMockTrainingResults(
        for patientId: String, 
        exerciseType: SupportedExerciseType
    ) -> [TrainingVisualizationData] {
        let recordCount = Int.random(in: 15...25) // 增加數據點數量
        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .month, value: -6, to: endDate) ?? endDate
        
        var results: [TrainingVisualizationData] = []
        
        // 生成隨機日期並排序
        let randomDates = generateRandomDates(from: startDate, to: endDate, count: recordCount)
        
        for (index, date) in randomDates.enumerated() {
            let progressRatio = Double(index) / Double(recordCount - 1) // 0.0 到 1.0 的進步比例
            let result = generateTrainingResult(
                for: patientId,
                exerciseType: exerciseType,
                date: date,
                progressRatio: progressRatio
            )
            results.append(result)
        }
        
        return results.sorted { $0.date < $1.date }
    }
    
    // MARK: - 日期生成
    
    private static func generateRandomDates(from startDate: Date, to endDate: Date, count: Int) -> [Date] {
        let timeInterval = endDate.timeIntervalSince(startDate)
        var dates: [Date] = []
        
        for _ in 0..<count {
            let randomInterval = Double.random(in: 0...timeInterval)
            let randomDate = startDate.addingTimeInterval(randomInterval)
            dates.append(randomDate)
        }
        
        return dates.sorted()
    }
    
    // MARK: - 訓練結果生成
    
    private static func generateTrainingResult(
        for patientId: String,
        exerciseType: SupportedExerciseType,
        date: Date,
        progressRatio: Double
    ) -> TrainingVisualizationData {
        
        // 基於動作類型獲取治療師設定
        let therapistSettings = generateTherapistSettings(for: exerciseType, progressRatio: progressRatio)
        
        // 生成表現指標
        let performance = generatePerformanceMetrics(
            for: exerciseType,
            progressRatio: progressRatio
        )
        
        // 生成訓練時長
        let sessionDuration = generateSessionDuration(for: exerciseType)
        
        // 生成額外資訊
        let painLevel = generatePainLevel(progressRatio: progressRatio)
        let effortLevel = generateEffortLevel()
        let notes = generateNotes(for: exerciseType, progressRatio: progressRatio)
        
        return TrainingVisualizationData(
            patientId: patientId,
            exerciseName: exerciseType.displayName,
            date: date,
            sessionDuration: sessionDuration,
            therapistSettings: therapistSettings,
            performance: performance,
            painLevel: painLevel,
            effortLevel: effortLevel,
            notes: notes
        )
    }
    
    // MARK: - 治療師設定生成
    
    private static func generateTherapistSettings(
        for exerciseType: SupportedExerciseType,
        progressRatio: Double
    ) -> TherapistSettings {
        
        // 基於 ExerciseParameters.LegParameters 生成真實的治療師設定
        let baseLegParams = generateLegParametersForExerciseType(exerciseType, progressRatio: progressRatio)
        
        return TherapistSettings(
            exerciseName: exerciseType.displayName,
            sets: baseLegParams.sets,
            repetitions: baseLegParams.repetitions,
            restTime: baseLegParams.restTime,
            mvic: baseLegParams.mvic,
            maintainTime: baseLegParams.duration,
            kneeAngleStart: baseLegParams.kneeAngleStart,
            kneeAngleEnd: baseLegParams.kneeAngleEnd,
            hipAngleStart: baseLegParams.hipAngleStart,
            hipAngleEnd: baseLegParams.hipAngleEnd,
            weight: baseLegParams.weight,
            stimulation: baseLegParams.stimulation,
            stimulationIntensity: baseLegParams.stimulationIntensity
        )
    }
    
    private static func generateLegParametersForExerciseType(
        _ exerciseType: SupportedExerciseType,
        progressRatio: Double
    ) -> LegParameters {
        
        switch exerciseType {
        case .kneeExtension:
            // 股四頭肌終端伸展：等長收縮動作，有維持時間、膝關節角度、電刺激（移除MVIC）
            let baseDuration = 5 + Int(progressRatio * 10) // 5-15秒
            let baseReps = 8 + Int(progressRatio * 7) // 8-15次
            
            // 角度隨進步調整：從較小角度開始，漸進到更大角度
            let kneeEnd = 70 + Int(progressRatio * 20) // 70-90度
            
            return LegParameters(
                sets: 3,
                repetitions: min(15, baseReps),
                restTime: 30,
                duration: min(15, baseDuration),
                kneeAngleStart: 0,         // 完全伸直開始
                kneeAngleEnd: min(90, kneeEnd),
                hipAngleStart: nil,        // 股四頭肌訓練不用髖關節角度
                hipAngleEnd: nil,
                weight: nil,               // 等長收縮不加重
                mvic: nil,                 // 移除MVIC參數
                stimulation: progressRatio > 0.3 ? Bool.random() : false,
                stimulationIntensity: progressRatio > 0.3 ? Int.random(in: 3...7) : nil
            )
            
        case .partialSquat:
            // 部分蹲：動態動作，有維持時間、膝關節角度，無MVIC
            let baseSets = 3 + Int(progressRatio * 2) // 3-5組
            let baseReps = 10 + Int(progressRatio * 15) // 10-25次
            let baseRest = max(30, 60 - Int(progressRatio * 20)) // 60-30秒
            let baseDuration = 6 + Int(progressRatio * 6) // 6-12秒維持時間
            
            // 角度隨進步調整：從較淺蹲位開始，漸進到更深蹲位
            let kneeEnd = 45 + Int(progressRatio * 30) // 45-75度（部分蹲不會太深）
            
            return LegParameters(
                sets: min(5, baseSets),
                repetitions: min(25, baseReps),
                restTime: baseRest,
                duration: min(12, baseDuration), // 部分蹲有維持時間
                kneeAngleStart: 0,               // 站立位開始
                kneeAngleEnd: min(75, kneeEnd),  // 部分蹲角度範圍
                hipAngleStart: nil,              // 股四頭肌訓練不用髖關節角度
                hipAngleEnd: nil,
                weight: nil,                     // 初期不加重
                mvic: nil,                       // 部分蹲不用MVIC
                stimulation: progressRatio > 0.4 ? Bool.random() : false,
                stimulationIntensity: progressRatio > 0.4 ? Int.random(in: 3...7) : nil
            )
            
        case .stepUp:
            // 登階運動：功能性動作，無維持時間、無角度限制、無MVIC，可開啟電刺激，可能加重
            let baseReps = 8 + Int(progressRatio * 12) // 8-20次
            let baseRest = max(40, 80 - Int(progressRatio * 30)) // 80-40秒
            let baseWeight = progressRatio > 0.3 ? Double.random(in: 0...5) : 0 // 進階加重
            
            return LegParameters(
                sets: 3,
                repetitions: min(20, baseReps),
                restTime: baseRest,
                duration: nil,       // 登階不用維持時間
                kneeAngleStart: nil, // 登階運動沒有角度限制
                kneeAngleEnd: nil,
                hipAngleStart: nil,  
                hipAngleEnd: nil,
                weight: baseWeight > 0 ? baseWeight : nil, // 進階可能加重
                mvic: nil,           // 登階不用MVIC
                stimulation: progressRatio > 0.5 ? Bool.random() : false,
                stimulationIntensity: progressRatio > 0.5 ? Int.random(in: 3...7) : nil
            )
        }
    }
    
    // MARK: - 表現指標生成
    
    private static func generatePerformanceMetrics(
        for exerciseType: SupportedExerciseType,
        progressRatio: Double
    ) -> TrainingPerformanceMetrics {
        
        let weights = exerciseType.performanceWeights
        let baseNoise = 0.1 // 基礎隨機變動
        
        // 肌力 (0-100，越高越好)
        let baseMuscleStrength = 30.0 + progressRatio * 50.0 // 30-80分
        let muscleStrength = baseMuscleStrength * weights.strength + 
                           Double.random(in: -baseNoise*10...baseNoise*10)
        
        // 穩定度 (0-100，越高越好)
        let baseStability = 40.0 + progressRatio * 45.0 // 40-85分
        let stability = baseStability * weights.stability + 
                       Double.random(in: -baseNoise*10...baseNoise*10)
        
        // 規律性 (0-100，越高越好)
        let baseRegularity = 35.0 + progressRatio * 50.0 // 35-85分
        let regularity = baseRegularity * weights.regularity + 
                        Double.random(in: -baseNoise*10...baseNoise*10)
        
        // 反應時間 (0-100分，越高越好)
        let baseReactionTime = 30.0 + progressRatio * 50.0 // 30-80分，改為正向評分
        let reactionTime = baseReactionTime * weights.reaction + 
                          Double.random(in: -baseNoise*10...baseNoise*10)
        
        // 完成度 (0-100，越高越好)
        let baseCompletionRate = 50.0 + progressRatio * 40.0 // 50-90分
        let completionRate = baseCompletionRate * weights.completion + 
                           Double.random(in: -baseNoise*10...baseNoise*10)
        
        return TrainingPerformanceMetrics(
            muscleStrength: max(0, min(100, muscleStrength)),
            stability: max(0, min(100, stability)),
            regularity: max(0, min(100, regularity)),
            reactionTime: max(0, min(100, reactionTime)),
            completionRate: max(0, min(100, completionRate))
        )
    }
    
    // MARK: - 輔助數據生成
    
    private static func generateSessionDuration(for exerciseType: SupportedExerciseType) -> TimeInterval {
        switch exerciseType {
        case .kneeExtension:
            return TimeInterval.random(in: 300...600) // 5-10分鐘
        case .partialSquat:
            return TimeInterval.random(in: 400...800) // 6-13分鐘
        case .stepUp:
            return TimeInterval.random(in: 500...900) // 8-15分鐘
        }
    }
    
    private static func generatePainLevel(progressRatio: Double) -> Int? {
        // 疼痛隨進步減少
        let basePain = Int(8.0 - progressRatio * 6.0) // 8降到2
        let variation = Int.random(in: -1...1)
        return max(0, min(10, basePain + variation))
    }
    
    private static func generateEffortLevel() -> Int? {
        return Int.random(in: 6...9) // 努力程度較為穩定
    }
    
    private static func generateNotes(
        for exerciseType: SupportedExerciseType,
        progressRatio: Double
    ) -> String? {
        
        let progressiveNotes: [String]
        
        switch exerciseType {
        case .kneeExtension:
            progressiveNotes = [
                "膝關節伸展角度逐漸改善",
                "肌肉收縮品質提升",
                "終端伸展維持能力增強",
                "膝關節穩定性明顯改善",
                "動作執行越來越流暢"
            ]
            
        case .partialSquat:
            progressiveNotes = [
                "蹲下深度逐漸增加",
                "平衡控制能力提升",
                "下肢肌力明顯增強",
                "動作協調性改善",
                "膝關節承重能力提升"
            ]
            
        case .stepUp:
            progressiveNotes = [
                "登階動作更加穩定",
                "單腿支撐能力增強",
                "動作節奏掌握良好",
                "平衡反應速度提升",
                "整體功能性活動改善"
            ]
        }
        
        if progressRatio > 0.6 {
            return progressiveNotes.randomElement()
        } else if progressRatio > 0.3 {
            return progressiveNotes.randomElement()
        }
        
        return nil
    }
}


import Foundation
import GRDB

// MARK: - Database Migration and Data Transfer

/// 負責將現有UserDefaults數據遷移到GRDB數據庫
class DatabaseMigrationManager {
    static let shared = DatabaseMigrationManager()
    private let database = TrainingResultDatabase.shared
    
    private init() {}
    
    /// 執行完整的數據遷移
    func performMigration() throws {
        print("開始數據庫遷移...")
        
        // 檢查是否已經遷移過
        if UserDefaults.standard.bool(forKey: "database_migration_completed") {
            print("數據庫遷移已完成")
            return
        }
        
        try migrateTrainingRecords()
        try migrateAssessmentRecords()
        
        // 標記遷移完成
        UserDefaults.standard.set(true, forKey: "database_migration_completed")
        print("數據庫遷移完成")
    }
    
    /// 遷移訓練記錄數據
    private func migrateTrainingRecords() throws {
        print("遷移訓練記錄...")
        
        if let data = UserDefaults.standard.data(forKey: "trainingRecords"),
           let oldRecords = try? JSONDecoder().decode([TrainingRecord].self, from: data) {
            
            for oldRecord in oldRecords {
                try migrateTrainingRecord(oldRecord)
            }
            
            print("已遷移 \(oldRecords.count) 條訓練記錄")
        }
    }
    
    /// 遷移評估記錄數據
    private func migrateAssessmentRecords() throws {
        print("遷移評估記錄...")
        
        if let data = UserDefaults.standard.data(forKey: "assessmentRecords"),
           let oldRecords = try? JSONDecoder().decode([AssessmentRecord].self, from: data) {
            
            for oldRecord in oldRecords {
                try migrateAssessmentRecord(oldRecord)
            }
            
            print("已遷移 \(oldRecords.count) 條評估記錄")
        }
    }
    
    /// 遷移單個訓練記錄
    private func migrateTrainingRecord(_ oldRecord: TrainingRecord) throws {
        // 為每個運動創建一個訓練結果記錄
        for exerciseRecord in oldRecord.exercises {
            let trainingResult = PersistentTrainingResult(
                id: nil,
                sessionId: oldRecord.id.uuidString,
                patientId: oldRecord.patientId,
                exerciseId: exerciseRecord.exerciseId,
                recordDate: oldRecord.date,
                menuId: oldRecord.menuId.uuidString,
                leg: .right, // 默認右腿，舊數據可能沒有腿部信息
                
                // 目標參數 - 舊數據可能沒有，使用默認值
                targetSets: exerciseRecord.sets.count,
                targetReps: exerciseRecord.sets.first?.repetitions ?? 10,
                targetDuration: nil,
                targetRestTime: 30,
                targetKneeAngleStart: nil,
                targetKneeAngleEnd: nil,
                targetHipAngleStart: nil,
                targetHipAngleEnd: nil,
                targetMVIC: nil,
                stimulationEnabled: false,
                stimulationIntensity: nil,
                stimulationFrequency: nil,
                stimulationPulseWidth: nil,
                
                // 實際結果
                actualSets: exerciseRecord.sets.count,
                actualReps: exerciseRecord.sets.reduce(0) { $0 + $1.repetitions },
                totalDuration: exerciseRecord.sets.reduce(0) { $0 + $1.duration },
                avgPainScore: nil,
                notes: exerciseRecord.sets.compactMap { $0.notes }.joined(separator: "; "),
                overallCompletion: Double(exerciseRecord.sets.reduce(0) { $0 + $1.performance }) / Double(exerciseRecord.sets.count * 5),
                overallPerformance: Double(exerciseRecord.sets.reduce(0) { $0 + $1.performance }) / Double(exerciseRecord.sets.count),
                
                createdAt: oldRecord.date,
                updatedAt: oldRecord.date
            )
            
            let resultId = try database.saveTrainingResult(trainingResult)
            
            // 遷移組別數據
            for (index, set) in exerciseRecord.sets.enumerated() {
                let setResult = SetResult(
                    id: nil,
                    trainingResultId: resultId,
                    setNumber: index + 1,
                    repsAchieved: set.repetitions,
                    duration: set.duration,
                    restTime: 30.0, // 默認休息時間
                    painScore: nil,
                    notes: set.notes,
                    createdAt: oldRecord.date
                )
                
                try database.saveSetResult(setResult)
            }
            
            // 為遷移的數據創建基本的表現指標
            let completionMetric = PerformanceMetric(
                id: nil,
                trainingResultId: resultId,
                metricType: .completionRate,
                value: trainingResult.overallCompletion * 100,
                unit: "%",
                description: "從舊數據遷移的完成度",
                createdAt: oldRecord.date
            )
            
            try database.savePerformanceMetric(completionMetric)
        }
    }
    
    /// 遷移單個評估記錄
    private func migrateAssessmentRecord(_ oldRecord: AssessmentRecord) throws {
        let assessmentResult = AssessmentResult(
            id: nil,
            assessmentId: oldRecord.assessmentId,
            patientId: oldRecord.patientId,
            assessmentType: oldRecord.assessmentId, // 舊數據可能需要處理
            recordDate: oldRecord.date,
            totalScore: oldRecord.totalScore,
            maxScore: 100.0, // 默認最高分
            notes: oldRecord.notes,
            createdAt: oldRecord.date,
            updatedAt: oldRecord.date
        )
        
        let resultId = try database.saveAssessmentResult(assessmentResult)
        
        // 遷移分項分數
        for (category, score) in oldRecord.scores {
            let subScore = AssessmentSubScore(
                id: nil,
                assessmentResultId: resultId,
                category: category,
                score: score,
                maxScore: 100.0, // 默認最高分
                questionResponses: nil, // 舊數據可能沒有詳細問題回答
                createdAt: oldRecord.date
            )
            
            try database.saveAssessmentSubScore(subScore)
        }
    }
}

// MARK: - Sample Data Generator

/// 生成示例數據用於測試
class SampleDataGenerator {
    static let shared = SampleDataGenerator()
    private let database = TrainingResultDatabase.shared
    
    private init() {}
    
    /// 為指定患者生成示例訓練數據
    func generateSampleTrainingData(for patientId: String, days: Int = 30) throws {
        let calendar = Calendar.current
        let exerciseIds = [
            "quadriceps_isometric", "terminal_knee_extension", "straight_leg_raise",
            "prone_leg_lift", "side_lying_abduction", "bridge_exercise"
        ]
        
        for day in 0..<days {
            guard let date = calendar.date(byAdding: .day, value: -day, to: Date()) else { continue }
            
            // 每天隨機選擇1-3個運動
            let dayExercises = exerciseIds.shuffled().prefix(Int.random(in: 1...3))
            
            for exerciseId in dayExercises {
                try generateSampleExerciseResult(
                    patientId: patientId,
                    exerciseId: exerciseId,
                    date: date
                )
            }
        }
    }
    
    /// 生成單個運動的示例結果
    private func generateSampleExerciseResult(patientId: String, exerciseId: String, date: Date) throws {
        let sessionId = UUID().uuidString
        let targetSets = Int.random(in: 2...4)
        let targetReps = Int.random(in: 8...15)
        
        let trainingResult = PersistentTrainingResult(
            id: nil,
            sessionId: sessionId,
            patientId: patientId,
            exerciseId: exerciseId,
            recordDate: date,
            menuId: nil,
            leg: LegSide.allCases.randomElement()!,
            
            // 目標參數
            targetSets: targetSets,
            targetReps: targetReps,
            targetDuration: Int.random(in: 10...30),
            targetRestTime: 30,
            targetKneeAngleStart: 0,
            targetKneeAngleEnd: Int.random(in: 60...90),
            targetHipAngleStart: 0,
            targetHipAngleEnd: Int.random(in: 30...45),
            targetMVIC: Int.random(in: 40...80),
            stimulationEnabled: Bool.random(),
            stimulationIntensity: Int.random(in: 1...10),
            stimulationFrequency: Int.random(in: 1...10),
            stimulationPulseWidth: Int.random(in: 1...10),
            
            // 實際結果 (添加一些變異性)
            actualSets: targetSets,
            actualReps: Int.random(in: max(1, targetReps-2)...(targetReps+1)),
            totalDuration: TimeInterval.random(in: 180...600),
            avgPainScore: Double.random(in: 0...5),
            notes: generateRandomNotes(),
            overallCompletion: Double.random(in: 0.7...1.0),
            overallPerformance: Double.random(in: 3.0...5.0),
            
            createdAt: date,
            updatedAt: date
        )
        
        let resultId = try database.saveTrainingResult(trainingResult)
        
        // 生成組別結果
        for setNumber in 1...targetSets {
            let setResult = SetResult(
                id: nil,
                trainingResultId: resultId,
                setNumber: setNumber,
                repsAchieved: Int.random(in: max(1, targetReps-2)...targetReps),
                duration: TimeInterval.random(in: 30...120),
                restTime: TimeInterval.random(in: 25...45),
                painScore: Double.random(in: 0...5),
                notes: setNumber == 1 ? generateRandomNotes() : nil,
                createdAt: date
            )
            
            try database.saveSetResult(setResult)
        }
        
        // 生成表現指標 (對應CSV中的結果呈現)
        let metricsToGenerate = getMetricsForExercise(exerciseId)
        for metricType in metricsToGenerate {
            let metric = PerformanceMetric(
                id: nil,
                trainingResultId: resultId,
                metricType: metricType,
                value: generateMetricValue(for: metricType),
                unit: metricType.unit,
                description: metricType.description,
                createdAt: date
            )
            
            try database.savePerformanceMetric(metric)
        }
    }
    
    /// 為指定患者生成示例評估數據
    func generateSampleAssessmentData(for patientId: String, months: Int = 6) throws {
        let calendar = Calendar.current
        let assessmentTypes = ["WOMAC", "KOOS", "SF-36"]
        
        for month in 0..<months {
            guard let date = calendar.date(byAdding: .month, value: -month, to: Date()) else { continue }
            
            for assessmentType in assessmentTypes {
                // 每月隨機決定是否進行該評估
                if Bool.random() {
                    try generateSampleAssessmentResult(
                        patientId: patientId,
                        assessmentType: assessmentType,
                        date: date
                    )
                }
            }
        }
    }
    
    private func generateSampleAssessmentResult(patientId: String, assessmentType: String, date: Date) throws {
        let totalScore = Double.random(in: 20...80)
        let maxScore = 100.0
        
        let assessmentResult = AssessmentResult(
            id: nil,
            assessmentId: UUID().uuidString,
            patientId: patientId,
            assessmentType: assessmentType,
            recordDate: date,
            totalScore: totalScore,
            maxScore: maxScore,
            notes: generateRandomNotes(),
            createdAt: date,
            updatedAt: date
        )
        
        let resultId = try database.saveAssessmentResult(assessmentResult)
        
        // 生成分項分數
        let categories = getAssessmentCategories(for: assessmentType)
        for category in categories {
            let subScore = AssessmentSubScore(
                id: nil,
                assessmentResultId: resultId,
                category: category,
                score: Double.random(in: 15...25),
                maxScore: 25.0,
                questionResponses: nil,
                createdAt: date
            )
            
            try database.saveAssessmentSubScore(subScore)
        }
    }
    
    // MARK: - Helper Methods
    
    private func getMetricsForExercise(_ exerciseId: String) -> [MetricType] {
        // 根據運動類型返回相應的指標
        switch exerciseId {
        case "quadriceps_isometric":
            return [.muscleStrength, .stabilityEMG, .regularityEMG, .reactionTime, .completionRate]
        case "terminal_knee_extension", "straight_leg_raise":
            return [.muscleEndurance, .stabilityAngle, .regularityAngle, .reactionTime, .completionRate]
        case "bridge_exercise":
            return [.muscleStrength, .stabilityEMG, .regularityEMG, .reactionTime, .completionRate]
        default:
            return [.muscleEndurance, .stabilityAngle, .regularityAngle, .reactionTime, .completionRate]
        }
    }
    
    private func generateMetricValue(for metricType: MetricType) -> Double {
        switch metricType {
        case .muscleStrength, .muscleEndurance:
            return Double.random(in: 50...100)
        case .stabilityAngle, .stabilityEMG, .regularityAngle, .regularityEMG:
            return Double.random(in: 2...8) // 變異係數
        case .reactionTime:
            return Double.random(in: 200...800) // 毫秒
        case .completionRate:
            return Double.random(in: 70...100) // 百分比
        case .smoothness, .correctness:
            return Double.random(in: 3...5) // 1-5分
        default:
            return Double.random(in: 1...100)
        }
    }
    
    private func getAssessmentCategories(for assessmentType: String) -> [String] {
        switch assessmentType {
        case "WOMAC":
            return ["疼痛", "僵硬", "身體功能"]
        case "KOOS":
            return ["疼痛", "症狀", "日常生活活動", "體育及娛樂功能", "生活品質"]
        case "SF-36":
            return ["身體活動功能", "身體健康影響角色限制", "身體疼痛", "一般健康狀況"]
        default:
            return ["總分"]
        }
    }
    
    private func generateRandomNotes() -> String? {
        let notes = [
            "患者今日表現良好",
            "有輕微疼痛但能完成動作",
            "角度控制需要改善",
            "肌力有明顯進步",
            "建議增加訓練強度",
            nil, nil, nil // 增加沒有備註的機率
        ]
        return notes.randomElement()!
    }
}

// MARK: - Data Export for Development

/// 用於開發階段的數據匯出功能
class DataExporter {
    static let shared = DataExporter()
    private let database = TrainingResultDatabase.shared
    
    private init() {}
    
    /// 匯出指定患者的所有訓練數據為JSON
    func exportTrainingData(for patientId: String) throws -> Data {
        let results = try database.getTrainingResults(for: patientId)
        
        var exportData: [[String: Any]] = []
        
        for result in results {
            let sets = try database.getSetResults(for: result.id!)
            let metrics = try database.getPerformanceMetrics(for: result.id!)
            
            let resultData: [String: Any] = [
                "sessionId": result.sessionId,
                "exerciseId": result.exerciseId,
                "date": ISO8601DateFormatter().string(from: result.recordDate),
                "leg": result.leg.rawValue,
                "targetSets": result.targetSets,
                "actualSets": result.actualSets,
                "overallCompletion": result.overallCompletion,
                "overallPerformance": result.overallPerformance,
                "sets": sets.map { set in
                    [
                        "setNumber": set.setNumber,
                        "repsAchieved": set.repsAchieved,
                        "duration": set.duration,
                        "painScore": set.painScore as Any
                    ]
                },
                "metrics": metrics.map { metric in
                    [
                        "type": metric.metricType.rawValue,
                        "value": metric.value,
                        "unit": metric.unit as Any,
                        "description": metric.description as Any
                    ]
                }
            ]
            
            exportData.append(resultData)
        }
        
        return try JSONSerialization.data(withJSONObject: exportData, options: .prettyPrinted)
    }
    
    /// 匯出指定患者的所有評估數據為JSON
    func exportAssessmentData(for patientId: String) throws -> Data {
        let results = try database.getAssessmentResults(for: patientId)
        
        var exportData: [[String: Any]] = []
        
        for result in results {
            let subScores = try database.getAssessmentSubScores(for: result.id!)
            
            let resultData: [String: Any] = [
                "assessmentType": result.assessmentType,
                "date": ISO8601DateFormatter().string(from: result.recordDate),
                "totalScore": result.totalScore,
                "maxScore": result.maxScore,
                "subScores": subScores.map { subScore in
                    [
                        "category": subScore.category,
                        "score": subScore.score,
                        "maxScore": subScore.maxScore
                    ]
                }
            ]
            
            exportData.append(resultData)
        }
        
        return try JSONSerialization.data(withJSONObject: exportData, options: .prettyPrinted)
    }
}
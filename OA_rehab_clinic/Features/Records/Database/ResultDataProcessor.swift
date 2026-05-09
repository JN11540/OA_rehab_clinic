import Foundation
import GRDB

// MARK: - Data Processing for Patient App Results

/// 處理來自個案App的訓練結果數據
class ResultDataProcessor {
    static let shared = ResultDataProcessor()
    private let database = TrainingResultDatabase.shared
    
    private init() {}
    
    // MARK: - Training Result Processing
    
    /// 處理來自個案App的訓練結果JSON數據
    func processTrainingResult(from jsonData: Data) throws {
        let patientResult = try JSONDecoder().decode(PatientTrainingResult.self, from: jsonData)
        
        // 轉換為數據庫模型並保存
        let trainingResult = try convertToTrainingResult(patientResult)
        let resultId = try database.saveTrainingResult(trainingResult)
        
        // 保存組別結果
        for (index, set) in patientResult.sets.enumerated() {
            let setResult = convertToSetResult(set, setNumber: index + 1, trainingResultId: resultId)
            try database.saveSetResult(setResult)
            
            // 保存組別指標
            for metric in set.metrics ?? [] {
                let setMetric = convertToSetMetric(metric, setResultId: setResult.id!)
                try database.saveSetMetric(setMetric)
            }
        }
        
        // 保存整體表現指標
        for metric in patientResult.overallMetrics {
            let performanceMetric = convertToPerformanceMetric(metric, trainingResultId: resultId)
            try database.savePerformanceMetric(performanceMetric)
        }
    }
    
    /// 處理評估結果
    func processAssessmentResult(from jsonData: Data) throws {
        let patientAssessment = try JSONDecoder().decode(PatientAssessmentResult.self, from: jsonData)
        
        let assessmentResult = convertToAssessmentResult(patientAssessment)
        let resultId = try database.saveAssessmentResult(assessmentResult)
        
        // 保存分項分數
        for subScore in patientAssessment.subScores ?? [] {
            let assessmentSubScore = convertToAssessmentSubScore(subScore, assessmentResultId: resultId)
            try database.saveAssessmentSubScore(assessmentSubScore)
        }
    }
    
    // MARK: - Conversion Methods
    
    private func convertToTrainingResult(_ patientResult: PatientTrainingResult) throws -> PersistentTrainingResult {
        return PersistentTrainingResult(
            id: nil,
            sessionId: patientResult.sessionId ?? "",
            patientId: patientResult.patientId,
            exerciseId: patientResult.exerciseId,
            recordDate: patientResult.recordDate,
            menuId: patientResult.menuId,
            leg: LegSide(rawValue: patientResult.leg ?? "") ?? .right,

            // 目標參數
            targetSets: patientResult.targetParameters.sets ?? 0,
            targetReps: patientResult.targetParameters.reps ?? 0,
            targetDuration: patientResult.targetParameters.duration,
            targetRestTime: patientResult.targetParameters.restTime,
            targetKneeAngleStart: patientResult.targetParameters.kneeAngleStart,
            targetKneeAngleEnd: patientResult.targetParameters.kneeAngleEnd,
            targetHipAngleStart: patientResult.targetParameters.hipAngleStart,
            targetHipAngleEnd: patientResult.targetParameters.hipAngleEnd,
            targetMVIC: patientResult.targetParameters.mvic,
            stimulationEnabled: patientResult.targetParameters.stimulationEnabled,
            stimulationIntensity: patientResult.targetParameters.stimulationIntensity,
            stimulationFrequency: patientResult.targetParameters.stimulationFrequency,
            stimulationPulseWidth: patientResult.targetParameters.stimulationPulseWidth,
            
            // 實際結果
            actualSets: patientResult.actualSets ?? 0,
            actualReps: patientResult.actualReps ?? 0,
            totalDuration: patientResult.totalDuration,
            avgPainScore: patientResult.avgPainScore,
            notes: patientResult.notes,
            overallCompletion: patientResult.overallCompletion ?? 0,
            overallPerformance: patientResult.overallPerformance ?? 0,
            
            createdAt: Date(),
            updatedAt: Date()
        )
    }
    
    private func convertToSetResult(_ patientSet: PatientSetResult, setNumber: Int, trainingResultId: Int64) -> SetResult {
        return SetResult(
            id: nil,
            trainingResultId: trainingResultId,
            setNumber: setNumber,
            repsAchieved: patientSet.repsAchieved,
            duration: patientSet.duration,
            restTime: patientSet.restTime ?? 0,
            painScore: patientSet.painScore,
            notes: patientSet.notes,
            createdAt: Date()
        )
    }
    
    private func convertToSetMetric(_ patientMetric: PatientMetric, setResultId: Int64) -> SetMetric {
        return SetMetric(
            id: nil,
            setResultId: setResultId,
            metricType: MetricType(rawValue: patientMetric.type) ?? .completionRate,
            value: patientMetric.value,
            unit: patientMetric.unit,
            timestamp: patientMetric.timestamp,
            createdAt: Date()
        )
    }
    
    private func convertToPerformanceMetric(_ patientMetric: PatientMetric, trainingResultId: Int64) -> PerformanceMetric {
        return PerformanceMetric(
            id: nil,
            trainingResultId: trainingResultId,
            metricType: MetricType(rawValue: patientMetric.type) ?? .completionRate,
            value: patientMetric.value,
            unit: patientMetric.unit,
            description: patientMetric.description,
            createdAt: Date()
        )
    }
    
    private func convertToAssessmentResult(_ patientAssessment: PatientAssessmentResult) -> AssessmentResult {
        return AssessmentResult(
            id: nil,
            assessmentId: patientAssessment.assessmentId,
            patientId: patientAssessment.patientId,
            assessmentType: patientAssessment.assessmentType,
            recordDate: patientAssessment.recordDate,
            totalScore: patientAssessment.totalScore,
            maxScore: patientAssessment.maxScore,
            notes: patientAssessment.notes,
            createdAt: Date(),
            updatedAt: Date()
        )
    }
    
    private func convertToAssessmentSubScore(_ patientSubScore: PatientSubScore, assessmentResultId: Int64) -> AssessmentSubScore {
        let questionResponsesJSON = try? JSONEncoder().encode(patientSubScore.questionResponses)
        let questionResponsesString = questionResponsesJSON.flatMap { String(data: $0, encoding: .utf8) }
        
        return AssessmentSubScore(
            id: nil,
            assessmentResultId: assessmentResultId,
            category: patientSubScore.category,
            score: patientSubScore.score,
            maxScore: patientSubScore.maxScore,
            questionResponses: questionResponsesString,
            createdAt: Date()
        )
    }
}

// MARK: - Patient App Result Models

/// 個案App傳送的訓練結果數據結構
struct PatientTrainingResult: Codable {
    let sessionId: String?
    let patientId: String
    let exerciseId: String
    let recordDate: Date
    let menuId: String?
    let leg: String?

    // 目標參數 (從訓練安排複製)
    let targetParameters: PatientTargetParameters

    // 實際執行結果
    let actualSets: Int?
    let actualReps: Int?
    let totalDuration: TimeInterval
    let avgPainScore: Double?
    let notes: String?

    // 整體表現
    let overallCompletion: Double?
    let overallPerformance: Double?

    // 詳細的組別結果
    let sets: [PatientSetResult]

    // 整體指標 (對應CSV中的結果呈現)
    let overallMetrics: [PatientMetric]
}

struct PatientTargetParameters: Codable {
    let sets: Int?
    let reps: Int?
    let duration: Int?
    let restTime: Int
    let kneeAngleStart: Int?
    let kneeAngleEnd: Int?
    let hipAngleStart: Int?
    let hipAngleEnd: Int?
    let mvic: Int?
    let stimulationEnabled: Bool
    let stimulationIntensity: Int?
    let stimulationFrequency: Int?
    let stimulationPulseWidth: Int?
}

struct PatientSetResult: Codable {
    let repsAchieved: Int
    let duration: TimeInterval
    let restTime: TimeInterval?
    let painScore: Double?
    let notes: String?
    let metrics: [PatientMetric]?
}

struct PatientMetric: Codable {
    let type: String // MetricType.rawValue
    let value: Double
    let unit: String?
    let description: String?
    let timestamp: Date?
}

/// 個案App傳送的評估結果數據結構
struct PatientAssessmentResult: Codable {
    let assessmentId: String
    let patientId: String
    let assessmentType: String // AssessmentType.rawValue
    let recordDate: Date
    let totalScore: Double
    let maxScore: Double
    let notes: String?
    
    // 分項分數
    let subScores: [PatientSubScore]?
}

struct PatientSubScore: Codable {
    let category: String // 例如：WOMAC的"疼痛"、"僵硬"、"功能"
    let score: Double
    let maxScore: Double
    let questionResponses: [QuestionResponse] // 問題回答詳情
}

struct QuestionResponse: Codable {
    let questionId: String
    let question: String
    let answer: String
    let score: Double
}

// MARK: - Chart Data Models

/// 用於圖表顯示的數據結構
struct ChartDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let value: Double
    let metricType: MetricType
    let exerciseName: String?
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd"
        return formatter.string(from: date)
    }
}

struct ExerciseProgressData {
    let exerciseId: String
    let exerciseName: String
    let metrics: [MetricType: [ChartDataPoint]]
    let improvementRate: Double // 改善率
    let consistency: Double // 一致性分數
}

struct AssessmentProgressData {
    let assessmentType: AssessmentType
    let totalScores: [ChartDataPoint]
    let subScores: [String: [ChartDataPoint]] // 分項分數
    let improvementRate: Double
    let latestScore: Double
}

// MARK: - Data Analysis Extensions

extension TrainingResultDatabase {
    
    /// 獲取運動進度數據用於圖表顯示
    func getExerciseProgressData(patientId: String, 
                               exerciseId: String, 
                               days: Int = 30) throws -> ExerciseProgressData {
        let results = try getTrainingResults(for: exerciseId, patientId: patientId, 
                                           from: Calendar.current.date(byAdding: .day, value: -days, to: Date()))
        
        var metricsData: [MetricType: [ChartDataPoint]] = [:]
        
        for result in results {
            let metrics = try getPerformanceMetrics(for: result.id!)
            
            for metric in metrics {
                let dataPoint = ChartDataPoint(
                    date: result.recordDate,
                    value: metric.value,
                    metricType: metric.metricType,
                    exerciseName: nil // 可以從ExerciseStore獲取
                )
                
                metricsData[metric.metricType, default: []].append(dataPoint)
            }
        }
        
        // 計算改善率和一致性
        let improvementRate = calculateImprovementRate(from: metricsData)
        let consistency = calculateConsistency(from: results)
        
        return ExerciseProgressData(
            exerciseId: exerciseId,
            exerciseName: "", // 需要從ExerciseStore獲取
            metrics: metricsData,
            improvementRate: improvementRate,
            consistency: consistency
        )
    }
    
    /// 獲取評估進度數據
    func getAssessmentProgressData(patientId: String,
                                 assessmentType: AssessmentType,
                                 months: Int = 6) throws -> AssessmentProgressData {
        let results = try getAssessmentResults(
            for: patientId,
            assessmentType: assessmentType.rawValue,
            from: Calendar.current.date(byAdding: .month, value: -months, to: Date())
        )
        
        let totalScores = results.map { result in
            ChartDataPoint(
                date: result.recordDate,
                value: result.totalScore,
                metricType: .completionRate, // 暫時使用
                exerciseName: nil
            )
        }
        
        // TODO: 獲取分項分數
        let subScores: [String: [ChartDataPoint]] = [:]
        
        let improvementRate = calculateAssessmentImprovementRate(from: results)
        let latestScore = results.first?.totalScore ?? 0.0
        
        return AssessmentProgressData(
            assessmentType: assessmentType,
            totalScores: totalScores,
            subScores: subScores,
            improvementRate: improvementRate,
            latestScore: latestScore
        )
    }
    
    private func calculateImprovementRate(from metricsData: [MetricType: [ChartDataPoint]]) -> Double {
        // 計算主要指標的改善率
        guard let completionData = metricsData[.completionRate],
              completionData.count >= 2 else { return 0.0 }
        
        let sortedData = completionData.sorted { $0.date < $1.date }
        let firstValue = sortedData.first!.value
        let lastValue = sortedData.last!.value
        
        return (lastValue - firstValue) / firstValue * 100
    }
    
    private func calculateConsistency(from results: [PersistentTrainingResult]) -> Double {
        guard results.count >= 3 else { return 0.0 }
        
        let performances = results.map { $0.overallPerformance }
        let average = performances.reduce(0, +) / Double(performances.count)
        let variance = performances.map { pow($0 - average, 2) }.reduce(0, +) / Double(performances.count)
        let standardDeviation = sqrt(variance)
        
        // 一致性分數：標準差越小，一致性越高
        return max(0, 100 - standardDeviation * 20)
    }
    
    private func calculateAssessmentImprovementRate(from results: [AssessmentResult]) -> Double {
        guard results.count >= 2 else { return 0.0 }
        
        let sortedResults = results.sorted { $0.recordDate < $1.recordDate }
        let firstScore = sortedResults.first!.totalScore
        let lastScore = sortedResults.last!.totalScore
        
        return (lastScore - firstScore) / firstScore * 100
    }
}

// MARK: - Database Extensions for Set Metrics

extension TrainingResultDatabase {
    
    func saveSetMetric(_ metric: SetMetric) throws {
        try dbQueue.write { db in
            var mutableMetric = metric
            try mutableMetric.save(db)
        }
    }
    
    func getSetMetrics(for setResultId: Int64) throws -> [SetMetric] {
        return try dbQueue.read { db in
            return try SetMetric
                .filter(Column("setResultId") == setResultId)
                .fetchAll(db)
        }
    }
    
    func saveAssessmentSubScore(_ subScore: AssessmentSubScore) throws {
        try dbQueue.write { db in
            var mutableSubScore = subScore
            try mutableSubScore.save(db)
        }
    }
    
    func getAssessmentSubScores(for assessmentResultId: Int64) throws -> [AssessmentSubScore] {
        return try dbQueue.read { db in
            return try AssessmentSubScore
                .filter(Column("assessmentResultId") == assessmentResultId)
                .fetchAll(db)
        }
    }
}
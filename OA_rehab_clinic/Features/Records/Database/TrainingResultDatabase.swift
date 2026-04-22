import Foundation
import GRDB

// MARK: - 🏥 DATABASE LAYER - 持久化訓練結果數據模型
//
// 用途說明：
// - 儲存來自患者App的完整訓練數據
// - 包含詳細的設定參數、實際表現和各種指標
// - 支援GRDB持久化，用於長期數據存儲和查詢
// - 數據來源：患者App透過JSON格式傳輸的訓練記錄
// - 使用場景：數據庫操作、歷史記錄查詢、數據分析統計
//
// ⚠️ 注意：請勿與UI層的TrainingVisualizationData混淆使用

// MARK: - Database Models

/// 持久化訓練結果主記錄 - 來自患者App的完整訓練數據
/// 包含設定參數、實際表現和所有相關指標，用於數據庫持久化存儲
struct PersistentTrainingResult: Codable, FetchableRecord, MutablePersistableRecord {
    var id: Int64?
    let sessionId: String // 訓練階段識別碼
    let patientId: String
    let exerciseId: String // 對應 ExerciseModule.Exercise.id
    let recordDate: Date
    let menuId: String? // 關聯的訓練菜單
    let leg: LegSide // 左腿或右腿
    
    // 設定參數 (從 ExerciseParameters 複製)
    let targetSets: Int
    let targetReps: Int
    let targetDuration: Int? // 維持時間(秒)
    let targetRestTime: Int // 組間休息時間(秒)
    let targetKneeAngleStart: Int?
    let targetKneeAngleEnd: Int?
    let targetHipAngleStart: Int?
    let targetHipAngleEnd: Int?
    let targetMVIC: Int? // 肌電閾值(%)
    let stimulationEnabled: Bool
    let stimulationIntensity: Int?
    let stimulationFrequency: Int?
    let stimulationPulseWidth: Int?
    
    // 實際完成狀況
    let actualSets: Int
    let actualReps: Int
    let totalDuration: TimeInterval // 總訓練時間
    let avgPainScore: Double? // VAS疼痛量表平均分數 (0-10)
    let notes: String?
    
    // 整體完成度指標
    let overallCompletion: Double // 0.0-1.0
    let overallPerformance: Double // 1.0-5.0 整體表現評分
    
    let createdAt: Date
    let updatedAt: Date
    
    // MARK: - Database Table Definition
    static let databaseTableName = "training_results"
    
    mutating func didInsert(with rowID: Int64, for column: String?) {
        id = rowID
    }
}

/// 詳細的組別記錄
struct SetResult: Codable, FetchableRecord, MutablePersistableRecord {
    var id: Int64?
    let trainingResultId: Int64
    let setNumber: Int
    let repsAchieved: Int
    let duration: TimeInterval // 該組持續時間
    let restTime: TimeInterval // 組間實際休息時間
    let painScore: Double? // VAS疼痛量表 (0-10)
    let notes: String?
    
    let createdAt: Date
    
    static let databaseTableName = "set_results"
    
    mutating func didInsert(with rowID: Int64, for column: String?) {
        id = rowID
    }
}

/// 動作指標結果 (對應CSV中的"結果呈現")
struct PerformanceMetric: Codable, FetchableRecord, MutablePersistableRecord {
    var id: Int64?
    let trainingResultId: Int64
    let metricType: MetricType
    let value: Double
    let unit: String?
    let description: String?
    
    let createdAt: Date
    
    static let databaseTableName = "performance_metrics"
    
    mutating func didInsert(with rowID: Int64, for column: String?) {
        id = rowID
    }
}

/// 組別層級的指標 (每組的詳細表現)
struct SetMetric: Codable, FetchableRecord, MutablePersistableRecord {
    var id: Int64?
    let setResultId: Int64
    let metricType: MetricType
    let value: Double
    let unit: String?
    let timestamp: Date? // 測量時間點
    
    let createdAt: Date
    
    static let databaseTableName = "set_metrics"
    
    mutating func didInsert(with rowID: Int64, for column: String?) {
        id = rowID
    }
}

/// 評估結果記錄
struct AssessmentResult: Codable, FetchableRecord, MutablePersistableRecord {
    var id: Int64?
    let assessmentId: String // 對應Assessment.id
    let patientId: String
    let assessmentType: String // AssessmentType.rawValue
    let recordDate: Date
    let totalScore: Double
    let maxScore: Double
    let notes: String?
    
    let createdAt: Date
    let updatedAt: Date
    
    static let databaseTableName = "assessment_results"
    
    mutating func didInsert(with rowID: Int64, for column: String?) {
        id = rowID
    }
}

/// 評估分項分數
struct AssessmentSubScore: Codable, FetchableRecord, MutablePersistableRecord {
    var id: Int64?
    let assessmentResultId: Int64
    let category: String // WOMAC的疼痛、僵硬、功能等分類
    let score: Double
    let maxScore: Double
    let questionResponses: String? // JSON格式存儲問題回答
    
    let createdAt: Date
    
    static let databaseTableName = "assessment_sub_scores"
    
    mutating func didInsert(with rowID: Int64, for column: String?) {
        id = rowID
    }
}

// MARK: - Enums

enum LegSide: String, Codable, CaseIterable {
    case left = "左腿"
    case right = "右腿"
    case both = "雙腿"
}

enum MetricType: String, Codable, CaseIterable {
    // 肌力相關
    case muscleStrength = "肌力" // 肌電強度
    case muscleEndurance = "肌耐力" // 維持時角度變化
    
    // 穩定性相關
    case stabilityAngle = "穩定性_角度" // 每組角度變化
    case stabilityEMG = "穩定性_肌電" // 每組肌電變化
    case muscleStability = "肌肉穩定性" // 同組多次肌電變化
    case movementStability = "動作穩定性" // 維持時角度變化
    
    // 規律性
    case regularityAngle = "規律性_角度" // 同組多次角度變化
    case regularityEMG = "規律性_肌電" // 同組多次肌電變化
    
    // 反應與完成度
    case reactionTime = "反應時間"
    case completionRate = "完成度" // 達到設定閾值次數比例/正確動作次數比例
    
    // 動作品質
    case smoothness = "平滑度" // 單次動作忽快忽慢或暫停
    case correctness = "動作正確性" // 姿勢是否正確
    
    // 角度相關指標
    case angleRange = "角度範圍"
    case angleAccuracy = "角度準確度"
    case angleVariation = "角度變異"
    
    // 力量相關
    case emgIntensity = "肌電強度"
    case emgVariation = "肌電變異"
    case forceOutput = "力量輸出"
    
    var description: String {
        switch self {
        case .muscleStrength:
            return "肌力(肌電強度)"
        case .muscleEndurance:
            return "肌耐力(維持時角度變化)"
        case .stabilityAngle:
            return "穩定性(每組角度變化)"
        case .stabilityEMG:
            return "穩定性(每組肌電變化)"
        case .muscleStability:
            return "肌肉穩定性(同組多次肌電變化)"
        case .movementStability:
            return "動作穩定性(維持時角度變化)"
        case .regularityAngle:
            return "規律性(同組多次角度變化)"
        case .regularityEMG:
            return "規律性(同組多次肌電變化)"
        case .reactionTime:
            return "反應時間"
        case .completionRate:
            return "完成度(達到設定閾值次數比例)"
        case .smoothness:
            return "平滑度(單次動作忽快忽慢或暫停)"
        case .correctness:
            return "動作正確性(姿勢是否正確)"
        case .angleRange:
            return "關節角度範圍"
        case .angleAccuracy:
            return "角度準確度"
        case .angleVariation:
            return "角度變異度"
        case .emgIntensity:
            return "肌電信號強度"
        case .emgVariation:
            return "肌電信號變異"
        case .forceOutput:
            return "力量輸出"
        }
    }
    
    var unit: String {
        switch self {
        case .reactionTime:
            return "ms"
        case .completionRate:
            return "%"
        case .angleRange, .angleAccuracy, .angleVariation:
            return "度"
        case .emgIntensity, .emgVariation:
            return "%MVIC"
        case .muscleStrength, .muscleEndurance:
            return "N"
        case .forceOutput:
            return "N"
        default:
            return "分數"
        }
    }
}

// MARK: - Database Manager

class TrainingResultDatabase {
    static let shared = TrainingResultDatabase()
    internal var dbQueue: DatabaseQueue!
    
    private init() {
        setupDatabase()
    }
    
    private func setupDatabase() {
        let fileManager = FileManager.default
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let dbPath = documentsPath.appendingPathComponent("training_results.sqlite").path
        
        do {
            dbQueue = try DatabaseQueue(path: dbPath)
            try migrator.migrate(dbQueue)
        } catch {
            fatalError("Failed to setup database: \(error)")
        }
    }
    
    private var migrator: DatabaseMigrator {
        var migrator = DatabaseMigrator()
        
        migrator.registerMigration("createTables") { db in
            // 創建訓練結果表
            try db.create(table: "training_results") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("sessionId", .text).notNull()
                t.column("patientId", .text).notNull()
                t.column("exerciseId", .text).notNull()
                t.column("recordDate", .datetime).notNull()
                t.column("menuId", .text)
                t.column("leg", .text).notNull()
                
                // 目標參數
                t.column("targetSets", .integer).notNull()
                t.column("targetReps", .integer).notNull()
                t.column("targetDuration", .integer)
                t.column("targetRestTime", .integer).notNull()
                t.column("targetKneeAngleStart", .integer)
                t.column("targetKneeAngleEnd", .integer)
                t.column("targetHipAngleStart", .integer)
                t.column("targetHipAngleEnd", .integer)
                t.column("targetMVIC", .integer)
                t.column("stimulationEnabled", .boolean).notNull()
                t.column("stimulationIntensity", .integer)
                t.column("stimulationFrequency", .integer)
                t.column("stimulationPulseWidth", .integer)
                
                // 實際結果
                t.column("actualSets", .integer).notNull()
                t.column("actualReps", .integer).notNull()
                t.column("totalDuration", .double).notNull()
                t.column("avgPainScore", .double)
                t.column("notes", .text)
                t.column("overallCompletion", .double).notNull()
                t.column("overallPerformance", .double).notNull()
                
                t.column("createdAt", .datetime).notNull()
                t.column("updatedAt", .datetime).notNull()
                
                // 索引將在表創建後單獨創建
            }
            
            // 創建組別結果表
            try db.create(table: "set_results") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("trainingResultId", .integer)
                    .notNull()
                    .references("training_results", onDelete: .cascade)
                t.column("setNumber", .integer).notNull()
                t.column("repsAchieved", .integer).notNull()
                t.column("duration", .double).notNull()
                t.column("restTime", .double).notNull()
                t.column("painScore", .double)
                t.column("notes", .text)
                t.column("createdAt", .datetime).notNull()
                
                // 索引將在表創建後單獨創建
            }
            
            // 創建表現指標表
            try db.create(table: "performance_metrics") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("trainingResultId", .integer)
                    .notNull()
                    .references("training_results", onDelete: .cascade)
                t.column("metricType", .text).notNull()
                t.column("value", .double).notNull()
                t.column("unit", .text)
                t.column("description", .text)
                t.column("createdAt", .datetime).notNull()
                
                // 索引將在表創建後單獨創建
            }
            
            // 創建組別指標表
            try db.create(table: "set_metrics") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("setResultId", .integer)
                    .notNull()
                    .references("set_results", onDelete: .cascade)
                t.column("metricType", .text).notNull()
                t.column("value", .double).notNull()
                t.column("unit", .text)
                t.column("timestamp", .datetime)
                t.column("createdAt", .datetime).notNull()
                
                // 索引將在表創建後單獨創建
            }
            
            // 創建評估結果表
            try db.create(table: "assessment_results") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("assessmentId", .text).notNull()
                t.column("patientId", .text).notNull()
                t.column("assessmentType", .text).notNull()
                t.column("recordDate", .datetime).notNull()
                t.column("totalScore", .double).notNull()
                t.column("maxScore", .double).notNull()
                t.column("notes", .text)
                t.column("createdAt", .datetime).notNull()
                t.column("updatedAt", .datetime).notNull()
                
                // 索引將在表創建後單獨創建
            }
            
            // 創建評估分項表
            try db.create(table: "assessment_sub_scores") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("assessmentResultId", .integer)
                    .notNull()
                    .references("assessment_results", onDelete: .cascade)
                t.column("category", .text).notNull()
                t.column("score", .double).notNull()
                t.column("maxScore", .double).notNull()
                t.column("questionResponses", .text) // JSON
                t.column("createdAt", .datetime).notNull()
                
                // 索引將在表創建後單獨創建
            }
            
            // 創建索引
            try db.create(index: "idx_training_results_patient_date", on: "training_results", columns: ["patientId", "recordDate"])
            try db.create(index: "idx_training_results_exercise", on: "training_results", columns: ["exerciseId"])
            try db.create(index: "idx_training_results_session", on: "training_results", columns: ["sessionId"])
            
            try db.create(index: "idx_set_results_training", on: "set_results", columns: ["trainingResultId"])
            
            try db.create(index: "idx_performance_metrics_training_type", on: "performance_metrics", columns: ["trainingResultId", "metricType"])
            
            try db.create(index: "idx_set_metrics_set_type", on: "set_metrics", columns: ["setResultId", "metricType"])
            
            try db.create(index: "idx_assessment_results_patient_type_date", on: "assessment_results", columns: ["patientId", "assessmentType", "recordDate"])
            
            try db.create(index: "idx_assessment_sub_scores_result", on: "assessment_sub_scores", columns: ["assessmentResultId"])
        }
        
        return migrator
    }
}

// MARK: - Database Operations Extensions

extension TrainingResultDatabase {
    
    // MARK: - Training Results Operations
    
    func saveTrainingResult(_ result: PersistentTrainingResult) throws -> Int64 {
        return try dbQueue.write { db in
            var mutableResult = result
            try mutableResult.save(db)
            return mutableResult.id!
        }
    }
    
    func getTrainingResults(for patientId: String, 
                          from startDate: Date? = nil, 
                          to endDate: Date? = nil) throws -> [PersistentTrainingResult] {
        return try dbQueue.read { db in
            var request = PersistentTrainingResult
                .filter(Column("patientId") == patientId)
                .order(Column("recordDate").desc)
            
            if let startDate = startDate {
                request = request.filter(Column("recordDate") >= startDate)
            }
            if let endDate = endDate {
                request = request.filter(Column("recordDate") <= endDate)
            }
            
            return try request.fetchAll(db)
        }
    }
    
    func getTrainingResults(for exerciseId: String, 
                          patientId: String,
                          from startDate: Date? = nil, 
                          to endDate: Date? = nil) throws -> [PersistentTrainingResult] {
        return try dbQueue.read { db in
            var request = PersistentTrainingResult
                .filter(Column("patientId") == patientId && Column("exerciseId") == exerciseId)
                .order(Column("recordDate").desc)
            
            if let startDate = startDate {
                request = request.filter(Column("recordDate") >= startDate)
            }
            if let endDate = endDate {
                request = request.filter(Column("recordDate") <= endDate)
            }
            
            return try request.fetchAll(db)
        }
    }
    
    // MARK: - Set Results Operations
    
    func saveSetResult(_ setResult: SetResult) throws {
        try dbQueue.write { db in
            var mutableSet = setResult
            try mutableSet.save(db)
        }
    }
    
    func getSetResults(for trainingResultId: Int64) throws -> [SetResult] {
        return try dbQueue.read { db in
            return try SetResult
                .filter(Column("trainingResultId") == trainingResultId)
                .order(Column("setNumber"))
                .fetchAll(db)
        }
    }
    
    // MARK: - Performance Metrics Operations
    
    func savePerformanceMetric(_ metric: PerformanceMetric) throws {
        try dbQueue.write { db in
            var mutableMetric = metric
            try mutableMetric.save(db)
        }
    }
    
    func getPerformanceMetrics(for trainingResultId: Int64, 
                              metricType: MetricType? = nil) throws -> [PerformanceMetric] {
        return try dbQueue.read { db in
            var request = PerformanceMetric.filter(Column("trainingResultId") == trainingResultId)
            
            if let metricType = metricType {
                request = request.filter(Column("metricType") == metricType.rawValue)
            }
            
            return try request.fetchAll(db)
        }
    }
    
    // MARK: - Assessment Results Operations
    
    func saveAssessmentResult(_ result: AssessmentResult) throws -> Int64 {
        return try dbQueue.write { db in
            var mutableResult = result
            try mutableResult.save(db)
            return mutableResult.id!
        }
    }
    
    func getAssessmentResults(for patientId: String,
                            assessmentType: String? = nil,
                            from startDate: Date? = nil,
                            to endDate: Date? = nil) throws -> [AssessmentResult] {
        return try dbQueue.read { db in
            var request = AssessmentResult
                .filter(Column("patientId") == patientId)
                .order(Column("recordDate").desc)
            
            if let assessmentType = assessmentType {
                request = request.filter(Column("assessmentType") == assessmentType)
            }
            if let startDate = startDate {
                request = request.filter(Column("recordDate") >= startDate)
            }
            if let endDate = endDate {
                request = request.filter(Column("recordDate") <= endDate)
            }
            
            return try request.fetchAll(db)
        }
    }
    
    // MARK: - Analysis Methods
    
    /// 獲取運動表現趨勢數據
    func getExercisePerformanceTrend(patientId: String, 
                                   exerciseId: String, 
                                   metricType: MetricType,
                                   days: Int = 30) throws -> [(Date, Double)] {
        return try dbQueue.read { db in
            let endDate = Date()
            let startDate = Calendar.current.date(byAdding: .day, value: -days, to: endDate)!
            
            let sql = """
                SELECT tr.recordDate, AVG(pm.value) as avgValue
                FROM training_results tr
                JOIN performance_metrics pm ON tr.id = pm.trainingResultId
                WHERE tr.patientId = ? 
                  AND tr.exerciseId = ?
                  AND pm.metricType = ?
                  AND tr.recordDate >= ?
                  AND tr.recordDate <= ?
                GROUP BY DATE(tr.recordDate)
                ORDER BY tr.recordDate
            """
            
            let rows = try Row.fetchAll(db, sql: sql, arguments: [patientId, exerciseId, metricType.rawValue, startDate, endDate])
            
            return rows.compactMap { row in
                guard let date: Date = row["recordDate"],
                      let value: Double = row["avgValue"] else { return nil }
                return (date, value)
            }
        }
    }
    
    /// 獲取評估分數趨勢
    func getAssessmentScoreTrend(patientId: String,
                               assessmentType: String,
                               months: Int = 6) throws -> [(Date, Double)] {
        return try dbQueue.read { db in
            let endDate = Date()
            let startDate = Calendar.current.date(byAdding: .month, value: -months, to: endDate)!
            
            let sql = """
                SELECT recordDate, totalScore
                FROM assessment_results
                WHERE patientId = ? 
                  AND assessmentType = ?
                  AND recordDate >= ?
                  AND recordDate <= ?
                ORDER BY recordDate
            """
            
            let rows = try Row.fetchAll(db, sql: sql, arguments: [patientId, assessmentType, startDate, endDate])
            
            return rows.compactMap { row in
                guard let date: Date = row["recordDate"],
                      let score: Double = row["totalScore"] else { return nil }
                return (date, score)
            }
        }
    }
}
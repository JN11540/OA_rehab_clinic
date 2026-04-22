import Foundation

// 訓練紀錄
struct TrainingRecord: Identifiable, Codable {
    let id: UUID
    let patientId: String
    let date: Date
    let menuId: UUID
    let exercises: [ExerciseRecord]
    
    struct ExerciseRecord: Identifiable, Codable {
        let id: UUID
        let exerciseId: String
        let sets: [SetRecord]
        
        struct SetRecord: Codable {
            let repetitions: Int
            let weight: Double
            let duration: TimeInterval
            let performance: Int // 1-5 分表現評級
            let notes: String?
        }
    }
}

// 紀錄管理器
class RecordStore: ObservableObject {
    static let shared = RecordStore()
    
    @Published private(set) var trainingRecords: [TrainingRecord] = []
    @Published private(set) var assessmentRecords: [AssessmentRecord] = []
    
    private init() {
        loadRecords()
    }
    
    private func loadRecords() {
        // 從 UserDefaults 讀取紀錄
        if let data = UserDefaults.standard.data(forKey: "trainingRecords"),
           let decoded = try? JSONDecoder().decode([TrainingRecord].self, from: data) {
            trainingRecords = decoded
        }
        
        if let data = UserDefaults.standard.data(forKey: "assessmentRecords"),
           let decoded = try? JSONDecoder().decode([AssessmentRecord].self, from: data) {
            assessmentRecords = decoded
        }
    }
    
    private func saveRecords() {
        if let encoded = try? JSONEncoder().encode(trainingRecords) {
            UserDefaults.standard.set(encoded, forKey: "trainingRecords")
        }
        
        if let encoded = try? JSONEncoder().encode(assessmentRecords) {
            UserDefaults.standard.set(encoded, forKey: "assessmentRecords")
        }
    }
    
    // MARK: - Training Records
    func getTrainingRecords(for patientId: String) -> [TrainingRecord] {
        trainingRecords.filter { $0.patientId == patientId }
    }
    
    func addTrainingRecord(_ record: TrainingRecord) {
        trainingRecords.append(record)
        saveRecords()
    }
    
    // MARK: - Assessment Records
    func getAssessmentRecords(for patientId: String) -> [AssessmentRecord] {
        assessmentRecords.filter { $0.patientId == patientId }
    }
    
    func addAssessmentRecord(_ record: AssessmentRecord) {
        assessmentRecords.append(record)
        saveRecords()
    }
    
    // MARK: - Analysis Methods
    func getExerciseProgress(patientId: String, exerciseId: String, startDate: Date, endDate: Date) -> [TrainingRecord.ExerciseRecord] {
        return trainingRecords
            .filter { record in
                record.patientId == patientId &&
                record.date >= startDate &&
                record.date <= endDate
            }
            .flatMap { $0.exercises }
            .filter { $0.exerciseId == exerciseId }
    }
    
    func getAssessmentProgress(patientId: String, type: AssessmentType, startDate: Date, endDate: Date) -> [AssessmentRecord] {
        return assessmentRecords
            .filter { record in
                record.patientId == patientId &&
                record.assessmentId.contains(type.rawValue) &&
                record.date >= startDate &&
                record.date <= endDate
            }
            .sorted { $0.date < $1.date }
    }
} 
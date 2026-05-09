import Foundation

class JSONImportService {
    static let shared = JSONImportService()
    private init() {}

    enum ImportError: LocalizedError {
        case unknownFormat
        case decodingFailed(String)
        case invalidExerciseId(String)

        var errorDescription: String? {
            switch self {
            case .unknownFormat:
                return "無法識別的 JSON 格式"
            case .decodingFailed(let msg):
                return "解析失敗：\(msg)"
            case .invalidExerciseId(let id):
                return "JSON格式錯誤：exerciseId「\(id)」不是合法的動作名稱"
            }
        }
    }

    // MARK: - 主入口

    func importJSON(from url: URL) throws -> String {
        let accessing = url.startAccessingSecurityScopedResource()
        defer {
            if accessing { url.stopAccessingSecurityScopedResource() }
        }
        let data = try Data(contentsOf: url)
        return try importJSON(data)
    }

    func importJSON(_ data: Data) throws -> String {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        // 嘗試訓練結果（單筆）
        if let result = try? decoder.decode(PatientTrainingResult.self, from: data) {
            guard ExerciseValidator.isValid(result.exerciseId) else {
                throw ImportError.invalidExerciseId(result.exerciseId)
            }
            importTrainingResult(result)
            return "訓練紀錄匯入成功"
        }

       // 嘗試評量結果（單筆）
       if let result = try? decoder.decode(PatientAssessmentResult.self, from: data) {
           importAssessmentResult(result)
           return "評量紀錄匯入成功"
       }

        throw ImportError.unknownFormat
    }

    // MARK: - 訓練結果寫入

    private func importTrainingResult(_ result: PatientTrainingResult) {
        let trainingRecord = buildTrainingRecord(from: result)
        RecordStore.shared.addTrainingRecord(trainingRecord)
    }

    private func buildTrainingRecord(from result: PatientTrainingResult) -> TrainingRecord {
        func metric(_ type: String) -> Double? {
            result.overallMetrics.first(where: { $0.type == type })?.value
        }

        let setRecords = result.sets.map { s in
            TrainingRecord.ExerciseRecord.SetRecord(
                repetitions: s.repsAchieved,
                weight: 0,
                duration: s.duration,
                performance: 3,
                notes: s.notes
            )
        }

        let exerciseRecord = TrainingRecord.ExerciseRecord(
            id: UUID(),
            exerciseId: result.exerciseId,
            sets: setRecords,
            targetRestTime: result.targetParameters.restTime,
            targetDuration: result.targetParameters.duration,
            targetKneeAngleStart: result.targetParameters.kneeAngleStart,
            targetKneeAngleEnd: result.targetParameters.kneeAngleEnd,
            targetHipAngleStart: result.targetParameters.hipAngleStart,
            targetHipAngleEnd: result.targetParameters.hipAngleEnd,
            targetMVIC: result.targetParameters.mvic,
            stimulationEnabled: result.targetParameters.stimulationEnabled,
            stimulationIntensity: result.targetParameters.stimulationIntensity,
            muscleStrength: metric("肌力"),
            stability: metric("穩定性_角度"),
            regularity: metric("規律性_角度"),
            reactionTime: metric("反應時間"),
            completionRate: metric("完成度"),
            flexibility: metric("柔軟度"),
            balance: metric("平衡性")
        )

        return TrainingRecord(
            id: UUID(),
            patientId: result.patientId,
            date: result.recordDate,
            menuId: UUID(uuidString: result.menuId ?? "") ?? UUID(),
            exercises: [exerciseRecord],
            totalDuration: result.totalDuration,
            avgPainScore: result.avgPainScore
        )
    }

    // MARK: - 評量結果寫入（暫不啟用）

    private func importAssessmentResult(_ result: PatientAssessmentResult) {
        let scores = Dictionary(uniqueKeysWithValues:
            result.subScores.map { ($0.category, $0.score) }
        )

        let record = AssessmentRecord(
            id: UUID(),
            patientId: result.patientId,
            assessmentId: result.assessmentType,
            date: result.recordDate,
            scores: scores,
            totalScore: result.totalScore,
            notes: result.notes
        )

        RecordStore.shared.addAssessmentRecord(record)
    }
}

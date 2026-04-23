import Foundation

class JSONImportService {
    static let shared = JSONImportService()
    private init() {}

    enum ImportError: LocalizedError {
        case unknownFormat
        case decodingFailed(String)

        var errorDescription: String? {
            switch self {
            case .unknownFormat:
                return "無法識別的 JSON 格式"
            case .decodingFailed(let msg):
                return "解析失敗：\(msg)"
            }
        }
    }

    // MARK: - 主入口

    func importJSON(from url: URL) throws -> String {
        let data = try Data(contentsOf: url)
        return try importJSON(data)
    }

    func importJSON(_ data: Data) throws -> String {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        // 嘗試訓練結果（單筆）
        if let result = try? decoder.decode(PatientTrainingResult.self, from: data) {
            importTrainingResult(result)
            return "訓練紀錄匯入成功"
        }

//        // 嘗試評量結果（單筆）
//        if let result = try? decoder.decode(PatientAssessmentResult.self, from: data) {
//            importAssessmentResult(result)
//            return "評量紀錄匯入成功"
//        }

        throw ImportError.unknownFormat
    }

    // MARK: - 訓練結果寫入

    private func importTrainingResult(_ result: PatientTrainingResult) {
        let trainingRecord = buildTrainingRecord(from: result)
        RecordStore.shared.addTrainingRecord(trainingRecord)

        let vizData = buildVisualizationData(from: result)
        TrainingDataManager.shared.addTrainingResult(vizData)
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
            completionRate: metric("完成度")
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

    private func buildVisualizationData(from result: PatientTrainingResult) -> TrainingVisualizationData {
        func metric(_ type: String) -> Double {
            result.overallMetrics.first(where: { $0.type == type })?.value ?? 0
        }

        let settings = TherapistSettings(
            exerciseName: result.exerciseId,
            sets: result.targetParameters.sets,
            repetitions: result.targetParameters.reps,
            restTime: result.targetParameters.restTime,
            mvic: result.targetParameters.mvic,
            maintainTime: result.targetParameters.duration,
            kneeAngleStart: result.targetParameters.kneeAngleStart,
            kneeAngleEnd: result.targetParameters.kneeAngleEnd,
            hipAngleStart: result.targetParameters.hipAngleStart,
            hipAngleEnd: result.targetParameters.hipAngleEnd,
            stimulation: result.targetParameters.stimulationEnabled,
            stimulationIntensity: result.targetParameters.stimulationIntensity
        )

        let performance = TrainingPerformanceMetrics(
            muscleStrength: metric("肌力"),
            stability: metric("穩定性_角度"),
            regularity: metric("規律性_角度"),
            reactionTime: metric("反應時間"),
            completionRate: metric("完成度")
        )

        return TrainingVisualizationData(
            patientId: result.patientId,
            exerciseName: result.exerciseId,
            date: result.recordDate,
            sessionDuration: result.totalDuration,
            therapistSettings: settings,
            performance: performance,
            painLevel: result.avgPainScore.map { Int($0) },
            notes: result.notes
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

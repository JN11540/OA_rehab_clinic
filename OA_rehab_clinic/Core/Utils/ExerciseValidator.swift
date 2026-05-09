import Foundation

/// 動作名稱驗證工具 — 對應 ExerciseSamples.swift 的 22 種合法動作
enum ExerciseValidator {

    // MARK: - 合法動作名稱清單

    static let validExerciseNames: Set<String> = [
        "股四頭肌等長收縮",
        "膝關節終端伸展",
        "躺姿抬腿",
        "俯臥抬腿",
        "側躺抬腿（外展）",
        "側躺抬腿（內收）",
        "負重膝關節終端伸展",
        "站立膝關節終端伸展",
        "部分蹲",
        "橋式",
        "大腿內夾運動",
        "登階運動",
        "靠牆深蹲",
        "大腿後側肌群伸展（一）",
        "大腿後側肌群伸展（二）",
        "股四頭肌伸展（一）",
        "股四頭肌伸展（二）",
        "小腿後肌肉伸展（一）",
        "小腿後肌肉伸展（二）",
        "前後滑行運動",
        "側向滑行運動",
        "前跨步弓步蹲"
    ]

    // MARK: - 驗證方法

    /// 驗證 exerciseId 是否為合法動作名稱（完全匹配，不允許數字前綴）
    static func isValid(_ exerciseId: String) -> Bool {
        validExerciseNames.contains(exerciseId)
    }
}

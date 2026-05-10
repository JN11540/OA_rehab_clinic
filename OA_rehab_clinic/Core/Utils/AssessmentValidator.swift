import Foundation

/// 評量編號驗證工具 — 對應 6 種合法評量類型
enum AssessmentValidator {

    static let assessmentMap: [Int: String] = [
        1: "WOMAC",
        2: "KOOS",
        3: "SF-36",
        4: "椅子坐站測試",
        5: "原地站立抬膝",
        6: "開眼單足站立"
    ]

    /// 回傳合法評量名稱，id 不存在時回傳 nil
    static func name(for id: Int) -> String? {
        assessmentMap[id]
    }
}

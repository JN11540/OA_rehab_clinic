import Foundation

/// 指標編號驗證工具 — 對應 overallMetrics type 的 7 種合法指標
enum MetricValidator {

    static let metricMap: [Int: String] = [
        1: "肌力",
        2: "穩定性_角度",
        3: "規律性_角度",
        4: "反應時間",
        5: "完成度",
        6: "柔軟度",
        7: "平衡性"
    ]

    /// 回傳合法指標名稱，id 不存在時回傳 nil
    static func name(for id: Int) -> String? {
        metricMap[id]
    }
}

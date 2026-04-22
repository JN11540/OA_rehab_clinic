import Foundation

/**
 * Note - 備註數據模型
 *
 * 功能說明：
 * - 定義患者備註的核心數據結構
 * - 支援 JSON 序列化/反序列化用於数據持久化
 * - 支援 SwiftUI 列表顯示的 Identifiable 協議
 * - 採用字串格式儲存日期以簡化顯示
 *
 * 屬性說明：
 * - id: 唯一識別符，使用 UUID 生成
 * - patientId: 關聯的患者ID，用於篩選備註
 * - date: 日期字串，格式為 "YYYY.MM.dd"
 * - content: 備註內容，支援多行文字
 *
 * 架構重構說明：
 * - 從原本 Core/Components/Note.swift 的巨石檔案中提取
 * - 移動到 Features/Patient/Notes/Models/ 符合數據模型分類
 */
struct Note: Identifiable, Codable {
    let id: String
    let patientId: String
    var date: String
    var content: String
}
import Foundation
import SwiftUI

// MARK: - Assessment Types
public enum AssessmentType: String, Codable, CaseIterable {
    case womac = "WOMAC"
    case koos = "KOOS"
    case sf36 = "SF-36"
    case chairTest = "椅子坐站測試"
    case kneeRaise = "原地站立抬膝"
    case singleLegStand = "開眼單足站立"
    
    public var title: String {
        rawValue
    }
    
    public var color: Color {
        switch self {
        case .womac:
            return Color(red: 0.9, green: 0.3, blue: 0.3).opacity(0.9)  // 鮮紅色 (Red)
        case .koos:
            return Color(red: 1.0, green: 0.65, blue: 0.0).opacity(0.9)  // 橙色 (Orange)
        case .sf36:
            return Color(red: 0.6, green: 0.4, blue: 0.8).opacity(0.9)  // 深紫色 (Purple)
        case .chairTest:
            return Color(red: 0.0, green: 0.6, blue: 0.9).opacity(0.9)  // 鮮藍色 (Blue)
        case .kneeRaise:
            return Color(red: 0.0, green: 0.75, blue: 0.3).opacity(0.9)  // 鮮綠色 (Green)
        case .singleLegStand:
            return Color(red: 0.95, green: 0.75, blue: 0.2).opacity(0.9)  // 金黃色 (Yellow/Gold)
        }
    }
    
    public var description: String {
        switch self {
        case .womac:
            return "用於評估膝或髖關節炎(OA)的指標。包含24個問題，其中三個子類別分別用於評估關節炎的疼痛、僵硬、和關節功能。分數越高，表示身體功能受影響越大。最高為96分。"
        case .koos:
            return "用於評估膝關節損傷和骨關節炎的指標。包含42個問題，其中五個子類別分別用於疼痛、症狀(含僵硬)、日常生活活動、體育及娛樂功能、生活品質。分數越高，表示身體功能受影響越大。每個子類別最高分為100分。"
        case .sf36:
            return "衡量與健康相關的生活品質的指標。包含42個問題，其中八個子類別分別用於身體活動功能、身體健康影響角色限制、身體疼痛、一般健康狀況、活力狀況、社交功能、心理健康影響角色限制與情緒狀況。分數越高，表示身體功能受影響越大。每個子類別最高分為100分。"
        case .chairTest:
            return "測量下肢肌耐力，同時也可評估跌倒危險因子。"
        case .kneeRaise:
            return "測量下肢肌耐力，同時評估長者的心肺有氧耐力。"
        case .singleLegStand:
            return "測量下肢肌耐力，同時評估本體感覺等平衡能力。"
        }
    }
    
    public var category: AssessmentCategory {
        switch self {
        case .womac, .sf36, .koos:
            return .clinical
        case .chairTest, .kneeRaise, .singleLegStand:
            return .functional
        }
    }
}

public enum AssessmentCategory: String, Codable {
    case clinical = "臨床量表"
    case functional = "功能性評估"
    
    public var title: String {
        rawValue
    }
}

// MARK: - Assessment Model
public struct Assessment: Identifiable, Codable, Hashable {
    public let id: String
    public let type: AssessmentType
    public var scheduledDates: Set<Date>  // 已安排的評估日期
    public var completedDates: [Date]     // 已完成的評估日期，按時間倒序排列
    
    public init(
        id: String,
        type: AssessmentType,
        scheduledDates: Set<Date> = [],
        completedDates: [Date] = []
    ) {
        self.id = id
        self.type = type
        self.scheduledDates = scheduledDates
        self.completedDates = completedDates.sorted(by: >)  // 確保完成日期按時間倒序排列
    }
    
    public var title: String {
        type.title
    }
    
    // 格式化最近兩次的評估日期
    public var formattedRecentDates: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd"
        return completedDates
            .prefix(2)
            .map { formatter.string(from: $0) }
            .joined(separator: ", ")
    }
    
    // 取得最近的評估日期
    public var lastAssessmentDate: Date? {
        completedDates.first
    }
    
    // 檢查指定日期是否有安排評估
    public func hasScheduledAssessment(on date: Date) -> Bool {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        guard let normalizedDate = calendar.date(from: components) else { return false }
        
        return scheduledDates.contains { scheduledDate in
            let scheduledComponents = calendar.dateComponents([.year, .month, .day], from: scheduledDate)
            guard let normalizedScheduledDate = calendar.date(from: scheduledComponents) else { return false }
            return normalizedDate == normalizedScheduledDate
        }
    }
    
    // 檢查指定日期是否已完成評估
    public func hasCompletedAssessment(on date: Date) -> Bool {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        guard let normalizedDate = calendar.date(from: components) else { return false }
        
        return completedDates.contains { completedDate in
            let completedComponents = calendar.dateComponents([.year, .month, .day], from: completedDate)
            guard let normalizedCompletedDate = calendar.date(from: completedComponents) else { return false }
            return normalizedDate == normalizedCompletedDate
        }
    }
    
    // 新增：檢查排程日期是否已過期
    public func isPastScheduledDate(_ date: Date) -> Bool {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let scheduledDay = calendar.startOfDay(for: date)
        
        return scheduledDay < today
    }
    
    // 新增：獲取過期但尚未標記為已完成的排程日期
    public var pastScheduledDates: [Date] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        return scheduledDates
            .filter { calendar.startOfDay(for: $0) < today }
            .sorted()
    }
    
    // 新增：獲取未來的排程日期
    public var futureScheduledDates: [Date] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        return scheduledDates
            .filter { calendar.startOfDay(for: $0) >= today }
            .sorted()
    }
    
    // 新增：獲取最近兩次完成的評量日期
    public var recentCompletedDates: [Date] {
        return completedDates.prefix(2).map { $0 }
    }
    
    // MARK: - Hashable Implementation
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    public static func == (lhs: Assessment, rhs: Assessment) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Assessment Record
public struct AssessmentRecord: Identifiable, Codable, Equatable {
    public let id: UUID
    public let patientId: String
    public let assessmentId: String       // 對應到 Assessment 的 id
    public let date: Date
    public let scores: [String: Double]   // 各項評量分數
    public let totalScore: Double
    public let notes: String?
    
    public init(
        id: UUID = UUID(),
        patientId: String,
        assessmentId: String,
        date: Date,
        scores: [String: Double],
        totalScore: Double,
        notes: String? = nil
    ) {
        self.id = id
        self.patientId = patientId
        self.assessmentId = assessmentId
        self.date = date
        self.scores = scores
        self.totalScore = totalScore
        self.notes = notes
    }
} 
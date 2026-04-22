import Foundation
import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

public struct TrainingMenu: Identifiable, Codable, Equatable {
    public let id: UUID
    public var title: String
    public var isExclusive: Bool
    public var color: Color
    public var exercises: [ExerciseParameters]
    public var timeSlots: Set<String>
    public var patientId: String?
    public let createdAt: Date  // 新增：創建日期
    public var updatedAt: Date  // 新增：更新日期
    
    public init(
        id: UUID = UUID(),
        title: String,
        isExclusive: Bool,
        color: Color,
        exercises: [ExerciseParameters],
        timeSlots: Set<String> = [],
        patientId: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.isExclusive = isExclusive
        self.color = color
        self.exercises = exercises
        self.timeSlots = timeSlots
        self.patientId = patientId
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    // MARK: - Equatable
    public static func == (lhs: TrainingMenu, rhs: TrainingMenu) -> Bool {
        return lhs.id == rhs.id &&
               lhs.title == rhs.title &&
               lhs.isExclusive == rhs.isExclusive &&
               lhs.color == rhs.color &&
               lhs.exercises == rhs.exercises &&
               lhs.timeSlots == rhs.timeSlots &&
               lhs.patientId == rhs.patientId &&
               lhs.createdAt == rhs.createdAt &&
               lhs.updatedAt == rhs.updatedAt
    }
}

// MARK: - Color Codable Extension
extension Color: Codable {
    enum CodingKeys: String, CodingKey {
        case red, green, blue, opacity
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let red = try container.decode(Double.self, forKey: .red)
        let green = try container.decode(Double.self, forKey: .green)
        let blue = try container.decode(Double.self, forKey: .blue)
        let opacity = try container.decode(Double.self, forKey: .opacity)
        self.init(red: red, green: green, blue: blue, opacity: opacity)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var opacity: CGFloat = 0
        
        UIColor(self).getRed(&red, green: &green, blue: &blue, alpha: &opacity)
        
        try container.encode(red, forKey: .red)
        try container.encode(green, forKey: .green)
        try container.encode(blue, forKey: .blue)
        try container.encode(opacity, forKey: .opacity)
    }
}

// MARK: - Training Menu Store
public class TrainingMenuStore: ObservableObject {
    public static let shared = TrainingMenuStore()
    public static let preview = TrainingMenuStore(isPreview: true)
    
    @Published public var menus: [TrainingMenu] = []
    private let isPreview: Bool
    
    private init(isPreview: Bool = false) {
        self.isPreview = isPreview
        if !isPreview {
            loadMenus()
        }
    }
    
    private func loadMenus() {
        if isPreview { return }
        
        if let data = UserDefaults.standard.data(forKey: "trainingMenus"),
           let decodedMenus = try? JSONDecoder().decode([TrainingMenu].self, from: data) {
            menus = decodedMenus
        }
    }
    
    public func saveMenu(_ menu: TrainingMenu) {
        if isPreview { return }
        
        if let index = menus.firstIndex(where: { $0.id == menu.id }) {
            // 更新現有菜單時，更新 updatedAt 時間戳
            var updatedMenu = menu
            updatedMenu.updatedAt = Date()
            menus[index] = updatedMenu
        } else {
            menus.append(menu)
        }
        saveMenus()
    }
    
    public func deleteMenu(_ menu: TrainingMenu) {
        if isPreview { return }
        
        if let index = menus.firstIndex(where: { $0.id == menu.id }) {
            menus.remove(at: index)
            saveMenus()
            // 確保 UserDefaults 被更新
            if menus.isEmpty {
                UserDefaults.standard.removeObject(forKey: "trainingMenus")
            }
        }
    }
    
    private func saveMenus() {
        if isPreview { return }
        
        if menus.isEmpty {
            UserDefaults.standard.removeObject(forKey: "trainingMenus")
        } else if let encoded = try? JSONEncoder().encode(menus) {
            UserDefaults.standard.set(encoded, forKey: "trainingMenus")
        }
    }
    
    public func clearAllMenus() {
        if isPreview { return }
        menus.removeAll()
        UserDefaults.standard.removeObject(forKey: "trainingMenus")
        objectWillChange.send()
    }
    
    public func getExclusiveMenus(for patientId: String? = nil) -> [TrainingMenu] {
        if let patientId = patientId {
            return menus.filter { $0.isExclusive && $0.patientId == patientId }
        } else {
            return menus.filter { $0.isExclusive }
        }
    }
    
    public func getCommonMenus() -> [TrainingMenu] {
        menus.filter { !$0.isExclusive }
    }
    
    public func getMenu(by id: UUID) -> TrainingMenu? {
        return menus.first { $0.id == id }
    }
    
    public func removeAllMenusForPatient(_ patientId: String) {
        if !isPreview {
            menus.removeAll { menu in
                menu.isExclusive && menu.patientId == patientId
            }
            saveMenus()
        }
    }
} 
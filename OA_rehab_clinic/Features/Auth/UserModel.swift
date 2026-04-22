import SwiftUI

class UserModel: ObservableObject {
    // MARK: - Shared Instance
    static let shared = UserModel()
    
    // MARK: - Properties
    @Published var name: String {
        didSet {
            if !isPreview {
                saveUserData()
            }
        }
    }
    @Published var email: String {
        didSet {
            if !isPreview {
                saveUserData()
            }
        }
    }
    @Published var department: String {
        didSet {
            if !isPreview {
                saveUserData()
            }
        }
    }
    @Published var role: Role {
        didSet {
            if !isPreview {
                saveUserData()
            }
        }
    }
    
    private let defaults = UserDefaults.standard
    private let userDataKey = "userData"
    private let isPreview: Bool
    
    enum Role: String, CaseIterable, Codable {
        case doctor = "醫師"
        case therapist = "治療師"
    }
    
    // MARK: - User Data Structure
    struct UserData: Codable {
        var name: String
        var email: String
        var department: String
        var role: Role
    }
    
    // MARK: - Initialization
    init(preview: Bool = false) {
        self.isPreview = preview
        self.name = ""
        self.email = ""
        self.department = ""
        self.role = .doctor
        
        if !preview {
            loadUserData()
        }
    }
    
    // MARK: - Data Management
    private func loadUserData() {
        guard let data = defaults.data(forKey: userDataKey),
              let userData = try? JSONDecoder().decode(UserData.self, from: data) else {
            return
        }
        
        self.name = userData.name
        self.email = userData.email
        self.department = userData.department
        self.role = userData.role
    }
    
    func saveUserData() {
        guard !isPreview else { return }
        
        let userData = UserData(
            name: name,
            email: email,
            department: department,
            role: role
        )
        
        if let encoded = try? JSONEncoder().encode(userData) {
            defaults.set(encoded, forKey: userDataKey)
        }
    }
    
    func clearUserData() {
        guard !isPreview else { return }
        
        defaults.removeObject(forKey: userDataKey)
        name = ""
        email = ""
        department = ""
        role = .doctor
    }
}

// MARK: - Preview Helpers
extension UserModel {
    /// 用於 SwiftUI 預覽
    static var preview: UserModel {
        let model = UserModel(preview: true)
        model.name = "ＯＯＯ"
        model.email = "1234567@dmail.com"
        model.department = "ＯＯＯ復健科"
        model.role = .doctor
        return model
    }
}

// let userModel = UserModel.sample  // 這會保存新的示例數據

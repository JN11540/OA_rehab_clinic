import Foundation

// MARK: - Patient Model
struct Patient: Identifiable, Codable, Equatable {
    let id: String
    let name: String
    let gender: Gender
    let birthDate: Date
    let height: Double // in cm
    let weight: Double // in kg
    let affectedSide: AffectedSide
    let acceptsElectricity: Int // 0-10 級
    let equipment: Equipment
    var assessments: [Assessment] // 使用統一的 Assessment 結構
    
    var age: Int {
        Calendar.current.dateComponents([.year], from: birthDate, to: Date()).year ?? 0
    }
    
    static func == (lhs: Patient, rhs: Patient) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Patient Store
class PatientStore: ObservableObject {
    static let shared = PatientStore()
    static let preview = PatientStore(isPreview: true)
    
    @Published private(set) var patients: [Patient] = []
    private let isPreview: Bool
    
    private init(isPreview: Bool = false) {
        self.isPreview = isPreview
        if !isPreview {
            loadPatients()
        } else {
            // 在預覽模式下使用範例資料
            patients = [Patient.sample]
        }
    }
    
    private func loadPatients() {
        if let data = UserDefaults.standard.data(forKey: "patients"),
           let decodedPatients = try? JSONDecoder().decode([Patient].self, from: data) {
            patients = decodedPatients
        } else {
            // 如果沒有儲存的資料，使用範例資料
            patients = [Patient.sample]
        }
    }
    
    func addPatient(_ patient: Patient) {
        if !isPreview {
            if !patients.contains(where: { $0.id == patient.id }) {
                patients.append(patient)
                savePatients()
            }
        }
    }
    
    func removePatient(_ patient: Patient) {
        if !isPreview {
            // 刪除病患相關的訓練菜單
            TrainingMenuStore.shared.removeAllMenusForPatient(patient.id)
            
            // 刪除病患相關的訓練安排
            TrainingScheduleStore.shared.removeAllSchedulesForPatient(patient.id)
            
            // 刪除病患相關的備註
            let noteStore = NoteStore.shared
            let patientNotes = noteStore.getNotesForPatient(patient.id)
            for note in patientNotes {
                noteStore.deleteNote(note)
            }
            
            // 刪除病患資料
            patients.removeAll { $0.id == patient.id }
            savePatients()
        }
    }
    
    private func savePatients() {
        if !isPreview {
            if let encoded = try? JSONEncoder().encode(patients) {
                UserDefaults.standard.set(encoded, forKey: "patients")
            }
        }
    }
    
    func updatePatient(_ patient: Patient) {
        if !isPreview {
            if let index = patients.firstIndex(where: { $0.id == patient.id }) {
                patients[index] = patient
                savePatients()
            }
        }
    }
    
    // 模擬API搜尋功能
    func searchById(_ id: String) -> Patient? {
        // 先檢查是否已經存在於本地
        if patients.contains(where: { $0.id == id }) {
            return nil // 如果已存在，返回 nil 表示不能重複添加
        }
        
        // 模擬API搜尋
        if id == "K987654321" {
            return Patient.sampleToAdd
        }
        return nil
    }
}

// MARK: - Preview Helper

// Helper to create dates from year, month, day
private func createDate(year: Int, month: Int, day: Int) -> Date {
    var components = DateComponents()
    components.year = year
    components.month = month
    components.day = day
    return Calendar.current.date(from: components) ?? Date()
}

extension Patient {
    static var sample: Patient {
        return Patient(
            id: "K123456789",
            name: "王大明",
            gender: .male,
            birthDate: createDate(year: 1960, month: 1, day: 1),
            height: 170.0,
            weight: 65.0,
            affectedSide: .right,
            acceptsElectricity: 0,
            equipment: Equipment(
                smartKnee: .single,
                homeEquipment: ["瑜伽墊", "彈力帶", "平衡板"],
                stimulator: false
            ),
            assessments: [
                Assessment(
                    id: "sample_womac_01", // Fixed ID
                    type: .womac,
                    scheduledDates: [],
                    completedDates: []
                ),
                Assessment(
                    id: "sample_koos_01", // Fixed ID
                    type: .koos,
                    scheduledDates: [],
                    completedDates: []
                ),
                Assessment(
                    id: "sample_sf36_01", // Fixed ID
                    type: .sf36,
                    scheduledDates: [],
                    completedDates: []
                )
            ]
        )
    }

    static var sampleToAdd: Patient {
        Patient(
            id: "K987654321",
            name: "關詠詩",
            gender: .female,
            birthDate: createDate(year: 1965, month: 6, day: 15),
            height: 160.0,
            weight: 55.0,
            affectedSide: .left,
            acceptsElectricity: 3,
            equipment: Equipment(
                smartKnee: .none,
                homeEquipment: ["瑜伽墊", "彈力帶"],
                stimulator: false
            ),
            assessments: [] // sampleToAdd might not need pre-filled assessments, or they can also have fixed IDs if added
        )
    }
}

// MARK: - Supporting Types
enum Gender: String, Codable {
    case male = "男性"
    case female = "女性"
}

enum AffectedSide: String, Codable {
    case left = "左側"
    case right = "右側"
    case both = "雙側"
}

enum SmartKneeStatus: String, Codable {
    case none = "無"
    case single = "單腳"
    case both = "雙腳"
}

struct Equipment: Codable, Equatable {
    let smartKnee: SmartKneeStatus
    let homeEquipment: [String]  // 例如：["瑜伽墊", "彈力帶"]
    let stimulator: Bool
}

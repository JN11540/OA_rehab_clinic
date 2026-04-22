import SwiftUI
import Foundation

class AssessmentStore: ObservableObject {
    static let shared = AssessmentStore()
    static let preview = AssessmentStore(isPreview: true)
    
    @Published private(set) var assessments: [String: [Assessment]] = [:]
    private let isPreview: Bool
    
    private init(isPreview: Bool = false) {
        self.isPreview = isPreview
        if !isPreview {
            loadAssessments()
            // 初始化時檢查並更新過期的評估日期
            updatePastScheduledDates()
        }
    }
    
    private func loadAssessments() {
        if let data = UserDefaults.standard.data(forKey: "assessments"),
           let decoded = try? JSONDecoder().decode([String: [Assessment]].self, from: data) {
            assessments = decoded
        }
    }
    
    private func saveAssessments() {
        if !isPreview {
            if let encoded = try? JSONEncoder().encode(assessments) {
                UserDefaults.standard.set(encoded, forKey: "assessments")
                NotificationCenter.default.post(name: .assessmentsDidUpdate, object: nil)
            }
        }
    }
    
    func getAssessments(for patientId: String) -> [Assessment] {
        // 每次獲取評估時檢查並更新過期的評估日期
        updatePastScheduledDates()
        return assessments[patientId] ?? []
    }
    
    // 新增：檢查並更新過期的評估日期
    func updatePastScheduledDates() {
        let today = Calendar.current.startOfDay(for: Date())
        var hasUpdates = false
        
        // 遍歷所有病患的評估
        for (patientId, patientAssessments) in assessments {
            var updatedAssessments: [Assessment] = []
            
            for assessment in patientAssessments {
                var updatedAssessment = assessment
                var hasAssessmentUpdates = false
                
                // 找出過期的排程日期
                let pastScheduledDates = assessment.scheduledDates.filter { date in
                    Calendar.current.startOfDay(for: date) < today
                }
                
                if !pastScheduledDates.isEmpty {
                    // 從排程日期中移除過期日期
                    for date in pastScheduledDates {
                        updatedAssessment.scheduledDates.remove(date)
                    }
                    
                    // 將過期日期添加到已完成日期中（如果尚未存在）
                    for date in pastScheduledDates {
                        // 檢查該日期是否已經在完成日期列表中
                        let dateExists = updatedAssessment.completedDates.contains { completedDate in
                            Calendar.current.isDate(completedDate, inSameDayAs: date)
                        }
                        
                        if !dateExists {
                            updatedAssessment.completedDates.append(date)
                        }
                    }
                    
                    // 確保完成日期按時間倒序排列（最近的日期在前）
                    updatedAssessment.completedDates.sort(by: >)
                    hasAssessmentUpdates = true
                }
                
                if hasAssessmentUpdates {
                    updatedAssessments.append(updatedAssessment)
                    hasUpdates = true
                } else {
                    updatedAssessments.append(assessment)
                }
            }
            
            if hasUpdates {
                assessments[patientId] = updatedAssessments
            }
        }
        
        if hasUpdates {
            saveAssessments()
        }
    }
    
    func updateAssessment(_ assessment: Assessment, for patientId: String) {
        // 先獲取最新的病患資料
        guard var patient = PatientStore.shared.patients.first(where: { $0.id == patientId }) else { return }
        
        // 更新病患的評量列表
        var patientAssessments = patient.assessments
        
        // 更新或添加評量
        if let index = patientAssessments.firstIndex(where: { $0.id == assessment.id }) {
            patientAssessments[index] = assessment
        } else {
            patientAssessments.append(assessment)
        }
        
        // 更新 assessments 字典
        assessments[patientId] = patientAssessments
        
        // 更新病患資料
        patient.assessments = patientAssessments
        
        // 確保在主線程中執行 UI 更新，並確保更新順序正確
        DispatchQueue.main.async { [weak self] in
            // 1. 先保存評量資料
            self?.saveAssessments()
            
            // 2. 更新 PatientStore
            PatientStore.shared.updatePatient(patient)
            
            // 3. 發送通知以確保所有視圖都更新
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                NotificationCenter.default.post(name: .assessmentsDidUpdate, object: nil)
            }
        }
    }
    
    func toggleScheduledDate(_ date: Date, for assessment: Assessment, patientId: String) {
        var updatedAssessment = assessment
        
        // 檢查日期是否已過期
        let today = Calendar.current.startOfDay(for: Date())
        let scheduledDay = Calendar.current.startOfDay(for: date)
        
        if scheduledDay < today {
            // 如果是過期日期，則添加到已完成日期列表
            if updatedAssessment.scheduledDates.contains(date) {
                updatedAssessment.scheduledDates.remove(date)
            }
            
            // 檢查該日期是否已經在完成日期列表中
            let dateExists = updatedAssessment.completedDates.contains { completedDate in
                Calendar.current.isDate(completedDate, inSameDayAs: date)
            }
            
            if !dateExists {
                updatedAssessment.completedDates.append(date)
                // 確保完成日期按時間倒序排列
                updatedAssessment.completedDates.sort(by: >)
            }
        } else {
            // 如果是未來日期，則正常切換排程狀態
            if updatedAssessment.scheduledDates.contains(date) {
                updatedAssessment.scheduledDates.remove(date)
            } else {
                updatedAssessment.scheduledDates.insert(date)
            }
        }
        
        updateAssessment(updatedAssessment, for: patientId)
    }
    
    // 新增：刪除特定月份的評估日期（類似於 TrainingScheduleStore 的 removeDatesFromSchedule）
    func removeDatesFromAssessment(_ assessment: Assessment, inMonthOf referenceDate: Date, for patientId: String) {
        var updatedAssessment = assessment
        
        let calendar = Calendar.current
        let yearMonthToClear = calendar.dateComponents([.year, .month], from: referenceDate)
        
        // 過濾出不在指定月份的排程日期
        updatedAssessment.scheduledDates = updatedAssessment.scheduledDates.filter { dateInSchedule in
            let dateComponents = calendar.dateComponents([.year, .month], from: dateInSchedule)
            return !(dateComponents.year == yearMonthToClear.year && dateComponents.month == yearMonthToClear.month)
        }
        
        updateAssessment(updatedAssessment, for: patientId)
    }
}

// 通知名稱擴展
extension Notification.Name {
    static let assessmentsDidUpdate = Notification.Name("assessmentsDidUpdate")
}
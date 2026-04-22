// ClinicArrangeData.swift
import Foundation
// 移除 UIKit 導入，因為我們現在使用 FileShareManager

// MARK: - Enum Extensions for Export
// 移除重複的擴展，直接使用 rawValue 和 title

// 重要的class: ClinicDataExporter 

// MARK: - Date Formatter

fileprivate let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd"
    return formatter
}()

fileprivate let dateTimeFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd HH:mm"
    return formatter
}()

fileprivate let dateCodeFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyyMMdd"
    return formatter
}()

// MARK: - Data Models
struct ClinicArrangeData: Codable {
    let exportDate: String
    let patientInfo: PatientInfo
    let trainingSchedules: [TrainingScheduleData]
    let assessmentSchedules: [AssessmentScheduleData]
    
    struct PatientInfo: Codable {
        let id: String
        let name: String
        let gender: String
        let birthDate: String
        let height: Double
        let weight: Double
        let affectedSide: String
        
        enum CodingKeys: String, CodingKey {
            case id, name, gender, birthDate, height, weight, affectedSide
        }
        
        init(id: String, name: String, gender: String, birthDate: Date, height: Double, weight: Double, affectedSide: String) {
            self.id = id
            self.name = name
            self.gender = gender
            self.birthDate = dateFormatter.string(from: birthDate)
            self.height = height
            self.weight = weight
            self.affectedSide = affectedSide
        }
    }
    
    struct TrainingScheduleData: Codable {
        let id: String
        let menuTitle: String
        let timeSlots: [String]
        let scheduledDates: [String]
        let exercises: [ExerciseData]
        
        enum CodingKeys: String, CodingKey {
            case id, menuTitle, timeSlots, scheduledDates, exercises
        }
        
        init(menuTitle: String, timeSlots: Set<String>, scheduledDates: Set<Date>, exercises: [ExerciseData]) {
            let sortedDates = scheduledDates.sorted()
            let firstDate = sortedDates.first.map { dateCodeFormatter.string(from: $0) } ?? ""
            let lastDate = sortedDates.last.map { dateCodeFormatter.string(from: $0) } ?? ""
            let idBase = menuTitle.replacingOccurrences(of: " ", with: "")
            
            // 生成統一的 ID
            if !firstDate.isEmpty && !lastDate.isEmpty && firstDate != lastDate {
                self.id = "\(idBase)_\(firstDate)_\(lastDate)"
            } else if !firstDate.isEmpty {
                self.id = "\(idBase)_\(firstDate)"
            } else {
                self.id = idBase
            }
            
            self.menuTitle = menuTitle
            self.timeSlots = Array(timeSlots)
            self.scheduledDates = sortedDates.map { dateFormatter.string(from: $0) }
            self.exercises = exercises
        }
        
        // 新增：按月份初始化的方法
        init(menuTitle: String, timeSlots: Set<String>, scheduledDates: Set<Date>, exercises: [ExerciseData], forMonth yearMonth: DateComponents) {
            let sortedDates = scheduledDates.sorted()
            let idBase = menuTitle.replacingOccurrences(of: " ", with: "")
            let monthString = String(format: "%04d%02d", yearMonth.year ?? 0, yearMonth.month ?? 0)
            
            // 使用月份格式生成統一的 ID
            self.id = "\(idBase)_\(monthString)"
            
            self.menuTitle = menuTitle
            self.timeSlots = Array(timeSlots)
            self.scheduledDates = sortedDates.map { dateFormatter.string(from: $0) }
            self.exercises = exercises
        }
    }
    
    struct ExerciseData: Codable {
        let name: String
        let englishName: String
        let category: String
        let level: String?
        let rightLeg: LegData?
        let leftLeg: LegData?
        
        enum CodingKeys: String, CodingKey {
            case name, englishName, category, level, rightLeg, leftLeg
        }
        
        init(from exerciseParams: ExerciseParameters) {
            let exercise = exerciseParams.exercise
            self.name = exercise.name
            self.englishName = ExerciseData.getEnglishName(for: exercise)
            self.category = exercise.category
            self.level = exercise.level
            self.rightLeg = exerciseParams.rightLeg.map { LegData(from: $0) }
            self.leftLeg = exerciseParams.leftLeg.map { LegData(from: $0) }
        }
        
        static func getEnglishName(for exercise: ExerciseModule.Exercise) -> String {
            // 優先使用已有英文名稱
            if !exercise.englishName.isEmpty { return exercise.englishName }
            
            // 嘗試從樣本中查找
            if let sample = ExerciseModule.Exercise.findSample(by: exercise.name, category: exercise.category) {
                return sample.englishName
            }
            
            // 找不到則使用中文名
            return exercise.name
        }
        
        // 移除不再需要的 categoryCode 和 levelCode 方法，直接使用原始值
    }
    
    struct LegData: Codable {
        let sets: Int
        let repetitions: Int
        let restTime: Int?
        let duration: Int?
        let kneeAngleStart: Int?
        let kneeAngleEnd: Int?
        let hipAngleStart: Int?
        let hipAngleEnd: Int?
        let weight: Double?
        let mvic: Int?
        let stimulation: Bool
        let stimulationIntensity: Int?
        let stimulationFrequency: Int?
        let stimulationPulseWidth: Int?
        
        enum CodingKeys: String, CodingKey {
            case sets, repetitions, restTime, duration, kneeAngleStart, kneeAngleEnd, hipAngleStart, hipAngleEnd, weight, mvic, stimulation, stimulationIntensity, stimulationFrequency, stimulationPulseWidth
        }
        
        init(from leg: LegParameters) {
            self.sets = leg.sets
            self.repetitions = leg.repetitions
            self.restTime = leg.restTime
            self.duration = leg.duration
            self.kneeAngleStart = leg.kneeAngleStart
            self.kneeAngleEnd = leg.kneeAngleEnd
            self.hipAngleStart = leg.hipAngleStart
            self.hipAngleEnd = leg.hipAngleEnd
            self.weight = leg.weight
            self.mvic = leg.mvic
            self.stimulation = leg.stimulation
            self.stimulationIntensity = leg.stimulationIntensity
            self.stimulationFrequency = leg.stimulationFrequency
            self.stimulationPulseWidth = leg.stimulationPulseWidth
        }
    }
    
    struct AssessmentScheduleData: Codable {
        let id: String
        let type: String
        let scheduledDates: [String]
        let completedDates: [String]
        let scores: [AssessmentScore]?
        
        enum CodingKeys: String, CodingKey {
            case id, type, scheduledDates, completedDates, scores
        }
        
        init(assessment: Assessment) {
            self.type = assessment.type.title
            self.scheduledDates = assessment.scheduledDates.sorted().map { dateFormatter.string(from: $0) }
            self.completedDates = assessment.completedDates.sorted().map { dateFormatter.string(from: $0) }
            self.scores = nil
            
            // 简化ID生成策略：使用类型名称
            if !self.scheduledDates.isEmpty {
                let firstDate = self.scheduledDates.first!
                let lastDate = self.scheduledDates.last!
                if firstDate != lastDate {
                    self.id = "\(assessment.type.rawValue)_\(firstDate)_\(lastDate)"
                } else {
                    self.id = "\(assessment.type.rawValue)_\(firstDate)"
                }
            } else {
                self.id = assessment.type.rawValue
            }
        }
        
        // 新增：按月份初始化的方法
        init(assessment: Assessment, forMonth yearMonth: DateComponents) {
            self.type = assessment.type.title
            self.scheduledDates = assessment.scheduledDates.sorted().map { dateFormatter.string(from: $0) }
            self.completedDates = assessment.completedDates.sorted().map { dateFormatter.string(from: $0) }
            self.scores = nil
            
            // 使用月份格式生成 ID
            let monthString = String(format: "%04d%02d", yearMonth.year ?? 0, yearMonth.month ?? 0)
            self.id = "\(assessment.type.rawValue)_\(monthString)"
        }
    }
    
    struct AssessmentScore: Codable {
        let date: String
        let score: Double
        let notes: String?
        
        enum CodingKeys: String, CodingKey {
            case date, score, notes
        }
        
        init(date: Date, score: Double, notes: String?) {
            self.date = dateFormatter.string(from: date)
            self.score = score
            self.notes = notes
        }
    }
}

// MARK: - Data Export Manager  (在EditTrainingCalendarView中使用，匯出整個月的訓練安排)
class ClinicDataExporter {
    static let shared = ClinicDataExporter()
    private let fileManager = FileManager.default
    
    private init() {}
    
    func exportData(for patient: Patient) -> ClinicArrangeData {
        let scheduleStore = TrainingScheduleStore.shared
        let menuStore = TrainingMenuStore.shared
        
        let trainingData = scheduleStore.getSchedulesForPatient(patient.id).compactMap { schedule -> ClinicArrangeData.TrainingScheduleData? in
            guard let menu = menuStore.getMenu(by: schedule.menuId) else { return nil }
            return ClinicArrangeData.TrainingScheduleData(
                menuTitle: menu.title,
                timeSlots: menu.timeSlots,
                scheduledDates: schedule.dates,
                exercises: menu.exercises.map { params in
                    ClinicArrangeData.ExerciseData(from: params)
                }
            )
        }
        
        // 取得評估排程
        let assessmentData = patient.assessments.map { assessment in
            ClinicArrangeData.AssessmentScheduleData(assessment: assessment)
        }
        
        return ClinicArrangeData(
            exportDate: dateTimeFormatter.string(from: Date()),
            patientInfo: ClinicArrangeData.PatientInfo(
                id: patient.id,
                name: patient.name,
                gender: patient.gender.rawValue,
                birthDate: patient.birthDate,
                height: patient.height,
                weight: patient.weight,
                affectedSide: patient.affectedSide.rawValue
            ),
            trainingSchedules: trainingData,
            assessmentSchedules: assessmentData
        )
    }
    
    // 新增：按月份匯出數據
    func exportDataForMonth(for patient: Patient, month: Date) -> ClinicArrangeData {
        let calendar = Calendar.current
        let scheduleStore = TrainingScheduleStore.shared
        let menuStore = TrainingMenuStore.shared
        
        // 獲取指定月份的年月
        let yearMonth = calendar.dateComponents([.year, .month], from: month)
        
        // 過濾訓練排程：只包含指定月份的日期
        let trainingData = scheduleStore.getSchedulesForPatient(patient.id).compactMap { schedule -> ClinicArrangeData.TrainingScheduleData? in
            guard let menu = menuStore.getMenu(by: schedule.menuId) else { return nil }
            
            // 過濾出指定月份的日期
            let monthDates = schedule.dates.filter { date in
                let dateComponents = calendar.dateComponents([.year, .month], from: date)
                return dateComponents.year == yearMonth.year && dateComponents.month == yearMonth.month
            }
            
            // 如果該月份沒有安排，則跳過此菜單
            guard !monthDates.isEmpty else { return nil }
            
            return ClinicArrangeData.TrainingScheduleData(
                menuTitle: menu.title,
                timeSlots: menu.timeSlots,
                scheduledDates: Set(monthDates),
                exercises: menu.exercises.map { params in
                    ClinicArrangeData.ExerciseData(from: params)
                },
                forMonth: yearMonth
            )
        }
        
        // 過濾評估排程：只包含指定月份的日期
        let assessmentData = patient.assessments.compactMap { assessment -> ClinicArrangeData.AssessmentScheduleData? in
            // 過濾出指定月份的排程日期
            let monthScheduledDates = assessment.scheduledDates.filter { date in
                let dateComponents = calendar.dateComponents([.year, .month], from: date)
                return dateComponents.year == yearMonth.year && dateComponents.month == yearMonth.month
            }
            
            // 過濾出指定月份的完成日期
            let monthCompletedDates = assessment.completedDates.filter { date in
                let dateComponents = calendar.dateComponents([.year, .month], from: date)
                return dateComponents.year == yearMonth.year && dateComponents.month == yearMonth.month
            }
            
            // 如果該月份沒有任何評估活動，則跳過
            guard !monthScheduledDates.isEmpty || !monthCompletedDates.isEmpty else { return nil }
            
            // 創建一個臨時的 Assessment 物件，只包含該月份的日期
            var monthAssessment = assessment
            monthAssessment.scheduledDates = Set(monthScheduledDates)
            monthAssessment.completedDates = monthCompletedDates
            
            return ClinicArrangeData.AssessmentScheduleData(assessment: monthAssessment, forMonth: yearMonth)
        }
        
        return ClinicArrangeData(
            exportDate: dateTimeFormatter.string(from: Date()),
            patientInfo: ClinicArrangeData.PatientInfo(
                id: patient.id,
                name: patient.name,
                gender: patient.gender.rawValue,
                birthDate: patient.birthDate,
                height: patient.height,
                weight: patient.weight,
                affectedSide: patient.affectedSide.rawValue
            ),
            trainingSchedules: trainingData,
            assessmentSchedules: assessmentData
        )
    }
    
    func saveToFile(data: ClinicArrangeData, fileName: String = "clinic_arrange_data.json") throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let jsonData = try encoder.encode(data)
        guard let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            throw NSError(domain: "ClinicDataExporter", code: 1, userInfo: [NSLocalizedDescriptionKey: "無法取得檔案儲存路徑"])
        }
        let fileURL = documentsPath.appendingPathComponent(fileName)
        try jsonData.write(to: fileURL)
    }
    
    // 修改：匯出並共享病人安排數據
    func exportAndShareArrangement(for patient: Patient, completion: @escaping (Result<Void, Error>) -> Void) {
        let data = exportData(for: patient)
        
        do {
            // 使用更具描述性的文件名
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyyMMdd_HHmmss"
            let timestamp = dateFormatter.string(from: Date())
            let fileName = "訓練安排_\(patient.name)_\(timestamp).json"
            
            // 編碼數據
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            
            let jsonData = try encoder.encode(data)
            
            // 使用 FileShareManager 保存並共享數據
            FileShareManager.shared.saveAndShareData(jsonData, fileName: fileName, completion: completion)
        } catch {
            completion(.failure(error))
        }
    }
    
    // 新增：按月份匯出並共享病人安排數據
    func exportAndShareArrangementForMonth(for patient: Patient, month: Date, completion: @escaping (Result<Void, Error>) -> Void) {
        let data = exportDataForMonth(for: patient, month: month)
        
        do {
            // 使用月份格式的文件名
            let monthFormatter = DateFormatter()
            monthFormatter.dateFormat = "yyyy-MM"
            let monthString = monthFormatter.string(from: month)
            
            let timeFormatter = DateFormatter()
            timeFormatter.dateFormat = "yyyyMMdd_HHmmss"
            let timestamp = timeFormatter.string(from: Date())
            
            let fileName = "訓練安排_\(patient.name)_\(monthString)_\(timestamp).json"
            
            // 編碼數據
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            
            let jsonData = try encoder.encode(data)
            
            // 使用 FileShareManager 保存並共享數據
            FileShareManager.shared.saveAndShareData(jsonData, fileName: fileName, completion: completion)
        } catch {
            completion(.failure(error))
        }
    }
}

import Foundation

// 訓練菜單安排
struct TrainingSchedule: Identifiable, Codable, Equatable {
    let id: UUID
    let menuId: UUID
    let patientId: String
    var dates: Set<Date>  // 改用日期集合而不是開始和結束日期
    let timeSlots: Set<String>
    
    // 初始化方法
    init(id: UUID = UUID(), menuId: UUID, patientId: String, selectedDates: Set<Date>, timeSlots: Set<String>) {
        self.id = id
        self.menuId = menuId
        self.patientId = patientId
        self.dates = selectedDates
        self.timeSlots = timeSlots
    }
    
    // 實現 Equatable 協議
    static func == (lhs: TrainingSchedule, rhs: TrainingSchedule) -> Bool {
        return lhs.id == rhs.id &&
               lhs.menuId == rhs.menuId &&
               lhs.patientId == rhs.patientId &&
               lhs.dates == rhs.dates &&
               lhs.timeSlots == rhs.timeSlots
    }
    
    // 檢查日期是否在訓練安排中
    func isDateInRange(_ date: Date) -> Bool {
        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: date)
        guard let normalizedDate = calendar.date(from: dateComponents) else { return false }
        
        return dates.contains { calendar.isDate($0, inSameDayAs: normalizedDate) }
    }
    
    // 獲取所有日期
    func getDates() -> Set<Date> {
        return dates
    }
    
    // 格式化最近三個日期的方法
    func formatTopThreeDates() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM/dd"
        
        let sortedDates = Array(dates).sorted()
        if sortedDates.count <= 3 {
            return sortedDates.map { dateFormatter.string(from: $0) }.joined(separator: ", ")
        } else {
            let topThree = sortedDates.prefix(3).map { dateFormatter.string(from: $0) }.joined(separator: ", ")
            return "\(topThree)..."
        }
    }
}

// 用於管理訓練菜單安排的存儲
class TrainingScheduleStore: ObservableObject {
    static let shared = TrainingScheduleStore()
    static let preview = TrainingScheduleStore(isPreview: true)
    
    @Published private(set) var schedules: [TrainingSchedule] = []
    private let isPreview: Bool
    
    private init(isPreview: Bool = false) {
        self.isPreview = isPreview
        if !isPreview {
            loadSchedules()
        }
    }
    
    func loadSchedules() {
        if isPreview {
            schedules = []
            return
        }
        
        if let data = UserDefaults.standard.data(forKey: "trainingSchedules"),
           let decodedSchedules = try? JSONDecoder().decode([TrainingSchedule].self, from: data) {
            schedules = decodedSchedules
            objectWillChange.send()
        }
    }
    
    func reloadSchedules() {
        if !isPreview {
            loadSchedules()
        }
    }
    
    func addSchedule(_ schedule: TrainingSchedule) {
        schedules.append(schedule)
        saveSchedules()
    }
    
    func removeSchedule(_ schedule: TrainingSchedule) {
        if let index = schedules.firstIndex(where: { $0.id == schedule.id }) {
            schedules.remove(at: index)
            saveSchedules()
        }
    }
    
    func getSchedulesForPatient(_ patientId: String) -> [TrainingSchedule] {
        return schedules.filter { $0.patientId == patientId }
    }
    
    func getSchedulesForMenu(_ menuId: UUID) -> [TrainingSchedule] {
        return schedules.filter { $0.menuId == menuId }
    }
    
    func getSchedulesForDate(_ date: Date) -> [TrainingSchedule] {
        let calendar = Calendar.current
        return schedules.filter { schedule in
            schedule.dates.contains { calendar.isDate($0, inSameDayAs: date) }
        }
    }
    
    // New method to remove specific dates from a schedule
    func removeDatesFromSchedule(_ scheduleId: UUID, inMonthOf referenceDate: Date) {
        if let index = schedules.firstIndex(where: { $0.id == scheduleId }) {
            // Assuming TrainingSchedule is a struct, we need to modify a copy then replace.
            var scheduleToUpdate = schedules[index] 
            
            let calendar = Calendar.current
            let yearMonthToClear = calendar.dateComponents([.year, .month], from: referenceDate)
            
            // Filter out dates that are in the specified month
            scheduleToUpdate.dates = scheduleToUpdate.dates.filter { dateInSchedule in
                let dateComponents = calendar.dateComponents([.year, .month], from: dateInSchedule)
                return !(dateComponents.year == yearMonthToClear.year && dateComponents.month == yearMonthToClear.month)
            }
            
            if scheduleToUpdate.dates.isEmpty {
                // If no dates are left, remove the entire schedule
                schedules.remove(at: index)
            } else {
                // Otherwise, update the schedule with the modified dates
                schedules[index] = scheduleToUpdate
            }
            saveSchedules()
        }
    }
    
    func saveSchedules() {
        if isPreview { return }
        
        if let encoded = try? JSONEncoder().encode(schedules) {
            UserDefaults.standard.set(encoded, forKey: "trainingSchedules")
            objectWillChange.send()
        }
    }
    
    func removeAllSchedulesForPatient(_ patientId: String) {
        if !isPreview {
            schedules.removeAll { schedule in
                schedule.patientId == patientId
            }
            saveSchedules()
        }
    }
    

} 
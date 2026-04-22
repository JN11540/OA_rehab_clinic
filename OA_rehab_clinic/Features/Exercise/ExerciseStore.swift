import SwiftUI

// MARK: - Exercise Store
public class ExerciseStore: ObservableObject {
    public static let shared = ExerciseStore()
    @Published private(set) public var exercises: [ExerciseModule.Exercise] = []
    
    private let fileManager = FileManager.default
    private let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    private let defaultExercisesKey = "defaultExercisesInitialized"
    
    private init() {
        loadExercises()
    }
    
    public func addExercise(_ exercise: ExerciseModule.Exercise, image: UIImage) {
        // Save image to documents directory
        if let imageData = image.jpegData(compressionQuality: 0.8) {
            let imageUrl = documentsPath.appendingPathComponent("\(exercise.imageName).jpg")
            try? imageData.write(to: imageUrl)
        }
        
        // Add exercise to array and save
        exercises.append(exercise)
        saveExercises()
    }
    
    public func deleteExercise(_ exercise: ExerciseModule.Exercise) {
        // Delete image file
        let imageUrl = documentsPath.appendingPathComponent("\(exercise.imageName).jpg")
        try? fileManager.removeItem(at: imageUrl)
        
        // Remove exercise from array and save
        exercises.removeAll { $0.id == exercise.id }
        saveExercises()
    }
    
    private func loadExercises() {
        let url = documentsPath.appendingPathComponent("exercises.json")
        
        // 檢查是否有已保存的運動數據
        if fileManager.fileExists(atPath: url.path),
           let data = try? Data(contentsOf: url),
           let loadedExercises = try? JSONDecoder().decode([ExerciseModule.Exercise].self, from: data),
           !loadedExercises.isEmpty {
            // 如果有已保存的數據，直接加載
            exercises = loadedExercises
        } else {
            // 如果沒有已保存的數據，檢查是否已初始化過預設運動
            if !isDefaultExercisesInitialized() {
                // 首次啟動，初始化預設運動
                initializeDefaultExercises()
                // 標記已初始化預設運動
                markDefaultExercisesAsInitialized()
            }
        }
    }
    
    private func saveExercises() {
        let url = documentsPath.appendingPathComponent("exercises.json")
        guard let data = try? JSONEncoder().encode(exercises) else { return }
        try? data.write(to: url)
    }
    
    // 檢查是否已初始化過預設運動
    private func isDefaultExercisesInitialized() -> Bool {
        return UserDefaults.standard.bool(forKey: defaultExercisesKey)
    }
    
    // 標記已初始化預設運動
    private func markDefaultExercisesAsInitialized() {
        UserDefaults.standard.set(true, forKey: defaultExercisesKey)
    }
    
    // 初始化預設運動
    private func initializeDefaultExercises() {
        // 這裡我們會從 ExerciseSamples 中獲取預設運動
        // 但我們需要確保每個運動都有一個固定的 UUID
        // 這個方法會在應用首次啟動時調用
        
        // 注意：這裡我們假設 ExerciseModule.Exercise.defaultExercises 是一個包含所有預設運動的數組
        // 您需要在 ExerciseSamples.swift 中實現這個屬性
        
        // 加載預設運動
        let defaultExercises = getDefaultExercises()
        exercises = defaultExercises
        saveExercises()
    }
    
    // 獲取預設運動
    private func getDefaultExercises() -> [ExerciseModule.Exercise] {
        // 這裡我們需要從 ExerciseSamples 中獲取所有預設運動
        // 並確保每個運動都有一個固定的 UUID
        
        // 這只是一個示例，您需要根據您的實際情況修改
        var allExercises: [ExerciseModule.Exercise] = []
        
        // 從各個類別中獲取運動 (移除臀部肌群)
        allExercises.append(contentsOf: ExerciseModule.Exercise.quadricepsBasic)
        allExercises.append(contentsOf: ExerciseModule.Exercise.quadricepsIntermediate)
        allExercises.append(contentsOf: ExerciseModule.Exercise.quadricepsAdvanced)
        allExercises.append(contentsOf: ExerciseModule.Exercise.flexibilityBasic)
        allExercises.append(contentsOf: ExerciseModule.Exercise.proprioception)
        
        return allExercises
    }
} 
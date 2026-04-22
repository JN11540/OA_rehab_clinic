import SwiftUI
import Foundation
import UniformTypeIdentifiers

public enum ExerciseModule {
    // MARK: - Exercise
    public struct Exercise: Identifiable, Hashable, Codable, Transferable {
        public let id: UUID
        public let name: String
        public let englishName: String
        public let imageName: String
        public let category: String
        public let level: String?
        public let description: String?
        public let difficulty: String?
        
        public init(id: UUID? = nil, name: String, englishName: String, imageName: String, category: String, level: String?, description: String?, difficulty: String?) {
            self.id = id ?? UUID()
            self.name = name
            self.englishName = englishName
            self.imageName = imageName
            self.category = category
            self.level = level
            self.description = description
            self.difficulty = difficulty
        }
        
        public func hash(into hasher: inout Hasher) {
            hasher.combine(id)
        }
        
        public static func == (lhs: Exercise, rhs: Exercise) -> Bool {
            lhs.id == rhs.id
        }
        
        // MARK: - Transferable
        public static var transferRepresentation: some TransferRepresentation {
            CodableRepresentation(contentType: .exercise)
        }
    }
    
    // MARK: - Training Category
    public enum TrainingCategory: String, CaseIterable {
        case all = "所有訓練"
        case quadriceps = "股四頭肌肌力訓練"
        case flexibility = "柔軟度訓練"
        case proprioception = "膝關節本體感覺訓練"
    }
    
    // MARK: - Exercise Category
    public struct ExerciseCategory: Identifiable {
        public let id = UUID()
        public let name: String
        public let subcategories: [ExerciseSubcategory]
        
        public init(name: String, subcategories: [ExerciseSubcategory]) {
            self.name = name
            self.subcategories = subcategories
        }
    }
    
    // MARK: - Exercise Subcategory
    public struct ExerciseSubcategory: Identifiable {
        public let id = UUID()
        public let name: String
        public let exercises: [Exercise]
        
        public init(name: String, exercises: [Exercise]) {
            self.name = name
            self.exercises = exercises
        }
    }
    
    // MARK: - Helper Functions
    public static func getExercisesForCategory(_ category: TrainingCategory) -> [ExerciseCategory] {
        switch category {
        case .all:
            return ExerciseCategory.samples
        case .quadriceps:
            return [ExerciseCategory.samples[0]]
        case .flexibility:
            return [ExerciseCategory.samples[1]]
        case .proprioception:
            return [ExerciseCategory.samples[2]]
        }
    }
}

// MARK: - UTType Extension
extension UTType {
    static var exercise: UTType {
        UTType(exportedAs: "com.oa-rehab-clinic.exercise")
    }
} 


// Add to ExerciseModule.swift
extension ExerciseModule {
    public struct ParameterConfiguration: Codable, Equatable {
        // Basic parameters
        public var showSets: Bool = true                 // 組數    
        public var showRepetitions: Bool = true         // 次數
         
        // Time-related parameters
        public var showRestTime: Bool = false           // 組間休息時間
        public var showMantainTime: Bool = false         // 維持時間
        
        // Angle parameters
        public var showKneeAngle: Bool = false        // 膝關節角度
        public var showHipAngle: Bool = false         // 髖關節角度
        
        // Additional parameters
        public var showWeight: Bool = false           // 重量
        public var showMVIC: Bool = false             // 肌電閾值
        public var allowStimulation: Bool = false     // 電刺激
        
        public static func forExercise(_ exercise: Exercise) -> ParameterConfiguration {
            // Determine configuration based on exercise category and name
            var config = ParameterConfiguration()
            
            // Common for all
            config.showSets = true          // 組數
            config.showRepetitions = true   // 次數
            
            
            switch exercise.category {
            case "股四頭肌肌力訓練":
                config.showRestTime = true
                config.allowStimulation = true
                
                // could Add weight for intermediate/advanced exercises
                if exercise.level == "中階" || exercise.level == "高階" {
                    config.showWeight = false
                }

                if !exercise.name.contains("登階") || !exercise.name.contains("等長收縮") {
                    config.showKneeAngle = true
                }

                if !exercise.name.contains("登階") {
                    config.showMantainTime = true  //股四頭肌訓練裡只有登階運動沒有維持時間
                }
                
                // Specific exercises might need MVIC
                if exercise.name.contains("等長收縮") || exercise.name.contains("大腿內夾")  {
                    config.showMVIC = true    //股四頭肌訓練裡只有等長收縮跟大腿內夾運動有肌電閾值
                }
                
            // 臀部肌群相關動作現在歸入股四頭肌肌力訓練中
                
            case "柔軟度訓練":
                config.showMantainTime = true
                config.showRestTime = true
                config.allowStimulation = true
                
                // Determine angle type based on exercise
                if !exercise.name.contains("小腿後肌肉伸展") {
                    config.allowStimulation = true     //如果是小腿後肌肉伸展則不需要電刺激
                }
                
            case "膝關節本體感覺訓練":
                config.showHipAngle = true
                config.showRestTime = true
                config.allowStimulation = false
                
                // No MVIC for proprioception
                config.showMVIC = false
                
            default:
                // Default configuration for unknown categories
                config.showRestTime = true
                config.showMantainTime = true
            }
            
            return config
        }
    }
}
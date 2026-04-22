import Foundation
import SwiftUI

// MARK: - 📊 UI VISUALIZATION LAYER - 訓練表現視覺化數據模型
//
// 用途說明：
// - 專為訓練表現分析和圖表顯示設計的數據結構
// - 簡化的指標組合，適合UI展示和用戶理解
// - 支援時間趨勢分析和視覺化圖表渲染
// - 數據來源：數據庫查詢結果的轉換或模擬數據生成
// - 使用場景：圖表顯示、趨勢分析、用戶界面展示
//
// ⚠️ 注意：請勿與數據庫層的PersistentTrainingResult混淆使用

/**
 * TrainingPerformanceModels.swift - 訓練表現視覺化數據模型
 * 
 * 功能：
 * - 定義五個核心表現指標的數據結構
 * - 支援三個重要動作的訓練結果
 * - 整合治療師設定參數
 * - 為模擬數據生成和圖表顯示提供數據基礎
 */

// MARK: - 訓練表現指標

/**
 * TrainingPerformanceMetrics - 五個核心表現指標
 * 根據圖片中的結果呈現欄位定義
 */
struct TrainingPerformanceMetrics: Codable, Equatable {
    let muscleStrength: Double      // 肌力 (0-100)
    let stability: Double           // 穩定度 (0-100)
    let regularity: Double          // 規律性 (0-100)
    let reactionTime: Double        // 反應時間 (0-100分，越高越好)
    let completionRate: Double      // 完成度 (0-100)
    
    init(
        muscleStrength: Double = 0,
        stability: Double = 0,
        regularity: Double = 0,
        reactionTime: Double = 50,
        completionRate: Double = 0
    ) {
        self.muscleStrength = muscleStrength
        self.stability = stability
        self.regularity = regularity
        self.reactionTime = reactionTime
        self.completionRate = completionRate
    }
}

// MARK: - 治療師設定參數

/**
 * TherapistSettings - 治療師為特定動作設定的參數
 * 根據 ExerciseParameters.swift 中的 LegParameters 映射
 */
struct TherapistSettings: Codable, Equatable {
    let exerciseName: String
    let sets: Int                   // 組數
    let repetitions: Int            // 次數
    let restTime: Int               // 組間休息時間(秒)
    let mvic: Int?                  // MVIC百分比 (僅部分動作有)
    let maintainTime: Int?          // 維持時間(秒)
    
    // 角度參數
    let kneeAngleStart: Int?        // 膝關節角度下限
    let kneeAngleEnd: Int?          // 膝關節角度上限
    let hipAngleStart: Int?         // 髖關節角度下限
    let hipAngleEnd: Int?           // 髖關節角度上限
    
    // 其他參數
    let weight: Double?             // 重量(kg)
    let stimulation: Bool           // 電刺激開關
    let stimulationIntensity: Int?  // 電刺激強度
    
    init(
        exerciseName: String,
        sets: Int = 3,
        repetitions: Int = 10,
        restTime: Int = 30,
        mvic: Int? = nil,
        maintainTime: Int? = nil,
        kneeAngleStart: Int? = nil,
        kneeAngleEnd: Int? = nil,
        hipAngleStart: Int? = nil,
        hipAngleEnd: Int? = nil,
        weight: Double? = nil,
        stimulation: Bool = false,
        stimulationIntensity: Int? = nil
    ) {
        self.exerciseName = exerciseName
        self.sets = sets
        self.repetitions = repetitions
        self.restTime = restTime
        self.mvic = mvic
        self.maintainTime = maintainTime
        self.kneeAngleStart = kneeAngleStart
        self.kneeAngleEnd = kneeAngleEnd
        self.hipAngleStart = hipAngleStart
        self.hipAngleEnd = hipAngleEnd
        self.weight = weight
        self.stimulation = stimulation
        self.stimulationIntensity = stimulationIntensity
    }
    
    // 用於UI顯示的參數列表
    var displayParameters: [ParameterDisplayItem] {
        var items: [ParameterDisplayItem] = []
        
        // 基本參數
        items.append(ParameterDisplayItem(label: "組數", value: "\(sets) 組", icon: "number.square", color: .blue))
        items.append(ParameterDisplayItem(label: "次數", value: "\(repetitions) 次", icon: "repeat", color: .green))
        items.append(ParameterDisplayItem(label: "休息時間", value: "\(restTime) 秒", icon: "clock", color: .orange))
        
        // 時間相關參數
        if let maintainTime = maintainTime {
            items.append(ParameterDisplayItem(label: "維持時間", value: "\(maintainTime) 秒", icon: "timer", color: .indigo))
        }
        
        // 角度參數
        if let kneeStart = kneeAngleStart, let kneeEnd = kneeAngleEnd {
            items.append(ParameterDisplayItem(label: "膝關節角度", value: "\(kneeStart)°-\(kneeEnd)°", icon: "angle", color: .cyan))
        }
        
        if let hipStart = hipAngleStart, let hipEnd = hipAngleEnd {
            items.append(ParameterDisplayItem(label: "髖關節角度", value: "\(hipStart)°-\(hipEnd)°", icon: "angle", color: .teal))
        }
        
        // 其他參數
        if let weight = weight, weight > 0 {
            items.append(ParameterDisplayItem(label: "重量", value: "\(String(format: "%.1f", weight)) kg", icon: "scalemass", color: .brown))
        }
        
        if let mvic = mvic {
            items.append(ParameterDisplayItem(label: "MVIC", value: "\(mvic)%", icon: "bolt.circle", color: .purple))
        }
        
        // 電刺激參數
        items.append(ParameterDisplayItem(
            label: "電刺激", 
            value: stimulation ? "開啟" : "關閉", 
            icon: stimulation ? "bolt.fill" : "bolt.slash", 
            color: stimulation ? .yellow : .gray
        ))
        
        if stimulation, let intensity = stimulationIntensity {
            items.append(ParameterDisplayItem(label: "刺激強度", value: "\(intensity)", icon: "waveform", color: .yellow))
        }
        
        return items
    }
}

// MARK: - 參數顯示項目

struct ParameterDisplayItem {
    let label: String
    let value: String
    let icon: String
    let color: Color
}

// MARK: - 訓練結果記錄

/**
 * TrainingVisualizationData - 單次訓練的視覺化展示數據
 * 專為UI圖表和分析視圖設計，包含簡化的指標和元數據
 */
struct TrainingVisualizationData: Identifiable, Codable, Equatable {
    let id = UUID()
    let patientId: String
    let exerciseName: String
    let date: Date
    let sessionDuration: TimeInterval      // 訓練時長(秒)
    
    // 治療師設定的參數
    let therapistSettings: TherapistSettings
    
    // 實際表現指標
    let performance: TrainingPerformanceMetrics
    
    // 額外資訊
    let painLevel: Int?                    // 疼痛程度 (0-10)
    let effortLevel: Int?                  // 努力程度 (0-10)
    let notes: String?                     // 備註
    
    init(
        patientId: String,
        exerciseName: String,
        date: Date = Date(),
        sessionDuration: TimeInterval = 0,
        therapistSettings: TherapistSettings,
        performance: TrainingPerformanceMetrics,
        painLevel: Int? = nil,
        effortLevel: Int? = nil,
        notes: String? = nil
    ) {
        self.patientId = patientId
        self.exerciseName = exerciseName
        self.date = date
        self.sessionDuration = sessionDuration
        self.therapistSettings = therapistSettings
        self.performance = performance
        self.painLevel = painLevel
        self.effortLevel = effortLevel
        self.notes = notes
    }
}

// MARK: - 支援的動作類型

/**
 * SupportedExerciseType - 三個重要動作的枚舉
 * 每個動作有不同的表現特性和參數配置
 */
enum SupportedExerciseType: String, CaseIterable {
    case kneeExtension = "股四頭肌終端伸展"
    case partialSquat = "部分蹲"  
    case stepUp = "登階運動"
    
    var displayName: String {
        return self.rawValue
    }
    
    // 每個動作的預設治療師設定
    var defaultTherapistSettings: TherapistSettings {
        switch self {
        case .kneeExtension:
            // 股四頭肌終端伸展：股四頭肌肌力訓練類別，有維持時間、膝關節角度、電刺激（取消MVIC參數）
            return TherapistSettings(
                exerciseName: self.rawValue,
                sets: 3,
                repetitions: 10,
                restTime: 30,
                mvic: nil,             // 移除MVIC參數
                maintainTime: 5,       // 有維持時間
                kneeAngleStart: 0,     // 膝關節角度範圍
                kneeAngleEnd: 90,
                hipAngleStart: nil,    // 股四頭肌訓練不需要髖關節角度
                hipAngleEnd: nil,
                weight: nil,           // 初階動作不加重
                stimulation: false     // 可開啟電刺激
            )
            
        case .partialSquat:
            // 部分蹲：股四頭肌肌力訓練類別，有維持時間、膝關節角度、電刺激，但無MVIC
            return TherapistSettings(
                exerciseName: self.rawValue,
                sets: 3,
                repetitions: 15,
                restTime: 45,
                mvic: nil,             // 部分蹲沒有MVIC（根據ExerciseModule配置）
                maintainTime: 8,       // 有維持時間
                kneeAngleStart: 0,     // 膝關節角度範圍  
                kneeAngleEnd: 60,      // 部分蹲角度較小
                hipAngleStart: nil,    // 股四頭肌訓練不需要髖關節角度
                hipAngleEnd: nil,
                weight: nil,           // 初階動作不加重
                stimulation: false     // 可開啟電刺激
            )
            
        case .stepUp:
            // 登階運動：股四頭肌肌力訓練類別，無MVIC、無維持時間、無膝關節角度，可開啟電刺激
            return TherapistSettings(
                exerciseName: self.rawValue,
                sets: 3,
                repetitions: 12,
                restTime: 60,
                mvic: nil,             // 登階運動沒有MVIC
                maintainTime: nil,     // 登階運動沒有維持時間
                kneeAngleStart: nil,   // 登階運動沒有角度限制
                kneeAngleEnd: nil,
                hipAngleStart: nil,    
                hipAngleEnd: nil,
                weight: nil,           // 可能在高階時加重
                stimulation: false     // 可開啟電刺激
            )
        }
    }
    
    // 每個動作的表現指標權重（用於模擬數據生成）
    var performanceWeights: (strength: Double, stability: Double, regularity: Double, reaction: Double, completion: Double) {
        switch self {
        case .kneeExtension:
            // 股四頭肌終端伸展：重點提升肌力和穩定度
            return (strength: 1.0, stability: 1.0, regularity: 0.8, reaction: 0.7, completion: 0.9)
            
        case .partialSquat:
            // 部分蹲：重點提升肌力和完成度
            return (strength: 1.0, stability: 0.9, regularity: 0.8, reaction: 0.8, completion: 1.0)
            
        case .stepUp:
            // 登階運動：重點提升規律性和反應時間
            return (strength: 0.8, stability: 0.9, regularity: 1.0, reaction: 1.0, completion: 0.9)
        }
    }
    
    // 圖表顏色主題
    var colorTheme: (strength: Color, stability: Color, regularity: Color, reaction: Color, completion: Color) {
        return (
            strength: .red,
            stability: .blue, 
            regularity: .green,
            reaction: .orange,
            completion: .purple
        )
    }
}

// MARK: - 圖表數據點

/**
 * PerformanceChartDataPoint - 用於圖表顯示的數據點
 */
struct PerformanceChartDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let value: Double
    let metricType: String
    let exerciseName: String
}

// MARK: - 時間範圍

/**
 * TrainingDateRange - 訓練數據查看的時間範圍
 */
enum TrainingDateRange: CaseIterable {
    case oneWeek
    case oneMonth  
    case threeMonths
    case sixMonths
    
    var title: String {
        switch self {
        case .oneWeek: return "過去一週"
        case .oneMonth: return "過去一個月"
        case .threeMonths: return "過去三個月"
        case .sixMonths: return "過去六個月"
        }
    }
    
    var days: Int {
        switch self {
        case .oneWeek: return 7
        case .oneMonth: return 30
        case .threeMonths: return 90
        case .sixMonths: return 180
        }
    }
}

// MARK: - 輔助方法

extension SupportedExerciseType {
    
    /**
     * 從運動名稱字符串映射到支援的動作類型
     * 用於與現有的 ExerciseModule.Exercise 整合
     */
    static func from(exerciseName: String) -> SupportedExerciseType? {
        switch exerciseName {
        case "股四頭肌終端伸展", "2.膝關節終端伸展", "膝關節終端伸展":
            return .kneeExtension
        case "部分蹲", "9.部分蹲":
            return .partialSquat
        case "登階運動", "12.登階運動":
            return .stepUp
        default:
            return nil
        }
    }
}
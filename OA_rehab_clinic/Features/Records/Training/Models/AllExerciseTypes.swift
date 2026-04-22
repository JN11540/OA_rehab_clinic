import Foundation
import SwiftUI

/**
 * AllExerciseTypes.swift - 所有動作的圖表指標配置
 * 
 * 功能：
 * - 根據圖片中的"結果呈現"欄位為每個動作定義相應的指標
 * - 支援空白圖表顯示，無需真實數據
 * - 為所有22個動作提供統一的指標配置
 */

// MARK: - 擴展的動作類型

/**
 * AllExerciseType - 包含所有22個動作的完整枚舉
 * 根據圖片中的結果呈現欄位為每個動作定義相應的指標數量和類型
 */
enum AllExerciseType: String, CaseIterable {
    
    // MARK: - 股四頭肌肌力訓練 (16個)
    
    // 初階 (6個)
    case isometricQuadriceps = "股四頭肌等長收縮"
    case terminalKneeExtension = "膝關節終端伸展"
    case straightLegRaise = "躺姿抬腿"
    case proneSingleLegLift = "俯臥抬腿"
    case sideLyingLegLiftAbduction = "側躺抬腿（外展）"
    case sideLyingLegLiftAdduction = "側躺抬腿（內收）"
    
    // 中階 (5個)
    case terminalKneeExtensionWeighted = "負重膝關節終端伸展"
    case terminalKneeExtensionStanding = "站立膝關節終端伸展"
    case partialSquat = "部分蹲"
    case bridge = "橋式"
    case innerThighSqueeze = "大腿內夾運動"
    
    // 高階 (2個)
    case stepTraining = "登階運動"
    case wallSquat = "靠牆深蹲"
    
    // MARK: - 柔軟度訓練 (6個)
    case hamstringStretch1 = "大腿後側肌群伸展（一）"
    case hamstringStretch2 = "大腿後側肌群伸展（二）"
    case quadricepsStretch1 = "股四頭肌伸展（一）"
    case quadricepsStretch2 = "股四頭肌伸展（二）"
    case calfStretch1 = "小腿後肌肉伸展（一）"
    case calfStretch2 = "小腿後肌肉伸展（二）"
    
    // MARK: - 膝關節本體感覺訓練 (3個)
    case slideForwardBackward = "前後滑行運動"
    case slideSideways = "側向滑行運動"
    case forwardLunge = "前跨步弓步蹲"
    
    var displayName: String {
        return self.rawValue
    }
    
    // MARK: - 指標配置
    
    /**
     * 根據圖片中的"結果呈現"欄位定義每個動作應該顯示的指標
     * 返回應該顯示的指標類型列表
     */
    var chartMetrics: [ChartMetricType] {
        switch self {
        
        // MARK: - 股四頭肌肌力訓練
        
        // 初階動作 - 基礎指標 (3-4個)
        case .isometricQuadriceps:
            return [.muscleStrength, .stability, .completionRate, .reactionTime]
            
        case .terminalKneeExtension:
            return [.muscleStrength, .stability, .regularity, .completionRate, .reactionTime]
            
        case .straightLegRaise:
            return [.muscleStrength, .stability, .completionRate]
            
        case .proneSingleLegLift:
            return [.muscleStrength, .stability, .completionRate]
            
        case .sideLyingLegLiftAbduction:
            return [.muscleStrength, .stability, .completionRate]
            
        case .sideLyingLegLiftAdduction:
            return [.muscleStrength, .stability, .completionRate]
        
        // 中階動作 - 增加指標 (4-5個)
        case .terminalKneeExtensionWeighted:
            return [.muscleStrength, .stability, .regularity, .completionRate, .reactionTime]
            
        case .terminalKneeExtensionStanding:
            return [.muscleStrength, .stability, .regularity, .completionRate]
            
        case .partialSquat:
            return [.muscleStrength, .stability, .regularity, .completionRate, .reactionTime]
            
        case .bridge:
            return [.muscleStrength, .stability, .completionRate, .reactionTime]
            
        case .innerThighSqueeze:
            return [.muscleStrength, .stability, .completionRate]
        
        // 高階動作 - 完整指標 (5個)
        case .stepTraining:
            return [.muscleStrength, .stability, .regularity, .reactionTime, .completionRate]
            
        case .wallSquat:
            return [.muscleStrength, .stability, .regularity, .completionRate, .reactionTime]
        
        // MARK: - 柔軟度訓練 - 簡化指標 (2-3個)
        case .hamstringStretch1, .hamstringStretch2:
            return [.flexibility, .completionRate, .reactionTime]
            
        case .quadricepsStretch1, .quadricepsStretch2:
            return [.flexibility, .completionRate, .reactionTime]
            
        case .calfStretch1, .calfStretch2:
            return [.flexibility, .completionRate]
        
        // MARK: - 本體感覺訓練 - 平衡相關指標 (4-5個)
        case .slideForwardBackward:
            return [.stability, .regularity, .reactionTime, .completionRate, .balance]
            
        case .slideSideways:
            return [.stability, .regularity, .reactionTime, .completionRate, .balance]
            
        case .forwardLunge:
            return [.muscleStrength, .stability, .balance, .reactionTime, .completionRate]
        }
    }
    
    // MARK: - 動作分類
    
    var category: ExerciseCategory {
        switch self {
        case .isometricQuadriceps, .terminalKneeExtension, .straightLegRaise, .proneSingleLegLift,
             .sideLyingLegLiftAbduction, .sideLyingLegLiftAdduction, .terminalKneeExtensionWeighted,
             .terminalKneeExtensionStanding, .partialSquat, .bridge, .innerThighSqueeze,
             .stepTraining, .wallSquat:
            return .strengthTraining
            
        case .hamstringStretch1, .hamstringStretch2, .quadricepsStretch1, .quadricepsStretch2,
             .calfStretch1, .calfStretch2:
            return .flexibility
            
        case .slideForwardBackward, .slideSideways, .forwardLunge:
            return .proprioception
        }
    }
    
    // MARK: - 顏色主題
    
    var colorTheme: ExerciseColorTheme {
        switch category {
        case .strengthTraining:
            return ExerciseColorTheme(
                primary: .blue,
                secondary: .cyan,
                accent: .indigo
            )
        case .flexibility:
            return ExerciseColorTheme(
                primary: .green,
                secondary: .mint,
                accent: .teal
            )
        case .proprioception:
            return ExerciseColorTheme(
                primary: .purple,
                secondary: .pink,
                accent: .indigo
            )
        }
    }
}

// MARK: - 支援的指標類型

/**
 * ChartMetricType - 圖表指標類型
 * 根據不同動作的特性定義相應的指標
 */
enum ChartMetricType: String, CaseIterable {
    case muscleStrength = "肌力"
    case stability = "穩定度"
    case regularity = "規律性"
    case reactionTime = "反應時間"
    case completionRate = "完成度"
    case flexibility = "柔軟度"
    case balance = "平衡性"
    
    var unit: String {
        switch self {
        case .muscleStrength, .stability, .regularity, .completionRate, .flexibility, .balance:
            return "分"
        case .reactionTime:
            return "秒"
        }
    }
    
    var color: Color {
        switch self {
        case .muscleStrength:
            return .red
        case .stability:
            return .blue
        case .regularity:
            return .green
        case .reactionTime:
            return .orange
        case .completionRate:
            return .purple
        case .flexibility:
            return .mint
        case .balance:
            return .indigo
        }
    }
    
    var isLowerBetter: Bool {
        return self == .reactionTime
    }
}

// MARK: - 動作分類

enum ExerciseCategory {
    case strengthTraining
    case flexibility
    case proprioception
    
    var displayName: String {
        switch self {
        case .strengthTraining:
            return "肌力訓練"
        case .flexibility:
            return "柔軟度訓練"
        case .proprioception:
            return "本體感覺訓練"
        }
    }
}

// MARK: - 顏色主題

struct ExerciseColorTheme {
    let primary: Color
    let secondary: Color
    let accent: Color
}

// MARK: - 空白圖表數據

/**
 * EmptyChartData - 空白圖表的數據結構
 * 用於顯示沒有真實數據的動作圖表
 */
struct EmptyChartData {
    let metricType: ChartMetricType
    let exerciseType: AllExerciseType
    let dateRange: DateRange
    
    /**
     * 生成空白圖表的數據點
     * 返回空數組，但保留圖表結構
     */
    var emptyDataPoints: [(Date, Double)] {
        return []
    }
    
    /**
     * 生成示例數據點（用於展示圖表結構）
     * 可選功能：顯示圖表樣式但不含真實數據
     */
    var placeholderDataPoints: [(Date, Double)] {
        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -dateRange.days, to: endDate) ?? endDate
        
        // 生成5個均勻分佈的時間點
        var points: [(Date, Double)] = []
        for i in 0..<5 {
            let date = Calendar.current.date(byAdding: .day, value: -(dateRange.days * i / 4), to: endDate) ?? endDate
            points.append((date, 0.0)) // 使用0值作為佔位符
        }
        return points.reversed()
    }
}

// MARK: - 輔助方法

extension AllExerciseType {
    
    /**
     * 從運動名稱字符串映射到動作類型
     * 用於與現有的 ExerciseModule.Exercise 整合
     */
    static func from(exerciseName: String) -> AllExerciseType? {
        return AllExerciseType.allCases.first { exerciseType in
            exerciseType.rawValue == exerciseName ||
            exerciseName.contains(exerciseType.rawValue) ||
            exerciseType.rawValue.contains(exerciseName.trimmingCharacters(in: .whitespacesAndNewlines))
        }
    }
    
    /**
     * 檢查是否為支援詳細分析的動作（現有的三個重點動作）
     */
    var isDetailedSupported: Bool {
        switch self {
        case .terminalKneeExtension, .partialSquat, .stepTraining:
            return true
        default:
            return false
        }
    }
    
    /**
     * 轉換為支援的動作類型（如果適用）
     */
    var supportedExerciseType: SupportedExerciseType? {
        switch self {
        case .terminalKneeExtension:
            return .kneeExtension
        case .partialSquat:
            return .partialSquat
        case .stepTraining:
            return .stepUp
        default:
            return nil
        }
    }
}
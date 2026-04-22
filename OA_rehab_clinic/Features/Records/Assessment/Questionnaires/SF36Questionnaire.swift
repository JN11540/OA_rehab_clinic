//
//  SF36Questionnaire.swift
//  OA_rehab_clinic
//
//  Created by Claude Code on 2025-06-23.
//

import Foundation

// MARK: - SF-36 維度定義
/// SF-36健康調查量表的8個健康維度
enum SF36Dimension: String, CaseIterable, Codable {
    case physicalFunctioning = "身體功能"           // PF - 10題
    case rolePhysical = "身體角色功能"              // RP - 4題  
    case bodilyPain = "身體疼痛"                   // BP - 2題
    case generalHealth = "一般健康"                // GH - 5題
    case vitality = "活力"                         // VT - 4題
    case socialFunctioning = "社會功能"            // SF - 2題
    case roleEmotional = "情緒角色功能"            // RE - 3題
    case mentalHealth = "心理健康"                 // MH - 5題
    
    /// 各維度的題目數量
    var questionCount: Int {
        switch self {
        case .physicalFunctioning: return 10
        case .rolePhysical: return 4
        case .bodilyPain: return 2
        case .generalHealth: return 5
        case .vitality: return 4
        case .socialFunctioning: return 2
        case .roleEmotional: return 3
        case .mentalHealth: return 5
        }
    }
    
    /// 維度簡稱
    var abbreviation: String {
        switch self {
        case .physicalFunctioning: return "PF"
        case .rolePhysical: return "RP"
        case .bodilyPain: return "BP"
        case .generalHealth: return "GH"
        case .vitality: return "VT"
        case .socialFunctioning: return "SF"
        case .roleEmotional: return "RE"
        case .mentalHealth: return "MH"
        }
    }
}

// MARK: - SF-36 問題模型
/// SF-36問卷的單一問題
struct SF36Question: Identifiable, Codable {
    let id: Int                          // 問題編號 (1-36)
    let dimension: SF36Dimension         // 所屬維度
    let questionText: String             // 問題內容
    let options: [SF36Option]            // 選項列表
    let isReverseCoded: Bool             // 是否需要反向計分
    
    /// 問題標題（包含編號）
    var title: String {
        return "第\(id)題"
    }
}

// MARK: - SF-36 選項模型
/// SF-36問卷的選項
struct SF36Option: Identifiable, Codable {
    let id: Int                          // 選項編號
    let text: String                     // 選項文字
    let rawScore: Int                    // 原始分數
    
    // MARK: - 標準選項定義
    
    /// 身體功能限制選項 (3選項, 1-3分)
    static let physicalFunctioningOptions = [
        SF36Option(id: 1, text: "受到很大限制", rawScore: 1),
        SF36Option(id: 2, text: "受到一點限制", rawScore: 2),
        SF36Option(id: 3, text: "沒有受到限制", rawScore: 3)
    ]
    
    /// 是/否選項 (2選項, 1-2分)
    static let yesNoOptions = [
        SF36Option(id: 1, text: "是", rawScore: 1),
        SF36Option(id: 2, text: "否", rawScore: 2)
    ]
    
    /// 一般健康選項 (5選項, 1-5分)
    static let generalHealthOptions = [
        SF36Option(id: 1, text: "極好", rawScore: 1),
        SF36Option(id: 2, text: "很好", rawScore: 2),
        SF36Option(id: 3, text: "好", rawScore: 3),
        SF36Option(id: 4, text: "尚可", rawScore: 4),
        SF36Option(id: 5, text: "差", rawScore: 5)
    ]
    
    /// 頻率選項 (6選項, 1-6分)
    static let frequencyOptions = [
        SF36Option(id: 1, text: "一直都是", rawScore: 1),
        SF36Option(id: 2, text: "大部分時候", rawScore: 2),
        SF36Option(id: 3, text: "經常", rawScore: 3),
        SF36Option(id: 4, text: "有時候", rawScore: 4),
        SF36Option(id: 5, text: "很少", rawScore: 5),
        SF36Option(id: 6, text: "從來沒有", rawScore: 6)
    ]
    
    /// 疼痛程度選項 (6選項, 1-6分)
    static let painIntensityOptions = [
        SF36Option(id: 1, text: "沒有疼痛", rawScore: 1),
        SF36Option(id: 2, text: "很輕微", rawScore: 2),
        SF36Option(id: 3, text: "輕微", rawScore: 3),
        SF36Option(id: 4, text: "中等", rawScore: 4),
        SF36Option(id: 5, text: "嚴重", rawScore: 5),
        SF36Option(id: 6, text: "很嚴重", rawScore: 6)
    ]
    
    /// 疼痛干擾選項 (5選項, 1-5分)
    static let painInterferenceOptions = [
        SF36Option(id: 1, text: "完全沒有", rawScore: 1),
        SF36Option(id: 2, text: "一點點", rawScore: 2),
        SF36Option(id: 3, text: "中等程度", rawScore: 3),
        SF36Option(id: 4, text: "相當多", rawScore: 4),
        SF36Option(id: 5, text: "非常多", rawScore: 5)
    ]
    
    /// 社會功能選項 (5選項, 1-5分)
    static let socialFunctioningOptions = [
        SF36Option(id: 1, text: "完全沒有", rawScore: 1),
        SF36Option(id: 2, text: "輕微", rawScore: 2),
        SF36Option(id: 3, text: "中等程度", rawScore: 3),
        SF36Option(id: 4, text: "相當多", rawScore: 4),
        SF36Option(id: 5, text: "非常多", rawScore: 5)
    ]
}

// MARK: - SF-36 回答模型
/// 使用者對SF-36問題的回答
struct SF36Response: Codable {
    let questionId: Int                  // 問題ID
    let dimension: SF36Dimension         // 所屬維度
    let selectedOptionId: Int            // 選擇的選項ID
    let rawScore: Int                    // 原始分數
    let responseDate: Date               // 回答時間
    
    init(questionId: Int, dimension: SF36Dimension, selectedOptionId: Int, rawScore: Int, responseDate: Date = Date()) {
        self.questionId = questionId
        self.dimension = dimension
        self.selectedOptionId = selectedOptionId
        self.rawScore = rawScore
        self.responseDate = responseDate
    }
}

// MARK: - SF-36 評估結果
/// SF-36量表的評估結果，包含原始分數和標準化分數
struct SF36AssessmentResult: Codable {
    let responses: [SF36Response]                    // 所有回答
    let dimensionRawScores: [SF36Dimension: Int]     // 各維度原始分數
    let dimensionScores: [SF36Dimension: Double]     // 各維度標準化分數 (0-100)
    let completedAt: Date                            // 完成時間
    let patientId: String                            // 患者ID
    
    /// 總分（所有維度平均）
    var totalScore: Double {
        let allScores = dimensionScores.values
        return allScores.reduce(0, +) / Double(allScores.count)
    }
    
    /// 初始化並計算分數
    init(responses: [SF36Response], patientId: String, completedAt: Date = Date()) {
        self.responses = responses
        self.patientId = patientId
        self.completedAt = completedAt
        
        // 計算各維度原始分數
        var rawScores: [SF36Dimension: Int] = [:]
        for dimension in SF36Dimension.allCases {
            let dimensionResponses = responses.filter { $0.dimension == dimension }
            let rawScore = dimensionResponses.reduce(0) { $0 + $1.rawScore }
            rawScores[dimension] = rawScore
        }
        self.dimensionRawScores = rawScores
        
        // 計算標準化分數 (0-100)
        var standardizedScores: [SF36Dimension: Double] = [:]
        for dimension in SF36Dimension.allCases {
            let rawScore = rawScores[dimension] ?? 0
            let standardizedScore = SF36ScoringCalculator.calculateStandardizedScore(
                for: dimension,
                rawScore: rawScore
            )
            standardizedScores[dimension] = standardizedScore
        }
        self.dimensionScores = standardizedScores
    }
}

// MARK: - SF-36 計分計算器
/// SF-36量表的計分邏輯計算器
struct SF36ScoringCalculator {
    
    /// 計算標準化分數 (0-100)
    static func calculateStandardizedScore(for dimension: SF36Dimension, rawScore: Int) -> Double {
        let scoreRange = getScoreRange(for: dimension)
        let minPossibleScore = scoreRange.min
        let maxPossibleScore = scoreRange.max
        
        // 標準化公式：((實際分數 - 最低分數) / (最高分數 - 最低分數)) × 100
        let standardizedScore = Double(rawScore - minPossibleScore) / Double(maxPossibleScore - minPossibleScore) * 100.0
        
        return max(0.0, min(100.0, standardizedScore))
    }
    
    /// 獲取各維度的分數範圍
    private static func getScoreRange(for dimension: SF36Dimension) -> (min: Int, max: Int) {
        switch dimension {
        case .physicalFunctioning:
            return (min: 10, max: 30)  // 10題 × (1-3分)
        case .rolePhysical:
            return (min: 4, max: 8)    // 4題 × (1-2分)
        case .bodilyPain:
            return (min: 2, max: 11)   // 特殊計算：第21題(1-6) + 第22題(1-5)
        case .generalHealth:
            return (min: 5, max: 25)   // 5題 × (1-5分)
        case .vitality:
            return (min: 4, max: 24)   // 4題 × (1-6分)
        case .socialFunctioning:
            return (min: 2, max: 10)   // 2題 × (1-5分)
        case .roleEmotional:
            return (min: 3, max: 6)    // 3題 × (1-2分)
        case .mentalHealth:
            return (min: 5, max: 30)   // 5題 × (1-6分)
        }
    }
}

// MARK: - SF-36 問卷定義
/// SF-36量表的完整問卷定義
struct SF36Questionnaire {
    static let questions: [SF36Question] = [
        // 身體功能 (PF) - 第3-12題 (10題)
        SF36Question(id: 3, dimension: .physicalFunctioning, questionText: "劇烈活動，例如跑步、舉重物、參與劇烈運動", options: SF36Option.physicalFunctioningOptions, isReverseCoded: false),
        SF36Question(id: 4, dimension: .physicalFunctioning, questionText: "中等程度活動，例如搬桌子、拖地板、打保齡球、或打太極拳", options: SF36Option.physicalFunctioningOptions, isReverseCoded: false),
        SF36Question(id: 5, dimension: .physicalFunctioning, questionText: "提取或攜帶食品雜貨", options: SF36Option.physicalFunctioningOptions, isReverseCoded: false),
        SF36Question(id: 6, dimension: .physicalFunctioning, questionText: "爬幾層樓梯", options: SF36Option.physicalFunctioningOptions, isReverseCoded: false),
        SF36Question(id: 7, dimension: .physicalFunctioning, questionText: "爬一層樓梯", options: SF36Option.physicalFunctioningOptions, isReverseCoded: false),
        SF36Question(id: 8, dimension: .physicalFunctioning, questionText: "彎腰、跪下或蹲下", options: SF36Option.physicalFunctioningOptions, isReverseCoded: false),
        SF36Question(id: 9, dimension: .physicalFunctioning, questionText: "步行1公里以上", options: SF36Option.physicalFunctioningOptions, isReverseCoded: false),
        SF36Question(id: 10, dimension: .physicalFunctioning, questionText: "步行數個街口", options: SF36Option.physicalFunctioningOptions, isReverseCoded: false),
        SF36Question(id: 11, dimension: .physicalFunctioning, questionText: "步行一個街口", options: SF36Option.physicalFunctioningOptions, isReverseCoded: false),
        SF36Question(id: 12, dimension: .physicalFunctioning, questionText: "自己洗澡或穿衣", options: SF36Option.physicalFunctioningOptions, isReverseCoded: false),
        
        // 身體角色功能 (RP) - 第13-16題 (4題)
        SF36Question(id: 13, dimension: .rolePhysical, questionText: "您減少了工作或其他活動的時間", options: SF36Option.yesNoOptions, isReverseCoded: true),
        SF36Question(id: 14, dimension: .rolePhysical, questionText: "完成的工作或其他活動比您想要完成的少", options: SF36Option.yesNoOptions, isReverseCoded: true),
        SF36Question(id: 15, dimension: .rolePhysical, questionText: "工作或其他活動的種類受到限制", options: SF36Option.yesNoOptions, isReverseCoded: true),
        SF36Question(id: 16, dimension: .rolePhysical, questionText: "完成工作或其他活動有困難（例如，需要額外努力）", options: SF36Option.yesNoOptions, isReverseCoded: true),
        
        // 情緒角色功能 (RE) - 第17-19題 (3題)
        SF36Question(id: 17, dimension: .roleEmotional, questionText: "您減少了工作或其他活動的時間", options: SF36Option.yesNoOptions, isReverseCoded: true),
        SF36Question(id: 18, dimension: .roleEmotional, questionText: "完成的工作或其他活動比您想要完成的少", options: SF36Option.yesNoOptions, isReverseCoded: true),
        SF36Question(id: 19, dimension: .roleEmotional, questionText: "做工作或其他活動時不像平常那麼仔細", options: SF36Option.yesNoOptions, isReverseCoded: true),
        
        // 社會功能 (SF) - 第20, 32題 (2題)
        SF36Question(id: 20, dimension: .socialFunctioning, questionText: "在過去的四個星期中，您的身體健康或情緒問題在多大程度上妨礙了您與家人、朋友、鄰居或團體的正常社交活動？", options: SF36Option.socialFunctioningOptions, isReverseCoded: true),
        SF36Question(id: 32, dimension: .socialFunctioning, questionText: "在過去的四個星期中，有多少時候您的身體健康或情緒問題妨礙了您的社交活動（如拜訪朋友、親戚等）？", options: SF36Option.frequencyOptions, isReverseCoded: true),
        
        // 身體疼痛 (BP) - 第21-22題 (2題)
        SF36Question(id: 21, dimension: .bodilyPain, questionText: "在過去的四個星期中，您身體疼痛的程度如何？", options: SF36Option.painIntensityOptions, isReverseCoded: true),
        SF36Question(id: 22, dimension: .bodilyPain, questionText: "在過去的四個星期中，疼痛在多大程度上妨礙了您的正常工作（包括工作和家務）？", options: SF36Option.painInterferenceOptions, isReverseCoded: true),
        
        // 一般健康 (GH) - 第1, 33-36題 (5題)
        SF36Question(id: 1, dimension: .generalHealth, questionText: "總的來說，您認為您現在的健康狀況是：", options: SF36Option.generalHealthOptions, isReverseCoded: true),
        SF36Question(id: 33, dimension: .generalHealth, questionText: "我似乎比其他人更容易生病", options: SF36Option.frequencyOptions, isReverseCoded: false),
        SF36Question(id: 34, dimension: .generalHealth, questionText: "我跟任何人一樣健康", options: SF36Option.frequencyOptions, isReverseCoded: true),
        SF36Question(id: 35, dimension: .generalHealth, questionText: "我預期我的健康會變壞", options: SF36Option.frequencyOptions, isReverseCoded: false),
        SF36Question(id: 36, dimension: .generalHealth, questionText: "我的健康狀況極佳", options: SF36Option.frequencyOptions, isReverseCoded: true),
        
        // 活力 (VT) - 第23, 27, 29, 31題 (4題)
        SF36Question(id: 23, dimension: .vitality, questionText: "您感到充滿活力嗎？", options: SF36Option.frequencyOptions, isReverseCoded: true),
        SF36Question(id: 27, dimension: .vitality, questionText: "您有很多精力嗎？", options: SF36Option.frequencyOptions, isReverseCoded: true),
        SF36Question(id: 29, dimension: .vitality, questionText: "您覺得疲倦嗎？", options: SF36Option.frequencyOptions, isReverseCoded: false),
        SF36Question(id: 31, dimension: .vitality, questionText: "您覺得累壞了嗎？", options: SF36Option.frequencyOptions, isReverseCoded: false),
        
        // 心理健康 (MH) - 第24-26, 28, 30題 (5題)
        SF36Question(id: 24, dimension: .mentalHealth, questionText: "您是一個非常緊張的人嗎？", options: SF36Option.frequencyOptions, isReverseCoded: false),
        SF36Question(id: 25, dimension: .mentalHealth, questionText: "您感到心情低落，什麼事都不能讓您高興起來嗎？", options: SF36Option.frequencyOptions, isReverseCoded: false),
        SF36Question(id: 26, dimension: .mentalHealth, questionText: "您感到平靜和安寧嗎？", options: SF36Option.frequencyOptions, isReverseCoded: true),
        SF36Question(id: 28, dimension: .mentalHealth, questionText: "您感到沮喪和憂鬱嗎？", options: SF36Option.frequencyOptions, isReverseCoded: false),
        SF36Question(id: 30, dimension: .mentalHealth, questionText: "您是一個快樂的人嗎？", options: SF36Option.frequencyOptions, isReverseCoded: true)
    ].sorted { $0.id < $1.id } // 按題號排序
}

// MARK: - SF-36 Questions Database (參考WOMAC和KOOS架構)
/// SF-36問題資料庫，提供問題查詢和分組功能
struct SF36Questions {
    
    /// 維度描述文字
    static let dimensionDescriptions: [SF36Dimension: String] = [
        .physicalFunctioning: "以下問題是有關您的身體活動。您的健康狀況限制您從事這些活動嗎？如果有，限制程度如何？",
        .rolePhysical: "在過去的四個星期中，您是否因為身體健康問題而在工作或其他日常活動方面遇到下列任何問題？",
        .roleEmotional: "在過去的四個星期中，您是否因為情緒問題（如感覺憂鬱或焦慮）而在工作或其他日常活動方面遇到下列任何問題？",
        .socialFunctioning: "以下問題是關於您的社交活動",
        .bodilyPain: "以下問題是關於您的身體疼痛",
        .generalHealth: "以下問題是關於您對自己健康的看法",
        .vitality: "以下問題是關於您的感受和精力狀況",
        .mentalHealth: "以下問題是關於您的心理健康狀況"
    ]
    
    /// 獲取指定維度的問題列表
    static func getQuestions(for dimension: SF36Dimension) -> [SF36Question] {
        return SF36Questionnaire.questions.filter { $0.dimension == dimension }
    }
    
    /// 獲取指定維度的描述文字
    static func getDescription(for dimension: SF36Dimension) -> String? {
        return dimensionDescriptions[dimension]
    }
    
    /// 獲取所有問題（按維度分組）
    static var questionsByDimension: [SF36Dimension: [SF36Question]] {
        var grouped: [SF36Dimension: [SF36Question]] = [:]
        for dimension in SF36Dimension.allCases {
            grouped[dimension] = getQuestions(for: dimension)
        }
        return grouped
    }
    
    /// 獲取問題總數
    static var totalQuestionCount: Int {
        return SF36Questionnaire.questions.count
    }
}
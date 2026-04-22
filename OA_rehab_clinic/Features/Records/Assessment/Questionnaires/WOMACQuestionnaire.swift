import Foundation

/**
 * WOMACQuestionnaire.swift - WOMAC量表問卷數據結構
 * 
 * WOMAC (Western Ontario and McMaster Universities Osteoarthritis Index)
 * 用於評估膝或髖關節炎的標準化量表，包含24個問題，分為三個子類別：
 * - 醫師確認題：1個問題（第0題）
 * - 關節疼痛程度：5個問題（第1-5題）
 * - 關節僵硬程度：2個問題（第6-7題）
 * - 身體功能：17個問題（第8-24題）
 * 
 * 評分：每題0-4分，總分96分，分數越高表示症狀越嚴重
 * 注意：第0題為醫師確認題，不計入總分
 */

// MARK: - WOMAC Question Categories
enum WOMACCategory: String, CaseIterable, Codable {
    case doctorConfirmation = "關節疼痛頻率"
    case pain = "關節疼痛程度"
    case stiffness = "關節僵硬程度" 
    case physicalFunction = "身體功能"
    
    var maxScore: Int {
        switch self {
        case .doctorConfirmation: return 4 // 1題 x 4分，但不計入總分
        case .pain: return 20 // 5題 x 4分
        case .stiffness: return 8 // 2題 x 4分
        case .physicalFunction: return 68 // 17題 x 4分
        }
    }
    
    var isCountedInTotal: Bool {
        switch self {
        case .doctorConfirmation: return false
        default: return true
        }
    }
}

// MARK: - WOMAC Section Header
struct WOMACSection: Identifiable, Codable {
    let id: String
    let category: WOMACCategory
    let title: String
    let description: String?
}

// MARK: - WOMAC Question Model
struct WOMACQuestion: Identifiable, Codable {
    let id: Int
    let category: WOMACCategory
    let question: String
    let options: [WOMACOption]
    let isCountedInScore: Bool // 用於標記是否計入總分
    
    static let allQuestions = WOMACQuestions.questions
    static let allSections = WOMACQuestions.sections
}

// MARK: - WOMAC Answer Options
struct WOMACOption: Identifiable, Codable {
    let id: Int
    let text: String
    let score: Int
    
    static let standardOptions = [
        WOMACOption(id: 0, text: "無", score: 0),
        WOMACOption(id: 1, text: "輕微", score: 1),
        WOMACOption(id: 2, text: "中等", score: 2),
        WOMACOption(id: 3, text: "嚴重", score: 3),
        WOMACOption(id: 4, text: "極嚴重", score: 4)
    ]
}

// MARK: - WOMAC Response Model
struct WOMACResponse: Codable {
    let questionId: Int
    let selectedScore: Int
    let category: WOMACCategory
}

// MARK: - WOMAC Assessment Result
struct WOMACAssessmentResult: Codable {
    let responses: [WOMACResponse]
    let categoryScores: [WOMACCategory: Int]
    let totalScore: Int
    let maxTotalScore: Int = 96 // 不包含醫師確認題
    let completedAt: Date
    
    init(responses: [WOMACResponse], completedAt: Date = Date()) {
        self.responses = responses
        self.completedAt = completedAt
        
        // 計算各類別分數
        var categoryScores: [WOMACCategory: Int] = [:]
        for category in WOMACCategory.allCases {
            let categoryResponses = responses.filter { $0.category == category }
            categoryScores[category] = categoryResponses.reduce(0) { $0 + $1.selectedScore }
        }
        self.categoryScores = categoryScores
        
        // 計算總分 - 只計算計入總分的類別
        self.totalScore = responses
            .filter { $0.category.isCountedInTotal }
            .reduce(0) { $0 + $1.selectedScore }
    }
}

// MARK: - WOMAC Questions Database (重新組織的結構)
struct WOMACQuestions {
    
    // 問卷區段標題
    static let sections: [WOMACSection] = [
        WOMACSection(
            id: "pain_intro",
            category: .pain,
            title: "在過去一個禮拜，當您從事下列活動時，有哪些項目會使您的關節感到疼痛？",
            description: "請根據您的實際感受，為每個活動的疼痛程度評分"
        )
    ]
    
    static let questions: [WOMACQuestion] = [
        // 第0題：醫師確認題（不計入總分）
        WOMACQuestion(
            id: 0,
            category: .doctorConfirmation,
            question: "您的關節感到疼痛的頻率是多久？",
            options: WOMACOption.standardOptions,
            isCountedInScore: false
        ),
        
        // 關節疼痛程度 (第1-5題)
        WOMACQuestion(
            id: 1,
            category: .pain,
            question: "走在平坦的路上，您的關節有多痛？",
            options: WOMACOption.standardOptions,
            isCountedInScore: true
        ),
        WOMACQuestion(
            id: 2,
            category: .pain,
            question: "上下樓梯時，您的關節有多痛？",
            options: WOMACOption.standardOptions,
            isCountedInScore: true
        ),
        WOMACQuestion(
            id: 3,
            category: .pain,
            question: "晚上睡覺時，您的關節有多痛？",
            options: WOMACOption.standardOptions,
            isCountedInScore: true
        ),
        WOMACQuestion(
            id: 4,
            category: .pain,
            question: "坐或躺，您的關節有多痛？",
            options: WOMACOption.standardOptions,
            isCountedInScore: true
        ),
        WOMACQuestion(
            id: 5,
            category: .pain,
            question: "筆直站立時，您的關節有多痛？",
            options: WOMACOption.standardOptions,
            isCountedInScore: true
        ),
        
        // 關節僵硬程度 (第6-7題)
        WOMACQuestion(
            id: 6,
            category: .stiffness,
            question: "早晨剛起床時，您的關節有多僵硬？",
            options: WOMACOption.standardOptions,
            isCountedInScore: true
        ),
        WOMACQuestion(
            id: 7,
            category: .stiffness,
            question: "約莫傍晚時分，若您坐一下、躺一下或休息一下之後，您的關節有多僵硬？",
            options: WOMACOption.standardOptions,
            isCountedInScore: true
        ),
        
        // 身體功能 (第8-24題，共17題)
        WOMACQuestion(
            id: 8,
            category: .physicalFunction,
            question: "下樓時，您感到有多困難？",
            options: WOMACOption.standardOptions,
            isCountedInScore: true
        ),
        WOMACQuestion(
            id: 9,
            category: .physicalFunction,
            question: "上樓時，您感到有多困難？",
            options: WOMACOption.standardOptions,
            isCountedInScore: true
        ),
        WOMACQuestion(
            id: 10,
            category: .physicalFunction,
            question: "從椅子上站起來時，您感到有多困難？",
            options: WOMACOption.standardOptions,
            isCountedInScore: true
        ),
        WOMACQuestion(
            id: 11,
            category: .physicalFunction,
            question: "站的時候，您感到有多困難？",
            options: WOMACOption.standardOptions,
            isCountedInScore: true
        ),
        WOMACQuestion(
            id: 12,
            category: .physicalFunction,
            question: "彎腰時，您感到有多困難？",
            options: WOMACOption.standardOptions,
            isCountedInScore: true
        ),
        WOMACQuestion(
            id: 13,
            category: .physicalFunction,
            question: "走在平坦的路上，您感到有多困難？",
            options: WOMACOption.standardOptions,
            isCountedInScore: true
        ),
        WOMACQuestion(
            id: 14,
            category: .physicalFunction,
            question: "上車及下車時，您感到有多困難？",
            options: WOMACOption.standardOptions,
            isCountedInScore: true
        ),
        WOMACQuestion(
            id: 15,
            category: .physicalFunction,
            question: "逛街買東西時，您感到有多困難？",
            options: WOMACOption.standardOptions,
            isCountedInScore: true
        ),
        WOMACQuestion(
            id: 16,
            category: .physicalFunction,
            question: "穿上襪子時，您感到有多困難？",
            options: WOMACOption.standardOptions,
            isCountedInScore: true
        ),
        WOMACQuestion(
            id: 17,
            category: .physicalFunction,
            question: "從床上起身時，您感到有多困難？",
            options: WOMACOption.standardOptions,
            isCountedInScore: true
        ),
        WOMACQuestion(
            id: 18,
            category: .physicalFunction,
            question: "脫掉襪子時，您感到有多困難？",
            options: WOMACOption.standardOptions,
            isCountedInScore: true
        ),
        WOMACQuestion(
            id: 19,
            category: .physicalFunction,
            question: "躺在床上時，您感到有多困難？",
            options: WOMACOption.standardOptions,
            isCountedInScore: true
        ),
        WOMACQuestion(
            id: 20,
            category: .physicalFunction,
            question: "進出浴室洗澡時，您感到有多困難？",
            options: WOMACOption.standardOptions,
            isCountedInScore: true
        ),
        WOMACQuestion(
            id: 21,
            category: .physicalFunction,
            question: "坐的時候，您感到有多困難？",
            options: WOMACOption.standardOptions,
            isCountedInScore: true
        ),
        WOMACQuestion(
            id: 22,
            category: .physicalFunction,
            question: "上廁所時，您感到有多困難？",
            options: WOMACOption.standardOptions,
            isCountedInScore: true
        ),
        WOMACQuestion(
            id: 23,
            category: .physicalFunction,
            question: "做粗重家事時，您感到有多困難？",
            options: WOMACOption.standardOptions,
            isCountedInScore: true
        ),
        WOMACQuestion(
            id: 24,
            category: .physicalFunction,
            question: "做簡單家事時，您感到有多困難？",
            options: WOMACOption.standardOptions,
            isCountedInScore: true
        )
    ]
    
    // 輔助方法：依類別獲取問題
    static func getQuestions(for category: WOMACCategory) -> [WOMACQuestion] {
        return questions.filter { $0.category == category }
    }
    
    // 輔助方法：獲取計分問題總數（不包含醫師確認題）
    static var scoredQuestionCount: Int {
        return questions.filter { $0.isCountedInScore }.count
    }
    
    // 輔助方法：獲取問題總數（包含所有題目）
    static var totalQuestionCount: Int {
        return questions.count
    }
    
    // 輔助方法：獲取指定類別的區段標題
    static func getSection(for category: WOMACCategory) -> WOMACSection? {
        return sections.first { $0.category == category }
    }
}
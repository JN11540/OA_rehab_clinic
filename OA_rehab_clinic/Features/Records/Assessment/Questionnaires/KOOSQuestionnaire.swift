import Foundation

/**
 * KOOSQuestionnaire.swift - KOOS量表問卷數據結構
 * 
 * KOOS (Knee injury and Osteoarthritis Outcome Score)
 * 用於評估膝關節損傷和骨關節炎的標準化量表，包含42個問題，分為五個子類別：
 * - 疼痛：9個問題（P1-P9）
 * - 症狀：7個問題（S1-S7）
 * - 日常生活活動：17個問題（A1-A17）
 * - 運動與休閒功能：5個問題（SP1-SP5）
 * - 生活品質：4個問題（Q1-Q4）
 * 
 * 評分：每題0-4分，按類別計算平均分數後轉換成百分制
 * 公式：100 - (平均分數×100/4) = KOOS分數
 * 分數越高表示功能越好（與WOMAC相反）
 */

// MARK: - KOOS Question Categories
enum KOOSCategory: String, CaseIterable, Codable {
    case pain = "疼痛"
    case symptoms = "症狀"
    case adl = "日常生活活動"
    case sportRec = "運動與休閒功能"
    case qol = "生活品質"
    
    var questionCount: Int {
        switch self {
        case .pain: return 9
        case .symptoms: return 7
        case .adl: return 17
        case .sportRec: return 5
        case .qol: return 4
        }
    }
    
    var maxRawScore: Int {
        return questionCount * 4
    }
}

// MARK: - KOOS Section Header
struct KOOSSection: Identifiable, Codable {
    let id: String
    let category: KOOSCategory
    let title: String
    let description: String?
}

// MARK: - KOOS Question Model
struct KOOSQuestion: Identifiable, Codable {
    let id: String
    let questionNumber: Int
    let category: KOOSCategory
    let question: String
    let options: [KOOSOption]
    let isFrequencyQuestion: Bool // 用於區分頻率問題（如P1）
    
    static let allQuestions = KOOSQuestions.questions
    static let allSections = KOOSQuestions.sections
}

// MARK: - KOOS Answer Options
struct KOOSOption: Identifiable, Codable {
    let id: Int
    let text: String
    let score: Int
    
    static let frequencyOptions = [
        KOOSOption(id: 0, text: "從不", score: 0),
        KOOSOption(id: 1, text: "每月", score: 1),
        KOOSOption(id: 2, text: "每週", score: 2),
        KOOSOption(id: 3, text: "每天", score: 3),
        KOOSOption(id: 4, text: "總是", score: 4)
    ]
    
    static let painOptions = [
        KOOSOption(id: 0, text: "無", score: 0),
        KOOSOption(id: 1, text: "輕微", score: 1),
        KOOSOption(id: 2, text: "中等", score: 2),
        KOOSOption(id: 3, text: "嚴重", score: 3),
        KOOSOption(id: 4, text: "極嚴重", score: 4)
    ]
    
    static let difficultyOptions = [
        KOOSOption(id: 0, text: "無", score: 0),
        KOOSOption(id: 1, text: "輕微", score: 1),
        KOOSOption(id: 2, text: "中等", score: 2),
        KOOSOption(id: 3, text: "嚴重", score: 3),
        KOOSOption(id: 4, text: "極嚴重", score: 4)
    ]
    
    static let severityOptions = [
        KOOSOption(id: 0, text: "無", score: 0),
        KOOSOption(id: 1, text: "輕微", score: 1),
        KOOSOption(id: 2, text: "中等", score: 2),
        KOOSOption(id: 3, text: "嚴重", score: 3),
        KOOSOption(id: 4, text: "極嚴重", score: 4)
    ]
    
    static let amountOptions = [
        KOOSOption(id: 0, text: "完全沒有", score: 0),
        KOOSOption(id: 1, text: "一點點", score: 1),
        KOOSOption(id: 2, text: "中等程度", score: 2),
        KOOSOption(id: 3, text: "很多", score: 3),
        KOOSOption(id: 4, text: "極度", score: 4)
    ]
}

// MARK: - KOOS Response Model
struct KOOSResponse: Codable {
    let questionId: String
    let selectedScore: Int
    let category: KOOSCategory
}

// MARK: - KOOS Assessment Result
struct KOOSAssessmentResult: Codable {
    let responses: [KOOSResponse]
    let categoryScores: [KOOSCategory: Double]
    let totalScore: Double
    let completedAt: Date
    
    init(responses: [KOOSResponse], completedAt: Date = Date()) {
        self.responses = responses
        self.completedAt = completedAt
        
        // 計算各類別KOOS分數
        var categoryScores: [KOOSCategory: Double] = [:]
        for category in KOOSCategory.allCases {
            let categoryResponses = responses.filter { $0.category == category }
            let totalRawScore = categoryResponses.reduce(0) { $0 + $1.selectedScore }
            let meanScore = Double(totalRawScore) / Double(category.questionCount)
            let koosScore = 100.0 - (meanScore * 100.0 / 4.0)
            categoryScores[category] = koosScore
        }
        self.categoryScores = categoryScores
        
        // 計算總平均KOOS分數
        let allScores = categoryScores.values
        self.totalScore = allScores.reduce(0, +) / Double(allScores.count)
    }
}

// MARK: - KOOS Questions Database
struct KOOSQuestions {
    
    // 問卷區段標題
    static let sections: [KOOSSection] = [
        KOOSSection(
            id: "pain_intro",
            category: .pain,
            title: "疼痛",
            description: "您上週在做以下活動時，膝關節經歷了多大程度的疼痛？"
        ),
        KOOSSection(
            id: "symptoms_intro",
            category: .symptoms,
            title: "症狀",
            description: "請根據您上週膝關節的症狀回答以下問題"
        ),
        KOOSSection(
            id: "adl_intro",
            category: .adl,
            title: "日常生活活動",
            description: "以下問題與您身體功能有關。具體是指您四處走動和照顧自己的能力。對於下每項活動，請說明您上週因膝關節而經歷的困難程度"
        ),
        KOOSSection(
            id: "sport_intro",
            category: .sportRec,
            title: "運動與休閒功能",
            description: "以下問題與您在做激烈程度更高的活度時的身體功能有關。請回答您上週在做以下活動時膝關節經歷的困難程度"
        ),
        KOOSSection(
            id: "qol_intro",
            category: .qol,
            title: "生活品質",
            description: "過去一週，您對膝關節問題的感受程度"
        )
    ]
    
    static let questions: [KOOSQuestion] = [
        
        // 疼痛 (P1-P9)
        KOOSQuestion(
            id: "P1",
            questionNumber: 1,
            category: .pain,
            question: "您的膝關節多久會痛一次？",
            options: KOOSOption.frequencyOptions,
            isFrequencyQuestion: true
        ),
        KOOSQuestion(
            id: "P2",
            questionNumber: 2,
            category: .pain,
            question: "扭轉/轉動膝關節",
            options: KOOSOption.painOptions,
            isFrequencyQuestion: false
        ),
        KOOSQuestion(
            id: "P3",
            questionNumber: 3,
            category: .pain,
            question: "完全伸直膝蓋",
            options: KOOSOption.painOptions,
            isFrequencyQuestion: false
        ),
        KOOSQuestion(
            id: "P4",
            questionNumber: 4,
            category: .pain,
            question: "完全彎曲膝蓋",
            options: KOOSOption.painOptions,
            isFrequencyQuestion: false
        ),
        KOOSQuestion(
            id: "P5",
            questionNumber: 5,
            category: .pain,
            question: "在平坦的路面上行走",
            options: KOOSOption.painOptions,
            isFrequencyQuestion: false
        ),
        KOOSQuestion(
            id: "P6",
            questionNumber: 6,
            category: .pain,
            question: "上下樓梯",
            options: KOOSOption.painOptions,
            isFrequencyQuestion: false
        ),
        KOOSQuestion(
            id: "P7",
            questionNumber: 7,
            category: .pain,
            question: "晚上在床上睡覺時",
            options: KOOSOption.painOptions,
            isFrequencyQuestion: false
        ),
        KOOSQuestion(
            id: "P8",
            questionNumber: 8,
            category: .pain,
            question: "坐著或躺著",
            options: KOOSOption.painOptions,
            isFrequencyQuestion: false
        ),
        KOOSQuestion(
            id: "P9",
            questionNumber: 9,
            category: .pain,
            question: "站直",
            options: KOOSOption.painOptions,
            isFrequencyQuestion: false
        ),
        
        // 症狀 (S1-S7)
        KOOSQuestion(
            id: "S1",
            questionNumber: 1,
            category: .symptoms,
            question: "您的膝關節有腫脹嗎？",
            options: KOOSOption.frequencyOptions,
            isFrequencyQuestion: true
        ),
        KOOSQuestion(
            id: "S2",
            questionNumber: 2,
            category: .symptoms,
            question: "當您移動膝關節時，您是否會感覺到研磨感/摩擦感，聽到「咯咯聲」/「破裂聲」或其他任何類型的聲響？",
            options: KOOSOption.frequencyOptions,
            isFrequencyQuestion: true
        ),
        KOOSQuestion(
            id: "S3",
            questionNumber: 3,
            category: .symptoms,
            question: "當您移動膝關節時，膝關節是否有被卡住或者鎖住的感覺？",
            options: KOOSOption.frequencyOptions,
            isFrequencyQuestion: true
        ),
        KOOSQuestion(
            id: "S4",
            questionNumber: 4,
            category: .symptoms,
            question: "您能完全伸直您的膝關節嗎？",
            options: KOOSOption.difficultyOptions,
            isFrequencyQuestion: false
        ),
        KOOSQuestion(
            id: "S5",
            questionNumber: 5,
            category: .symptoms,
            question: "您能完全彎曲您的膝關節嗎？",
            options: KOOSOption.difficultyOptions,
            isFrequencyQuestion: false
        ),
        KOOSQuestion(
            id: "S6",
            questionNumber: 6,
            category: .symptoms,
            question: "早上第一次醒來後，您的膝關節僵硬有多嚴重？",
            options: KOOSOption.severityOptions,
            isFrequencyQuestion: false
        ),
        KOOSQuestion(
            id: "S7",
            questionNumber: 7,
            category: .symptoms,
            question: "在當天晚些的時候，您坐著、躺著或休息後，您的膝關節僵硬有多嚴重？",
            options: KOOSOption.severityOptions,
            isFrequencyQuestion: false
        ),
        
        // 日常生活活動 (A1-A17)
        KOOSQuestion(
            id: "A1",
            questionNumber: 1,
            category: .adl,
            question: "下樓梯",
            options: KOOSOption.difficultyOptions,
            isFrequencyQuestion: false
        ),
        KOOSQuestion(
            id: "A2",
            questionNumber: 2,
            category: .adl,
            question: "上樓梯",
            options: KOOSOption.difficultyOptions,
            isFrequencyQuestion: false
        ),
        KOOSQuestion(
            id: "A3",
            questionNumber: 3,
            category: .adl,
            question: "從坐著到站起來",
            options: KOOSOption.difficultyOptions,
            isFrequencyQuestion: false
        ),
        KOOSQuestion(
            id: "A4",
            questionNumber: 4,
            category: .adl,
            question: "站立",
            options: KOOSOption.difficultyOptions,
            isFrequencyQuestion: false
        ),
        KOOSQuestion(
            id: "A5",
            questionNumber: 5,
            category: .adl,
            question: "彎腰至地面/撿起一個物體",
            options: KOOSOption.difficultyOptions,
            isFrequencyQuestion: false
        ),
        KOOSQuestion(
            id: "A6",
            questionNumber: 6,
            category: .adl,
            question: "在平坦的路面上行走",
            options: KOOSOption.difficultyOptions,
            isFrequencyQuestion: false
        ),
        KOOSQuestion(
            id: "A7",
            questionNumber: 7,
            category: .adl,
            question: "上/下車",
            options: KOOSOption.difficultyOptions,
            isFrequencyQuestion: false
        ),
        KOOSQuestion(
            id: "A8",
            questionNumber: 8,
            category: .adl,
            question: "去購物",
            options: KOOSOption.difficultyOptions,
            isFrequencyQuestion: false
        ),
        KOOSQuestion(
            id: "A9",
            questionNumber: 9,
            category: .adl,
            question: "穿短襪/長襪",
            options: KOOSOption.difficultyOptions,
            isFrequencyQuestion: false
        ),
        KOOSQuestion(
            id: "A10",
            questionNumber: 10,
            category: .adl,
            question: "從躺下到站立",
            options: KOOSOption.difficultyOptions,
            isFrequencyQuestion: false
        ),
        KOOSQuestion(
            id: "A11",
            questionNumber: 11,
            category: .adl,
            question: "脫短襪/長襪",
            options: KOOSOption.difficultyOptions,
            isFrequencyQuestion: false
        ),
        KOOSQuestion(
            id: "A12",
            questionNumber: 12,
            category: .adl,
            question: "躺在床上（翻身、保持膝關節姿勢）",
            options: KOOSOption.difficultyOptions,
            isFrequencyQuestion: false
        ),
        KOOSQuestion(
            id: "A13",
            questionNumber: 13,
            category: .adl,
            question: "進/出浴缸",
            options: KOOSOption.difficultyOptions,
            isFrequencyQuestion: false
        ),
        KOOSQuestion(
            id: "A14",
            questionNumber: 14,
            category: .adl,
            question: "坐",
            options: KOOSOption.difficultyOptions,
            isFrequencyQuestion: false
        ),
        KOOSQuestion(
            id: "A15",
            questionNumber: 15,
            category: .adl,
            question: "如廁",
            options: KOOSOption.difficultyOptions,
            isFrequencyQuestion: false
        ),
        KOOSQuestion(
            id: "A16",
            questionNumber: 16,
            category: .adl,
            question: "坐繁重家務（搬動沉重的箱子、擦洗地板等）",
            options: KOOSOption.difficultyOptions,
            isFrequencyQuestion: false
        ),
        KOOSQuestion(
            id: "A17",
            questionNumber: 17,
            category: .adl,
            question: "坐輕鬆家務（做飯、除塵等）",
            options: KOOSOption.difficultyOptions,
            isFrequencyQuestion: false
        ),
        
        // 運動與休閒功能 (SP1-SP5)
        KOOSQuestion(
            id: "SP1",
            questionNumber: 1,
            category: .sportRec,
            question: "蹲下",
            options: KOOSOption.difficultyOptions,
            isFrequencyQuestion: false
        ),
        KOOSQuestion(
            id: "SP2",
            questionNumber: 2,
            category: .sportRec,
            question: "跑步",
            options: KOOSOption.difficultyOptions,
            isFrequencyQuestion: false
        ),
        KOOSQuestion(
            id: "SP3",
            questionNumber: 3,
            category: .sportRec,
            question: "跳躍",
            options: KOOSOption.difficultyOptions,
            isFrequencyQuestion: false
        ),
        KOOSQuestion(
            id: "SP4",
            questionNumber: 4,
            category: .sportRec,
            question: "扭動/轉動受傷的膝關節",
            options: KOOSOption.difficultyOptions,
            isFrequencyQuestion: false
        ),
        KOOSQuestion(
            id: "SP5",
            questionNumber: 5,
            category: .sportRec,
            question: "跪下",
            options: KOOSOption.difficultyOptions,
            isFrequencyQuestion: false
        ),
        
        // 生活品質 (Q1-Q4)
        KOOSQuestion(
            id: "Q1",
            questionNumber: 1,
            category: .qol,
            question: "您多久會意識到您的膝關節有問題？",
            options: KOOSOption.frequencyOptions,
            isFrequencyQuestion: true
        ),
        KOOSQuestion(
            id: "Q2",
            questionNumber: 2,
            category: .qol,
            question: "您有沒有改變自己的生活方式來避免可能對膝關節造成傷害的活動？",
            options: KOOSOption.amountOptions,
            isFrequencyQuestion: false
        ),
        KOOSQuestion(
            id: "Q3",
            questionNumber: 3,
            category: .qol,
            question: "您的膝關節問題會對您的自信心造成多少困擾？",
            options: KOOSOption.amountOptions,
            isFrequencyQuestion: false
        ),
        KOOSQuestion(
            id: "Q4",
            questionNumber: 4,
            category: .qol,
            question: "總體來說，您的膝關節給您帶來了多大的困難？",
            options: KOOSOption.amountOptions,
            isFrequencyQuestion: false
        )
    ]
    
    // 輔助方法：依類別獲取問題
    static func getQuestions(for category: KOOSCategory) -> [KOOSQuestion] {
        return questions.filter { $0.category == category }
    }
    
    // 輔助方法：獲取問題總數
    static var totalQuestionCount: Int {
        return questions.count
    }
    
    // 輔助方法：獲取指定類別的區段標題
    static func getSection(for category: KOOSCategory) -> KOOSSection? {
        return sections.first { $0.category == category }
    }
}
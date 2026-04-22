import Foundation
import SwiftUI

/**
 * MockAssessmentData.swift - 評量結果模擬數據生成器
 * 
 * 功能：
 * - 為 6 種評估類型生成符合邏輯的時間序列數據
 * - 模擬復健進步趨勢（WOMAC/SF-36 下降，KOOS/功能性評估 上升）
 * - 支援不同時間範圍的數據生成
 * - 為 ResultChangeView 提供預覽數據
 */

struct MockAssessmentData {
    
    // MARK: - 主要生成方法
    
    /**
     * 為指定患者和評估類型生成模擬評量記錄
     * - 生成過去 12 個月內 6-12 次隨機分佈的評估記錄
     * - 體現復健效果的漸進改善趨勢
     * - 確保任何時間範圍都有足夠的數據點
     */
    static func generateMockRecords(for patientId: String, type: AssessmentType) -> [AssessmentRecord] {
        let recordCount = Int.random(in: 6...12) // 增加數據點數量
        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .month, value: -12, to: endDate) ?? endDate
        
        var records: [AssessmentRecord] = []
        
        // 生成隨機日期並排序
        let randomDates = generateRandomDates(from: startDate, to: endDate, count: recordCount)
        
        for (index, date) in randomDates.enumerated() {
            let progressRatio = Double(index) / Double(recordCount - 1) // 0.0 到 1.0 的進步比例
            let record = generateRecord(for: patientId, type: type, date: date, progressRatio: progressRatio)
            records.append(record)
        }
        
        return records.sorted { $0.date < $1.date }
    }
    
    // MARK: - 日期生成
    
    private static func generateRandomDates(from startDate: Date, to endDate: Date, count: Int) -> [Date] {
        let timeInterval = endDate.timeIntervalSince(startDate)
        var dates: [Date] = []
        
        for _ in 0..<count {
            let randomInterval = Double.random(in: 0...timeInterval)
            let randomDate = startDate.addingTimeInterval(randomInterval)
            dates.append(randomDate)
        }
        
        return dates.sorted()
    }
    
    // MARK: - 記錄生成
    
    private static func generateRecord(for patientId: String, type: AssessmentType, date: Date, progressRatio: Double) -> AssessmentRecord {
        switch type {
        case .womac:
            return generateWOMACRecord(patientId: patientId, date: date, progressRatio: progressRatio)
        case .koos:
            return generateKOOSRecord(patientId: patientId, date: date, progressRatio: progressRatio)
        case .sf36:
            return generateSF36Record(patientId: patientId, date: date, progressRatio: progressRatio)
        case .chairTest:
            return generateChairTestRecord(patientId: patientId, date: date, progressRatio: progressRatio)
        case .kneeRaise:
            return generateKneeRaiseRecord(patientId: patientId, date: date, progressRatio: progressRatio)
        case .singleLegStand:
            return generateSingleLegStandRecord(patientId: patientId, date: date, progressRatio: progressRatio)
        }
    }
    
    // MARK: - WOMAC 數據生成
    
    private static func generateWOMACRecord(patientId: String, date: Date, progressRatio: Double) -> AssessmentRecord {
        // WOMAC: 分數越高越糟糕，復健後分數應該下降
        // 初始總分範圍: 60-90, 最終總分範圍: 30-50
        let initialTotal = Double.random(in: 60...90)
        let finalTotal = Double.random(in: 30...50)
        let currentTotal = initialTotal - (initialTotal - finalTotal) * progressRatio
        
        // 各分項分數 (保持合理比例)
        let painRatio = 0.25 + Double.random(in: -0.05...0.05) // 疼痛約佔25%
        let stiffnessRatio = 0.15 + Double.random(in: -0.03...0.03) // 僵硬約佔15%
        let functionRatio = 0.60 + Double.random(in: -0.05...0.05) // 功能約佔60%
        
        let painScore = currentTotal * painRatio
        let stiffnessScore = currentTotal * stiffnessRatio
        let functionScore = currentTotal * functionRatio
        
        return AssessmentRecord(
            patientId: patientId,
            assessmentId: "womac-\(UUID().uuidString.prefix(8))",
            date: date,
            scores: [
                "關節疼痛程度": painScore,
                "關節僵硬程度": stiffnessScore,
                "身體功能": functionScore
            ],
            totalScore: currentTotal,
            notes: generateWOMACNotes(progressRatio: progressRatio)
        )
    }
    
    // MARK: - KOOS 數據生成
    
    private static func generateKOOSRecord(patientId: String, date: Date, progressRatio: Double) -> AssessmentRecord {
        // KOOS: 分數越高越好，復健後分數應該上升
        // 初始總分範圍: 40-60, 最終總分範圍: 70-85
        let initialTotal = Double.random(in: 40...60)
        let finalTotal = Double.random(in: 70...85)
        let currentTotal = initialTotal + (finalTotal - initialTotal) * progressRatio
        
        // 各分項分數 (按 KOOS 標準)
        let painScore = generateKOOSDimensionScore(baseLine: currentTotal, variation: 5)
        let symptomsScore = generateKOOSDimensionScore(baseLine: currentTotal, variation: 8)
        let adlScore = generateKOOSDimensionScore(baseLine: currentTotal, variation: 6)
        let sportScore = generateKOOSDimensionScore(baseLine: currentTotal, variation: 10)
        let qolScore = generateKOOSDimensionScore(baseLine: currentTotal, variation: 12)
        
        return AssessmentRecord(
            patientId: patientId,
            assessmentId: "koos-\(UUID().uuidString.prefix(8))",
            date: date,
            scores: [
                "疼痛": painScore,
                "症狀": symptomsScore,
                "日常生活活動": adlScore,
                "運動與休閒功能": sportScore,
                "生活品質": qolScore
            ],
            totalScore: currentTotal,
            notes: generateKOOSNotes(progressRatio: progressRatio)
        )
    }
    
    private static func generateKOOSDimensionScore(baseLine: Double, variation: Double) -> Double {
        let score = baseLine + Double.random(in: -variation...variation)
        return max(0, min(100, score)) // 限制在 0-100 範圍內
    }
    
    // MARK: - SF-36 數據生成
    
    private static func generateSF36Record(patientId: String, date: Date, progressRatio: Double) -> AssessmentRecord {
        // SF-36: 類似 KOOS，分數越高越好
        // 初始總分範圍: 45-65, 最終總分範圍: 70-90
        let initialTotal = Double.random(in: 45...65)
        let finalTotal = Double.random(in: 70...90)
        let currentTotal = initialTotal + (finalTotal - initialTotal) * progressRatio
        
        // 8個維度分數
        let pfScore = generateSF36DimensionScore(baseLine: currentTotal, variation: 8)  // 身體功能
        let rpScore = generateSF36DimensionScore(baseLine: currentTotal, variation: 12) // 身體角色功能
        let bpScore = generateSF36DimensionScore(baseLine: currentTotal, variation: 10) // 身體疼痛
        let ghScore = generateSF36DimensionScore(baseLine: currentTotal, variation: 6)  // 一般健康
        let vtScore = generateSF36DimensionScore(baseLine: currentTotal, variation: 8)  // 活力
        let sfScore = generateSF36DimensionScore(baseLine: currentTotal, variation: 7)  // 社會功能
        let reScore = generateSF36DimensionScore(baseLine: currentTotal, variation: 15) // 情緒角色功能
        let mhScore = generateSF36DimensionScore(baseLine: currentTotal, variation: 9)  // 心理健康
        
        return AssessmentRecord(
            patientId: patientId,
            assessmentId: "sf36-\(UUID().uuidString.prefix(8))",
            date: date,
            scores: [
                "身體功能": pfScore,
                "身體角色功能": rpScore,
                "身體疼痛": bpScore,
                "一般健康": ghScore,
                "活力": vtScore,
                "社會功能": sfScore,
                "情緒角色功能": reScore,
                "心理健康": mhScore
            ],
            totalScore: currentTotal,
            notes: generateSF36Notes(progressRatio: progressRatio)
        )
    }
    
    private static func generateSF36DimensionScore(baseLine: Double, variation: Double) -> Double {
        let score = baseLine + Double.random(in: -variation...variation)
        return max(0, min(100, score)) // 限制在 0-100 範圍內
    }
    
    // MARK: - 功能性評估數據生成
    
    private static func generateChairTestRecord(patientId: String, date: Date, progressRatio: Double) -> AssessmentRecord {
        // 椅子坐站測試: 30秒內完成次數，越多越好
        // 初始範圍: 6-10次, 最終範圍: 12-18次
        let initialCount = Double.random(in: 6...10)
        let finalCount = Double.random(in: 12...18)
        let currentCount = initialCount + (finalCount - initialCount) * progressRatio
        
        return AssessmentRecord(
            patientId: patientId,
            assessmentId: "chair-test-\(UUID().uuidString.prefix(8))",
            date: date,
            scores: ["次數": currentCount],
            totalScore: currentCount,
            notes: generateFunctionalNotes(type: "椅子坐站測試", score: currentCount, progressRatio: progressRatio)
        )
    }
    
    private static func generateKneeRaiseRecord(patientId: String, date: Date, progressRatio: Double) -> AssessmentRecord {
        // 原地站立抬膝: 30秒內完成次數，越多越好
        // 初始範圍: 15-25次, 最終範圍: 30-45次
        let initialCount = Double.random(in: 15...25)
        let finalCount = Double.random(in: 30...45)
        let currentCount = initialCount + (finalCount - initialCount) * progressRatio
        
        return AssessmentRecord(
            patientId: patientId,
            assessmentId: "knee-raise-\(UUID().uuidString.prefix(8))",
            date: date,
            scores: ["次數": currentCount],
            totalScore: currentCount,
            notes: generateFunctionalNotes(type: "原地站立抬膝", score: currentCount, progressRatio: progressRatio)
        )
    }
    
    private static func generateSingleLegStandRecord(patientId: String, date: Date, progressRatio: Double) -> AssessmentRecord {
        // 開眼單足站立: 持續時間(秒)，越長越好
        // 初始範圍: 5-15秒, 最終範圍: 25-60秒
        let initialTime = Double.random(in: 5...15)
        let finalTime = Double.random(in: 25...60)
        let currentTime = initialTime + (finalTime - initialTime) * progressRatio
        
        return AssessmentRecord(
            patientId: patientId,
            assessmentId: "single-leg-stand-\(UUID().uuidString.prefix(8))",
            date: date,
            scores: ["時間": currentTime],
            totalScore: currentTime,
            notes: generateFunctionalNotes(type: "開眼單足站立", score: currentTime, progressRatio: progressRatio)
        )
    }
    
    // MARK: - 註記生成
    
    private static func generateWOMACNotes(progressRatio: Double) -> String? {
        let notes = [
            "患者膝關節疼痛程度有所改善",
            "下樓梯時疼痛感減輕",
            "關節僵硬狀況持續改善中",
            "日常活動能力提升",
            "晨起關節僵硬感減少"
        ]
        
        if progressRatio > 0.7 {
            return notes.randomElement()
        } else if progressRatio > 0.3 {
            return notes.randomElement()
        }
        return nil
    }
    
    private static func generateKOOSNotes(progressRatio: Double) -> String? {
        let notes = [
            "膝關節功能明顯改善",
            "運動耐受度提升",
            "生活品質持續改善",
            "疼痛控制良好",
            "關節活動度增加"
        ]
        
        if progressRatio > 0.5 {
            return notes.randomElement()
        }
        return nil
    }
    
    private static func generateSF36Notes(progressRatio: Double) -> String? {
        let notes = [
            "整體健康狀況改善",
            "身體活力提升",
            "情緒狀態穩定",
            "社交功能恢復良好",
            "心理健康狀況佳"
        ]
        
        if progressRatio > 0.6 {
            return notes.randomElement()
        }
        return nil
    }
    
    private static func generateFunctionalNotes(type: String, score: Double, progressRatio: Double) -> String? {
        if progressRatio > 0.5 {
            switch type {
            case "椅子坐站測試":
                return "下肢肌力明顯提升，坐站動作更加流暢"
            case "原地站立抬膝":
                return "心肺耐力和下肢協調性都有改善"
            case "開眼單足站立":
                return "平衡能力和本體感覺顯著進步"
            default:
                return nil
            }
        }
        return nil
    }
}

// MARK: - RecordStore 擴展 (模擬數據集成)

extension RecordStore {
    
    /**
     * 獲取模擬評量進度數據
     * 用於 ResultChangeView 的預覽和測試
     */
    func getMockAssessmentProgress(
        patientId: String,
        type: AssessmentType,
        startDate: Date,
        endDate: Date
    ) -> [AssessmentRecord] {
        // 生成完整的模擬數據
        let allMockRecords = MockAssessmentData.generateMockRecords(for: patientId, type: type)
        
        // 過濾指定時間範圍內的記錄
        return allMockRecords.filter { record in
            record.date >= startDate && record.date <= endDate
        }
    }
}
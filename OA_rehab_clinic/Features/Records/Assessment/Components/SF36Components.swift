//
//  SF36Components.swift
//  OA_rehab_clinic
//
//  Created by Claude Code on 2025-06-23.
//

import SwiftUI
import Foundation

/**
 * SF36Components.swift - SF-36評量相關的UI組件集合
 * 
 * 包含以下組件：
 * - SF36AssessmentToggleView: Toggle展開/折疊視圖
 * - SF36DetailedView: 詳細問卷內容顯示  
 * - SF36CategorySection: 分類別問題顯示
 * - SF36DimensionScoreView: 分維度分數進度條
 * 
 * 設計原則：
 * 參考WOMACComponents.swift和KOOSComponents.swift的架構
 * 臨床端App只顯示個案端App的評估結果，不進行評估
 */

// MARK: - Main Toggle View

/**
 * SF36AssessmentToggleView - SF-36評量結果的Toggle展開/折疊視圖
 * 
 * 功能：
 * - 折疊狀態：顯示最近三次評量日期和總分
 * - 展開狀態：顯示選中日期的完整SF-36問卷內容
 * - 支援展開/折疊動畫效果
 */
struct SF36AssessmentToggleView: View {
    let patient: Patient
    let selectedDate: Date
    @Binding var isExpanded: Bool
    @EnvironmentObject private var recordStore: RecordStore
    
    // 外部點擊處理器（可選）
    var onToggle: (() -> Void)? = nil
    
    private var selectedRecord: AssessmentRecord? {
        recordStore.getAssessmentRecords(for: patient.id)
            .first(where: { 
                Calendar.current.isDate($0.date, inSameDayAs: selectedDate) &&
                $0.assessmentId.contains("SF-36")
            })
    }
    
    private var recentRecords: [AssessmentRecord] {
        recordStore.getAssessmentRecords(for: patient.id)
            .filter { $0.assessmentId.contains("SF-36") }
            .sorted { $0.date > $1.date }
            .prefix(3)
            .map { $0 }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Toggle Header
            Button(action: {
                if let onToggle = onToggle {
                    onToggle()
                } else {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                        isExpanded.toggle()
                    }
                }
            }) {
                HStack {
                    Text("SF-36 健康調查量表")
                        .font(.headline)
                        .foregroundColor(.primary)
                    Spacer()
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(AssessmentType.sf36.color)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8, corners: [.topLeft, .topRight])
            }
            .buttonStyle(PlainButtonStyle())
            
            // Content Area
            if isExpanded {
                // 展開狀態：顯示詳細問卷
                expandedContent
            } else {
                // 折疊狀態：顯示最近三次分數
                collapsedContent
            }
        }
        .background(Color.white)
        .cornerRadius(8)
        .shadow(color: .black.opacity(0.1), radius: 2, y: 1)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    private var collapsedContent: some View {
        VStack(alignment: .leading, spacing: 6) {
            if recentRecords.isEmpty {
                Text("尚無SF-36評量紀錄")
                    .foregroundColor(.gray)
                    .font(.system(size: 14))
                    .frame(maxWidth: .infinity, minHeight: 60)
                    .background(Color.gray.opacity(0.05))
                    .cornerRadius(6)
            } else {
                // 緊湊的橫向三欄顯示
                HStack(spacing: 8) {
                    ForEach(Array(recentRecords.enumerated()), id: \.1.id) { index, record in
                        SF36CompactScoreColumn(
                            record: record, 
                            isSelected: Calendar.current.isDate(record.date, inSameDayAs: selectedDate),
                            isLatest: index == 0
                        )
                        .frame(maxWidth: .infinity)
                    }
                    
                    // 填充空欄位（如果少於三次記錄）
                    ForEach(recentRecords.count..<3, id: \.self) { _ in
                        SF36CompactEmptyColumn()
                            .frame(maxWidth: .infinity)
                    }
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }
    
    private var expandedContent: some View {
        ScrollView {
            SF36DetailedView(record: selectedRecord, selectedDate: selectedDate)
                .padding()
        }
        .frame(maxHeight: 350)
    }
}

// MARK: - Recent Scores

/**
 * SF36CompactScoreColumn - 緊湊版橫向三欄顯示的SF-36評量分數組件
 */
struct SF36CompactScoreColumn: View {
    let record: AssessmentRecord
    let isSelected: Bool
    let isLatest: Bool
    
    var body: some View {
        VStack(spacing: 4) {
            // 總分
            Text("\(Int(record.totalScore))")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(isSelected ? .white : (isLatest ? AssessmentType.sf36.color : .primary))
            
            // 日期
            Text(DateFormatter.shortDate.string(from: record.date))
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(isSelected ? .white : .secondary)
        }
        .frame(height: 50)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isSelected ? AssessmentType.sf36.color : (isLatest ? AssessmentType.sf36.color.opacity(0.1) : Color.gray.opacity(0.05)))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(isSelected ? AssessmentType.sf36.color : (isLatest ? AssessmentType.sf36.color.opacity(0.3) : Color.clear), lineWidth: 1)
        )
    }
}

/**
 * SF36CompactEmptyColumn - 空的分數欄位
 */
struct SF36CompactEmptyColumn: View {
    var body: some View {
        VStack(spacing: 4) {
            Text("--")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.gray)
            
            Text("--/--")
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.gray)
        }
        .frame(height: 50)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.gray.opacity(0.05))
        )
    }
}

// MARK: - Detailed View

/**
 * SF36DetailedView - SF-36評量的詳細結果顯示
 */
struct SF36DetailedView: View {
    let record: AssessmentRecord?
    let selectedDate: Date
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 評量標題和總分
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("SF-36 健康調查量表")
                        .font(.title3)
                        .fontWeight(.bold)
                    Spacer()
                    Text("\(selectedDate, style: .date)")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                
                HStack {
                    Text("總分:")
                        .font(.headline)
                    if let record = record {
                        Text("\(Int(record.totalScore))/100")
                            .font(.headline)
                            .foregroundColor(AssessmentType.sf36.color)
                    } else {
                        Text("___/100")
                            .font(.headline)
                            .foregroundColor(.gray)
                    }
                    Spacer()
                    Text("分數越高，表示健康狀況越好")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            .padding()
            .background(AssessmentType.sf36.color.opacity(0.1))
            .cornerRadius(8)
            
            // 各維度分數顯示
            VStack(alignment: .leading, spacing: 12) {
                ForEach(SF36Dimension.allCases, id: \.self) { dimension in
                    SF36DimensionScoreView(
                        dimension: dimension,
                        score: record?.scores[dimension.rawValue].map(Int.init) ?? nil
                    )
                }
            }
            
            Divider()
            
            // 詳細問題和答案
            VStack(alignment: .leading, spacing: 16) {
                Text("詳細問答內容")
                    .font(.headline)
                
                // 按維度顯示問題
                ForEach(SF36Dimension.allCases, id: \.self) { dimension in
                    SF36DimensionSection(
                        dimension: dimension,
                        record: record
                    )
                }
            }
            
            // 備註（如果有）
            if let record = record, let notes = record.notes, !notes.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("備註")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(notes)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .padding()
                        .background(Color.gray.opacity(0.05))
                        .cornerRadius(8)
                }
            }
        }
    }
    
    private func scoreColor(for score: Double) -> Color {
        switch score {
        case 80...100: return .green
        case 60..<80: return .orange
        default: return .red
        }
    }
}

// MARK: - Dimension Scores Section

/**
 * SF36DimensionScoresSection - SF-36各維度分數顯示區域
 */
struct SF36DimensionScoresSection: View {
    let scores: [String: Double]
    
    // SF-36維度映射（中文名稱到英文縮寫）
    private let dimensionMapping: [String: String] = [
        "身體功能": "PF",
        "身體角色功能": "RP", 
        "身體疼痛": "BP",
        "一般健康": "GH",
        "活力": "VT",
        "社會功能": "SF",
        "情緒角色功能": "RE",
        "心理健康": "MH"
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("各維度分數")
                .font(.headline)
                .foregroundColor(.primary)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(Array(dimensionMapping.keys.sorted()), id: \.self) { dimension in
                    if let score = scores[dimension] {
                        SF36DimensionScoreCard(
                            dimension: dimension,
                            abbreviation: dimensionMapping[dimension] ?? "",
                            score: score
                        )
                    }
                }
            }
        }
    }
}

/**
 * SF36DimensionScoreCard - SF-36單一維度分數卡片
 */
struct SF36DimensionScoreCard: View {
    let dimension: String
    let abbreviation: String
    let score: Double
    
    private var scoreColor: Color {
        switch score {
        case 80...100: return .green
        case 60..<80: return .orange
        default: return .red
        }
    }
    
    var body: some View {
        VStack(spacing: 8) {
            // 維度縮寫
            Text(abbreviation)
                .font(.caption.bold())
                .foregroundColor(.secondary)
            
            // 分數
            Text(String(format: "%.0f", score))
                .font(.title3.bold())
                .foregroundColor(scoreColor)
            
            // 維度名稱
            Text(dimension)
                .font(.caption2)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity)
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(scoreColor.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(scoreColor, lineWidth: 1)
                )
        )
    }
}

/**
 * SF36DimensionScoreView - SF-36單一維度分數顯示組件（類似WOMAC的CategoryScoreView）
 */
struct SF36DimensionScoreView: View {
    let dimension: SF36Dimension
    let score: Int?
    
    private var percentage: Double {
        guard let score = score else { return 0 }
        return Double(score) / 100.0
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(dimension.rawValue)
                    .font(.system(size: 14, weight: .medium))
                Spacer()
                if let score = score {
                    Text("\(score)/100")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.primary)
                } else {
                    Text("___/100")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.gray)
                }
            }
            
            // 進度條
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 6)
                    
                    Rectangle()
                        .fill(AssessmentType.sf36.color)
                        .frame(width: geometry.size.width * percentage, height: 6)
                }
            }
            .frame(height: 6)
            .cornerRadius(3)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Detailed Question Views

/**
 * SF36DimensionSection - SF-36分維度問題詳細顯示組件
 */
struct SF36DimensionSection: View {
    let dimension: SF36Dimension
    let record: AssessmentRecord?
    
    private var dimensionQuestions: [SF36Question] {
        SF36Questions.getQuestions(for: dimension)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 維度標題
            HStack {
                Text(dimension.rawValue)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(AssessmentType.sf36.color)
                Spacer()
                Text("(\(dimensionQuestions.count)題)")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding(.bottom, 8)
            
            // 引導問句（顯示dimension的description）
            if let description = SF36Questions.getDescription(for: dimension) {
                Text(description)
                    .font(.system(size: 14))
                    .foregroundColor(AssessmentType.sf36.color)
                    .italic()
                    .padding(.bottom, 8)
            }
            
            // 問題列表
            ForEach(Array(dimensionQuestions.enumerated()), id: \.1.id) { index, question in
                SF36QuestionRow(
                    question: question,
                    questionNumber: index + 1,
                    selectedScore: getQuestionScore(questionId: question.id)
                )
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(8)
    }
    
    private func getQuestionScore(questionId: Int) -> Int? {
        guard let record = record else { return nil }
        
        // TODO: 實際應該從record中解析個別問題答案
        // 暫時從record.notes中的JSON或其他格式解析個別問題答案
        // 目前使用模擬數據
        return Int.random(in: 1...6) // 模擬分數，根據SF-36選項範圍
    }
}

/**
 * SF36QuestionRow - 單一SF-36問題顯示組件
 */
struct SF36QuestionRow: View {
    let question: SF36Question
    let questionNumber: Int
    let selectedScore: Int?
    
    private var selectedOption: SF36Option? {
        guard let score = selectedScore else { return nil }
        return question.options.first { $0.rawScore == score }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 問題
            HStack(alignment: .top, spacing: 8) {
                Text("\(question.id).")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.gray)
                    .frame(width: 30, alignment: .leading)
                
                Text(question.questionText)
                    .font(.system(size: 16))
                    .foregroundColor(.primary)
                    .fixedSize(horizontal: false, vertical: true)
                
                Spacer()
            }
            
            // 反向計分標註
            if question.isReverseCoded {
                Text("(反向計分)")
                    .font(.system(size: 14))
                    .foregroundColor(.orange)
                    .padding(.leading, 38)
            }
            
            // 選項和答案
            HStack {
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    if let selectedOption = selectedOption, let score = selectedScore {
                        Text(selectedOption.text)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(getScoreColor(score, isReverseCoded: question.isReverseCoded))
                        
                        Text("(\(score)分)")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                    } else {
                        Text("未選擇")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.gray)
                        
                        Text("(___分)")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(selectedScore != nil ? getScoreColor(selectedScore!, isReverseCoded: question.isReverseCoded).opacity(0.1) : Color.gray.opacity(0.1))
                .cornerRadius(6)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color.white)
        .cornerRadius(6)
        .shadow(color: .black.opacity(0.05), radius: 1, y: 1)
    }
    
    private func getScoreColor(_ score: Int, isReverseCoded: Bool) -> Color {
        // SF-36的計分需要考慮反向計分
        let effectiveScore = isReverseCoded ? (question.options.count + 1 - score) : score
        let maxScore = question.options.count
        
        let percentage = Double(effectiveScore) / Double(maxScore)
        
        switch percentage {
        case 0.8...1.0:
            return .green     // 最好
        case 0.6..<0.8:
            return AssessmentType.sf36.color      // 好
        case 0.4..<0.6:
            return .yellow    // 中等
        case 0.2..<0.4:
            return .orange    // 差
        default:
            return .red       // 最差
        }
    }
}

// MARK: - Extensions

extension DateFormatter {
    static let shortDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd"
        return formatter
    }()
    
    static let fullDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd"
        return formatter
    }()
}
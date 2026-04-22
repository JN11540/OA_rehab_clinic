import SwiftUI

/**
 * KOOSComponents.swift - KOOS評量相關的UI組件集合
 * 
 * 包含以下組件：
 * - KOOSAssessmentToggleView: KOOS Toggle展開/折疊視圖
 * - KOOSDetailedView: 詳細問卷內容顯示  
 * - KOOSCategorySection: 分類別問題顯示
 * - KOOSQuestionRow: 單一問題顯示
 * - KOOSCategoryScoreView: 分類別分數進度條
 * 
 * 設計原則：
 * 參考WOMACComponents.swift的架構，為KOOS量表創建專用組件
 * 支援KOOS特有的計分方式（分數越高表示功能越好）
 */

// MARK: - Main Toggle View

/**
 * KOOSAssessmentToggleView - KOOS評量結果的Toggle展開/折疊視圖
 * 
 * 功能：
 * - 折疊狀態：顯示最近三次評量日期和總分
 * - 展開狀態：顯示選中日期的完整KOOS問卷內容
 * - 支援展開/折疊動畫效果
 */
struct KOOSAssessmentToggleView: View {
    let patient: Patient
    let selectedDate: Date
    @Binding var isExpanded: Bool
    @EnvironmentObject private var recordStore: RecordStore
    
    // 外部點擊處理器（可選）
    var onToggle: (() -> Void)? = nil
    
    private var selectedRecord: AssessmentRecord? {
        recordStore.getAssessmentRecords(for: patient.id)
            .first(where: { Calendar.current.isDate($0.date, inSameDayAs: selectedDate) })
    }
    
    private var recentRecords: [AssessmentRecord] {
        recordStore.getAssessmentRecords(for: patient.id)
            .filter { $0.assessmentId.contains("KOOS") || $0.scores.keys.contains("疼痛") }
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
                    Text("KOOS 評量結果")
                        .font(.headline)
                        .foregroundColor(.primary)
                    Spacer()
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(AssessmentType.koos.color)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
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
                Text("尚無KOOS評量紀錄")
                    .foregroundColor(.gray)
                    .font(.system(size: 14))
                    .frame(maxWidth: .infinity, minHeight: 60)
                    .background(Color.gray.opacity(0.05))
                    .cornerRadius(6)
            } else {
                // 緊湊的橫向三欄顯示
                HStack(spacing: 8) {
                    ForEach(Array(recentRecords.enumerated()), id: \.1.id) { index, record in
                        KOOSCompactScoreColumn(
                            record: record, 
                            isSelected: Calendar.current.isDate(record.date, inSameDayAs: selectedDate),
                            isLatest: index == 0
                        )
                        .frame(maxWidth: .infinity)
                    }
                    
                    // 填充空欄位（如果少於三次記錄）
                    ForEach(recentRecords.count..<3, id: \.self) { _ in
                        KOOSCompactEmptyColumn()
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
            KOOSDetailedView(record: selectedRecord, selectedDate: selectedDate)
                .padding()
        }
        .frame(maxHeight: 350) // 調整為更合適的高度
    }
}

// MARK: - Recent Scores

/**
 * KOOSCompactScoreColumn - 緊湊版橫向三欄顯示的KOOS評量分數組件
 */
struct KOOSCompactScoreColumn: View {
    let record: AssessmentRecord
    let isSelected: Bool
    let isLatest: Bool
    
    var body: some View {
        VStack(spacing: 4) {
            // 總分
            Text("\(Int(record.totalScore))")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(isSelected ? AssessmentType.koos.color : .primary)
            
            // 日期（簡化）
            Text(record.date, style: .date)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.gray)
                .lineLimit(1)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 4)
        .background(isSelected ? AssessmentType.koos.color.opacity(0.1) : Color.gray.opacity(0.05))
        .cornerRadius(6)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(isSelected ? AssessmentType.koos.color.opacity(0.3) : Color.clear, lineWidth: 1)
        )
    }
}

/**
 * KOOSCompactEmptyColumn - 緊湊版空的KOOS評量分數欄位組件
 */
struct KOOSCompactEmptyColumn: View {
    var body: some View {
        VStack(spacing: 4) {
            Text("--")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.gray.opacity(0.4))
            
            Text("--/--")
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.gray.opacity(0.4))
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 4)
        .background(Color.gray.opacity(0.02))
        .cornerRadius(6)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(Color.gray.opacity(0.1), lineWidth: 1)
        )
    }
}



// MARK: - KOOS Detailed Views

/**
 * KOOSDetailedView - KOOS問卷詳細內容顯示組件
 * 
 * 支援無數據狀態，總是顯示完整問卷結構
 */
struct KOOSDetailedView: View {
    let record: AssessmentRecord?
    let selectedDate: Date
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 評量標題和總分
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("KOOS 評量結果")
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
                            .foregroundColor(AssessmentType.koos.color)
                    } else {
                        Text("___/100")
                            .font(.headline)
                            .foregroundColor(.gray)
                    }
                    Spacer()
                    Text("分數越高，表示身體功能越好")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            .padding()
            .background(AssessmentType.koos.color.opacity(0.1))
            .cornerRadius(8)
            
            // 分類別顯示分數
            VStack(alignment: .leading, spacing: 12) {
                ForEach(KOOSCategory.allCases, id: \.self) { category in
                    KOOSCategoryScoreView(
                        category: category,
                        score: record?.scores[category.rawValue].map(Int.init) ?? nil
                    )
                }
            }
            
            Divider()
            
            // 詳細問題和答案
            VStack(alignment: .leading, spacing: 16) {
                Text("詳細問答內容")
                    .font(.headline)
                
                // 按類別顯示問題
                ForEach(KOOSCategory.allCases, id: \.self) { category in
                    KOOSCategorySection(
                        category: category,
                        record: record
                    )
                }
            }
        }
    }
}

/**
 * KOOSCategorySection - KOOS分類別問題詳細顯示組件
 */
struct KOOSCategorySection: View {
    let category: KOOSCategory
    let record: AssessmentRecord?
    
    private var categoryQuestions: [KOOSQuestion] {
        KOOSQuestions.getQuestions(for: category)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 類別標題
            HStack {
                Text(category.rawValue)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(AssessmentType.koos.color)
                Spacer()
                Text("(\(categoryQuestions.count)題)")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding(.bottom, 8)
            
            // 引導問句（顯示section的description）
            if let section = KOOSQuestions.getSection(for: category),
               let description = section.description {
                Text(description)
                    .font(.system(size: 14))
                    .foregroundColor(.blue)
                    .italic()
                    .padding(.bottom, 8)
            }
            
            // 問題列表
            ForEach(Array(categoryQuestions.enumerated()), id: \.1.id) { index, question in
                KOOSQuestionRow(
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
    
    private func getQuestionScore(questionId: String) -> Int? {
        guard let record = record else { return nil }
        
        // TODO: 實際應該從record中解析個別問題答案
        // 暫時從record.notes中的JSON或其他格式解析個別問題答案
        // 目前使用模擬數據
        return Int.random(in: 0...4) // 模擬分數 0-4
    }
}

/**
 * KOOSQuestionRow - 單一KOOS問題顯示組件
 */
struct KOOSQuestionRow: View {
    let question: KOOSQuestion
    let questionNumber: Int
    let selectedScore: Int?
    
    private var selectedOption: KOOSOption? {
        guard let score = selectedScore else { return nil }
        return question.options.first { $0.score == score }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 問題
            HStack(alignment: .top, spacing: 8) {
                Text("\(question.id).")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.gray)
                    .frame(width: 30, alignment: .leading)
                
                Text(question.question)
                    .font(.system(size: 16))
                    .foregroundColor(.primary)
                    .fixedSize(horizontal: false, vertical: true)
                
                Spacer()
            }
            
            // 特別標註頻率問題
            if question.isFrequencyQuestion {
                Text("(頻率問題)")
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
                            .foregroundColor(getScoreColor(score))
                        
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
                .background(selectedScore != nil ? getScoreColor(selectedScore!).opacity(0.1) : Color.gray.opacity(0.1))
                .cornerRadius(6)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color.white)
        .cornerRadius(6)
        .shadow(color: .black.opacity(0.05), radius: 1, y: 1)
    }
    
    private func getScoreColor(_ score: Int) -> Color {
        // KOOS計分：分數越高表示功能越好，所以顏色相反
        switch score {
        case 0:
            return .red       // 最差 - 紅色
        case 1:
            return .orange    // 差 - 橙色
        case 2:
            return .yellow    // 中等 - 黃色
        case 3:
            return .blue      // 好 - 藍色
        case 4:
            return AssessmentType.koos.color     // 最好
        default:
            return .gray
        }
    }
}

// MARK: - Score Visualization

/**
 * KOOSCategoryScoreView - KOOS分類別分數顯示組件
 */
struct KOOSCategoryScoreView: View {
    let category: KOOSCategory
    let score: Int?
    
    private var percentage: Double {
        guard let score = score else { return 0 }
        return Double(score) / 100.0
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(category.rawValue)
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
                        .fill(AssessmentType.koos.color)
                        .frame(width: geometry.size.width * percentage, height: 6)
                }
            }
            .frame(height: 6)
            .cornerRadius(3)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Previews

// MARK: - Previews
// Note: Previews are temporarily disabled to avoid dependency issues
// They can be re-enabled once all components are properly integrated
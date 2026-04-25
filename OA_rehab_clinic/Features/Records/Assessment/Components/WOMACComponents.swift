import SwiftUI

/**
 * WOMACComponents.swift - WOMAC評量相關的UI組件集合
 * 
 * 包含以下組件：
 * - AssessmentToggleView: Toggle展開/折疊視圖
 * - WOMACDetailedView: 詳細問卷內容顯示  
 * - WOMACCategorySection: 分類別問題顯示
 * - WOMACQuestionRow: 單一問題顯示
 * - CategoryScoreView: 分類別分數進度條
 * 
 * 重構說明：
 * 從 AssessmentContentViews.swift 中提取所有 WOMAC 相關組件
 * 集中管理以便重複使用和維護
 */

// MARK: - Main Toggle View

/**
 * AssessmentToggleView - 評量結果的Toggle展開/折疊視圖
 * 
 * 功能：
 * - 折疊狀態：顯示最近三次評量日期和總分
 * - 展開狀態：顯示選中日期的完整WOMAC問卷內容
 * - 支援展開/折疊動畫效果
 */
struct AssessmentToggleView: View {
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
            .filter { $0.assessmentId.contains("WOMAC") }
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
                    Text("WOMAC 評量結果")
                        .font(.headline)
                        .foregroundColor(.primary)
                    Spacer()
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(AssessmentType.womac.color)
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
                Text("尚無WOMAC評量紀錄")
                    .foregroundColor(.gray)
                    .font(.system(size: 14))
                    .frame(maxWidth: .infinity, minHeight: 60)
                    .background(Color.gray.opacity(0.05))
                    .cornerRadius(6)
            } else {
                // 緊湊的橫向三欄顯示
                HStack(spacing: 8) {
                    ForEach(Array(recentRecords.enumerated()), id: \.1.id) { index, record in
                        CompactScoreColumn(
                            record: record, 
                            isSelected: Calendar.current.isDate(record.date, inSameDayAs: selectedDate),
                            isLatest: index == 0
                        )
                        .frame(maxWidth: .infinity)
                    }
                    
                    // 填充空欄位（如果少於三次記錄）
                    ForEach(recentRecords.count..<3, id: \.self) { _ in
                        CompactEmptyColumn()
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
            WOMACDetailedView(record: selectedRecord, selectedDate: selectedDate)
                .padding()
        }
        .frame(maxHeight: 350) // 調整為更合適的高度
    }
}

// MARK: - Recent Scores

/**
 * CompactScoreColumn - 緊湊版橫向三欄顯示的評量分數組件
 */
struct CompactScoreColumn: View {
    let record: AssessmentRecord
    let isSelected: Bool
    let isLatest: Bool
    
    var body: some View {
        VStack(spacing: 4) {
            // 總分
            Text("\(Int(record.totalScore))")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(isSelected ? AssessmentType.womac.color : .primary)
            
            // 日期（簡化）
            Text(record.date, style: .date)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.gray)
                .lineLimit(1)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 4)
        .background(isSelected ? AssessmentType.womac.color.opacity(0.1) : Color.gray.opacity(0.05))
        .cornerRadius(6)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(isSelected ? AssessmentType.womac.color.opacity(0.3) : Color.clear, lineWidth: 1)
        )
    }
}

/**
 * CompactEmptyColumn - 緊湊版空的評量分數欄位組件
 */
struct CompactEmptyColumn: View {
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



// MARK: - WOMAC Detailed Views

/**
 * WOMACDetailedView - WOMAC問卷詳細內容顯示組件
 * 
 * 🔧 更新：支援無數據狀態，總是顯示完整問卷結構
 */
struct WOMACDetailedView: View {
    let record: AssessmentRecord?
    let selectedDate: Date
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 評量標題和總分
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("WOMAC 評量結果")
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
                        Text("\(Int(record.totalScore))/96")
                            .font(.headline)
                            .foregroundColor(AssessmentType.womac.color)
                    } else {
                        Text("___/96")
                            .font(.headline)
                            .foregroundColor(.gray)
                    }
                    Spacer()
                    Text("分數越高，表示身體功能受影響越大")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            .padding()
            .background(AssessmentType.womac.color.opacity(0.1))
            .cornerRadius(8)
            
            // 分類別顯示分數
            VStack(alignment: .leading, spacing: 12) {
                ForEach(WOMACCategory.allCases, id: \.self) { category in
                    CategoryScoreView(
                        category: category,
                        score: record?.scores[category.rawValue].map(Int.init) ?? nil,
                        maxScore: category.maxScore
                    )
                }
            }
            
            Divider()
            
            // 詳細問題和答案
            VStack(alignment: .leading, spacing: 16) {
                Text("詳細問答內容")
                    .font(.headline)
                
                // 按類別顯示問題
                ForEach(WOMACCategory.allCases, id: \.self) { category in
                    WOMACCategorySection(
                        category: category,
                        record: record
                    )
                }
            }
        }
    }
}

/**
 * WOMACCategorySection - WOMAC分類別問題詳細顯示組件
 */
struct WOMACCategorySection: View {
    let category: WOMACCategory
    let record: AssessmentRecord?
    
    private var categoryQuestions: [WOMACQuestion] {
        WOMACQuestions.getQuestions(for: category)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 類別標題
            HStack {
                Text(category.rawValue)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(AssessmentType.womac.color)
                Spacer()
                Text("(\(categoryQuestions.count)題)")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding(.bottom, 8)
            
            // 問題列表
            ForEach(Array(categoryQuestions.enumerated()), id: \.1.id) { index, question in
                WOMACQuestionRow(
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
        // 🔧 修改：從record中解析問題回答，沒有record時返回nil
        guard let record = record else { return nil }
        
        // TODO: 實際應該從record中解析個別問題答案
        // 暫時從record.notes中的JSON或其他格式解析個別問題答案
        // 目前使用模擬數據
        return Int.random(in: 0...4) // 模擬分數 0-4
    }
}

/**
 * WOMACQuestionRow - 單一WOMAC問題顯示組件
 */
struct WOMACQuestionRow: View {
    let question: WOMACQuestion
    let questionNumber: Int
    let selectedScore: Int?
    
    private var selectedOption: WOMACOption? {
        guard let score = selectedScore else { return nil }
        return question.options.first { $0.score == score }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 問題
            HStack(alignment: .top, spacing: 8) {
                Text("\(questionNumber).")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.gray)
                    .frame(width: 20, alignment: .leading)
                
                Text(question.question)
                    .font(.system(size: 16))
                    .foregroundColor(.primary)
                    .fixedSize(horizontal: false, vertical: true)
                
                Spacer()
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
        switch score {
        case 0:
            return .green
        case 1:
            return .yellow
        case 2:
            return .orange
        case 3:
            return .red
        case 4:
            return .purple
        default:
            return .gray
        }
    }
}

// MARK: - Score Visualization

/**
 * CategoryScoreView - WOMAC分類別分數顯示組件
 */
struct CategoryScoreView: View {
    let category: WOMACCategory
    let score: Int?
    let maxScore: Int
    
    private var percentage: Double {
        guard let score = score, maxScore > 0 else { return 0 }
        return Double(score) / Double(maxScore)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(category.rawValue)
                    .font(.system(size: 14, weight: .medium))
                Spacer()
                if let score = score {
                    Text("\(score)/\(maxScore)")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.primary)
                } else {
                    Text("___/\(maxScore)")
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
                        .fill(AssessmentType.womac.color)
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

#Preview("AssessmentToggleView") {
    AssessmentToggleView(
        patient: Patient.sample,
        selectedDate: Date(),
        isExpanded: .constant(false)
    )
    .environmentObject(RecordStore.shared)
    .frame(width: 600, height: 400)
    .background(Color.gray.opacity(0.1))
}

#Preview("WOMACDetailedView - 有數據") {
    WOMACDetailedView(
        record: AssessmentRecord(
            id: UUID(),
            patientId: "sample",
            assessmentId: "womac-001",
            date: Date(),
            scores: [
                "關節疼痛程度": 15.0,
                "關節僵硬程度": 6.0,
                "身體功能": 42.0
            ],
            totalScore: 63.0,
            notes: "患者反應膝關節在下樓梯時疼痛較明顯"
        ),
        selectedDate: Date()
    )
    .padding()
    .background(Color.gray.opacity(0.1))
}

#Preview("WOMACDetailedView - 無數據") {
    WOMACDetailedView(
        record: nil,
        selectedDate: Date()
    )
    .padding()
    .background(Color.gray.opacity(0.1))
}


#Preview("橫向三欄顯示 - 三次記錄") {
    let sampleRecords = [
        AssessmentRecord(
            id: UUID(),
            patientId: "sample",
            assessmentId: "womac-001",
            date: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date(),
            scores: [
                "關節疼痛頻率": 2.0,
                "關節疼痛程度": 15.0,
                "關節僵硬程度": 6.0,
                "身體功能": 42.0
            ],
            totalScore: 63.0,
            notes: "最近一次評量"
        ),
        AssessmentRecord(
            id: UUID(),
            patientId: "sample",
            assessmentId: "womac-002",
            date: Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date(),
            scores: [
                "關節疼痛頻率": 3.0,
                "關節疼痛程度": 18.0,
                "關節僵硬程度": 7.0,
                "身體功能": 50.0
            ],
            totalScore: 75.0,
            notes: "一週前評量"
        ),
        AssessmentRecord(
            id: UUID(),
            patientId: "sample",
            assessmentId: "womac-003",
            date: Calendar.current.date(byAdding: .day, value: -14, to: Date()) ?? Date(),
            scores: [
                "關節疼痛頻率": 4.0,
                "關節疼痛程度": 20.0,
                "關節僵硬程度": 8.0,
                "身體功能": 60.0
            ],
            totalScore: 88.0,
            notes: "兩週前評量"
        )
    ]
    
    VStack(spacing: 12) {
        Text("最近三次評量結果")
            .font(.subheadline)
            .foregroundColor(.gray)
            .padding(.horizontal)
            .padding(.top)
        
        // 橫向三欄顯示
        HStack(spacing: 12) {
            ForEach(Array(sampleRecords.enumerated()), id: \.1.id) { index, record in
                CompactScoreColumn(
                    record: record,
                    isSelected: index == 0, // 第一個記錄為選中狀態
                    isLatest: index == 0
                )
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal)
        .padding(.bottom)
    }
    .background(Color.white)
    .cornerRadius(8)
    .padding()
    .background(Color.gray.opacity(0.1))
}

#Preview("橫向三欄顯示 - 兩次記錄含空欄位") {
    let sampleRecords = [
        AssessmentRecord(
            id: UUID(),
            patientId: "sample",
            assessmentId: "womac-001",
            date: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date(),
            scores: [
                "關節疼痛頻率": 2.0,
                "關節疼痛程度": 15.0,
                "關節僵硬程度": 6.0,
                "身體功能": 42.0
            ],
            totalScore: 63.0,
            notes: "最近一次評量"
        ),
        AssessmentRecord(
            id: UUID(),
            patientId: "sample",
            assessmentId: "womac-002",
            date: Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date(),
            scores: [
                "關節疼痛頻率": 3.0,
                "關節疼痛程度": 18.0,
                "關節僵硬程度": 7.0,
                "身體功能": 50.0
            ],
            totalScore: 75.0,
            notes: "一週前評量"
        )
    ]
    
    VStack(spacing: 12) {
        Text("最近三次評量結果")
            .font(.subheadline)
            .foregroundColor(.gray)
            .padding(.horizontal)
            .padding(.top)
        
        // 橫向三欄顯示（包含空欄位）
        HStack(spacing: 12) {
            ForEach(Array(sampleRecords.enumerated()), id: \.1.id) { index, record in
                CompactScoreColumn(
                    record: record,
                    isSelected: index == 0,
                    isLatest: index == 0
                )
                .frame(maxWidth: .infinity)
            }
            
            // 填充空欄位
            ForEach(sampleRecords.count..<3, id: \.self) { _ in
                CompactEmptyColumn()
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal)
        .padding(.bottom)
    }
    .background(Color.white)
    .cornerRadius(8)
    .padding()
    .background(Color.gray.opacity(0.1))
}
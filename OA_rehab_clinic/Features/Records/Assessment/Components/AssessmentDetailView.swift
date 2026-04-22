import SwiftUI

/**
 * AssessmentDetailView.swift - 單次評量結果的詳細顯示組件
 * 
 * 功能：
 * - 顯示評量日期和總分
 * - 列舉所有分項的詳細分數
 * - 顯示留言或註解（如果有）
 * - 用於在DailyResultView和ResultChangeView中展示評量詳情
 * 
 * 重構說明：
 * 從 AssessmentContentViews.swift 中提取為共享組件
 * 可被多個評量相關視圖重複使用
 */

struct AssessmentDetailView: View {
    let record: AssessmentRecord
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(record.date, style: .date)
                    .font(.subheadline)
                Spacer()
                Text("總分: \(String(format: "%.1f", record.totalScore))")
                    .font(.headline)
            }
            
            Divider()
            
            ForEach(Array(record.scores.sorted(by: { $0.key < $1.key })), id: \.key) { item in
                HStack {
                    Text(item.key)
                    Spacer()
                    Text(String(format: "%.1f", item.value))
                }
                .font(.system(size: 14))
                .foregroundColor(.gray)
            }
            
            if let notes = record.notes {
                Text(notes)
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                    .padding(.top, 4)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
}

// MARK: - Preview
#Preview {
    AssessmentDetailView(
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
        )
    )
    .padding()
    .background(Color.gray.opacity(0.1))
}
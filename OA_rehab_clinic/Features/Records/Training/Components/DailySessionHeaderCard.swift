import SwiftUI

/**
 * DailySessionHeaderCard.swift - 單日訓練概況標題卡片
 * 
 * 功能：
 * - 顯示選中日期和菜單名稱
 * - 顯示總訓練時長和VAS疼痛分數
 * - 提供簡潔的單日訓練概覽
 * - 支援數據缺失時的友好提示
 */

struct DailySessionHeaderCard: View {
    let date: Date
    let menuTitle: String?
    let totalDuration: TimeInterval?
    let vasScore: Double?
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd"
        formatter.locale = Locale(identifier: "zh_TW")
        return formatter
    }
    
    private var dayOfWeekFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        formatter.locale = Locale(identifier: "zh_TW")
        return formatter
    }
    
    private var formattedDuration: String {
        guard let duration = totalDuration else { return "--" }
        let minutes = Int(duration / 60)
        let seconds = Int(duration.truncatingRemainder(dividingBy: 60))
        return minutes > 0 ? "\(minutes)分\(seconds)秒" : "\(seconds)秒"
    }
    
    private var formattedVasScore: String {
        guard let score = vasScore else { return "--" }
        return String(format: "%.1f", score)
    }
    
    private var vasColor: Color {
        guard let score = vasScore else { return .gray }
        switch score {
        case 0..<3:
            return .green
        case 3..<6:
            return .orange
        case 6...10:
            return .red
        default:
            return .gray
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 上半部：日期和菜單
            HStack(alignment: .center, spacing: 16) {
                // 日期信息
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Image(systemName: "calendar")
                            .foregroundColor(.blue)
                            .font(.title2)
                        
                        Text(dateFormatter.string(from: date))
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                    }
                    
                    Text(dayOfWeekFormatter.string(from: date))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.leading, 32) // 對齊圖標
                }
                
                Spacer()
                
                // 菜單名稱
                if let menuTitle = menuTitle {
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("訓練菜單")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(menuTitle)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.trailing)
                    }
                } else {
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("訓練菜單")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("無排程資料")
                            .font(.headline)
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            
            // 分隔線
            Divider()
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
            
            // 下半部：時長和VAS分數
            HStack(spacing: 24) {
                // 訓練時長
                HStack(spacing: 12) {
                    Circle()
                        .fill(Color.blue.opacity(0.1))
                        .frame(width: 40, height: 40)
                        .overlay(
                            Image(systemName: "clock.fill")
                                .foregroundColor(.blue)
                                .font(.system(size: 18))
                        )
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("總時長")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(formattedDuration)
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(totalDuration != nil ? .primary : .gray)
                    }
                }
                
                Spacer()
                
                // VAS疼痛分數
                HStack(spacing: 12) {
                    Circle()
                        .fill(vasColor.opacity(0.1))
                        .frame(width: 40, height: 40)
                        .overlay(
                            Image(systemName: vasScore != nil ? "face.dashed.fill" : "face.dashed")
                                .foregroundColor(vasColor)
                                .font(.system(size: 18))
                        )
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("疼痛指數")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        HStack(spacing: 4) {
                            Text(formattedVasScore)
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundColor(vasScore != nil ? vasColor : .gray)
                            
                            if vasScore != nil {
                                Text("/ 10")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 16)
        }
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Preview

#Preview("有完整數據") {
    DailySessionHeaderCard(
        date: Date(),
        menuTitle: "下肢肌力強化訓練",
        totalDuration: 2700, // 45分鐘
        vasScore: 3.5
    )
    .padding()
    .background(Color.gray.opacity(0.1))
}

#Preview("部分數據缺失") {
    DailySessionHeaderCard(
        date: Date(),
        menuTitle: "上肢復健訓練",
        totalDuration: nil,
        vasScore: nil
    )
    .padding()
    .background(Color.gray.opacity(0.1))
}

#Preview("無菜單數據") {
    DailySessionHeaderCard(
        date: Date(),
        menuTitle: nil,
        totalDuration: 1800, // 30分鐘
        vasScore: 7.2
    )
    .padding()
    .background(Color.gray.opacity(0.1))
}
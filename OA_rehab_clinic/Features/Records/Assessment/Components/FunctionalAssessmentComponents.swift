//
//  FunctionalAssessmentComponents.swift
//  OA_rehab_clinic
//
//  Created by Claude Code on 2025-06-23.
//

import SwiftUI
import Foundation

/**
 * FunctionalAssessmentComponents.swift - 功能性評估相關的UI組件集合
 * 
 * 包含以下組件：
 * - ChairTestToggleView: 椅子坐站測試Toggle展開/折疊視圖
 * - KneeRaiseToggleView: 原地站立抬膝Toggle展開/折疊視圖
 * - SingleLegStandToggleView: 開眼單足站立Toggle展開/折疊視圖
 * 
 * 設計原則：
 * 功能性評估相對簡單，只需顯示單一數值結果和最近三次記錄
 * 參考WOMAC/KOOS/SF-36的架構但大幅簡化
 */

// MARK: - 椅子坐站測試組件

/**
 * ChairTestToggleView - 椅子坐站測試的Toggle展開/折疊視圖
 * 
 * 顯示格式：椅子坐站測試：__次 / 30秒
 */
struct ChairTestToggleView: View {
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
                $0.assessmentId.contains("椅子坐站測試")
            })
    }
    
    private var recentRecords: [AssessmentRecord] {
        recordStore.getAssessmentRecords(for: patient.id)
            .filter { $0.assessmentId.contains("椅子坐站測試") }
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
                    Text("椅子坐站測試")
                        .font(.headline)
                        .foregroundColor(.primary)
                    Spacer()
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(AssessmentType.chairTest.color)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .clipShape(RoundedCorner(radius: 8, corners: [.topLeft, .topRight]))
            }
            .buttonStyle(PlainButtonStyle())
            
            // Content Area
            if isExpanded {
                // 展開狀態：顯示詳細結果
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
                Text("尚無椅子坐站測試紀錄")
                    .foregroundColor(.gray)
                    .font(.system(size: 14))
                    .frame(maxWidth: .infinity, minHeight: 60)
                    .background(Color.gray.opacity(0.05))
                    .cornerRadius(6)
            } else {
                // 緊湊的橫向三欄顯示
                HStack(spacing: 8) {
                    ForEach(Array(recentRecords.enumerated()), id: \.1.id) { index, record in
                        FunctionalTestCompactColumn(
                            record: record, 
                            isSelected: Calendar.current.isDate(record.date, inSameDayAs: selectedDate),
                            isLatest: index == 0,
                            unit: "次",
                            color: AssessmentType.chairTest.color
                        )
                        .frame(maxWidth: .infinity)
                    }
                    
                    // 填充空欄位（如果少於三次記錄）
                    ForEach(recentRecords.count..<3, id: \.self) { _ in
                        FunctionalTestEmptyColumn(unit: "次")
                            .frame(maxWidth: .infinity)
                    }
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }
    
    private var expandedContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 測試標題和結果
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("椅子坐站測試")
                        .font(.title3)
                        .fontWeight(.bold)
                    Spacer()
                    Text("\(selectedDate, style: .date)")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                
                HStack {
                    Text("結果:")
                        .font(.headline)
                    if let record = selectedRecord {
                        Text("\(Int(record.totalScore))次 / 30秒")
                            .font(.headline)
                            .foregroundColor(AssessmentType.chairTest.color)
                    } else {
                        Text("___次 / 30秒")
                            .font(.headline)
                            .foregroundColor(.gray)
                    }
                    Spacer()
                    Text("測量下肢肌耐力，評估跌倒危險因子")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            .padding()
            .background(AssessmentType.chairTest.color.opacity(0.1))
            .cornerRadius(8)
            
            // 備註（如果有）
            if let record = selectedRecord, let notes = record.notes, !notes.isEmpty {
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
        .padding()
        .frame(maxHeight: 200)
    }
}

// MARK: - 原地站立抬膝組件

/**
 * KneeRaiseToggleView - 原地站立抬膝的Toggle展開/折疊視圖
 * 
 * 顯示格式：原地站立抬膝：__次 / 2分鐘
 */
struct KneeRaiseToggleView: View {
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
                $0.assessmentId.contains("原地站立抬膝")
            })
    }
    
    private var recentRecords: [AssessmentRecord] {
        recordStore.getAssessmentRecords(for: patient.id)
            .filter { $0.assessmentId.contains("原地站立抬膝") }
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
                    Text("原地站立抬膝")
                        .font(.headline)
                        .foregroundColor(.primary)
                    Spacer()
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(AssessmentType.kneeRaise.color)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .clipShape(RoundedCorner(radius: 8, corners: [.topLeft, .topRight]))
            }
            .buttonStyle(PlainButtonStyle())
            
            // Content Area
            if isExpanded {
                // 展開狀態：顯示詳細結果
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
                Text("尚無原地站立抬膝紀錄")
                    .foregroundColor(.gray)
                    .font(.system(size: 14))
                    .frame(maxWidth: .infinity, minHeight: 60)
                    .background(Color.gray.opacity(0.05))
                    .cornerRadius(6)
            } else {
                // 緊湊的橫向三欄顯示
                HStack(spacing: 8) {
                    ForEach(Array(recentRecords.enumerated()), id: \.1.id) { index, record in
                        FunctionalTestCompactColumn(
                            record: record, 
                            isSelected: Calendar.current.isDate(record.date, inSameDayAs: selectedDate),
                            isLatest: index == 0,
                            unit: "次",
                            color: AssessmentType.kneeRaise.color
                        )
                        .frame(maxWidth: .infinity)
                    }
                    
                    // 填充空欄位（如果少於三次記錄）
                    ForEach(recentRecords.count..<3, id: \.self) { _ in
                        FunctionalTestEmptyColumn(unit: "次")
                            .frame(maxWidth: .infinity)
                    }
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }
    
    private var expandedContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 測試標題和結果
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("原地站立抬膝")
                        .font(.title3)
                        .fontWeight(.bold)
                    Spacer()
                    Text("\(selectedDate, style: .date)")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                
                HStack {
                    Text("結果:")
                        .font(.headline)
                    if let record = selectedRecord {
                        Text("\(Int(record.totalScore))次 / 2分鐘")
                            .font(.headline)
                            .foregroundColor(AssessmentType.kneeRaise.color)
                    } else {
                        Text("___次 / 2分鐘")
                            .font(.headline)
                            .foregroundColor(.gray)
                    }
                    Spacer()
                    Text("測量下肢肌耐力，評估心肺有氧耐力")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            .padding()
            .background(AssessmentType.kneeRaise.color.opacity(0.1))
            .cornerRadius(8)
            
            // 備註（如果有）
            if let record = selectedRecord, let notes = record.notes, !notes.isEmpty {
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
        .padding()
        .frame(maxHeight: 200)
    }
}

// MARK: - 開眼單足站立組件

/**
 * SingleLegStandToggleView - 開眼單足站立的Toggle展開/折疊視圖
 * 
 * 顯示格式：開眼單足站立：__秒 / 30秒
 */
struct SingleLegStandToggleView: View {
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
                $0.assessmentId.contains("開眼單足站立")
            })
    }
    
    private var recentRecords: [AssessmentRecord] {
        recordStore.getAssessmentRecords(for: patient.id)
            .filter { $0.assessmentId.contains("開眼單足站立") }
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
                    Text("開眼單足站立")
                        .font(.headline)
                        .foregroundColor(.primary)
                    Spacer()
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(AssessmentType.singleLegStand.color)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .clipShape(RoundedCorner(radius: 8, corners: [.topLeft, .topRight]))
            }
            .buttonStyle(PlainButtonStyle())
            
            // Content Area
            if isExpanded {
                // 展開狀態：顯示詳細結果
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
                Text("尚無開眼單足站立紀錄")
                    .foregroundColor(.gray)
                    .font(.system(size: 14))
                    .frame(maxWidth: .infinity, minHeight: 60)
                    .background(Color.gray.opacity(0.05))
                    .cornerRadius(6)
            } else {
                // 緊湊的橫向三欄顯示
                HStack(spacing: 8) {
                    ForEach(Array(recentRecords.enumerated()), id: \.1.id) { index, record in
                        FunctionalTestCompactColumn(
                            record: record, 
                            isSelected: Calendar.current.isDate(record.date, inSameDayAs: selectedDate),
                            isLatest: index == 0,
                            unit: "秒",
                            color: AssessmentType.singleLegStand.color
                        )
                        .frame(maxWidth: .infinity)
                    }
                    
                    // 填充空欄位（如果少於三次記錄）
                    ForEach(recentRecords.count..<3, id: \.self) { _ in
                        FunctionalTestEmptyColumn(unit: "秒")
                            .frame(maxWidth: .infinity)
                    }
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }
    
    private var expandedContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 測試標題和結果
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("開眼單足站立")
                        .font(.title3)
                        .fontWeight(.bold)
                    Spacer()
                    Text("\(selectedDate, style: .date)")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                
                HStack {
                    Text("結果:")
                        .font(.headline)
                    if let record = selectedRecord {
                        Text("\(Int(record.totalScore))秒 / 30秒")
                            .font(.headline)
                            .foregroundColor(AssessmentType.singleLegStand.color)
                    } else {
                        Text("___秒 / 30秒")
                            .font(.headline)
                            .foregroundColor(.gray)
                    }
                    Spacer()
                    Text("測量下肢肌耐力，評估本體感覺等平衡能力")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            .padding()
            .background(AssessmentType.singleLegStand.color.opacity(0.1))
            .cornerRadius(8)
            
            // 備註（如果有）
            if let record = selectedRecord, let notes = record.notes, !notes.isEmpty {
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
        .padding()
        .frame(maxHeight: 200)
    }
}

// MARK: - 共用組件

/**
 * FunctionalTestCompactColumn - 功能性測試緊湊版橫向三欄顯示組件
 */
struct FunctionalTestCompactColumn: View {
    let record: AssessmentRecord
    let isSelected: Bool
    let isLatest: Bool
    let unit: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            // 分數
            Text("\(Int(record.totalScore))")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(isSelected ? .white : (isLatest ? color : .primary))
            
            // 單位
            Text(unit)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(isSelected ? .white : .secondary)
            
            // 日期
            Text(DateFormatter.shortDate.string(from: record.date))
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(isSelected ? .white : .secondary)
        }
        .frame(height: 60)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isSelected ? color : (isLatest ? color.opacity(0.1) : Color.gray.opacity(0.05)))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(isSelected ? color : (isLatest ? color.opacity(0.3) : Color.clear), lineWidth: 1)
        )
    }
}

/**
 * FunctionalTestEmptyColumn - 功能性測試空的分數欄位
 */
struct FunctionalTestEmptyColumn: View {
    let unit: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text("--")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.gray)
            
            Text(unit)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.gray)
            
            Text("--/--")
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.gray)
        }
        .frame(height: 60)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.gray.opacity(0.05))
        )
    }
}

// MARK: - Extensions

// RoundedCorner extension should be available from CalendarExtensions.swift
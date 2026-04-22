import SwiftUI

/**
 * MedicalRecordField - 病歷號顯示欄位組件
 *
 * 功能說明：
 * - 顯示患者的病歷號資訊
 * - 提供統一的欄位樣式和布局
 * - 使用唯讀模式，不支援編輯
 * - 適用於 CaseManageView 中的患者資訊區域
 *
 * UI 設計：
 * - 白色背景和圓角設計與其他卡片保持一致
 * - 使用 RoundedBorderTextFieldStyle 統一樣式
 *
 * 架構重構說明：
 * - 從原本 Core/Components/MedicalRecord.swift 移動
 * - 移動到 Features/Patient/Components/ 符合功能模組化
 * - 命名更清晰反映實際功能（Field 而非 Record）
 */
struct MedicalRecordField: View {
    let patientId: String
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("病歷號")
                .font(.headline)
            TextField("", text: .constant(patientId))
                .textFieldStyle(RoundedBorderTextFieldStyle())
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(12)
    }
}
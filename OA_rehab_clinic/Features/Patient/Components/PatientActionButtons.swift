import SwiftUI

/**
 * PatientActionButtons - 患者相關動作按鈕組件
 *
 * 功能說明：
 * - 提供快速導航到患者的訓練紀錄和評量紀錄
 * - 整合環境物件來傳遞必要的 Store 和 Model
 * - 提供統一的按鈕樣式和互動設計
 * - 支援直接跳轉到特定的主標籤（訓練/評量）
 *
 * 導航功能：
 * - 「檢視訓練紀錄」 -> TrainingRecordView(訓練標籤)
 * - 「檢視評量紀錄」 -> TrainingRecordView(評量標籤)
 *
 * UI 設計：
 * - Teal 顏色作為主色調，綫合 CaseManageView 整體設計
 * - 圓角按鈕和邊框設計提供現代感
 * - 固定按鈕高度確保一致性
 *
 * 架構重構說明：
 * - 從原本 Core/Components/Buttons/ActionButtonsCard.swift 重構
 * - 移除了 CalendarActionButton，只保留導航功能
 * - 移動到 Features/Patient/Components/ 符合業務邏輯歸屬
 * - 解決了 Core 中包含業務邏輯的架構問題
 */
struct PatientActionButtons: View {
    let patient: Patient
    @EnvironmentObject private var scheduleStore: TrainingScheduleStore
    @EnvironmentObject private var menuStore: TrainingMenuStore
    @EnvironmentObject private var userModel: UserModel
    
    var body: some View {
        VStack(spacing: 16) {  // 增加按鈕間距
            NavigationLink {
                TrainingRecordView(patient: patient, initialMainTab: .training)
                    .environmentObject(scheduleStore)
                    .environmentObject(menuStore)
                    .environmentObject(userModel)
            } label: {
                Text("檢視訓練紀錄")
                    .font(.system(size: 18, weight: .medium))  // 調整字體大小和粗細
                    .foregroundColor(.teal)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)  // 固定按鈕高度
                    .background(Color.white)
                    .cornerRadius(22)  // 圓角隨高度調整
                    .overlay(
                        RoundedRectangle(cornerRadius: 22)
                            .stroke(Color.teal, lineWidth: 1.5)  // 加粗邊框
                    )
            }
            
            NavigationLink {
                TrainingRecordView(patient: patient, initialMainTab: .assessment)
                    .environmentObject(scheduleStore)
                    .environmentObject(menuStore)
                    .environmentObject(userModel)
            } label: {
                Text("檢視評量紀錄")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.teal)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(Color.white)
                    .cornerRadius(22)
                    .overlay(
                        RoundedRectangle(cornerRadius: 22)
                            .stroke(Color.teal, lineWidth: 1.5)
                    )
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 16)  // 減少水平內邊距
        .padding(.vertical, 24)    // 減少垂直內邊距
        .background(Color.white)
        .cornerRadius(18)
    }
}
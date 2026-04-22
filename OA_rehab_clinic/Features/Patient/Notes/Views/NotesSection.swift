import SwiftUI

/**
 * NotesSection - 備註區域組件
 *
 * 功能說明：
 * - 在 CaseManageView 中作為備註区域的主容器
 * - 整合 MedicalRecordField 和 NotesCard 組件
 * - 使用 Grid 布局確保整齊排列
 * - 維持與 CalendarCard 一致的高度設定
 *
 * 架構重構說明：
 * - 從原本 Core/Components/Note.swift 中提取
 * - 移動到 Features/Patient/Notes/Views/ 符合功能組織
 * - 接受 showingAddNote binding 控制表單狀態
 */
struct NotesSection: View {
    private let fixedHeight: CGFloat = 450  // 與 CalendarCard 相同的高度
    
    let patient: Patient
    @Binding var showingAddNote: Bool
    
    var body: some View {
        Grid(alignment: .top, verticalSpacing: 20) {
            MedicalRecordField(patientId: patient.id)
            NotesCard(patient: patient, showingAddNote: $showingAddNote)
        }
    }
}
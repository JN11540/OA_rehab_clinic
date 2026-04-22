import SwiftUI

/**
 * NotesCard - 備註卡片組件
 *
 * 功能說明：
 * - 顯示指定患者的所有備註列表
 * - 提供滾動查看功能支援多個備註
 * - 包含「新增備註」按鈕和表單彈窗
 * - 當無備註時顯示預設提示訊息
 * - 適用於 CaseManageView 的備註區域
 *
 * 架構重構說明：
 * - 從原本 Core/Components/Note.swift 中提取
 * - 移動到 Features/Patient/Notes/Views/ 符合組件分類
 * - 使用 ObservedObject 以支援 iOS 16.0+
 */
struct NotesCard: View {
    let patient: Patient
    @ObservedObject private var noteStore = NoteStore.shared
    @Binding var showingAddNote: Bool
    
    private var patientNotes: [Note] {
        noteStore.getNotesForPatient(patient.id)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("備註")
                .font(.headline)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 15) {
                    if patientNotes.isEmpty {
                        // 顯示預設備註
                        NoteRow(note: Note(
                            id: "placeholder",
                            patientId: patient.id,
                            date: "YYYY.MM.DD",
                            content: "尚未新增備註"
                        ))
                        .allowsHitTesting(false)
                        .opacity(0.5)
                    } else {
                        ForEach(patientNotes) { note in
                            NoteRow(note: note)
                        }
                    }
                }
            }
            
            Spacer()
            Button(action: {
                showingAddNote = true
            }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("新增備註")
                }
                .foregroundColor(.blue)
            }
            Spacer()
        }
        .frame(maxHeight: 280)
        .padding(20)
        .background(Color.white)
        .cornerRadius(12)
        .sheet(isPresented: $showingAddNote) {
            EditNoteView(patientId: patient.id)
        }
    }
}
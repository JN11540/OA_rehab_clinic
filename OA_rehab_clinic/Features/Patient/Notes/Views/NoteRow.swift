import SwiftUI

/**
 * NoteRow - 單個備註列表項目組件
 *
 * 功能說明：
 * - 顯示單個備註的日期和內容
 * - 提供編輯和刪除功能按鈕
 * - 支援編輯表單彈窗和刪除確認對話框
 * - 整合 NoteStore 進行數據操作
 *
 * 架構重構說明：
 * - 從原本 Core/Components/Note.swift 中提取
 * - 移動到 Features/Patient/Notes/Views/ 符合組件分類
 * - 使用 ObservedObject 以支援 iOS 16.0+
 */
struct NoteRow: View {
    let note: Note
    @ObservedObject private var noteStore = NoteStore.shared
    @State private var showingEditSheet = false
    @State private var showingDeleteAlert = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(note.date)
                .font(.caption)
                .foregroundColor(.gray)
            
            Text(note.content)
            
            HStack {
                Spacer()
                Button(action: {
                    showingEditSheet = true
                }) {
                    Image(systemName: "pencil.circle")
                        .foregroundColor(.blue)
                }
                Button(action: {
                    showingDeleteAlert = true
                }) {
                    Image(systemName: "trash.circle")
                        .foregroundColor(.red)
                }
            }
            
            Divider()
        }
        .sheet(isPresented: $showingEditSheet) {
            EditNoteView(note: note)
        }
        .alert("確認刪除", isPresented: $showingDeleteAlert) {
            Button("取消", role: .cancel) {}
            Button("刪除", role: .destructive) {
                noteStore.deleteNote(note)
            }
        } message: {
            Text("確定要刪除這個備註嗎？")
        }
    }
}
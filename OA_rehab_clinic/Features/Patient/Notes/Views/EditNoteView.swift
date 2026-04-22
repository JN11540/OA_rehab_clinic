import SwiftUI

/**
 * EditNoteView - 備註編輯/新增表單組件
 *
 * 功能說明：
 * - 支援新增和編輯兩種模式
 * - 提供 TextEditor 供使用者輸入備註內容
 * - 自動生成日期戲記
 * - 整合 NoteStore 進行數據保存
 *
 * 初始化方式：
 * - init(patientId:) - 用於新增備註
 * - init(note:) - 用於編輯現有備註
 *
 * 架構重構說明：
 * - 從原本 Core/Components/Note.swift 中提取
 * - 移動到 Features/Patient/Notes/Views/ 符合組件分類
 * - 使用 ObservedObject 以支援 iOS 16.0+
 */
struct EditNoteView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject private var noteStore = NoteStore.shared
    @State private var noteContent: String
    private let note: Note?
    private let patientId: String
    
    // 用於新增備註
    init(patientId: String) {
        self.patientId = patientId
        self.note = nil
        _noteContent = State(initialValue: "")
    }
    
    // 用於編輯備註
    init(note: Note) {
        self.patientId = note.patientId
        self.note = note
        _noteContent = State(initialValue: note.content)
    }
    
    var body: some View {
        NavigationView {
            Form {
                TextEditor(text: $noteContent)
                    .frame(height: 100)
            }
            .navigationTitle(note == nil ? "新增備註" : "編輯備註")
            .navigationBarItems(
                leading: Button("取消") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("儲存") {
                    if !noteContent.isEmpty {
                        let formatter = DateFormatter()
                        formatter.dateFormat = "YYYY.MM.dd"
                        
                        if let existingNote = note {
                            // 編輯現有備註
                            let updatedNote = Note(
                                id: existingNote.id,
                                patientId: existingNote.patientId,
                                date: formatter.string(from: Date()),
                                content: noteContent
                            )
                            noteStore.updateNote(updatedNote)
                        } else {
                            // 新增備註
                            let newNote = Note(
                                id: UUID().uuidString,
                                patientId: patientId,
                                date: formatter.string(from: Date()),
                                content: noteContent
                            )
                            noteStore.addNote(newNote)
                        }
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            )
        }
    }
}
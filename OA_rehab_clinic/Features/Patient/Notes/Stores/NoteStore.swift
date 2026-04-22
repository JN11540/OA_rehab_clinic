import Foundation
import SwiftUI

/**
 * NoteStore - 備註數據管理中心
 *
 * 功能說明：
 * - 管理所有患者的備註數據，提供 CRUD 操作
 * - 使用 UserDefaults 進行本地數據持久化
 * - 採用單例模式，確保數據一致性
 * - 支援按患者ID篩選備註
 *
 * 架構重構說明：
 * - 從原本 Core/Components/Note.swift 的巨石檔案中提取
 * - 移動到 Features/Patient/Notes/Stores/ 符合功能模組化
 * - 使用 ObservableObject 以支援 iOS 16.0+
 */
class NoteStore: ObservableObject {
    static let shared = NoteStore()
    @Published private(set) var notes: [Note] = []
    
    private init() {
        loadNotes()
    }
    
    private func loadNotes() {
        if let data = UserDefaults.standard.data(forKey: "patientNotes"),
           let decodedNotes = try? JSONDecoder().decode([Note].self, from: data) {
            notes = decodedNotes
        }
    }
    
    private func saveNotes() {
        if let encoded = try? JSONEncoder().encode(notes) {
            UserDefaults.standard.set(encoded, forKey: "patientNotes")
        }
    }
    
    func getNotesForPatient(_ patientId: String) -> [Note] {
        return notes.filter { $0.patientId == patientId }
    }
    
    func addNote(_ note: Note) {
        notes.append(note)
        saveNotes()
    }
    
    func updateNote(_ note: Note) {
        if let index = notes.firstIndex(where: { $0.id == note.id }) {
            notes[index] = note
            saveNotes()
        }
    }
    
    func deleteNote(_ note: Note) {
        notes.removeAll { $0.id == note.id }
        saveNotes()
    }
}
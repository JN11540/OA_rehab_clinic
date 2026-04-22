import SwiftUI
import PhotosUI

// MARK: - Add Exercise View
public struct AddExerciseView: View {
    @Binding var isPresented: Bool
    @StateObject private var exerciseStore = ExerciseStore.shared
    
    @State private var name = ""
    @State private var englishName = ""
    @State private var selectedCategory = ExerciseModule.TrainingCategory.all
    @State private var selectedLevel = ""
    @State private var description = ""
    @State private var difficulty = ""
    @State private var selectedImage: UIImage?
    @State private var showingImagePicker = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    public init(isPresented: Binding<Bool>) {
        self._isPresented = isPresented
    }
    
    // 生成穩定的 UUID 函數 - 與 ExerciseSamples.swift 中的相同
    private func stableUUID(for name: String, category: String) -> UUID {
        // 將名稱和類別組合成一個字符串
        let combinedString = "\(name)_\(category)"
        
        // 計算字符串的哈希值
        var hasher = Hasher()
        hasher.combine(combinedString)
        let hashValue = hasher.finalize()
        
        // 使用哈希值創建一個穩定的 UUID
        // 我們使用 UUID 的版本 5 (SHA-1)，它允許我們基於名稱空間和名稱生成 UUID
        // 但由於 Swift 沒有直接支持這個功能，我們使用一個簡單的方法來模擬
        
        // 將哈希值轉換為 16 字節的數據
        var uuidBytes = withUnsafeBytes(of: hashValue) { Array($0) }
        // 確保有 16 字節
        while uuidBytes.count < 16 {
            uuidBytes.append(0)
        }
        if uuidBytes.count > 16 {
            uuidBytes = Array(uuidBytes.prefix(16))
        }
        
        // 設置 UUID 版本 (版本 4 - 隨機)
        uuidBytes[6] = (uuidBytes[6] & 0x0F) | 0x40
        // 設置 UUID 變體 (RFC 4122)
        uuidBytes[8] = (uuidBytes[8] & 0x3F) | 0x80
        
        // 創建 UUID
        let uuid = NSUUID(uuidBytes: uuidBytes)
        return uuid as UUID
    }
    
    public var body: some View {
        NavigationView {
            Form {
                Section(header: Text("基本資訊")) {
                    TextField("動作名稱", text: $name)
                    TextField("英文名稱", text: $englishName)
                    
                    Picker("分類", selection: $selectedCategory) {
                        ForEach(ExerciseModule.TrainingCategory.allCases, id: \.self) { category in
                            Text(category.rawValue).tag(category)
                        }
                    }
                    
                    TextField("難度等級", text: $selectedLevel)
                }
                
                Section(header: Text("動作說明")) {
                    VStack(alignment: .leading) {
                        Text("動作描述")
                            .font(.caption)
                            .foregroundColor(.gray)
                        TextEditor(text: $description)
                            .frame(height: 100)
                    }
                    
                    VStack(alignment: .leading) {
                        Text("完成標準")
                            .font(.caption)
                            .foregroundColor(.gray)
                        TextEditor(text: $difficulty)
                            .frame(height: 100)
                    }
                }
                
                Section(header: Text("動作圖片")) {
                    if let image = selectedImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 200)
                    }
                    
                    Button(action: {
                        showingImagePicker = true
                    }) {
                        HStack {
                            Image(systemName: "photo")
                            Text(selectedImage == nil ? "選擇圖片" : "更換圖片")
                        }
                    }
                }
            }
            .navigationTitle("新增動作")
            .navigationBarItems(
                leading: Button("取消") {
                    isPresented = false
                },
                trailing: Button("儲存") {
                    saveExercise()
                }
                .disabled(!isValid)
            )
            .alert("提示", isPresented: $showingAlert) {
                Button("確定", role: .cancel) {}
            } message: {
                Text(alertMessage)
            }
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(image: $selectedImage)
        }
    }
    
    private var isValid: Bool {
        !name.isEmpty && !englishName.isEmpty && selectedCategory != .all &&
                    !selectedLevel.isEmpty && !description.isEmpty && !difficulty.isEmpty &&
        !selectedLevel.isEmpty && selectedImage != nil
    }
    
    private func saveExercise() {
        guard let image = selectedImage else { return }
        
        let imageName = "exercise_\(UUID().uuidString)"
        let exercise = ExerciseModule.Exercise(
            id: stableUUID(for: name, category: selectedCategory.rawValue),
            name: name,
            englishName: englishName,
            imageName: imageName,
            category: selectedCategory.rawValue,
            level: selectedLevel,
            description: description,
            difficulty: difficulty
        )
        
        exerciseStore.addExercise(exercise, image: image)
        alertMessage = "動作已成功儲存"
        showingAlert = true
        
        // 延遲關閉視窗，讓使用者看到成功訊息
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            isPresented = false
        }
    }
} 
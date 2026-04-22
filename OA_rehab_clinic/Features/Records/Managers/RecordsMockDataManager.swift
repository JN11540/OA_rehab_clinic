import Foundation
import SwiftUI
import Combine

/**
 * RecordsMockDataManager - Records模擬數據統一管理器
 * 
 * 核心功能：
 * - 統一控制所有Records視圖的模擬數據顯示
 * - 整合現有的智能切換邏輯（不破壞現有機制）
 * - 提供Patient-GRDB自動連結功能
 * - 支援全局開關和局部覆蓋
 * - 環境感知（開發/生產環境自動適配）
 * 
 * 設計原則：
 * - 最小侵入：現有視圖邏輯100%保持不變
 * - 增強控制：在現有機制基礎上添加全局控制層
 * - 智能決策：維持現有的自動切換邏輯
 * - 向後兼容：所有現有API和行為完全保持
 */
class RecordsMockDataManager: ObservableObject {
    static let shared = RecordsMockDataManager()
    
    // MARK: - 全局模擬數據控制
    @Published var globalMockDataEnabled: Bool {
        didSet {
            UserDefaults.standard.set(globalMockDataEnabled, forKey: "recordsGlobalMockDataEnabled")
            
            // 發送通知給所有Records視圖
            NotificationCenter.default.post(
                name: .recordsMockDataSettingChanged, 
                object: nil,
                userInfo: ["enabled": globalMockDataEnabled]
            )
            
            print("🔄 Records全局模擬數據設置變更: \(globalMockDataEnabled)")
        }
    }
    
    // MARK: - 當前患者管理
    @Published var currentPatient: Patient? {
        didSet {
            if let patient = currentPatient {
                checkPatientDataAvailability(patient)
                
                // 通知所有視圖患者已切換
                NotificationCenter.default.post(
                    name: .currentPatientChanged, 
                    object: nil,
                    userInfo: ["patient": patient]
                )
                
                print("👤 當前患者切換: \(patient.name)")
            }
        }
    }
    
    // MARK: - 患者數據可用性
    @Published var hasRealTrainingData: Bool = false
    @Published var hasRealAssessmentData: Bool = false
    
    // MARK: - 環境檢測
    private var isDevelopment: Bool {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }
    
    var isProduction: Bool {
        return !isDevelopment
    }
    
    private init() {
        // 🛠️ 開發期間臨時設定：強制開啟模擬數據
        let forceEnableForDevelopment = true  // 設為 false 可恢復正常邏輯
        
        if forceEnableForDevelopment {
            self.globalMockDataEnabled = true
            print("🛠️ 開發期間強制開啟模擬數據")
        } else {
            // 正常的環境檢測邏輯
            #if DEBUG
            let defaultValue = true // 開發環境預設開啟
            #else
            let defaultValue = false // 生產環境預設關閉
            #endif
            
            self.globalMockDataEnabled = UserDefaults.standard.object(forKey: "recordsGlobalMockDataEnabled") as? Bool ?? defaultValue
            
            // 生產環境強制關閉
            if isProduction {
                globalMockDataEnabled = false
            }
        }
        
        // 詳細的初始化狀態報告
        let savedValue = UserDefaults.standard.object(forKey: "recordsGlobalMockDataEnabled") as? Bool
        print("🔧 RecordsMockDataManager 初始化")
        print("   - 編譯環境: \(isDevelopment ? "開發 (DEBUG)" : "生產 (RELEASE)")")
        
        if forceEnableForDevelopment {
            print("   - 開發模式: 強制開啟")
        } else {
            #if DEBUG
            let displayDefaultValue = true
            #else
            let displayDefaultValue = false
            #endif
            print("   - 環境預設值: \(displayDefaultValue)")
        }
        
        print("   - UserDefaults 儲存值: \(savedValue?.description ?? "無儲存值")")
        print("   - 最終全局模擬數據狀態: \(globalMockDataEnabled ? "✅ 開啟" : "❌ 關閉")")
        
        if !forceEnableForDevelopment && isProduction && (savedValue == true) {
            print("⚠️ 注意：生產環境強制關閉模擬數據，忽略 UserDefaults 中的 true 設定")
        }
    }
    
    // MARK: - 患者數據檢查
    private func checkPatientDataAvailability(_ patient: Patient) {
        // 檢查訓練數據 - 整合 GRDB 和 UserDefaults
        let userDefaultsTrainingRecords = RecordStore.shared.getTrainingRecords(for: patient.id)
        
        // 檢查 GRDB 數據（使用 try? 處理可能的錯誤）
        let grdbTrainingResults = (try? TrainingResultDatabase.shared.getTrainingResults(for: patient.id)) ?? []
        hasRealTrainingData = !userDefaultsTrainingRecords.isEmpty || !grdbTrainingResults.isEmpty
        
        // 檢查評估數據 - 檢查所有評估類型
        let assessmentTypes: [AssessmentType] = [.womac, .koos, .sf36, .chairTest, .kneeRaise, .singleLegStand]
        
        // 計算新的數據狀態
        let newTrainingDataStatus = !userDefaultsTrainingRecords.isEmpty || !grdbTrainingResults.isEmpty
        let newAssessmentDataStatus = assessmentTypes.contains { type in
            let records = RecordStore.shared.getAssessmentProgress(
                patientId: patient.id,
                type: type,
                startDate: Calendar.current.date(byAdding: .month, value: -12, to: Date()) ?? Date(),
                endDate: Date()
            )
            return !records.isEmpty
        }
        
        // 只在狀態變化時輸出
        if hasRealTrainingData != newTrainingDataStatus || hasRealAssessmentData != newAssessmentDataStatus {
            print("📊 患者數據檢查結果:")
            print("   - 患者: \(patient.name)")
            print("   - 有真實訓練數據: \(newTrainingDataStatus) (UserDefaults: \(!userDefaultsTrainingRecords.isEmpty), GRDB: \(!grdbTrainingResults.isEmpty))")
            print("   - 有真實評估數據: \(newAssessmentDataStatus)")
        }
        
        // 更新狀態
        hasRealTrainingData = newTrainingDataStatus
        hasRealAssessmentData = newAssessmentDataStatus
    }
    
    // MARK: - 智能決策接口
    
    /**
     * 決定是否在訓練視圖中使用模擬數據
     * 整合現有邏輯：全局設置 + 數據可用性 + 局部覆蓋
     */
    func shouldUseTrainingMockData(localOverride: Bool? = nil) -> Bool {
        // 1. 檢查全局強制開啟（開發期間使用）
        if globalMockDataEnabled {
            print("✅ 全局開啟模擬數據")
        }
        
        // 2. 生產環境檢查（但允許開發期間覆蓋）
        if isProduction && !globalMockDataEnabled {
            if localOverride == true {
                print("🔒 生產環境強制禁用模擬數據（忽略局部覆蓋）")
            }
            return false
        }
        
        // 3. 如果有局部覆蓋，優先使用
        if let override = localOverride {
            print("🎯 使用局部覆蓋決策: \(override)")
            return override
        }
        
        // 4. 全局禁用時不使用
        if !globalMockDataEnabled {
            print("⏹️ 全局設置禁用模擬數據")
            return false
        }
        
        // 5. 有真實數據時優先使用真實數據（智能切換）
        if hasRealTrainingData {
            print("✅ 檢測到真實訓練數據，使用真實數據")
            return false
        }
        
        // 6. 最終：全局允許且無真實數據時使用模擬數據
        print("🎲 無真實數據，使用模擬數據")
        return true
    }
    
    /**
     * 決定是否在評估視圖中使用模擬數據
     */
    func shouldUseAssessmentMockData(localOverride: Bool? = nil) -> Bool {
        // 1. 檢查全局強制開啟（開發期間使用）
        if globalMockDataEnabled {
            print("✅ 評估數據全局開啟模擬數據")
        }
        
        // 2. 生產環境檢查（但允許開發期間覆蓋）
        if isProduction && !globalMockDataEnabled {
            if localOverride == true {
                print("🔒 生產環境強制禁用評估模擬數據（忽略局部覆蓋）")
            }
            return false
        }
        
        // 3. 如果有局部覆蓋，優先使用
        if let override = localOverride {
            print("🎯 評估數據使用局部覆蓋決策: \(override)")
            return override
        }
        
        // 4. 全局禁用時不使用
        if !globalMockDataEnabled {
            print("⏹️ 全局設置禁用評估模擬數據")
            return false
        }
        
        // 5. 有真實數據時優先使用真實數據（智能切換）
        if hasRealAssessmentData {
            print("✅ 檢測到真實評估數據，使用真實數據")
            return false
        }
        
        // 6. 最終：全局允許且無真實數據時使用模擬數據
        print("🎲 無真實評估數據，使用模擬數據")
        return true
    }
    
    // MARK: - 開發者工具
    func toggleGlobalMockData() {
        if isProduction {
            print("⚠️ 生產環境無法切換模擬數據狀態")
            return
        }
        globalMockDataEnabled.toggle()
        print("🔄 手動切換模擬數據狀態為: \(globalMockDataEnabled ? "開啟" : "關閉")")
    }
    
    func forceEnableMockData() {
        if isProduction {
            print("⚠️ 生產環境無法強制開啟模擬數據")
            return
        }
        globalMockDataEnabled = true
        print("✅ 手動強制開啟模擬數據")
    }
    
    func forceDisableMockData() {
        globalMockDataEnabled = false
        print("❌ 手動強制關閉模擬數據")
    }
    
    func resetToDefaults() {
        #if DEBUG
        globalMockDataEnabled = true
        print("🔄 重置為開發環境預設值: 開啟")
        #else
        globalMockDataEnabled = false
        print("🔄 重置為生產環境預設值: 關閉")
        #endif
    }
    
    // MARK: - 調試信息
    func printCurrentStatus() {
        print("📋 RecordsMockDataManager 當前狀態:")
        print("   - 全局模擬數據啟用: \(globalMockDataEnabled)")
        print("   - 當前患者: \(currentPatient?.name ?? "未選擇")")
        print("   - 有真實訓練數據: \(hasRealTrainingData)")
        print("   - 有真實評估數據: \(hasRealAssessmentData)")
        print("   - 環境: \(isDevelopment ? "開發" : "生產")")
        print("   - UserDefaults 設定: \(UserDefaults.standard.object(forKey: "recordsGlobalMockDataEnabled") ?? "未設定")")
    }
    
    // MARK: - 狀態查詢
    var currentStatus: String {
        return globalMockDataEnabled ? "開啟" : "關閉"
    }
    
    /// 立即檢查並打印當前狀態（用於調試）
    func checkCurrentState() {
        let savedValue = UserDefaults.standard.object(forKey: "recordsGlobalMockDataEnabled") as? Bool
        print("\n🔍 RecordsMockDataManager 即時狀態檢查:")
        print("   - 當前時間: \(Date())")
        print("   - 編譯環境: \(isDevelopment ? "開發 (DEBUG)" : "生產 (RELEASE)")")
        print("   - UserDefaults 當前值: \(savedValue?.description ?? "無儲存值")")
        print("   - globalMockDataEnabled: \(globalMockDataEnabled)")
        print("   - 實際狀態: \(globalMockDataEnabled ? "✅ 開啟" : "❌ 關閉")")
        print("   - 當前患者: \(currentPatient?.name ?? "未設置")")
        print("   - 有真實訓練數據: \(hasRealTrainingData)")
        print("   - 有真實評估數據: \(hasRealAssessmentData)")
        
        // 檢查決策邏輯
        print("\n🎯 決策邏輯檢查:")
        print("   - 訓練模擬數據決策: \(shouldUseTrainingMockData() ? "使用模擬數據" : "不使用模擬數據")")
        print("   - 評估模擬數據決策: \(shouldUseAssessmentMockData() ? "使用模擬數據" : "不使用模擬數據")")
        print("")
    }
    
    // MARK: - Patient-GRDB 連結增強
    
    /**
     * 載入患者的所有GRDB數據
     * 確保模擬數據管理器能準確判斷數據可用性
     */
    func loadPatientGRDBData(_ patient: Patient) {
        Task {
            do {
                // 在背景執行數據庫查詢
                let trainingResults = try TrainingResultDatabase.shared.getTrainingResults(for: patient.id)
                
                await MainActor.run {
                    let hasGRDBData = !trainingResults.isEmpty
                    if hasGRDBData {
                        hasRealTrainingData = true
                        print("🗄️ 從GRDB載入患者 \(patient.name) 的訓練數據: \(trainingResults.count) 條記錄")
                    }
                }
            } catch {
                await MainActor.run {
                    print("⚠️ 載入患者 \(patient.name) GRDB數據時發生錯誤: \(error)")
                }
            }
        }
    }
    
    /**
     * 預載入患者數據（在患者選擇時調用）
     */
    func preloadPatientData(_ patient: Patient) {
        currentPatient = patient
        loadPatientGRDBData(patient)
    }
}

// MARK: - 通知名稱擴展
extension Notification.Name {
    /// Records模擬數據設置變更通知
    static let recordsMockDataSettingChanged = Notification.Name("recordsMockDataSettingChanged")
    
    /// 當前患者切換通知
    static let currentPatientChanged = Notification.Name("currentPatientChanged")
}

// MARK: - 開發調試擴展
#if DEBUG
extension RecordsMockDataManager {
    /// 開發環境專用：強制設置患者數據狀態（用於測試）
    func setMockPatientDataStatus(hasTraining: Bool, hasAssessment: Bool) {
        hasRealTrainingData = hasTraining
        hasRealAssessmentData = hasAssessment
        print("🧪 測試設置 - 訓練數據: \(hasTraining), 評估數據: \(hasAssessment)")
    }
    
    /// 開發環境專用：重置所有狀態
    func resetForTesting() {
        globalMockDataEnabled = true
        currentPatient = nil
        hasRealTrainingData = false
        hasRealAssessmentData = false
        print("🧪 已重置所有測試狀態")
    }
}
#endif
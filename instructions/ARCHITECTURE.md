# OA 復健診所 iOS 應用程式架構文檔

## 專案概述

**OA_rehab_clinic** 是專為醫生和物理治療師設計的 iPad 應用程式，用於骨關節炎患者的復健運動管理。

- **平台**: iOS 16.0+, iPad 專用（橫向模式）
- **技術**: Swift + SwiftUI, MVVM + Observable 架構
- **功能**: 患者管理、運動計劃、訓練排程、績效追蹤

## 系統架構

### 分層架構
```
App Layer (應用入口)
    ↓
Features Layer (功能模組)
├── Auth          # 用戶認證
├── Patient       # 患者管理
├── Exercise      # 運動模組
├── TrainingMenu  # 訓練菜單與排程
└── Records       # 訓練與評估記錄
    ↓
Core Layer (共用組件)
├── Components    # UI 組件
├── Theme        # 色彩主題
└── Utils        # 工具函數
    ↓
Data Layer (資料存儲)
```

## 功能模組詳細架構

### 1. Auth 模組
```
Auth/
├── WelcomeView.swift       # 歡迎頁面
├── LoginView.swift         # 登入介面
├── UserProfileView.swift   # 用戶檔案
├── InfoView.swift          # 資訊頁面
└── UserModel.swift         # 用戶資料模型
```

### 2. Patient 模組
```
Patient/
├── CasesView.swift                    # 病例列表
├── CaseManageView.swift               # 病例管理
├── AddPatientView.swift               # 新增患者
├── PatientUserProfileView.swift       # 患者檔案
├── Components/                        # 患者相關組件
├── Notes/                             # 筆記系統
│   ├── Models/Note.swift
│   ├── Stores/NoteStore.swift
│   └── Views/                         # 筆記相關視圖
└── MockData/Patient.swift             # 模擬資料
```

### 3. Exercise 模組
```
Exercise/
├── ExerciseModule.swift               # 運動模組核心
├── ExerciseStore.swift                # 運動資料存儲
├── ExerciseParameters.swift           # 運動參數
├── ExerciseParameterCard.swift        # 參數卡片 UI
├── ExerciseSamples.swift              # 樣本資料
├── ExerciseCard.swift                 # 運動卡片 UI
├── ExerciseConstants.swift            # 運動常數
├── ExerciseEdit/                      # 運動編輯子模組
│   ├── AddExerciseView.swift
│   ├── ExerciseDropZone.swift
│   └── ImagePicker.swift
└── ExerciseList/                      # 運動列表子模組
    ├── CategoryMenu.swift
    ├── ExerciseListCard.swift
    ├── ExerciseSectionView.swift
    └── SubcategoryView.swift
```

### 4. TrainingMenu 模組 (重構架構)

**重構成果** (2025年重構):
- **代碼縮減**: 主視圖從 1,575 行縮減至 495 行 (減少 68%)
- **MVVM 分離**: 引入專門的 ViewModels 和 Services
- **組件化**: 創建可重用的 UI 組件

```
TrainingMenu/
├── ViewModels/                        # MVVM 視圖模型層
│   ├── CalendarSchedulingViewModel.swift     # 主協調器 (365行)
│   ├── TrainingSchedulingViewModel.swift     # 訓練排程邏輯 (463行)
│   ├── AssessmentSchedulingViewModel.swift   # 評估排程邏輯 (209行)
│   └── CalendarUIStateManager.swift          # UI 狀態管理 (125行)
├── Services/                          # 業務邏輯服務層
│   ├── ScheduleConflictService.swift         # 排程衝突檢測 (344行)
│   └── DateRangeService.swift                # 日期範圍管理 (205行)
├── Views/Components/                  # 組件化 UI 層
│   ├── MenuSelection/                 # 菜單選擇組件
│   │   ├── MenuSelectionCard.swift
│   │   ├── MenuEditCard.swift
│   │   ├── TrainingMenuEditSheet.swift
│   │   ├── CompactExerciseListItem.swift
│   │   └── TrainingListCard.swift
│   ├── SchedulingTab/                 # 排程標籤組件
│   │   ├── TrainingSchedulingView.swift
│   │   └── AssessmentSchedulingView.swift
│   └── AssessmentSelectionCard.swift
├── EditTrainingCalendarView.swift     # 主要月曆編輯視圖 (495行)
├── MenuManagementView.swift           # 菜單管理視圖 (802行)
├── EditTrainingMenuView.swift         # 訓練菜單編輯 (176行)
├── TrainingMenu.swift                 # 訓練菜單模型 (177行)
└── TrainingSchedule.swift             # 訓練排程模型 (164行)
```

**主要功能**:
- 訓練菜單建立和編輯
- 訓練與評估排程管理
- 排程衝突檢測和解決
- 日曆視圖整合和互動
- 月度排程匯出功能

### 5. Records 模組 (訓練績效追蹤)

```
Records/
├── TrainingRecordView.swift           # 主容器視圖 (196行)
├── Managers/                          # 統一管理器
│   └── RecordsMockDataManager.swift          # 模擬數據統一管理器 (376行)
├── Models/                            # 資料模型
│   ├── RecordModels.swift
│   ├── ClinicArrangeData.swift
│   └── AssessmentTypes.swift
├── Stores/                            # 資料存儲
│   ├── AssessmentStore.swift
│   └── MockAssessmentData.swift
├── Database/                          # 資料庫層
│   ├── TrainingResultDatabase.swift
│   ├── DatabaseMigration.swift
│   └── ResultDataProcessor.swift
├── Training/                          # 訓練記錄模組
│   ├── Components/                    # 訓練組件
│   │   ├── PerformanceChartCard.swift        # 績效圖表卡片 (393行)
│   │   ├── TherapistSettingsCard.swift      # 治療師參數卡片 (355行)
│   │   ├── DailySessionHeaderCard.swift     # 單日訓練概況標題 (217行)
│   │   ├── ExerciseDetailCard.swift         # 動作詳細資訊卡片 (447行)
│   │   ├── ExerciseToggleGrid.swift         # 動作選擇Toggle網格 (267行)
│   │   └── EmptyMetricsView.swift           # 統一空白指標視圖 (289行)
│   ├── Views/                         # 訓練視圖
│   │   ├── PerformanceChangeView.swift       # 績效變化視圖 (405行)
│   │   └── DailyPerformanceView.swift        # 每日績效視圖 (391行)
│   ├── Models/                        # 訓練模型
│   │   ├── TrainingPerformanceModels.swift
│   │   └── AllExerciseTypes.swift            # 完整動作配置模型 (334行)
│   └── Stores/                        # 訓練資料存儲
│       └── MockTrainingData.swift            # 智能模擬數據生成器 (817行)
├── Assessment/                        # 評估記錄模組
│   ├── Components/                    # 評估組件
│   ├── Questionnaires/               # 問卷調查
│   └── Views/                        # 評估視圖
└── Shared/                           # 共用組件
    └── Calendar/                     # 日曆容器
        ├── TrainingCalendarContainer.swift
        └── AssessmentCalendarContainer.swift
```

**Records 模組核心功能**:
- **統一模擬數據管理**: RecordsMockDataManager 提供全局控制和智能切換
- **智能數據管理**: 真實數據優先，無數據時自動切換模擬數據
- **五項核心指標**: 肌力、穩定度、規律性、反應時間、完成度
- **標準化評分系統**: 統一0-100分正向評分，反應時間標準化處理
- **模組化UI組件**: 可重用的卡片式設計，支援折疊展開
- **滑動窗口圖表**: 支援大量數據的分頁瀏覽和手勢操作
- **智能模擬數據**: 基於真實菜單架構生成7天進步趨勢數據

## Core 模組架構

### Components 模組
```
Components/
├── Buttons/                   # 按鈕組件
│   └── TabButton.swift
├── Cards/                     # 卡片組件
│   └── PatientInfoCard.swift
├── Forms/                     # 表單組件
│   ├── CalendarActionButton.swift
│   └── InfoField.swift
├── Calendar/                  # 日曆組件
│   ├── BaseCalendarView.swift
│   ├── DateRangeGesture.swift
│   └── _deprecated/
├── GradientBackground.swift   # 漸層背景
└── NavigationHeader.swift     # 導航標頭
```

### Theme 模組
```
Theme/
└── AppColors.swift           # 色彩方案定義
```

### Utils 模組
```
Utils/
├── CalendarExtensions.swift  # 日曆擴展
└── FileShareManager.swift    # 檔案分享管理
```

## 資料模型架構

### 核心資料模型

```swift
// 患者模型
struct Patient {
    let id: String
    var name: String
    var gender: Gender
    var dateOfBirth: Date
    var medicalHistory: [MedicalRecord]
}

// 訓練菜單模型
struct TrainingMenu {
    let id: UUID
    var title: String
    var isExclusive: Bool        // 專屬/共通
    var exercises: [ExerciseParameters]
    var timeSlots: Set<String>   // 時段
    var selectedColor: Color     // 標示顏色
    var patientId: String?
}

// 訓練績效指標
struct TrainingPerformanceMetrics {
    let muscleStrength: Double   // 肌力 (0-100)
    let stability: Double        // 穩定度 (0-100)
    let regularity: Double       // 規律性 (0-100)
    let reactionTime: Double     // 反應時間 (毫秒)
    let completionRate: Double   // 完成度 (0-100)
}

// 治療師設定參數
struct TherapistSettings {
    let exerciseName: String
    let sets: Int               // 組數
    let repetitions: Int        // 次數
    let restTime: Int           // 休息時間
    let mvic: Int?              // MVIC百分比
    let stimulation: Bool       // 電刺激開關
}
```

## 狀態管理架構

### Observable 模式
使用 SwiftUI 的 `@Observable` 和 `ObservableObject` 進行狀態管理：

```swift
// iOS 17.0+ 新特性
@Observable
final class ExerciseStore {
    var exercises: [Exercise] = []
}

// iOS 16.0+ 相容性
class TrainingMenuStore: ObservableObject {
    @Published var menus: [TrainingMenu] = []
}
```

### MVVM 架構模式
```
View → ViewModel (@ObservableObject) → Model → Data Layer
  ↑                                            ↓
  ←────────── State Update ←──────────────────
```

## 重要架構決策

### TrainingMenu ViewModels 重構 (2025年)
- **問題**: 單一 ViewModel 過於龐大 (1,575行)
- **解決方案**: 拆分為四個專門的組件
  - `CalendarSchedulingViewModel`: 主協調器
  - `TrainingSchedulingViewModel`: 訓練排程邏輯
  - `AssessmentSchedulingViewModel`: 評估排程邏輯
  - `CalendarUIStateManager`: UI 狀態管理
- **效果**: 代碼可維護性大幅提升，職責分離清晰

### Records 模組設計原則
- **數據視覺化優先**: 五項核心指標的圖表呈現
- **滑動窗口技術**: 處理大量歷史數據的性能優化
- **模擬數據整合**: 開發和演示階段的數據支援
- **組件化設計**: 可重用的圖表和參數顯示組件

### 統一模擬數據管理系統 (2025年)
- **問題**: Records 各視圖模擬數據控制分散，缺乏統一管理
- **解決方案**: 實作 `RecordsMockDataManager` 統一控制系統
  - **零破壞性整合**: 保持現有邏輯100%不變，僅添加全局控制層
  - **智能決策邏輯**: 真實數據優先 → 全局設置檢查 → 局部覆蓋支援
  - **環境感知配置**: 開發環境預設開啟，生產環境強制關閉
  - **患者感知管理**: 自動檢查患者真實數據可用性 (GRDB + UserDefaults)
  - **通知驅動同步**: 狀態變更自動同步所有 Records 視圖
- **效果**: 開發調試更便利，數據展示更一致，生產環境更安全

## 開發指導原則

### 新菜單預設值
- **時段**: 預設選擇所有時段 (早中下晚)
- **顏色**: 預設使用第一個顏色選項而非粉色
- **類型**: 根據建立位置自動設定專屬/共通屬性

### ViewModels 架構指導
- **單一職責**: 每個 ViewModel 專注特定業務領域
- **依賴注入**: 通過初始化注入必要的服務和狀態管理器
- **響應式設計**: 使用 `@Published` 確保 UI 自動更新
- **協調器模式**: 使用主 ViewModel 協調多個子 ViewModel

### UI/UX 設計原則
- **iPad 優化**: 專為橫向模式設計的佈局
- **醫療專業**: 符合醫療環境的專業界面
- **互動性**: 支援手勢操作和即時反饋
- **可訪問性**: 支援動態字體和輔助功能

---

此架構文檔提供了 OA 復健診所 iOS 應用程式的最新技術架構概覽，反映了重構後的模組化設計和績效追蹤功能的完整實現。 
import SwiftUI

/**
 * TrainingRecordView - 訓練與評量歷史紀錄的主容器/路由視圖
 * 
 * 功能描述：
 * - 作為Records系統的主要容器，管理四個內容視圖的切換
 * - 提供雙層標籤系統：主標籤（訓練/評量）+ 詳細標籤（變化/每日）
 * - 負責UI布局管理，包括患者資訊卡片和內容區域
 * - 路由不同的內容視圖組合，但不包含具體的內容實現
 * 
 * 四個內容視圖組合：
 * 1. 訓練紀錄 + 檢視動作表現變化 → PerformanceChangeContent
 * 2. 訓練紀錄 + 檢視當日動作表現 → DailyPerformanceContent
 * 3. 評量紀錄 + 檢視評量結果變化 → ResultChangeContent
 * 4. 評量紀錄 + 檢視當日評量結果 → DailyResultContent
 * 
 * 注意：這是一個純粹的容器/路由視圖，不應包含任何業務邏輯或數據處理
 */
struct TrainingRecordView: View {
    // MARK: - Properties
    let patient: Patient // 患者資訊，用於傳遞給子視圖
    @EnvironmentObject private var userModel: UserModel // 用戶模型，管理當前登入狀態
    @EnvironmentObject private var scheduleStore: TrainingScheduleStore // 訓練排程資料
    @EnvironmentObject private var menuStore: TrainingMenuStore // 訓練菜單資料
    @StateObject private var mockDataManager = RecordsMockDataManager.shared // 統一模擬數據管理器
    @State private var selectedMainTab: MainTab // 主標籤狀態（訓練/評量）
    @State private var selectedDetailTab: DetailTab // 詳細標籤狀態（變化/每日）
    
    // 固定的布局常量
    private let gridColumns = 5
    private let patientCardHeight: CGFloat = UIScreen.main.bounds.height / 5 // 與 CaseManageView 一致
    private let contentHeight: CGFloat = 450 // 與其他卡片保持一致
    private let contentSpacing: CGFloat = 4 // 減少間距使布局更緊湊
    
    // MARK: - Tab Enums
    enum MainTab {
        case training    // 訓練紀錄主標籤
        case assessment  // 評量紀錄主標籤
    }
    
    enum DetailTab {
        case change // 檢視變化趨勢（圖表視圖）
        case daily  // 檢視當日詳細資料（日曆視圖）
    }
    
    // MARK: - Initializer
    // 初始化方法，允許從外部設置初始標籤狀態
    // 用於支援從ActionButtonsCard等外部視圖直接導航到特定標籤
    init(patient: Patient, initialMainTab: MainTab = .training) {
        self.patient = patient
        _selectedMainTab = State(initialValue: initialMainTab)
        _selectedDetailTab = State(initialValue: .daily) // 預設顯示當日詳細視圖
    }
    
    var body: some View {
        NavigationStack {
            mainContent
        }
    }
    
    private var mainContent: some View {
        ZStack {
            // Background
            GradientBackground(
                startColor: Color(red: 0.47, green: 0.84, blue: 0.98),
                endColor: Color(red: 0.72, green: 0.89, blue: 0.59)
            )
            .ignoresSafeArea(edges: .all)
            
            VStack(spacing: 20) {
                // Header
                NavigationHeader(
                    patient: patient,
                    pageTitle: "歷史紀錄"
                )
                
                contentGrid
            }
        }
        .onAppear {
            // 在主容器層面設置當前患者到統一管理器
            mockDataManager.currentPatient = patient
            
            // 檢查當前模擬數據狀態
            mockDataManager.checkCurrentState()
        }
        .environmentObject(mockDataManager) // 將統一管理器傳遞給所有子視圖
    }
    
    private var contentGrid: some View {
        Grid(alignment: .leading, horizontalSpacing: contentSpacing, verticalSpacing: contentSpacing) {
            // Patient Info Row
            GridRow {
                PatientInfoCard(patient: patient)
                    .gridCellColumns(gridColumns)
                    .frame(height: patientCardHeight)
            }
            
            // Content Area
            GridRow {
                contentArea
            }
        }
        .padding(.horizontal, 30)
    }
    
    private var contentArea: some View {
        VStack(spacing: 0) {
            tabButtons
            
            // MARK: - Content Area Router
            // 根據標籤組合路由到對應的內容視圖
            Group {
                switch (selectedMainTab, selectedDetailTab) {
                case (.training, .change):
                    // 訓練表現變化趨勢圖表（Views/Training/PerformanceChangeView.swift）
                    PerformanceChangeView(patient: patient)
                case (.training, .daily):
                    // 每日訓練詳細資料with日曆（Views/Training/DailyPerformanceView.swift）
                    DailyPerformanceView(patient: patient)
                case (.assessment, .change):
                    // 評量結果變化趨勢圖表（Views/Assessment/ResultChangeView.swift）
                    ResultChangeView(patient: patient)
                case (.assessment, .daily):
                    // 每日評量詳細資料with日曆（Views/Assessment/DailyResultView.swift）
                    DailyResultView(patient: patient)
                }
            }
            .frame(height: contentHeight)
        }
        .background(.opacity(0))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
        .gridCellColumns(gridColumns)
        .padding(.vertical, 0)
    }
    
    private var tabButtons: some View {
        HStack(spacing: contentSpacing) {
            // Left Buttons
            HStack(spacing: 10) {
                TabButton(
                    title: "訓練紀錄",
                    isSelected: selectedMainTab == .training,
                    action: {
                        withAnimation {
                            selectedMainTab = .training
                            selectedDetailTab = .daily
                        }
                    }
                )
                
                TabButton(
                    title: "評量紀錄",
                    isSelected: selectedMainTab == .assessment,
                    action: {
                        withAnimation {
                            selectedMainTab = .assessment
                            selectedDetailTab = .daily
                        }
                    }
                )
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            Spacer()
            
            // Right Buttons
            HStack(spacing: 10) {
                TabButton(
                    title: selectedMainTab == .training ? "檢視當日動作表現" : "檢視當日評量結果",
                    isSelected: selectedDetailTab == .daily,
                    action: {
                        withAnimation {
                            selectedDetailTab = .daily
                        }
                    }
                )
                
                TabButton(
                    title: selectedMainTab == .training ? "檢視動作表現變化" : "檢視評量結果變化",
                    isSelected: selectedDetailTab == .change,
                    action: {
                        withAnimation {
                            selectedDetailTab = .change
                        }
                    }
                )
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .frame(height: 44)
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
    }
}

#Preview {
    TrainingRecordView(patient: Patient.sample)
        .environmentObject(TrainingScheduleStore.shared)
        .environmentObject(TrainingMenuStore.shared)
        .environmentObject(UserModel.shared)
} 

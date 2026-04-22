import SwiftUI

/**
 * DailyResultView.swift - 每日評量詳細資料視圖
 * 
 * 功能：
 * - 左側：評量toggle區域，顯示最近三次分數和詳細問卷
 * - 右側：CalendarCard日曆組件，顯示評量排程和完成狀態
 * - 支援展開/折疊查看WOMAC問卷詳細內容
 * 
 * 重構說明：
 * 從 AssessmentContentViews.swift 中提取的 DailyResultContent
 * 重命名為 DailyResultView 以保持命名一致性
 * 
 * UI設計：
 * - 折疊狀態：緊湊顯示最近三次評量分數
 * - 展開狀態：顯示選中日期的完整問卷內容
 * - 互斥展開：同時只有一個量表可以展開
 * - 固定高度：避免影響下方Tab按鈕
 * - 動態高度：根據展開狀態調整容器高度
 */

struct DailyResultView: View {
    let patient: Patient
    @StateObject private var recordStore = RecordStore.shared
    @EnvironmentObject private var scheduleStore: TrainingScheduleStore
    @EnvironmentObject private var menuStore: TrainingMenuStore
    @EnvironmentObject private var userModel: UserModel
    @State private var selectedDate = Date()
    @State private var expandedToggle: ToggleType? = nil
    
    // 定義Toggle類型枚舉
    enum ToggleType: CaseIterable {
        case womac
        case koos
        case sf36
        case chairTest
        case kneeRaise
        case singleLegStand
        
        var title: String {
            switch self {
            case .womac: return "WOMAC"
            case .koos: return "KOOS"
            case .sf36: return "SF-36"
            case .chairTest: return "椅子坐站測試"
            case .kneeRaise: return "原地站立抬膝"
            case .singleLegStand: return "開眼單足站立"
            }
        }
    }
    
    var body: some View {
        HStack(alignment: .center, spacing: 0) {
            // Content Area (Left Side) - 評量Toggle區域
            VStack(spacing: 0) {
                // 日期顯示區域
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("評量結果")
                            .font(.title2)
                            .fontWeight(.bold)
                        Text("選擇日期：\(selectedDate, style: .date)")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 8)
                .background(Color.gray.opacity(0.05))
                
                ScrollViewReader { proxy in
                ScrollView(.vertical, showsIndicators: true) {
                    VStack(alignment: .leading, spacing: 8) {
                        // WOMAC 評量Toggle
                        AssessmentToggleView(
                            patient: patient,
                            selectedDate: selectedDate,
                            isExpanded: .constant(expandedToggle == .womac),
                            onToggle: {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    expandedToggle = expandedToggle == .womac ? nil : .womac
                                }
                            }
                        )
                        .environmentObject(recordStore)
                        .id("womac-toggle")
                        
                        // KOOS 評量Toggle  
                        KOOSAssessmentToggleView(
                            patient: patient,
                            selectedDate: selectedDate,
                            isExpanded: .constant(expandedToggle == .koos),
                            onToggle: {
                                let newToggleState: ToggleType? = expandedToggle == .koos ? nil : .koos
                                
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    expandedToggle = newToggleState
                                }
                                
                                // 當KOOS展開時，自動滾動讓KOOS置頂
                                if newToggleState == .koos {
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                                        withAnimation(.easeInOut(duration: 0.5)) {
                                            proxy.scrollTo("koos-toggle", anchor: .top)
                                        }
                                    }
                                }
                            }
                        )
                        .environmentObject(recordStore)
                        .id("koos-toggle")
                        
                        // SF-36 評量Toggle  
                        SF36AssessmentToggleView(
                            patient: patient,
                            selectedDate: selectedDate,
                            isExpanded: .constant(expandedToggle == .sf36),
                            onToggle: {
                                let newToggleState: ToggleType? = expandedToggle == .sf36 ? nil : .sf36
                                
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    expandedToggle = newToggleState
                                }
                                
                                // 當SF-36展開時，自動滾動讓SF-36置頂
                                if newToggleState == .sf36 {
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                                        withAnimation(.easeInOut(duration: 0.5)) {
                                            proxy.scrollTo("sf36-toggle", anchor: .top)
                                        }
                                    }
                                }
                            }
                        )
                        .environmentObject(recordStore)
                        .id("sf36-toggle")
                        
                        // 椅子坐站測試Toggle
                        ChairTestToggleView(
                            patient: patient,
                            selectedDate: selectedDate,
                            isExpanded: .constant(expandedToggle == .chairTest),
                            onToggle: {
                                let newToggleState: ToggleType? = expandedToggle == .chairTest ? nil : .chairTest
                                
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    expandedToggle = newToggleState
                                }
                                
                                // 當椅子坐站測試展開時，自動滾動
                                if newToggleState == .chairTest {
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                                        withAnimation(.easeInOut(duration: 0.5)) {
                                            proxy.scrollTo("chairtest-toggle", anchor: .top)
                                        }
                                    }
                                }
                            }
                        )
                        .environmentObject(recordStore)
                        .id("chairtest-toggle")
                        
                        // 原地站立抬膝Toggle
                        KneeRaiseToggleView(
                            patient: patient,
                            selectedDate: selectedDate,
                            isExpanded: .constant(expandedToggle == .kneeRaise),
                            onToggle: {
                                let newToggleState: ToggleType? = expandedToggle == .kneeRaise ? nil : .kneeRaise
                                
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    expandedToggle = newToggleState
                                }
                                
                                // 當原地站立抬膝展開時，自動滾動
                                if newToggleState == .kneeRaise {
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                                        withAnimation(.easeInOut(duration: 0.5)) {
                                            proxy.scrollTo("kneeraise-toggle", anchor: .top)
                                        }
                                    }
                                }
                            }
                        )
                        .environmentObject(recordStore)
                        .id("kneeraise-toggle")
                        
                        // 開眼單足站立Toggle
                        SingleLegStandToggleView(
                            patient: patient,
                            selectedDate: selectedDate,
                            isExpanded: .constant(expandedToggle == .singleLegStand),
                            onToggle: {
                                let newToggleState: ToggleType? = expandedToggle == .singleLegStand ? nil : .singleLegStand
                                
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    expandedToggle = newToggleState
                                }
                                
                                // 當開眼單足站立展開時，自動滾動
                                if newToggleState == .singleLegStand {
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                                        withAnimation(.easeInOut(duration: 0.5)) {
                                            proxy.scrollTo("singlelegstand-toggle", anchor: .top)
                                        }
                                    }
                                }
                            }
                        )
                        .environmentObject(recordStore)
                        .id("singlelegstand-toggle")
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 0)
                    .padding(.bottom, 8)
                }
                }
            }
            .frame(maxWidth: .infinity, alignment: .top)
            .frame(maxHeight: 500) // 調整高度以容納新的日期顯示區域
            .animation(.easeInOut(duration: 0.3), value: expandedToggle)
            
            // Calendar (Right Side)
            UnifiedCalendarContainer(
                currentDate: $selectedDate,
                patient: patient,
                selectedMenu: nil,
                selectedAssessments: [],
                onDateSelected: { date in
                    selectedDate = date
                    // 保持toggle展開狀態，讓用戶可以快速比較不同日期的同一量表結果
                },
                onExistingScheduleTap: { date in
                    // 處理點擊現有排程的日期
                    selectedDate = date
                    // 保持toggle展開狀態，讓用戶可以快速比較不同日期的同一量表結果
                },
                selectionMode: .single,
                isEditable: true,
                allowPastDatesSelection: true  // 允許選擇過去日期以查看歷史結果
            )
            .environmentObject(scheduleStore)
            .environmentObject(AssessmentStore.shared)
            .frame(width: 430)
        }
        .background(Color.white)
        .onAppear {
            scheduleStore.reloadSchedules()
            // 預設選擇當天日期
            selectedDate = Date()
        }
    }
}

// MARK: - Preview
#Preview {
    DailyResultView(patient: Patient.sample)
        .environmentObject(TrainingScheduleStore.shared)
        .environmentObject(TrainingMenuStore.shared)
        .environmentObject(UserModel.shared)
        .environmentObject(RecordStore.shared)
        .onAppear {
            TrainingScheduleStore.shared.reloadSchedules()
        }
        .frame(width: 1000, height: 600)
        .background(Color.gray.opacity(0.1))
}
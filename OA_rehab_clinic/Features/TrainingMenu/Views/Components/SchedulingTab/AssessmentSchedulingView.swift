import SwiftUI
import Foundation

/**
 * AssessmentSchedulingView - 評估排程視圖
 *
 * 功能說明：
 * - 專門處理評估量表的排程介面
 * - 包含評估選擇和月曆互動
 * - 支援多種評估類型的排程
 *
 * 設計原則：
 * - 單一職責：只處理評估排程相關 UI
 * - 一致性：與 TrainingSchedulingView 保持相似結構
 * - 靈活性：支援未來擴展更多評估類型
 *
 * 重構說明：
 * - 從 EditTrainingCalendarView 提取評估相關 UI
 * - 統一評估排程的操作流程
 * - 簡化狀態管理
 */
struct AssessmentSchedulingView: View {
    // MARK: - 屬性
    
    /// 共享的視圖模型
    @ObservedObject var viewModel: CalendarSchedulingViewModel
    
    /// 環境注入
    @EnvironmentObject private var assessmentStore: AssessmentStore
    
    // MARK: - Body
    
    var body: some View {
        Grid(alignment: .leading, horizontalSpacing: 15, verticalSpacing: 15) {
            GridRow {
                // 左側：評估選擇區域（3格）
                assessmentSelectionSection
                    .gridCellColumns(3)
                
                // 右側：月曆和操作區域（2格）
                calendarSection
                    .gridCellColumns(2)
            }
        }
    }
    
    // MARK: - 子視圖
    
    /// 評估選擇區域
    private var assessmentSelectionSection: some View {
        AssessmentSelectionCard(
            assessments: viewModel.patient.assessments,
            selectedAssessment: $viewModel.selectedAssessment,
            onSelect: viewModel.handleAssessmentSelection
        )
    }
    
    /// 月曆和操作區域
    private var calendarSection: some View {
        VStack(spacing: 0) {
            // 狀態指示器
            if viewModel.selectedAssessment != nil {
                statusIndicator
            }
            
            // 月曆容器
            calendarContainer
                .id(viewModel.calendarViewId)
            
            // 儲存按鈕
            saveButton
        }
    }
    
    /// 狀態指示器
    private var statusIndicator: some View {
        Group {
            if let assessment = viewModel.selectedAssessment {
                HStack {
                    Circle()
                        .fill(assessment.type.color)
                        .frame(width: 12, height: 12)
                    
                    Text("編輯「\(assessment.title)」當月排程")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Button(action: {
                        viewModel.assessmentViewModel.resetState()
                        viewModel.refreshCalendar()
                    }) {
                        Text("取消選擇")
                            .font(.system(size: 14))
                            .foregroundColor(.blue)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }
        }
    }
    
    /// 月曆容器
    private var calendarContainer: some View {
        UnifiedCalendarContainer(
            currentDate: $viewModel.currentDate,
            patient: viewModel.patient,
            selectedMenu: nil,
            selectedAssessments: viewModel.selectedAssessmentSet,
            onDateRangeSelected: viewModel.handleDateRangeSelection,
            onDateSelected: nil,
            onExistingScheduleTap: nil,
            selectionMode: .range,
            isEditable: true,
            isEditingExistingSchedule: false,
            initialSelectedDates: viewModel.selectedDates
        )
        .environmentObject(TrainingScheduleStore.shared)
        .environmentObject(assessmentStore)
    }
    
    /// 儲存按鈕
    private var saveButton: some View {
        CalendarActionButton(
            isEditing: viewModel.selectedAssessment != nil,
            hasChanges: viewModel.hasAssessmentChanges || viewModel.selectedAssessment != nil,
            buttonText: viewModel.assessmentButtonText,
            action: viewModel.saveAssessmentSchedule
        )
    }
    
}

// MARK: - Preview

#if DEBUG
struct AssessmentSchedulingView_Previews: PreviewProvider {
    static var previews: some View {
        Text("AssessmentSchedulingView Preview")
    }
}
#endif
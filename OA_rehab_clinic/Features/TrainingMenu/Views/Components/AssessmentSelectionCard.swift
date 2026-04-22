import SwiftUI
import Foundation


struct AssessmentSelectionCard: View {
    let assessments: [Assessment]
    @Binding var selectedAssessment: Assessment?
    let onSelect: (Assessment) -> Void
    @State private var expandedAssessments: Set<String> = []
    
    var clinicalAssessments: [Assessment] {
        AssessmentType.allCases
            .filter { $0.category == .clinical }
            .map { type in
                assessments.first { $0.type == type } ??
                Assessment(id: type.rawValue, type: type)
            }
    }
    
    var functionalAssessments: [Assessment] {
        AssessmentType.allCases
            .filter { $0.category == .functional }
            .map { type in
                assessments.first { $0.type == type } ??
                Assessment(id: type.rawValue, type: type)
            }
    }
    
    private func handleSelection(_ assessment: Assessment) {
        // 支援點擊相同量表來取消選擇
        if selectedAssessment?.id == assessment.id {
            // 如果點擊的是已選中的量表，取消選擇
            selectedAssessment = nil
        } else {
            // 否則正常選擇該量表
            onSelect(assessment)
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                // Clinical Assessments Section
                if !clinicalAssessments.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("臨床量表")
                            .font(.title3)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                        
                        ForEach(clinicalAssessments) { assessment in
                            AssessmentItemView(
                                assessment: assessment,
                                isSelected: selectedAssessment?.id == assessment.id,
                                isExpanded: expandedAssessments.contains(assessment.id),
                                onSelect: { handleSelection(assessment) },
                                onToggle: { isExpanded in
                                    withAnimation(.spring(response: 0.3)) {
                                        if isExpanded {
                                            expandedAssessments.insert(assessment.id)
                                        } else {
                                            expandedAssessments.remove(assessment.id)
                                        }
                                    }
                                }
                            )
                        }
                    }
                }
                
                // Functional Assessments Section
                if !functionalAssessments.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("功能性評估")
                            .font(.title3)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                        
                        ForEach(functionalAssessments) { assessment in
                            AssessmentItemView(
                                assessment: assessment,
                                isSelected: selectedAssessment?.id == assessment.id,
                                isExpanded: expandedAssessments.contains(assessment.id),
                                onSelect: { handleSelection(assessment) },
                                onToggle: { isExpanded in
                                    withAnimation(.spring(response: 0.3)) {
                                        if isExpanded {
                                            expandedAssessments.insert(assessment.id)
                                        } else {
                                            expandedAssessments.remove(assessment.id)
                                        }
                                    }
                                }
                            )
                        }
                    }
                }
            }
            .padding(.vertical)
            .background(Color.white)
        }
    }
}

private struct AssessmentItemView: View {
    let assessment: Assessment
    let isSelected: Bool
    let isExpanded: Bool
    let onSelect: () -> Void
    let onToggle: (Bool) -> Void
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd"
        return formatter
    }()
    
    private var recentCompletedDates: [Date] {
        return assessment.completedDates.prefix(2).map { $0 }
    }
    
    private func formatDates(_ dates: [Date]) -> String {
        return dates
            .map { dateFormatter.string(from: $0) }
            .joined(separator: ", ")
    }
    
    var body: some View {
        VStack(spacing: 8) {
            Button(action: onSelect) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 8) {
                            Rectangle()
                                .fill(assessment.type.color)
                                .frame(width: 20, height: 20)
                                .cornerRadius(4)
                            
                            Text(assessment.title)
                                .font(.headline)
                                .foregroundColor(.primary)
                        }
                        
                        if !assessment.completedDates.isEmpty {
                            Text("最近評量：\(formatDates(recentCompletedDates))")
                                .font(.system(size: 12))
                                .foregroundColor(.gray)
                        }
                    }
                    
                    Spacer()
                    
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(assessment.type.color)
                    }
                    
                    ToggleButton(
                        isExpanded: .constant(isExpanded),
                        color: .blue,
                        action: { onToggle(!isExpanded) }
                    )
                }
                .buttonStyle(PlainButtonStyle())
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? assessment.type.color.opacity(0.1) : Color.gray.opacity(0.1)))
            }
            
            if isExpanded {
                VStack(alignment: .leading, spacing: 4) {
                    Divider()
                    
                    Text(assessment.type.description)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    if assessment.completedDates.count > 2 {
                        Text("共有 \(assessment.completedDates.count) 筆評量記錄")
                            .font(.caption)
                            .foregroundColor(.blue)
                            .padding(.top, 4)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
                .transition(.opacity)
            }
        }
        .padding(.horizontal)
    }
}

private struct ToggleButton: View {
    @Binding var isExpanded: Bool
    let color: Color
    var action: (() -> Void)? = nil
    
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3)) {
                action?()
            }
        }) {
            Image(systemName: "chevron.down")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(color)
                .rotationEffect(.degrees(isExpanded ? 180 : 0))
                .padding(8)
                .background(
                    Circle()
                        .fill(color.opacity(0.1))
                )
        }
    }
}

#Preview {
    AssessmentSelectionCard(
        assessments: Patient.sample.assessments,
        selectedAssessment: .constant(nil),
        onSelect: { _ in }
    )
    .padding()
    .background(Color.gray.opacity(0.1))
} 
import SwiftUI
import Foundation

// 直接依賴 Swift 的自動 module 匯入，無需 import OA_rehab_clinic


// 簡潔版運動項目列表項目
struct CompactExerciseListItem: View {
    let parameters: ExerciseParameters
    
    private var config: ExerciseModule.ParameterConfiguration {
        ExerciseModule.ParameterConfiguration.forExercise(parameters.exercise)
    }
    
    private func legSummary(_ leg: LegParameters?, side: String) -> some View {
        guard let leg = leg else { return AnyView(EmptyView()) }
        return AnyView(
            VStack(alignment: .center, spacing: 8) {
                Text(side)
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
                HStack(spacing: 12) {
                    // 組數
                    if config.showSets {
                        VStack(spacing: 2) {
                            Text("組數").font(.system(size: 12)).foregroundColor(.gray)
                            Text("\(leg.sets)").font(.system(size: 14)).foregroundColor(.blue)
                        }.frame(width: 45)
                    }
                    // 次數
                    if config.showRepetitions {
                        VStack(spacing: 2) {
                            Text("次數").font(.system(size: 12)).foregroundColor(.gray)
                            Text("\(leg.repetitions)").font(.system(size: 14)).foregroundColor(.blue)
                        }.frame(width: 45)
                    }
                    // 維持時間
                    if config.showMantainTime {
                        VStack(spacing: 2) {
                            Text("維持").font(.system(size: 12)).foregroundColor(.gray)
                            Text(leg.duration != nil ? "\(leg.duration!)秒" : "-").font(.system(size: 14)).foregroundColor(.blue)
                        }.frame(width: 45)
                    }
                    // 休息時間
                    if config.showRestTime {
                        VStack(spacing: 2) {
                            Text("休息").font(.system(size: 12)).foregroundColor(.gray)
                            Text("\(leg.restTime)秒").font(.system(size: 14)).foregroundColor(.blue)
                        }.frame(width: 45)
                    }
                    // 膝關節角度
                    if config.showKneeAngle {
                        VStack(spacing: 2) {
                            Text("膝角").font(.system(size: 12)).foregroundColor(.gray)
                            Text(angleText(start: leg.kneeAngleStart, end: leg.kneeAngleEnd)).font(.system(size: 14)).foregroundColor(.blue)
                        }.frame(width: 55)
                    }
                    // 髖關節角度
                    if config.showHipAngle {
                        VStack(spacing: 2) {
                            Text("髖角").font(.system(size: 12)).foregroundColor(.gray)
                            Text(angleText(start: leg.hipAngleStart, end: leg.hipAngleEnd)).font(.system(size: 14)).foregroundColor(.blue)
                        }.frame(width: 55)
                    }
                    // 重量
                    if config.showWeight {
                        VStack(spacing: 2) {
                            Text("重量").font(.system(size: 12)).foregroundColor(.gray)
                            Text(leg.weight != nil ? String(format: "%.1fkg", leg.weight!) : "-").font(.system(size: 14)).foregroundColor(.blue)
                        }.frame(width: 55)
                    }
                    // MVIC
                    if config.showMVIC {
                        VStack(spacing: 2) {
                            Text("MVIC").font(.system(size: 12)).foregroundColor(.gray)
                            Text(leg.mvic != nil ? "\(leg.mvic!)%" : "-").font(.system(size: 14)).foregroundColor(.blue)
                        }.frame(width: 50)
                    }
                    // 電刺激
                    if config.allowStimulation && leg.stimulation {
                        VStack(spacing: 2) {
                            HStack(spacing: 2) {
                                Image(systemName: "bolt.fill").foregroundColor(.green)
                                Text("刺激")
                            }.font(.system(size: 12)).foregroundColor(.gray)
                            Text(stimulationSummary(leg)).font(.system(size: 14)).foregroundColor(.blue)
                        }.frame(width: 60)
                    }
                }
            }
        )
    }
    
    private func angleText(start: Int?, end: Int?) -> String {
        if let s = start, let e = end { return "\(s)~\(e)°" }
        if let s = start { return "\(s)°" }
        if let e = end { return "~\(e)°" }
        return "-"
    }
    
    private func stimulationSummary(_ leg: LegParameters) -> String {
        var parts: [String] = []
        if let i = leg.stimulationIntensity { parts.append("強度\(i)") }
        if let f = leg.stimulationFrequency { parts.append("頻率\(f)") }
        if let w = leg.stimulationPulseWidth { parts.append("寬\(w)") }
        return parts.isEmpty ? "ON" : parts.joined(separator: "/")
    }
    
    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                // 運動名稱（中英文）
                VStack(alignment: .leading, spacing: 2) {
                    Text(parameters.exercise.name)
                        .font(.system(size: 16, weight: .medium))
                    Text(parameters.exercise.englishName)
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                }
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 20) {
                        if parameters.leftLeg != nil {
                            legSummary(parameters.leftLeg, side: "左腳")
                        }
                        if parameters.rightLeg != nil {
                            if parameters.leftLeg != nil {
                                Divider().frame(height: 50)
                            }
                            legSummary(parameters.rightLeg, side: "右腳")
                        }
                    }
                    .padding(.trailing, 8)
                }
            }
            Spacer()
        }
        .padding(12)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
} 
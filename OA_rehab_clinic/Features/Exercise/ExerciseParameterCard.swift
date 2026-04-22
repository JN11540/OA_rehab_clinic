import SwiftUI
import Foundation
import UniformTypeIdentifiers

// Import all the needed modules/files
import Foundation



// Import necessary modules for ExerciseParameters

struct ExerciseParameterCard: View {
    let exercise: ExerciseModule.Exercise
    @Binding var isPresented: Bool
    @Binding var selectedExercises: [ExerciseParameters]
    let editingExercise: ExerciseParameters?
    
    @State private var rightLegEnabled: Bool
    @State private var leftLegEnabled: Bool
    @State private var rightParameters: LegParameters
    @State private var leftParameters: LegParameters
    
    private let contentWidth: CGFloat = 700  // 增加寬度以適應新的參數
    
    init(
        exercise: ExerciseModule.Exercise,
        isPresented: Binding<Bool>,
        selectedExercises: Binding<[ExerciseParameters]>,
        editingExercise: ExerciseParameters? = nil
    ) {
        self.exercise = exercise
        self._isPresented = isPresented
        self._selectedExercises = selectedExercises
        self.editingExercise = editingExercise
        
        // 初始化參數
        if let editingExercise = editingExercise {
            // 編輯模式：使用現有參數
            _rightLegEnabled = State(initialValue: editingExercise.rightLeg != nil)
            _leftLegEnabled = State(initialValue: editingExercise.leftLeg != nil)
            _rightParameters = State(initialValue: editingExercise.rightLeg ?? LegParameters.defaultFor(exercise: exercise))
            _leftParameters = State(initialValue: editingExercise.leftLeg ?? LegParameters.defaultFor(exercise: exercise))
        } else {
            // 新增模式：使用預設值，預設開啟右腳
            _rightLegEnabled = State(initialValue: true)
            _leftLegEnabled = State(initialValue: false)
            _rightParameters = State(initialValue: LegParameters.defaultFor(exercise: exercise))
            _leftParameters = State(initialValue: LegParameters.defaultFor(exercise: exercise))
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 8) {
                    // 運動資訊區域
                    VStack(alignment: .leading, spacing: 12) {
                        // 類別標題
                        HStack {
                            Text(exercise.category)
                                .font(.headline)
                                .foregroundColor(.blue)
                            if let level = exercise.level {
                                Text(level)
                                    .font(.subheadline)
                                    .foregroundColor(.blue.opacity(0.8))
                            }
                        }
                        .shadow(color: .gray.opacity(0.3), radius: 1, x: 0, y: 1)
                            
                        // 運動資訊
                        HStack(spacing: 16) {
                            // 圖片
                            if let image = UIImage(named: exercise.imageName) {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 120, height: 120)
                                    .cornerRadius(8)
                            }
                            
                            // 文字說明
                            VStack(alignment: .leading, spacing: 6) {
                                Text(exercise.name)
                                    .font(.title3)
                                    .bold()
                                Text(exercise.englishName)
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                
                                if let description = exercise.description {
                                    Text("簡易說明")
                                        .font(.subheadline)
                                        .bold()
                                        .padding(.top, 4)
                                    Text(description)
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                }
                                
                                if let difficulty = exercise.difficulty {
                                    Text("可調整難度標準")
                                        .font(.subheadline)
                                        .bold()
                                        .padding(.top, 4)
                                    Text(difficulty)
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                }
                            }
                            Spacer(minLength: 0)
                        }
                    }
                    .padding()
                    .frame(width: contentWidth)
                    .background(Color.white)
                    .cornerRadius(12)
                    
                    // 右腳參數設定
                    VStack(alignment: .leading, spacing: 12) {
                        Button(action: { rightLegEnabled.toggle() }) {
                            HStack(spacing: 8) {
                                Image(systemName: rightLegEnabled ? "circle.inset.filled" : "circle")
                                    .foregroundColor(rightLegEnabled ? .blue : .gray)
                                Text("右腳")
                                    .foregroundColor(rightLegEnabled ? .primary : .gray)
                            }
                        }
                        .buttonStyle(.plain)
                        
                        ParameterRow(parameters: $rightParameters, exercise: exercise)
                            .disabled(!rightLegEnabled)
                    }
                    .padding()
                    .frame(width: contentWidth)
                    .background(Color.white)
                    .cornerRadius(12)
                    
                    // 左腳參數設定
                    VStack(alignment: .leading, spacing: 12) {
                        Button(action: { leftLegEnabled.toggle() }) {
                            HStack(spacing: 8) {
                                Image(systemName: leftLegEnabled ? "circle.inset.filled" : "circle")
                                    .foregroundColor(leftLegEnabled ? .blue : .gray)
                                Text("左腳")
                                    .foregroundColor(leftLegEnabled ? .primary : .gray)
                            }
                        }
                        .buttonStyle(.plain)
                        
                        ParameterRow(parameters: $leftParameters, exercise: exercise)
                            .disabled(!leftLegEnabled)
                    }
                    .padding()
                    .frame(width: contentWidth)
                    .background(Color.white)
                    .cornerRadius(12)
                }
                .padding(.vertical)
            }
            .frame(width: contentWidth + 20)
            .background(Color("ParameterBackground", bundle: nil))
            
            Divider()
            
            // 底部按鈕
            HStack(spacing: 20) {
                Spacer()

                Button("取消") {
                    isPresented = false
                }
                .buttonStyle(.bordered)
                
                Button(editingExercise != nil ? "更新參數" : "新增動作") {
                    if let editingExercise = editingExercise,
                       let index = selectedExercises.firstIndex(where: { $0.id == editingExercise.id }) {
                        // 更新現有運動的參數
                        var updatedExercise = editingExercise
                        updatedExercise.rightLeg = rightLegEnabled ? rightParameters : nil
                        updatedExercise.leftLeg = leftLegEnabled ? leftParameters : nil
                        selectedExercises[index] = updatedExercise
                    } else {
                        // 新增運動
                        let parameters = ExerciseParameters(
                            exercise: exercise,
                            rightLeg: rightLegEnabled ? rightParameters : nil,
                            leftLeg: leftLegEnabled ? leftParameters : nil
                        )
                        selectedExercises.append(parameters)
                    }
                    isPresented = false
                }
                .buttonStyle(.borderedProminent)
                .disabled(!rightLegEnabled && !leftLegEnabled)
            }
            .padding()
            .background(Color.white)
        }
        .frame(width: contentWidth + 50)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(radius: 5)
    }
}

// Modify ExerciseParameterCard.swift
struct ParameterRow: View {
    @Binding var parameters: LegParameters
    let exercise: ExerciseModule.Exercise
    @Environment(\.isEnabled) private var isEnabled
    
    // Pre-compute configuration outside the body
    private var config: ExerciseModule.ParameterConfiguration {
        ExerciseModule.ParameterConfiguration.forExercise(exercise)
    }
    
    // Helper functions to reduce complexity
    private func getTextColor() -> Color {
        return isEnabled ? Color.primary : Color.gray
    }
    
    private func getFormattedText<T>(_ value: T?) -> String where T: CustomStringConvertible {
        if let value = value {
            return value.description
        }
        return "0"
    }
    
    // Action handlers
    private func decrementSets() {
        if parameters.sets > 1 {
            parameters.sets -= 1
        }
    }
    
    private func incrementSets() {
        parameters.sets += 1
    }
    
    private func decrementRepetitions() {
        if parameters.repetitions > 1 {
            parameters.repetitions -= 1
        }
    }
    
    private func incrementRepetitions() {
        parameters.repetitions += 1
    }
    
    private func decrementRestTime() {
        if parameters.restTime > 5 {
            parameters.restTime -= 5
        }
    }
    
    private func incrementRestTime() {
        parameters.restTime += 5
    }
    
    private func decrementDuration() {
        if let duration = parameters.duration, duration > 5 {
            parameters.duration = duration - 5
        }
    }
    
    private func incrementDuration() {
        if parameters.duration == nil {
            parameters.duration = 5
        } else {
            parameters.duration! += 5
        }
    }
    
    private func decrementWeight() {
        if let weight = parameters.weight, weight > 0 {
            parameters.weight = weight - 0.5
        }
    }
    
    private func incrementWeight() {
        if parameters.weight == nil {
            parameters.weight = 0.5
        } else {
            parameters.weight! += 0.5
        }
    }
    
    private func decrementMVIC() {
        if let mvic = parameters.mvic, mvic > 0 {
            parameters.mvic = mvic - 5
        }
    }
    
    private func incrementMVIC() {
        if parameters.mvic == nil {
            parameters.mvic = 5
        } else {
            parameters.mvic! += 5
        }
    }
    
    // Add stimulation parameter helpers
    private func decrementStimulationIntensity() {
        if let intensity = parameters.stimulationIntensity, intensity > 0 {
            parameters.stimulationIntensity = intensity - 1
        }
    }
    
    private func incrementStimulationIntensity() {
        if parameters.stimulationIntensity == nil {
            parameters.stimulationIntensity = 1
        } else if parameters.stimulationIntensity! < 20 {
            parameters.stimulationIntensity! += 1
        }
    }
    
    private func decrementStimulationFrequency() {
        if let freq = parameters.stimulationFrequency, freq > 0 {
            parameters.stimulationFrequency = freq - 1
        }
    }
    
    private func incrementStimulationFrequency() {
        if parameters.stimulationFrequency == nil {
            parameters.stimulationFrequency = 1
        } else if parameters.stimulationFrequency! < 10 {
            parameters.stimulationFrequency! += 1
        }
    }
    
    private func decrementStimulationPulseWidth() {
        if let width = parameters.stimulationPulseWidth, width > 0 {
            parameters.stimulationPulseWidth = width - 1
        }
    }
    
    private func incrementStimulationPulseWidth() {
        if parameters.stimulationPulseWidth == nil {
            parameters.stimulationPulseWidth = 1
        } else if parameters.stimulationPulseWidth! < 10 {
            parameters.stimulationPulseWidth! += 1
        }
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // 基本參數和電刺激開關
            HStack {
                Text("詳細設定")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                Spacer()
                
                if config.allowStimulation {
                    HStack(spacing: 16) {
                        Text("電刺激")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        Toggle("", isOn: $parameters.stimulation)
                            .toggleStyle(SwitchToggleStyle(tint: .blue))
                            .labelsHidden()
                    }
                }

                Spacer()
            }
            .padding(.bottom, 4)
            
            // First row of parameters
            HStack(spacing: 16) {
                // Sets
                if config.showSets {
                    VStack(alignment: .center, spacing: 4) {
                        Text("組數")
                            .font(.caption)
                            .foregroundColor(.gray)
                        HStack {
                            Button("-") { decrementSets() }
                            
                            // Use helper methods for colors and text formatting
                            let setsText = "\(parameters.sets)"
                            let textColor = getTextColor()
                            
                            Text(setsText)
                                .frame(width: 40)
                                .foregroundColor(textColor)
                                
                            Button("+") { incrementSets() }
                        }
                        .padding(4)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
                
                // Repetitions
                if config.showRepetitions {
                    VStack(alignment: .center, spacing: 4) {
                        Text("次數")
                            .font(.caption)
                            .foregroundColor(.gray)
                        HStack {
                            Button("-") { decrementRepetitions() }
                            
                            // Use helper methods for colors and text formatting
                            let repsText = "\(parameters.repetitions)"
                            let textColor = getTextColor()
                            
                            Text(repsText)
                                .frame(width: 40)
                                .foregroundColor(textColor)
                                
                            Button("+") { incrementRepetitions() }
                        }
                        .padding(4)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
                
                // Rest Time
                if config.showRestTime {
                    VStack(alignment: .center, spacing: 4) {
                        Text("休息時間(秒)")
                            .font(.caption)
                            .foregroundColor(.gray)
                        HStack {
                            Button("-") { decrementRestTime() }
                            
                            // Use helper methods for colors and text formatting
                            let restText = "\(parameters.restTime)"
                            let textColor = getTextColor()
                            
                            Text(restText)
                                .frame(width: 40)
                                .foregroundColor(textColor)
                                
                            Button("+") { incrementRestTime() }
                        }
                        .padding(4)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
                
                // Duration
                if config.showMantainTime {
                    VStack(alignment: .center, spacing: 4) {
                        Text("維持時間(秒)")
                            .font(.caption)
                            .foregroundColor(.gray)
                        HStack {
                            Button("-") { decrementDuration() }
                            
                            // Use helper methods for colors and text formatting
                            let durationValue = parameters.duration ?? 0
                            let durationText = "\(durationValue)"
                            let textColor = getTextColor()
                            
                            Text(durationText)
                                .frame(width: 40)
                                .foregroundColor(textColor)
                                
                            Button("+") { incrementDuration() }
                        }
                        .padding(4)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
            }
            
            // Second row of parameters
            HStack(spacing: 16) {
                // Knee Angle
                if config.showKneeAngle {
                    VStack(alignment: .center, spacing: 4) {
                        Text("膝關節角度")
                            .font(.caption)
                            .foregroundColor(.gray)
                        HStack {
                            // Use helper methods for colors and text formatting
                            let textFieldColor = getTextColor()
                            let separatorColor = getTextColor()
                            
                            TextField("", value: $parameters.kneeAngleStart, formatter: NumberFormatter())
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 40)   
                                .foregroundColor(textFieldColor)
                                
                            Text("~")
                                .frame(width: 10)
                                .foregroundColor(separatorColor)
                                
                            TextField("", value: $parameters.kneeAngleEnd, formatter: NumberFormatter())
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 40)
                                .foregroundColor(textFieldColor)
                        }
                    }
                }
                
                // Hip Angle
                if config.showHipAngle {
                    VStack(alignment: .center, spacing: 4) {
                        Text("髖關節角度")
                            .font(.caption)
                            .foregroundColor(.gray)
                        HStack {
                            // Use helper methods for colors and text formatting
                            let textFieldColor = getTextColor()
                            let separatorColor = getTextColor()
                            
                            TextField("", value: $parameters.hipAngleStart, formatter: NumberFormatter())
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 40)   
                                .foregroundColor(textFieldColor)
                                
                            Text("~")
                                .frame(width: 10)
                                .foregroundColor(separatorColor)
                                
                            TextField("", value: $parameters.hipAngleEnd, formatter: NumberFormatter())
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 40)
                                .foregroundColor(textFieldColor)
                        }
                    }
                }
                
                // Weight
                if config.showWeight {
                    VStack(alignment: .center, spacing: 4) {
                        Text("重量(kg)")
                            .font(.caption)
                            .foregroundColor(.gray)
                        HStack {
                            Button("-") { decrementWeight() }
                            
                            // Use helper methods for colors and text formatting
                            let weightValue = parameters.weight ?? 0
                            let formattedWeight = String(format: "%.1f", weightValue)
                            let textColor = getTextColor()
                            
                            Text(formattedWeight)
                                .frame(width: 40)
                                .foregroundColor(textColor)
                                
                            Button("+") { incrementWeight() }
                        }
                        .padding(4)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
                
                // MVIC (muscle activation threshold)
                if config.showMVIC {
                    VStack(alignment: .center, spacing: 4) {
                        Text("肌電閾值(%)")
                            .font(.caption)
                            .foregroundColor(.gray)
                        HStack {
                            Button("-") { decrementMVIC() }
                            
                            // Use helper methods for colors and text formatting
                            let mvicValue = parameters.mvic ?? 0
                            let mvicText = "\(mvicValue)"
                            
                            let textColor = getTextColor()
                            
                            Text(mvicText)
                                .frame(width: 40)
                                .foregroundColor(textColor)
                                
                            Button("+") { incrementMVIC() }
                        }
                        .padding(4)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
            }
            
            // Stimulation parameters (third row)
            if config.allowStimulation && parameters.stimulation {
                HStack(spacing: 16) {
                    // Stimulation Intensity
                    VStack(alignment: .center, spacing: 4) {
                        Text("強度")
                            .font(.caption)
                            .foregroundColor(.gray)
                        HStack {
                            Button("-") { decrementStimulationIntensity() }
                            
                            // Use helper methods for colors and text formatting
                            let intensityValue = parameters.stimulationIntensity ?? 0
                            let intensityText = "\(intensityValue)"
                            let textColor = getTextColor()
                            
                            Text(intensityText)
                                .frame(width: 40)
                                .foregroundColor(textColor)
                                
                            Button("+") { incrementStimulationIntensity() }
                        }
                        .padding(4)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                    }
                    
                    // Frequency
                    VStack(alignment: .center, spacing: 4) {
                        Text("頻率")
                            .font(.caption)
                            .foregroundColor(.gray)
                        HStack {
                            Button("-") { decrementStimulationFrequency() }
                            
                            // Use helper methods for colors and text formatting
                            let freqValue = parameters.stimulationFrequency ?? 0
                            let freqText = "\(freqValue)"
                            let textColor = getTextColor()
                            
                            Text(freqText)
                                .frame(width: 40)
                                .foregroundColor(textColor)
                                
                            Button("+") { incrementStimulationFrequency() }
                        }
                        .padding(4)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                    }
                    
                    // Pulse Width
                    VStack(alignment: .center, spacing: 4) {
                        Text("脈波寬度")
                            .font(.caption)
                            .foregroundColor(.gray)
                        HStack {
                            Button("-") { decrementStimulationPulseWidth() }
                            
                            // Use helper methods for colors and text formatting
                            let widthValue = parameters.stimulationPulseWidth ?? 0
                            let widthText = "\(widthValue)"
                            let textColor = getTextColor()
                            
                            Text(widthText)
                                .frame(width: 40)
                                .foregroundColor(textColor)
                                
                            Button("+") { incrementStimulationPulseWidth() }
                        }
                        .padding(4)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
            }
        }
    }
}

#Preview {
    ZStack {
        Color.black.opacity(0.3)
            .ignoresSafeArea()
        
        ExerciseParameterCard(
            exercise: ExerciseModule.Exercise.quadricepsBasic[0],
            isPresented: .constant(true),
            selectedExercises: .constant([]),
            editingExercise: nil
        )
    }
} 
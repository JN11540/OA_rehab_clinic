import Foundation
import SwiftUI
import UniformTypeIdentifiers

// MARK: - UTType Extension
extension UTType {
    static var exerciseParameters: UTType {
        UTType(exportedAs: "com.ttri.oa-rehab-clinic.exercise-parameters")
    }
}



public struct ExerciseParameters: Identifiable, Codable, Transferable, Equatable {
    public var id = UUID()
    public let exercise: ExerciseModule.Exercise
    public var rightLeg: LegParameters?
    public var leftLeg: LegParameters?
    
    public init(
        exercise: ExerciseModule.Exercise,
        rightLeg: LegParameters? = nil,
        leftLeg: LegParameters? = nil
    ) {
        self.exercise = exercise
        self.rightLeg = rightLeg
        self.leftLeg = leftLeg
    }
    
    // MARK: - Transferable
    public static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .exerciseParameters)
    }
    
    // MARK: - Equatable
    public static func == (lhs: ExerciseParameters, rhs: ExerciseParameters) -> Bool {
        return lhs.id == rhs.id &&
               lhs.exercise.id == rhs.exercise.id &&
               lhs.rightLeg == rhs.rightLeg &&
               lhs.leftLeg == rhs.leftLeg
    }
}

// Leg parameters structure
public struct LegParameters: Codable, Equatable {
    public var sets: Int
    public var repetitions: Int

    // Time-related parameters
    public var restTime: Int            // 組間休息時間(秒)
    public var duration: Int?           // 維持時間(秒)
    
    // Angle parameters
    public var kneeAngleStart: Int?     // 膝關節角度下限
    public var kneeAngleEnd: Int?       // 膝關節角度上限
    public var hipAngleStart: Int?      // 髖關節角度下限
    public var hipAngleEnd: Int?        // 髖關節角度上限
    
    // Additional parameters
    public var weight: Double?          // 重量(kg)
    public var mvic: Int?               // 肌電閾值(%)
    
    // Stimulation parameters
    public var stimulation: Bool
    public var stimulationIntensity: Int?
    public var stimulationFrequency: Int?
    public var stimulationPulseWidth: Int?
    
    public init(
        sets: Int = 3,
        repetitions: Int = 10,
        restTime: Int = 30,
        duration: Int? = 30,
        kneeAngleStart: Int? = 0,
        kneeAngleEnd: Int? = 90,
        hipAngleStart: Int? = 0,
        hipAngleEnd: Int? = 40,
        weight: Double? = 0,
        mvic: Int? = 60,
        stimulation: Bool = false,
        stimulationIntensity: Int? = 5,
        stimulationFrequency: Int? = 5,
        stimulationPulseWidth: Int? = 5
    ) {
        self.sets = sets
        self.repetitions = repetitions
        self.restTime = restTime
        self.duration = duration
        self.kneeAngleStart = kneeAngleStart
        self.kneeAngleEnd = kneeAngleEnd
        self.hipAngleStart = hipAngleStart
        self.hipAngleEnd = hipAngleEnd
        self.weight = weight
        self.mvic = mvic
        self.stimulation = stimulation
        self.stimulationIntensity = stimulationIntensity
        self.stimulationFrequency = stimulationFrequency
        self.stimulationPulseWidth = stimulationPulseWidth
    }
    
    // Add default instance for legacy code
    public static var `default`: LegParameters {
        return LegParameters(
            sets: 3,
            repetitions: 10,
            restTime: 30,
            duration: 30,
            kneeAngleStart: 0,
            kneeAngleEnd: 90,
            hipAngleStart: 0,
            hipAngleEnd: 40,
            weight: 0,
            mvic: 60,
            stimulation: false,
            stimulationIntensity: 5,
            stimulationFrequency: 5,
            stimulationPulseWidth: 5
        )
    }
    
    public static func defaultFor(exercise: ExerciseModule.Exercise) -> LegParameters {
        let config = ExerciseModule.ParameterConfiguration.forExercise(exercise)
        return LegParameters(
            sets: 3,
            repetitions: 10,
            restTime: config.showRestTime ? 30 : 30,
            duration: config.showMantainTime ? 30 : nil,
            kneeAngleStart: config.showKneeAngle ? 0 : nil,
            kneeAngleEnd: config.showKneeAngle ? 90 : nil,
            hipAngleStart: config.showHipAngle ? 0 : nil,
            hipAngleEnd: config.showHipAngle ? 40 : nil,
            weight: config.showWeight ? 0 : nil,
            mvic: config.showMVIC ? 60 : nil,
            stimulation: false,
            stimulationIntensity: config.allowStimulation ? 5 : nil,
            stimulationFrequency: config.allowStimulation ? 5 : nil,
            stimulationPulseWidth: config.allowStimulation ? 5 : nil
        )
    }
    
    // MARK: - Equatable
    public static func == (lhs: LegParameters, rhs: LegParameters) -> Bool {
        return lhs.sets == rhs.sets &&
               lhs.repetitions == rhs.repetitions &&
               lhs.weight == rhs.weight &&
               lhs.restTime == rhs.restTime &&
               lhs.duration == rhs.duration &&
               lhs.kneeAngleStart == rhs.kneeAngleStart &&
               lhs.kneeAngleEnd == rhs.kneeAngleEnd &&
               lhs.hipAngleStart == rhs.hipAngleStart &&
               lhs.hipAngleEnd == rhs.hipAngleEnd &&
               lhs.mvic == rhs.mvic &&
               lhs.stimulation == rhs.stimulation &&
               lhs.stimulationIntensity == rhs.stimulationIntensity &&
               lhs.stimulationFrequency == rhs.stimulationFrequency &&
               lhs.stimulationPulseWidth == rhs.stimulationPulseWidth
    }
} 

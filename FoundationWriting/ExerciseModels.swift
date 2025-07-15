//
//  ExerciseModels.swift
//  FoundationWriting
//
//  Created by Hans Axelsson on 7/15/25.
//
import Foundation

// MARK: - Writing Exercise

struct WritingExercise: Identifiable, Codable {
    let id: UUID
    let title: String
    let description: String
    let type: ExerciseType
    let targetSkill: SkillArea
    let difficulty: Difficulty
    let instructions: String
    let objectives: [String]
    let expectedOutcome: String
    let timeEstimate: TimeInterval
    let createdDate: Date
    let sampleResponse: String?
    
    enum ExerciseType: String, Codable, CaseIterable {
        case grammar = "grammar"
        case style = "style"
        case clarity = "clarity"
        case vocabulary = "vocabulary"
        case structure = "structure"
        case tone = "tone"
        case creative = "creative"
        case warmUp = "warm_up"
        case timed = "timed"
        case challenge = "challenge"
        
        var displayName: String {
            switch self {
            case .grammar: return "Grammar"
            case .style: return "Style"
            case .clarity: return "Clarity"
            case .vocabulary: return "Vocabulary"
            case .structure: return "Structure"
            case .tone: return "Tone"
            case .creative: return "Creative"
            case .warmUp: return "Warm-Up"
            case .timed: return "Timed"
            case .challenge: return "Challenge"
            }
        }
        
        var iconName: String {
            switch self {
            case .grammar: return "textformat.abc"
            case .style: return "paintbrush.fill"
            case .clarity: return "eye.fill"
            case .vocabulary: return "book.fill"
            case .structure: return "rectangle.3.group.fill"
            case .tone: return "speaker.wave.2.fill"
            case .creative: return "lightbulb.fill"
            case .warmUp: return "flame.fill"
            case .timed: return "timer"
            case .challenge: return "target"
            }
        }
        
        var color: String {
            switch self {
            case .grammar: return "red"
            case .style: return "blue"
            case .clarity: return "orange"
            case .vocabulary: return "purple"
            case .structure: return "green"
            case .tone: return "pink"
            case .creative: return "cyan"
            case .warmUp: return "yellow"
            case .timed: return "indigo"
            case .challenge: return "brown"
            }
        }
    }
    
enum Difficulty: String, Codable, CaseIterable, Comparable {
        case easy = "easy"
        case medium = "medium"
        case hard = "hard"
        case expert = "expert"
        
        var displayName: String {
            return rawValue.capitalized
        }
        
        var color: String {
            switch self {
            case .easy: return "green"
            case .medium: return "orange"
            case .hard: return "red"
            case .expert: return "purple"
            }
        }
        
        var experienceMultiplier: Double {
            switch self {
            case .easy: return 1.0
            case .medium: return 1.5
            case .hard: return 2.0
            case .expert: return 3.0
            }
        }
        
        var iconName: String {
            switch self {
            case .easy: return "1.circle.fill"
            case .medium: return "2.circle.fill"
            case .hard: return "3.circle.fill"
            case .expert: return "star.circle.fill"
            }
        }

        // MARK: - Comparable Conformance
        static func < (lhs: Difficulty, rhs: Difficulty) -> Bool {
            lhs.rawValue < rhs.rawValue
        }
    }
    
    // Computed properties
    var estimatedTimeString: String {
        let minutes = Int(timeEstimate / 60)
        if minutes < 60 {
            return "\(minutes) min"
        } else {
            let hours = minutes / 60
            let remainingMinutes = minutes % 60
            if remainingMinutes == 0 {
                return "\(hours)h"
            } else {
                return "\(hours)h \(remainingMinutes)m"
            }
        }
    }
    
    var isTimeSensitive: Bool {
        return type == .timed || type == .challenge
    }

    /// Memberwise initializer with default sampleResponse
    public init(
        id: UUID,
        title: String,
        description: String,
        type: ExerciseType,
        targetSkill: SkillArea,
        difficulty: Difficulty,
        instructions: String,
        objectives: [String],
        expectedOutcome: String,
        timeEstimate: TimeInterval,
        createdDate: Date,
        sampleResponse: String? = nil
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.type = type
        self.targetSkill = targetSkill
        self.difficulty = difficulty
        self.instructions = instructions
        self.objectives = objectives
        self.expectedOutcome = expectedOutcome
        self.timeEstimate = timeEstimate
        self.createdDate = createdDate
        self.sampleResponse = sampleResponse
    }
    
    var complexityScore: Double {
        let difficultyScore = difficulty.experienceMultiplier
        let timeScore = min(timeEstimate / 1800, 2.0) // Max 2.0 for 30+ minutes
        return (difficultyScore + timeScore) / 2.0
    }
}

// MARK: - Exercise Result

struct ExerciseResult: Identifiable, Codable {
    let id: UUID
    let exerciseId: UUID
    let userResponse: String
    let analysis: EnhancedWritingAnalysis
    let performance: ExercisePerformance
    let timeSpent: TimeInterval
    let completedAt: Date
    let feedback: ExerciseFeedback
    
    // Computed properties
    var timeEfficiencyDescription: String {
        switch performance.timeEfficiency {
        case 0.9...: return "Excellent timing"
        case 0.8..<0.9: return "Good timing"
        case 0.6..<0.8: return "Took longer than expected"
        default: return "Slow completion"
        }
    }
    
    var performanceGrade: String {
        switch performance.overallScore {
        case 0.9...: return "A"
        case 0.8..<0.9: return "B"
        case 0.7..<0.8: return "C"
        case 0.6..<0.7: return "D"
        default: return "F"
        }
    }
    
    var overallRating: ExerciseRating {
        switch performance.overallScore {
        case 0.9...: return .excellent
        case 0.8..<0.9: return .good
        case 0.7..<0.8: return .satisfactory
        case 0.6..<0.7: return .needsImprovement
        default: return .poor
        }
    }
}

enum ExerciseRating: String, Codable {
    case excellent = "excellent"
    case good = "good"
    case satisfactory = "satisfactory"
    case needsImprovement = "needs_improvement"
    case poor = "poor"
    
    var displayName: String {
        switch self {
        case .excellent: return "Excellent"
        case .good: return "Good"
        case .satisfactory: return "Satisfactory"
        case .needsImprovement: return "Needs Improvement"
        case .poor: return "Poor"
        }
    }
    
    var color: String {
        switch self {
        case .excellent: return "green"
        case .good: return "blue"
        case .satisfactory: return "orange"
        case .needsImprovement: return "yellow"
        case .poor: return "red"
        }
    }
    
    var iconName: String {
        switch self {
        case .excellent: return "star.fill"
        case .good: return "hand.thumbsup.fill"
        case .satisfactory: return "checkmark.circle.fill"
        case .needsImprovement: return "exclamationmark.triangle.fill"
        case .poor: return "xmark.circle.fill"
        }
    }

}

// MARK: - Exercise Performance

struct ExercisePerformance: Codable {
    let overallScore: Double
    let skillScores: [String: Double]
    let timeEfficiency: Double
    let improvementAreas: [String]
    
    // Computed properties
    var strengthAreas: [String] {
        return skillScores.compactMap { key, value in
            value >= 0.8 ? key : nil
        }.sorted()
    }
    
    var weaknessAreas: [String] {
        return skillScores.compactMap { key, value in
            value < 0.6 ? key : nil
        }.sorted()
    }
    
    var averageSkillScore: Double {
        guard !skillScores.isEmpty else { return 0.0 }
        return skillScores.values.reduce(0, +) / Double(skillScores.count)
    }
    
    var performanceLevel: PerformanceLevel {
        switch overallScore {
        case 0.9...: return .mastery
        case 0.8..<0.9: return .proficient
        case 0.7..<0.8: return .developing
        case 0.6..<0.7: return .beginning
        default: return .struggling
        }
    }
}

enum PerformanceLevel: String, Codable {
    case mastery = "mastery"
    case proficient = "proficient"
    case developing = "developing"
    case beginning = "beginning"
    case struggling = "struggling"
    
    var displayName: String {
        return rawValue.capitalized
    }
    
    var description: String {
        switch self {
        case .mastery: return "You've mastered this skill"
        case .proficient: return "You're proficient in this area"
        case .developing: return "Your skills are developing well"
        case .beginning: return "You're beginning to understand this skill"
        case .struggling: return "This skill needs more practice"
        }
    }
    
    var color: String {
        switch self {
        case .mastery: return "green"
        case .proficient: return "blue"
        case .developing: return "orange"
        case .beginning: return "yellow"
        case .struggling: return "red"
        }
    }
    
    var iconName: String {
        switch self {
        case .mastery: return "crown.fill"
        case .proficient: return "checkmark.seal.fill"
        case .developing: return "arrow.up.circle.fill"
        case .beginning: return "seedling"
        case .struggling: return "exclamationmark.triangle.fill"
        }
    }
}

// MARK: - Exercise Feedback

struct ExerciseFeedback: Codable {
    let overallMessage: String
    let strengths: [String]
    let improvementAreas: [String]
    let tips: [String]
    let nextSteps: [String]
    
    // Computed properties
    var hasPositiveFeedback: Bool {
        return !strengths.isEmpty
    }
    
    var hasConstructiveFeedback: Bool {
        return !improvementAreas.isEmpty || !tips.isEmpty
    }
    
    var feedbackSummary: String {
        var summary = overallMessage
        
        if !strengths.isEmpty {
            summary += "\n\nStrengths: " + strengths.joined(separator: ", ")
        }
        
        if !improvementAreas.isEmpty {
            summary += "\n\nAreas for improvement: " + improvementAreas.joined(separator: ", ")
        }
        
        return summary
    }
}

// MARK: - Exercise Statistics

struct ExerciseStatistics: Codable {
    let totalExercisesCompleted: Int
    let averageScore: Double
    let totalTimeSpent: TimeInterval
    let skillBreakdown: [SkillArea: SkillStatistics]
    let difficultyBreakdown: [WritingExercise.Difficulty: Int]
    let recentTrend: PerformanceTrend
    
    struct SkillStatistics: Codable {
        let exercisesCompleted: Int
        let averageScore: Double
        let bestScore: Double
        let worstScore: Double
        let improvementRate: Double
        let lastPracticed: Date?
        
        var proficiencyLevel: PerformanceLevel {
            switch averageScore {
            case 0.9...: return .mastery
            case 0.8..<0.9: return .proficient
            case 0.7..<0.8: return .developing
            case 0.6..<0.7: return .beginning
            default: return .struggling
            }
        }
        
        var practiceFrequency: PracticeFrequency {
            guard let lastPracticed = lastPracticed else { return .never }
            
            let daysSinceLastPractice = Date().timeIntervalSince(lastPracticed) / (24 * 3600)
            
            switch daysSinceLastPractice {
            case 0..<1: return .daily
            case 1..<3: return .frequent
            case 3..<7: return .weekly
            case 7..<30: return .monthly
            default: return .rarely
            }
        }
    }
    
    enum PerformanceTrend: String, Codable {
        case improving = "improving"
        case stable = "stable"
        case declining = "declining"
        case insufficient_data = "insufficient_data"
        
        var displayName: String {
            switch self {
            case .improving: return "Improving"
            case .stable: return "Stable"
            case .declining: return "Declining"
            case .insufficient_data: return "Insufficient Data"
            }
        }
        
        var color: String {
            switch self {
            case .improving: return "green"
            case .stable: return "blue"
            case .declining: return "red"
            case .insufficient_data: return "gray"
            }
        }
        
        var iconName: String {
            switch self {
            case .improving: return "arrow.up.right"
            case .stable: return "arrow.right"
            case .declining: return "arrow.down.right"
            case .insufficient_data: return "questionmark"
            }
        }
    }
    
    enum PracticeFrequency: String, Codable {
        case daily = "daily"
        case frequent = "frequent"
        case weekly = "weekly"
        case monthly = "monthly"
        case rarely = "rarely"
        case never = "never"
        
        var displayName: String {
            return rawValue.capitalized
        }
        
        var color: String {
            switch self {
            case .daily: return "green"
            case .frequent: return "blue"
            case .weekly: return "orange"
            case .monthly: return "yellow"
            case .rarely: return "red"
            case .never: return "gray"
            }
        }
        
        var recommendation: String {
            switch self {
            case .daily: return "Excellent consistency!"
            case .frequent: return "Great practice rhythm"
            case .weekly: return "Consider practicing more frequently"
            case .monthly: return "Try to practice more regularly"
            case .rarely: return "Regular practice will help improve your skills"
            case .never: return "Start with short daily exercises"
            }
        }
    }
    
    // Computed properties
    var averageTimePerExercise: TimeInterval {
        guard totalExercisesCompleted > 0 else { return 0 }
        return totalTimeSpent / Double(totalExercisesCompleted)
    }
    
    var totalHoursSpent: Double {
        return totalTimeSpent / 3600
    }
    
    var mostPracticedSkill: SkillArea? {
        return skillBreakdown.max { $0.value.exercisesCompleted < $1.value.exercisesCompleted }?.key
    }
    
    var leastPracticedSkill: SkillArea? {
        return skillBreakdown.min { $0.value.exercisesCompleted < $1.value.exercisesCompleted }?.key
    }
    
    var preferredDifficulty: WritingExercise.Difficulty? {
        return difficultyBreakdown.max { $0.value < $1.value }?.key
    }
}

// MARK: - Exercise Template

struct ExerciseTemplate: Identifiable {
    let id: UUID
    let name: String
    let category: WritingExercise.ExerciseType
    let templateInstructions: String
    let variableParameters: [String] // Parameters that can be customized
    let difficultyRange: ClosedRange<WritingExercise.Difficulty>
    let estimatedTimeRange: ClosedRange<TimeInterval>
    let createdBy: String? // User ID for custom templates
    let isPublic: Bool
    let tags: [String]
    
    // Generate a specific exercise from this template
    func generateExercise(
        targetSkill: SkillArea,
        difficulty: WritingExercise.Difficulty,
        customParameters: [String: String] = [:]
    ) -> WritingExercise {
        
        var instructions = templateInstructions
        
        // Replace variable parameters
        for (parameter, value) in customParameters {
            instructions = instructions.replacingOccurrences(of: "{\(parameter)}", with: value)
        }
        
        // Calculate time estimate based on difficulty
        let baseTime = estimatedTimeRange.lowerBound
        let timeMultiplier = difficulty.experienceMultiplier
        let estimatedTime = baseTime * timeMultiplier
        
        return WritingExercise(
            id: UUID(),
            title: "\(name) (\(difficulty.displayName))",
            description: "Generated from \(name) template",
            type: category,
            targetSkill: targetSkill,
            difficulty: difficulty,
            instructions: instructions,
            objectives: generateObjectives(for: targetSkill, difficulty: difficulty),
            expectedOutcome: "Improved \(targetSkill.displayName.lowercased()) skills",
            timeEstimate: estimatedTime,
            createdDate: Date(),
        )
    }
    
    private func generateObjectives(for skill: SkillArea, difficulty: WritingExercise.Difficulty) -> [String] {
        var objectives = ["Practice \(skill.displayName.lowercased()) skills"]
        
        switch difficulty {
        case .easy:
            objectives.append("Master basic concepts")
        case .medium:
            objectives.append("Apply skills in context")
        case .hard:
            objectives.append("Demonstrate advanced understanding")
        case .expert:
            objectives.append("Achieve mastery level")
        }
        
        return objectives
    }
}

// MARK: - Custom Exercise

struct CustomExercise: Identifiable, Codable {
    let id: UUID
    let createdBy: String // User ID
    let title: String
    let description: String
    let instructions: String
    let targetSkill: SkillArea
    let difficulty: WritingExercise.Difficulty
    let estimatedTime: TimeInterval
    let isPublic: Bool
    let tags: [String]
    let createdDate: Date
    let timesUsed: Int
    let averageRating: Double
    let reviews: [ExerciseReview]
    
    struct ExerciseReview: Codable {
        let userId: String
        let rating: Int // 1-5 stars
        let comment: String?
        let reviewDate: Date
    }
    
    // Convert to standard WritingExercise
    func toWritingExercise() -> WritingExercise {
        return WritingExercise(
            id: id,
            title: title,
            description: description,
            type: .challenge,
            targetSkill: targetSkill,
            difficulty: difficulty,
            instructions: instructions,
            objectives: ["Complete custom exercise", "Apply \(targetSkill.displayName.lowercased()) skills"],
            expectedOutcome: "Improved writing skills through custom practice",
            timeEstimate: estimatedTime,
            createdDate: createdDate,
        )
    }
}

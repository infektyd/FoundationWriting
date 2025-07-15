//
//  AdaptiveLearningEngine.swift
//  FoundationWriting
//
//  Created by Hans Axelsson on 7/15/25.
//
import Foundation
import SwiftUI

/// Intelligent learning roadmap generation with skill progression tracking
@MainActor
class AdaptiveLearningEngine: ObservableObject {
    @Published var currentRoadmap: PersonalizedLearningRoadmap?
    @Published var skillProgress: [SkillArea: SkillProgress] = [:]
    @Published var learningHistory: [LearningSession] = []
    
    private let analysisService: any EnhancedWritingAnalysisService
    private let userPreferences: UserLearningPreferences
    
    init(
        analysisService: any EnhancedWritingAnalysisService = MockWritingAnalysisService(),
        userPreferences: UserLearningPreferences = UserLearningPreferences()
    ) {
        self.analysisService = analysisService
        self.userPreferences = userPreferences
        initializeSkillProgress()
    }
    
    /// Generates an adaptive learning roadmap based on analysis and user progress
    func generateAdaptiveRoadmap(
        from analysis: EnhancedWritingAnalysis,
        timeframe: Int = 4
    ) async throws -> PersonalizedLearningRoadmap {
        
        // Analyze current skill gaps
        let skillGaps = identifySkillGaps(from: analysis)
        
        // Consider user's learning history and preferences
        let personalizedModules = await createPersonalizedModules(
            for: skillGaps,
            timeframe: timeframe,
            analysis: analysis
        )
        
        // Calculate optimal learning sequence
        let optimizedSequence = optimizeLearningSequence(personalizedModules)
        
        // Generate insights based on progress
        let insights = generatePersonalizedInsights(from: analysis, skillGaps: skillGaps)
        
        let roadmap = PersonalizedLearningRoadmap(
            modules: optimizedSequence,
            totalDuration: Double(timeframe * 7 * 24 * 3600), // weeks to seconds
            personalizedInsights: insights
        )
        
        currentRoadmap = roadmap
        return roadmap
    }
    
    /// Records completion of a learning session to track progress
    func recordLearningSession(
        _ session: LearningSession
    ) {
        learningHistory.append(session)
        updateSkillProgress(from: session)
        
        // Limit history to last 50 sessions
        if learningHistory.count > 50 {
            learningHistory.removeFirst()
        }
    }
    
    /// Updates skill progress based on learning session
    private func updateSkillProgress(from session: LearningSession) {
        let skillArea = session.skillArea
        var progress = skillProgress[skillArea] ?? SkillProgress(
            skillArea: skillArea,
            currentLevel: 0.0,
            targetLevel: 1.0,
            sessionsCompleted: 0,
            lastPracticed: Date()
        )
        
        // Calculate improvement based on session performance
        let improvement = calculateImprovement(from: session)
        progress.currentLevel = min(progress.currentLevel + improvement, progress.targetLevel)
        progress.sessionsCompleted += 1
        progress.lastPracticed = session.completedAt
        
        skillProgress[skillArea] = progress
    }
    
    /// Identifies skill gaps from writing analysis
    private func identifySkillGaps(from analysis: EnhancedWritingAnalysis) -> [SkillGap] {
        var gaps: [SkillGap] = []
        
        for suggestion in analysis.improvementSuggestions {
            let skillArea = mapImprovementAreaToSkill(suggestion.area)
            let currentLevel = skillProgress[skillArea]?.currentLevel ?? 0.0
            let targetLevel = calculateTargetLevel(for: suggestion)
            
            if targetLevel > currentLevel {
                gaps.append(SkillGap(
                    skillArea: skillArea,
                    currentLevel: currentLevel,
                    targetLevel: targetLevel,
                    priority: suggestion.priority,
                    suggestion: suggestion
                ))
            }
        }
        
        return gaps.sorted { $0.priority > $1.priority }
    }
    
    /// Creates personalized learning modules
    private func createPersonalizedModules(
        for skillGaps: [SkillGap],
        timeframe: Int,
        analysis: EnhancedWritingAnalysis
    ) async -> [PersonalizedLearningRoadmap.LearningModule] {
        
        var modules: [PersonalizedLearningRoadmap.LearningModule] = []
        
        for gap in skillGaps.prefix(5) { // Focus on top 5 gaps
            let module = await createModuleForSkillGap(gap, analysis: analysis)
            modules.append(module)
        }
        
        return modules
    }
    
    /// Creates a learning module for a specific skill gap
    private func createModuleForSkillGap(
        _ gap: SkillGap,
        analysis: EnhancedWritingAnalysis
    ) async -> PersonalizedLearningRoadmap.LearningModule {
        
        let objectives = generateObjectives(for: gap)
        let exercises = await generateExercises(for: gap)
        let estimatedTime = calculateEstimatedTime(for: gap)
        let difficulty = calculateDifficulty(for: gap)
        
        return PersonalizedLearningRoadmap.LearningModule(
            title: generateModuleTitle(for: gap),
            objectives: objectives,
            estimatedTime: estimatedTime,
            difficulty: difficulty,
            exercises: exercises
        )
    }
    
    /// Optimizes the learning sequence based on dependencies and difficulty
    private func optimizeLearningSequence(
        _ modules: [PersonalizedLearningRoadmap.LearningModule]
    ) -> [PersonalizedLearningRoadmap.LearningModule] {
        
        // Sort by difficulty (easier first) and estimated time
        return modules.sorted { lhs, rhs in
            if abs(lhs.difficulty - rhs.difficulty) > 0.1 {
                return lhs.difficulty < rhs.difficulty
            }
            return lhs.estimatedTime < rhs.estimatedTime
        }
    }
    
    /// Generates personalized insights based on analysis and skill gaps
    private func generatePersonalizedInsights(
        from analysis: EnhancedWritingAnalysis,
        skillGaps: [SkillGap]
    ) -> [String: Any] {
        
        var insights: [String: Any] = [:]
        
        // Overall assessment
        insights["overallLevel"] = calculateOverallLevel()
        insights["improvementVelocity"] = calculateImprovementVelocity()
        insights["focusAreas"] = skillGaps.prefix(3).map { $0.skillArea.rawValue }
        insights["estimatedTimeToImprovement"] = estimateTimeToImprovement(skillGaps)
        insights["strengths"] = identifyStrengths()
        insights["weeklyGoal"] = generateWeeklyGoal(from: skillGaps)
        
        return insights
    }
    
    // MARK: - Helper Methods
    
    private func mapImprovementAreaToSkill(_ area: EnhancedWritingAnalysisOptions.ImprovementFocus) -> SkillArea {
        switch area {
        case .grammar: return .grammar
        case .style: return .style
        case .clarity: return .clarity
        case .vocabulary: return .vocabulary
        case .structure: return .structure
        case .tone: return .tone
        case .creativity: return .creativity
        }
    }
    
    private func calculateTargetLevel(for suggestion: EnhancedWritingAnalysis.ImprovementSuggestion) -> Double {
        // Base target on priority and learning effort
        return min(suggestion.priority * 0.8 + suggestion.learningEffort * 0.2, 1.0)
    }
    
    private func calculateImprovement(from session: LearningSession) -> Double {
        // Improvement based on session performance and time spent
        let baseImprovement = session.performanceScore * 0.1
        let timeBonus = min(session.timeSpent / 3600, 1.0) * 0.05 // Max 5% bonus for hour+ sessions
        return baseImprovement + timeBonus
    }
    
    private func initializeSkillProgress() {
        for skillArea in SkillArea.allCases {
            skillProgress[skillArea] = SkillProgress(
                skillArea: skillArea,
                currentLevel: 0.3, // Start with basic level
                targetLevel: 1.0,
                sessionsCompleted: 0,
                lastPracticed: Date().addingTimeInterval(-30 * 24 * 3600) // 30 days ago
            )
        }
    }
    
    private func generateObjectives(for gap: SkillGap) -> [String] {
        switch gap.skillArea {
        case .grammar:
            return ["Master subject-verb agreement", "Improve punctuation usage", "Reduce grammatical errors"]
        case .style:
            return ["Develop consistent writing voice", "Vary sentence structure", "Improve flow between paragraphs"]
        case .clarity:
            return ["Eliminate ambiguous phrases", "Use precise language", "Improve logical organization"]
        case .vocabulary:
            return ["Expand word choice variety", "Use domain-specific terms", "Improve word precision"]
        case .structure:
            return ["Organize ideas logically", "Improve paragraph transitions", "Create compelling introductions"]
        case .tone:
            return ["Match tone to audience", "Maintain consistent voice", "Convey appropriate emotion"]
        case .creativity:
            return ["Use vivid imagery", "Employ creative metaphors", "Develop unique perspectives"]
        }
    }
    
    private func generateExercises(for gap: SkillGap) async -> [PersonalizedLearningRoadmap.LearningExercise] {
        // Generate contextual exercises based on the specific gap
        let exerciseTitle = "Targeted \(gap.skillArea.rawValue.capitalized) Practice"
        let instructions = generateInstructions(for: gap.skillArea)
        let outcome = "Improved \(gap.skillArea.rawValue) in your writing"
        
        return [
            PersonalizedLearningRoadmap.LearningExercise(
                description: exerciseTitle,
                instructions: instructions,
                expectedOutcome: outcome,
                resources: gap.suggestion.resources
            )
        ]
    }
    
    private func generateInstructions(for skillArea: SkillArea) -> String {
        switch skillArea {
        case .grammar:
            return "Review your recent writing and identify 3 grammatical patterns to improve. Practice with targeted exercises."
        case .style:
            return "Rewrite 3 paragraphs using different sentence structures and rhythms."
        case .clarity:
            return "Take a complex paragraph and rewrite it to be 30% shorter while maintaining all key information."
        case .vocabulary:
            return "Replace 10 generic words in your writing with more specific, precise alternatives."
        case .structure:
            return "Outline your ideas before writing and practice using clear topic sentences."
        case .tone:
            return "Rewrite the same paragraph for 3 different audiences (casual, professional, academic)."
        case .creativity:
            return "Add vivid sensory details and creative comparisons to make your writing more engaging."
        }
    }
    
    private func calculateEstimatedTime(for gap: SkillGap) -> TimeInterval {
        let baseTime: TimeInterval = 3600 // 1 hour
        let difficultyMultiplier = gap.targetLevel - gap.currentLevel
        return baseTime * (1.0 + difficultyMultiplier)
    }
    
    private func calculateDifficulty(for gap: SkillGap) -> Double {
        return gap.targetLevel - gap.currentLevel
    }
    
    private func generateModuleTitle(for gap: SkillGap) -> String {
        return "\(gap.skillArea.displayName) Mastery"
    }
    
    private func calculateOverallLevel() -> Double {
        let levels = skillProgress.values.map { $0.currentLevel }
        return levels.reduce(0, +) / Double(levels.count)
    }
    
    private func calculateImprovementVelocity() -> Double {
        let recentSessions = learningHistory.suffix(10)
        guard !recentSessions.isEmpty else { return 0.0 }
        
        return recentSessions.map { $0.performanceScore }.reduce(0, +) / Double(recentSessions.count)
    }
    
    private func estimateTimeToImprovement(_ gaps: [SkillGap]) -> TimeInterval {
        return gaps.prefix(3).map { calculateEstimatedTime(for: $0) }.reduce(0, +)
    }
    
    private func identifyStrengths() -> [String] {
        return skillProgress.compactMap { key, value in
            value.currentLevel > 0.7 ? key.displayName : nil
        }
    }
    
    private func generateWeeklyGoal(from gaps: [SkillGap]) -> String {
        guard let topGap = gaps.first else {
            return "Continue practicing your writing skills"
        }
        return "Focus on improving \(topGap.skillArea.displayName.lowercased()) this week"
    }
}

// MARK: - Supporting Data Models

enum SkillArea: String, CaseIterable {
    case grammar, style, clarity, vocabulary, structure, tone, creativity
    
    var displayName: String {
        switch self {
        case .grammar: return "Grammar"
        case .style: return "Writing Style"
        case .clarity: return "Clarity"
        case .vocabulary: return "Vocabulary"
        case .structure: return "Structure"
        case .tone: return "Tone"
        case .creativity: return "Creativity"
        }
    }
}

struct SkillProgress: Codable {
    let skillArea: SkillArea
    var currentLevel: Double
    let targetLevel: Double
    var sessionsCompleted: Int
    var lastPracticed: Date
    
    var progressPercentage: Double {
        return currentLevel / targetLevel
    }
}

struct SkillGap {
    let skillArea: SkillArea
    let currentLevel: Double
    let targetLevel: Double
    let priority: Double
    let suggestion: EnhancedWritingAnalysis.ImprovementSuggestion
    
    var gapSize: Double {
        return targetLevel - currentLevel
    }
}

struct LearningSession: Codable, Identifiable {
    let id = UUID()
    let skillArea: SkillArea
    let performanceScore: Double // 0.0 to 1.0
    let timeSpent: TimeInterval
    let completedAt: Date
    let exerciseType: String
}

struct UserLearningPreferences: Codable {
    var preferredLearningPace: LearningPace = .moderate
    var focusAreas: Set<SkillArea> = []
    var dailyTimeCommitment: TimeInterval = 1800 // 30 minutes
    var reminderEnabled: Bool = true
    
    enum LearningPace: String, CaseIterable, Codable {
        case relaxed, moderate, intensive
        
        var multiplier: Double {
            switch self {
            case .relaxed: return 0.7
            case .moderate: return 1.0
            case .intensive: return 1.5
            }
        }
    }
}
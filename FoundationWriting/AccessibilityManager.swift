//
//  AccessibilityManager.swift
//  FoundationWriting
//
//  Created by Hans Axelsson on 7/15/25.
//
import Foundation
import SwiftUI
import AppKit
import Combine

/// Manages accessibility features and compliance for the Writing Coach app
@MainActor
class AccessibilityManager: ObservableObject {
    @Published var accessibilitySettings: AccessibilitySettings
    @Published var isVoiceOverRunning = false
    @Published var isReduceMotionEnabled = false
    @Published var isHighContrastEnabled = false
    @Published var currentFontSize: AccessibilityFontSize = .medium
    
    private let userDefaults = UserDefaults.standard
    private let settingsKey = "AccessibilitySettings"
    
    init() {
        self.accessibilitySettings = Self.loadSettings() ?? AccessibilitySettings()
        setupSystemObservers()
        updateSystemAccessibilityState()
    }
    
    /// Updates accessibility settings and saves them
    func updateSettings(_ settings: AccessibilitySettings) {
        accessibilitySettings = settings
        saveSettings()
        applyAccessibilitySettings()
    }
    
    /// Applies current accessibility settings to the app
    func applyAccessibilitySettings() {
        // Apply font size changes
        NotificationCenter.default.post(
            name: .accessibilityFontSizeChanged,
            object: accessibilitySettings.fontSize
        )
        
        // Apply contrast changes
        NotificationCenter.default.post(
            name: .accessibilityContrastChanged,
            object: accessibilitySettings.highContrast
        )
        
        // Apply motion preferences
        NotificationCenter.default.post(
            name: .accessibilityMotionChanged,
            object: accessibilitySettings.reduceMotion
        )
        
        // Apply color preferences
        NotificationCenter.default.post(
            name: .accessibilityColorChanged,
            object: accessibilitySettings.colorScheme
        )
    }
    
    /// Generates accessibility labels for UI elements
    func generateAccessibilityLabel(
        for element: AccessibilityElement,
        context: [String: Any] = [:]
    ) -> String {
        
        switch element {
        case .analysisResult(let analysis):
            return generateAnalysisAccessibilityLabel(analysis)
            
        case .suggestionCard(let suggestion):
            return generateSuggestionAccessibilityLabel(suggestion)
            
        case .progressIndicator(let progress):
            return "Progress: \(Int(progress * 100)) percent complete"
            
        case .skillLevel(let skill, let level):
            return "\(skill.displayName): Level \(level)"
            
        case .exerciseCard(let exercise):
            return generateExerciseAccessibilityLabel(exercise)
            
        case .achievementBadge(let achievement):
            return "Achievement: \(achievement.title). \(achievement.description)"
            
        case .textHighlight(let highlight):
            return generateHighlightAccessibilityLabel(highlight)
            
        case .exportButton(let format):
            return "Export analysis as \(format.displayName)"
            
        case .configurationOption(let option, let value):
            return "\(option): \(value)"
            
        case .customElement(let label):
            return label
        }
    }
    
    /// Generates accessibility hints for interactive elements
    func generateAccessibilityHint(for element: AccessibilityElement) -> String? {
        switch element {
        case .suggestionCard:
            return "Double-tap to view detailed explanation and examples"
            
        case .exerciseCard:
            return "Double-tap to start this writing exercise"
            
        case .achievementBadge:
            return "Recently unlocked achievement"
            
        case .textHighlight:
            return "Double-tap to see improvement suggestion"
            
        case .exportButton:
            return "Double-tap to export your analysis report"
            
        case .configurationOption:
            return "Double-tap to modify this setting"
            
        default:
            return nil
        }
    }
    
    /// Provides audio description for screen readers
    func generateAudioDescription(
        for content: AudioDescriptionContent
    ) -> String {
        switch content {
        case .analysisResults(let analysis):
            return generateAnalysisAudioDescription(analysis)
            
        case .improvementSuggestions(let suggestions):
            return generateSuggestionsAudioDescription(suggestions)
            
        case .learningProgress(let progress):
            return generateProgressAudioDescription(progress)
            
        case .exerciseInstructions(let exercise):
            return generateExerciseAudioDescription(exercise)
            
        case .writeAssistance(let text, let highlights):
            return generateWritingAssistanceAudioDescription(text, highlights)
        }
    }
    
    /// Checks if specific accessibility feature is enabled
    func isAccessibilityFeatureEnabled(_ feature: AccessibilityFeature) -> Bool {
        switch feature {
        case .voiceOver:
            return isVoiceOverRunning
        case .reduceMotion:
            return isReduceMotionEnabled || accessibilitySettings.reduceMotion
        case .highContrast:
            return isHighContrastEnabled || accessibilitySettings.highContrast
        case .largeText:
            return accessibilitySettings.fontSize.rawValue > AccessibilityFontSize.medium.rawValue
        case .screenReader:
            return isVoiceOverRunning
        case .colorBlindFriendly:
            return accessibilitySettings.colorBlindFriendly
        case .keyboardNavigation:
            return accessibilitySettings.keyboardNavigation
        case .audioDescriptions:
            return accessibilitySettings.audioDescriptions
        }
    }
    
    /// Provides alternative text descriptions for visual elements
    func getAlternativeTextDescription(for visualElement: VisualElement) -> String {
        switch visualElement {
        case .chart(let data):
            return generateChartDescription(data)
            
        case .graph(let data):
            return generateGraphDescription(data)
            
        case .progressBar(let value, let label):
            return "\(label): \(Int(value * 100))% complete"
            
        case .colorIndicator(let color, let meaning):
            return "\(meaning) indicated by \(color.accessibilityName)"
            
        case .badge(let badge):
            return "Badge: \(badge.displayName). \(badge.description)"
            
        case .diagram(let description):
            return "Diagram: \(description)"
        }
    }
    
    // MARK: - Private Methods
    
    private func setupSystemObservers() {
        // Observe VoiceOver state changes
        NotificationCenter.default.addObserver(
            forName: NSWorkspace.accessibilityDisplayOptionsDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                await self?.updateSystemAccessibilityState()
            }
        }
        
        // Observe reduced motion preference changes
        NotificationCenter.default.addObserver(
            forName: NSWorkspace.accessibilityDisplayOptionsDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                await self?.updateSystemAccessibilityState()
            }
        }
    }
    
    private func updateSystemAccessibilityState() {
        isVoiceOverRunning = NSWorkspace.shared.isVoiceOverEnabled
        isReduceMotionEnabled = NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
        isHighContrastEnabled = NSWorkspace.shared.accessibilityDisplayShouldIncreaseContrast
    }
    
    private static func loadSettings() -> AccessibilitySettings? {
        guard let data = UserDefaults.standard.data(forKey: "AccessibilitySettings"),
              let settings = try? JSONDecoder().decode(AccessibilitySettings.self, from: data) else {
            return nil
        }
        return settings
    }
    
    private func saveSettings() {
        if let encoded = try? JSONEncoder().encode(accessibilitySettings) {
            userDefaults.set(encoded, forKey: settingsKey)
        }
    }
    
    // MARK: - Label Generation Methods
    
    private func generateAnalysisAccessibilityLabel(_ analysis: EnhancedWritingAnalysis) -> String {
        let grade = analysis.metrics.fleschKincaidGrade
        let level = analysis.metrics.fleschKincaidLabel
        let suggestions = analysis.improvementSuggestions.count
        
        return "Writing analysis complete. Readability: \(level), grade level \(String(format: "%.1f", grade)). \(suggestions) improvement suggestions available."
    }
    
    private func generateSuggestionAccessibilityLabel(_ suggestion: EnhancedWritingAnalysis.ImprovementSuggestion) -> String {
        let priority = Int(suggestion.priority * 100)
        return "Improvement suggestion: \(suggestion.title). Priority: \(priority) percent. Area: \(suggestion.area.rawValue). \(suggestion.description)"
    }
    
    private func generateExerciseAccessibilityLabel(_ exercise: WritingExercise) -> String {
        return "Writing exercise: \(exercise.title). Type: \(exercise.type.displayName). Difficulty: \(exercise.difficulty.displayName). Estimated time: \(exercise.estimatedTimeString)."
    }
    
    private func generateHighlightAccessibilityLabel(_ highlight: TextHighlight) -> String {
        let priority = Int(highlight.priority * 100)
        return "Text highlight: \(highlight.type.rawValue) issue. Priority: \(priority) percent. \(highlight.suggestion.title)."
    }
    
    // MARK: - Audio Description Methods
    
    private func generateAnalysisAudioDescription(_ analysis: EnhancedWritingAnalysis) -> String {
        var description = "Your writing analysis is complete. "
        
        // Readability information
        let grade = analysis.metrics.fleschKincaidGrade
        let level = analysis.metrics.fleschKincaidLabel
        description += "Your text has a \(level) reading level, equivalent to grade \(String(format: "%.1f", grade)). "
        
        // Sentence structure
        let avgSentenceLength = analysis.metrics.averageSentenceLength
        if avgSentenceLength > 20 {
            description += "Your sentences are relatively long, averaging \(String(format: "%.1f", avgSentenceLength)) words. Consider breaking them up for better readability. "
        } else if avgSentenceLength < 10 {
            description += "Your sentences are quite short, averaging \(String(format: "%.1f", avgSentenceLength)) words. You might benefit from combining some for better flow. "
        } else {
            description += "Your sentence length is well-balanced, averaging \(String(format: "%.1f", avgSentenceLength)) words. "
        }
        
        // Vocabulary diversity
        let diversity = analysis.metrics.vocabularyDiversity
        if diversity >= 0.8 {
            description += "Your vocabulary is very diverse, showing excellent word variety. "
        } else if diversity >= 0.6 {
            description += "Your vocabulary shows good diversity with room for more variation. "
        } else {
            description += "Consider expanding your vocabulary to add more variety to your writing. "
        }
        
        // Improvement suggestions summary
        let suggestionCount = analysis.improvementSuggestions.count
        if suggestionCount > 0 {
            description += "I found \(suggestionCount) areas where you can improve your writing. "
            
            let topSuggestion = analysis.improvementSuggestions.first!
            description += "The top priority is \(topSuggestion.title): \(topSuggestion.description) "
        } else {
            description += "Your writing looks great with no major improvement areas identified. "
        }
        
        return description
    }
    
    private func generateSuggestionsAudioDescription(_ suggestions: [EnhancedWritingAnalysis.ImprovementSuggestion]) -> String {
        guard !suggestions.isEmpty else {
            return "No improvement suggestions at this time. Your writing is looking good!"
        }
        
        var description = "Here are your improvement suggestions, listed by priority: "
        
        for (index, suggestion) in suggestions.prefix(3).enumerated() {
            let priority = Int(suggestion.priority * 100)
            description += "Suggestion \(index + 1): \(suggestion.title). Priority level: \(priority) percent. "
            description += "\(suggestion.description) "
            
            if !suggestion.beforeExample.isEmpty {
                description += "For example, instead of '\(suggestion.beforeExample)', try '\(suggestion.afterExample)'. "
            }
        }
        
        if suggestions.count > 3 {
            description += "And \(suggestions.count - 3) additional suggestions are available in the detailed view. "
        }
        
        return description
    }
    
    private func generateProgressAudioDescription(_ progress: [SkillArea: SkillProgress]) -> String {
        guard !progress.isEmpty else {
            return "No progress data available yet. Complete some writing exercises to start tracking your improvement!"
        }
        
        var description = "Here's your writing skill progress: "
        
        // Overall progress
        let overallProgress = progress.values.map { $0.progressPercentage }.reduce(0, +) / Double(progress.count)
        description += "Overall, you're at \(Int(overallProgress * 100)) percent proficiency across all skills. "
        
        // Best skills
        let topSkills = progress.sorted { $0.value.progressPercentage > $1.value.progressPercentage }.prefix(2)
        if let bestSkill = topSkills.first {
            let percentage = Int(bestSkill.value.progressPercentage * 100)
            description += "Your strongest area is \(bestSkill.key.displayName) at \(percentage) percent. "
        }
        
        // Areas needing work
        let weakestSkills = progress.sorted { $0.value.progressPercentage < $1.value.progressPercentage }.prefix(2)
        if let weakestSkill = weakestSkills.first {
            let percentage = Int(weakestSkill.value.progressPercentage * 100)
            description += "Focus on \(weakestSkill.key.displayName), which is at \(percentage) percent. "
        }
        
        // Recent activity
        let recentlyPracticed = progress.filter { 
            Date().timeIntervalSince($0.value.lastPracticed) < 7 * 24 * 3600 
        }
        
        if !recentlyPracticed.isEmpty {
            description += "You've practiced \(recentlyPracticed.count) skills this week. Keep up the great work! "
        } else {
            description += "Try to practice some writing exercises this week to continue improving. "
        }
        
        return description
    }
    
    private func generateExerciseAudioDescription(_ exercise: WritingExercise) -> String {
        var description = "Exercise: \(exercise.title). "
        description += "This is a \(exercise.difficulty.displayName) level \(exercise.type.displayName) exercise. "
        description += "It should take approximately \(exercise.estimatedTimeString) to complete. "
        description += "The goal is to improve your \(exercise.targetSkill.displayName.lowercased()) skills. "
        
        if !exercise.objectives.isEmpty {
            description += "Objectives include: \(exercise.objectives.joined(separator: ", ")). "
        }
        
        description += "Instructions: \(exercise.instructions)"
        
        return description
    }
    
    private func generateWritingAssistanceAudioDescription(_ text: String, _ highlights: [TextHighlight]) -> String {
        let wordCount = text.split { $0.isWhitespace }.count
        var description = "You've written \(wordCount) words. "
        
        if highlights.isEmpty {
            description += "No immediate suggestions for improvement. "
        } else {
            description += "I found \(highlights.count) areas for potential improvement. "
            
            // Group by type
            let highlightGroups = Dictionary(grouping: highlights) { $0.type }
            
            for (type, groupedHighlights) in highlightGroups {
                let count = groupedHighlights.count
                if count == 1 {
                    description += "One \(type.rawValue) suggestion. "
                } else {
                    description += "\(count) \(type.rawValue) suggestions. "
                }
            }
            
            // Mention highest priority
            if let topHighlight = highlights.first {
                description += "The top priority is: \(topHighlight.suggestion.title). "
            }
        }
        
        return description
    }
    
    private func generateChartDescription(_ data: ChartData) -> String {
        switch data {
        case .skillProgress(let skills):
            var description = "Skill progress chart showing "
            
            for (skill, progress) in skills {
                let percentage = Int(progress * 100)
                description += "\(skill.displayName): \(percentage) percent. "
            }
            
            return description
            
        case .performanceTrend(let trend):
            return "Performance trend chart showing \(trend.count) data points over time. Your performance has been \(calculateTrend(trend))."
            
        case .timeSpent(let data):
            let totalHours = data.reduce(0, +) / 3600
            return "Time spent chart showing \(String(format: "%.1f", totalHours)) total hours of practice."
        }
    }
    
    private func generateGraphDescription(_ data: GraphData) -> String {
        switch data {
        case .readabilityOverTime(let points):
            return "Readability improvement graph with \(points.count) data points. Your readability has improved from \(String(format: "%.1f", points.first?.y ?? 0)) to \(String(format: "%.1f", points.last?.y ?? 0))."
            
        case .vocabularyDiversity(let points):
            return "Vocabulary diversity graph showing progression from \(String(format: "%.0f", (points.first?.y ?? 0) * 100)) percent to \(String(format: "%.0f", (points.last?.y ?? 0) * 100)) percent."
            
        case .writingFrequency(let frequency):
            return "Writing frequency data showing an average of \(String(format: "%.1f", frequency)) sessions per week."
        }
    }
    
    private func calculateTrend(_ data: [Double]) -> String {
        guard data.count >= 2 else { return "insufficient data" }
        
        let first = data.prefix(data.count / 2).reduce(0, +) / Double(data.count / 2)
        let last = data.suffix(data.count / 2).reduce(0, +) / Double(data.count / 2)
        
        let improvement = (last - first) / first
        
        if improvement > 0.1 {
            return "improving significantly"
        } else if improvement > 0.05 {
            return "improving gradually"
        } else if improvement > -0.05 {
            return "stable"
        } else if improvement > -0.1 {
            return "declining slightly"
        } else {
            return "declining"
        }
    }
}

// MARK: - Extensions for System Accessibility

extension NSWorkspace {
    var isVoiceOverEnabled: Bool {
        // Check if VoiceOver is running
        return NSWorkspace.shared.runningApplications.contains { app in
            app.bundleIdentifier == "com.apple.VoiceOver"
        }
    }
}

extension NSColor {
    var accessibilityName: String {
        // Provide descriptive names for colors
        if self.isEqual(NSColor.red) { return "red" }
        if self.isEqual(NSColor.blue) { return "blue" }
        if self.isEqual(NSColor.green) { return "green" }
        if self.isEqual(NSColor.yellow) { return "yellow" }
        if self.isEqual(NSColor.orange) { return "orange" }
        if self.isEqual(NSColor.purple) { return "purple" }
        if self.isEqual(NSColor.black) { return "black" }
        if self.isEqual(NSColor.white) { return "white" }
        if self.isEqual(NSColor.gray) { return "gray" }
        return "color"
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let accessibilityFontSizeChanged = Notification.Name("AccessibilityFontSizeChanged")
    static let accessibilityContrastChanged = Notification.Name("AccessibilityContrastChanged")
    static let accessibilityMotionChanged = Notification.Name("AccessibilityMotionChanged")
    static let accessibilityColorChanged = Notification.Name("AccessibilityColorChanged")
}

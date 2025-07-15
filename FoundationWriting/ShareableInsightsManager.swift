//
//  ShareableInsightsManager.swift
//  FoundationWriting
//
//  Created by Hans Axelsson on 7/15/25.
//
import Foundation
import AppKit
import SwiftUI

/// Manages creation and sharing of writing insights and achievements
@MainActor
class ShareableInsightsManager: ObservableObject {
    @Published var generatedInsights: [ShareableInsight] = []
    @Published var isGenerating = false
    
    private let configManager: ConfigurationManager
    
    init(configManager: ConfigurationManager) {
        self.configManager = configManager
    }
    
    /// Generates shareable insights from analysis results
    func generateInsights(
        from analysis: EnhancedWritingAnalysis,
        originalText: String,
        progress: [SkillArea: SkillProgress]
    ) async throws -> [ShareableInsight] {
        
        isGenerating = true
        defer { isGenerating = false }
        
        var insights: [ShareableInsight] = []
        
        // Progress milestone insights
        insights.append(contentsOf: generateProgressInsights(progress))
        
        // Improvement insights
        insights.append(contentsOf: generateImprovementInsights(analysis))
        
        // Achievement insights
        insights.append(contentsOf: generateAchievementInsights(analysis, progress: progress))
        
        // Writing quality insights
        insights.append(contentsOf: generateQualityInsights(analysis, textLength: originalText.count))
        
        // Personal growth insights
        insights.append(contentsOf: generateGrowthInsights(progress))
        
        generatedInsights = insights
        return insights
    }
    
    /// Shares an insight via the system share sheet
    func shareInsight(_ insight: ShareableInsight, format: ShareFormat = .image) async throws {
        switch format {
        case .image:
            let image = try await generateInsightImage(insight)
            await shareImage(image, with: insight.shareText)
            
        case .text:
            await shareText(insight.shareText)
            
        case .link:
            // Generate a shareable link (would integrate with web service)
            let linkText = "\(insight.shareText)\n\nGenerated with Writing Coach App"
            await shareText(linkText)
        }
    }
    
    /// Generates a visual image for the insight
    private func generateInsightImage(_ insight: ShareableInsight) async throws -> NSImage {
        let imageSize = CGSize(width: 800, height: 600)
        let image = NSImage(size: imageSize)
        
        image.lockFocus()
        
        // Background gradient
        let backgroundColors = getColorsForType(insight.type)
        let gradient = NSGradient(colors: backgroundColors)
        gradient?.draw(in: NSRect(origin: .zero, size: imageSize), angle: 45)
        
        // Add logo/branding area
        let brandingRect = NSRect(x: 50, y: imageSize.height - 100, width: imageSize.width - 100, height: 50)
        drawBranding(in: brandingRect)
        
        // Main content area
        let contentRect = NSRect(x: 60, y: 120, width: imageSize.width - 120, height: imageSize.height - 240)
        drawInsightContent(insight, in: contentRect)
        
        // Footer
        let footerRect = NSRect(x: 50, y: 40, width: imageSize.width - 100, height: 40)
        drawFooter(in: footerRect)
        
        image.unlockFocus()
        
        return image
    }
    
    // MARK: - Insight Generation Methods
    
    private func generateProgressInsights(_ progress: [SkillArea: SkillProgress]) -> [ShareableInsight] {
        var insights: [ShareableInsight] = []
        
        // Overall progress
        let overallProgress = progress.values.map { $0.progressPercentage }.reduce(0, +) / Double(progress.count)
        
        if overallProgress >= 0.5 {
            insights.append(ShareableInsight(
                id: UUID(),
                type: .progress,
                title: "Writing Progress Milestone! 🎯",
                description: "I've reached \(Int(overallProgress * 100))% overall progress in my writing skills!",
                metrics: ["Overall Progress": "\(Int(overallProgress * 100))%"],
                shareText: "🎯 Just reached \(Int(overallProgress * 100))% overall progress in my writing journey! Continuously improving with @WritingCoachApp #WritingGoals #PersonalGrowth",
                visualData: ProgressVisualData(
                    percentage: overallProgress,
                    skillBreakdown: progress.mapValues { $0.progressPercentage }
                )
            ))
        }
        
        // Individual skill milestones
        for (skill, skillProgress) in progress {
            if skillProgress.progressPercentage >= 0.8 && skillProgress.sessionsCompleted >= 5 {
                insights.append(ShareableInsight(
                    id: UUID(),
                    type: .achievement,
                    title: "\(skill.displayName) Mastery! 🏆",
                    description: "Achieved 80%+ proficiency in \(skill.displayName.lowercased()) after \(skillProgress.sessionsCompleted) practice sessions.",
                    metrics: [
                        "Skill Level": "\(Int(skillProgress.progressPercentage * 100))%",
                        "Sessions Completed": "\(skillProgress.sessionsCompleted)"
                    ],
                    shareText: "🏆 Just mastered \(skill.displayName.lowercased())! Reached \(Int(skillProgress.progressPercentage * 100))% proficiency after \(skillProgress.sessionsCompleted) practice sessions. #WritingSkills #Achievement",
                    visualData: SkillMasteryVisualData(
                        skillArea: skill,
                        level: skillProgress.progressPercentage,
                        sessionsCompleted: skillProgress.sessionsCompleted
                    )
                ))
            }
        }
        
        return insights
    }
    
    private func generateImprovementInsights(_ analysis: EnhancedWritingAnalysis) -> [ShareableInsight] {
        var insights: [ShareableInsight] = []
        
        // Readability improvements
        let grade = analysis.metrics.fleschKincaidGrade
        if grade <= 12 && grade >= 8 {
            insights.append(ShareableInsight(
                id: UUID(),
                type: .improvement,
                title: "Perfect Readability Level! 📚",
                description: "My writing hits the sweet spot with a \(analysis.metrics.fleschKincaidLabel) reading level (Grade \(String(format: "%.1f", grade))).",
                metrics: [
                    "Reading Level": analysis.metrics.fleschKincaidLabel,
                    "Grade Level": String(format: "%.1f", grade),
                    "Sentence Length": "\(String(format: "%.1f", analysis.metrics.averageSentenceLength)) words"
                ],
                shareText: "📚 My writing just hit the perfect readability level! \(analysis.metrics.fleschKincaidLabel) reading level means my ideas are clear and accessible. #WritingTips #ClearCommunication",
                visualData: ReadabilityVisualData(
                    grade: grade,
                    label: analysis.metrics.fleschKincaidLabel,
                    sentenceLength: analysis.metrics.averageSentenceLength,
                    vocabularyDiversity: analysis.metrics.vocabularyDiversity
                )
            ))
        }
        
        // Vocabulary diversity
        if analysis.metrics.vocabularyDiversity >= 0.7 {
            insights.append(ShareableInsight(
                id: UUID(),
                type: .improvement,
                title: "Rich Vocabulary Achievement! 🌟",
                description: "Achieved \(Int(analysis.metrics.vocabularyDiversity * 100))% vocabulary diversity - keeping my writing fresh and engaging!",
                metrics: [
                    "Vocabulary Diversity": "\(Int(analysis.metrics.vocabularyDiversity * 100))%",
                    "Average Word Length": "\(String(format: "%.1f", analysis.metrics.averageWordLength)) chars"
                ],
                shareText: "🌟 My writing vocabulary diversity just hit \(Int(analysis.metrics.vocabularyDiversity * 100))%! Keeping my language fresh and engaging. #VocabularyGoals #WritingSkills",
                visualData: VocabularyVisualData(
                    diversity: analysis.metrics.vocabularyDiversity,
                    averageWordLength: analysis.metrics.averageWordLength
                )
            ))
        }
        
        return insights
    }
    
    private func generateAchievementInsights(_ analysis: EnhancedWritingAnalysis, progress: [SkillArea: SkillProgress]) -> [ShareableInsight] {
        var insights: [ShareableInsight] = []
        
        // Multiple area improvement
        let highPrioritySuggestions = analysis.improvementSuggestions.filter { $0.priority >= 0.7 }
        if highPrioritySuggestions.count >= 3 {
            let areas = Set(highPrioritySuggestions.map { $0.area })
            
            insights.append(ShareableInsight(
                id: UUID(),
                type: .achievement,
                title: "Multi-Skill Growth! 🚀",
                description: "Identified improvement opportunities across \(areas.count) different writing areas - ready to level up!",
                metrics: [
                    "Focus Areas": "\(areas.count)",
                    "High Priority Items": "\(highPrioritySuggestions.count)"
                ],
                shareText: "🚀 Excited about my writing growth plan! Focusing on \(areas.count) key areas with \(highPrioritySuggestions.count) targeted improvements. #WritingGrowth #SkillDevelopment",
                visualData: MultiSkillVisualData(
                    focusAreas: Array(areas),
                    suggestionCount: highPrioritySuggestions.count
                )
            ))
        }
        
        // Consistency achievement
        let totalSessions = progress.values.map { $0.sessionsCompleted }.reduce(0, +)
        if totalSessions >= 20 {
            insights.append(ShareableInsight(
                id: UUID(),
                type: .achievement,
                title: "Consistency Champion! 💪",
                description: "Completed \(totalSessions) writing practice sessions - building strong habits!",
                metrics: [
                    "Total Sessions": "\(totalSessions)",
                    "Active Skills": "\(progress.count)"
                ],
                shareText: "💪 Consistency pays off! Just completed my \(totalSessions)th writing practice session. Building strong writing habits one session at a time! #WritingHabits #Consistency",
                visualData: ConsistencyVisualData(
                    totalSessions: totalSessions,
                    skillCount: progress.count
                )
            ))
        }
        
        return insights
    }
    
    private func generateQualityInsights(_ analysis: EnhancedWritingAnalysis, textLength: Int) -> [ShareableInsight] {
        var insights: [ShareableInsight] = []
        
        // Long form writing achievement
        if textLength >= 1000 {
            let wordCount = textLength / 5 // Rough word count estimation
            
            insights.append(ShareableInsight(
                id: UUID(),
                type: .quality,
                title: "Long-Form Writing! ✍️",
                description: "Analyzed a substantial piece with ~\(wordCount) words - showing commitment to detailed expression!",
                metrics: [
                    "Approximate Words": "\(wordCount)",
                    "Character Count": "\(textLength)",
                    "Improvement Areas": "\(analysis.improvementSuggestions.count)"
                ],
                shareText: "✍️ Just analyzed a ~\(wordCount) word piece! Committed to improving my long-form writing with detailed feedback. #LongFormWriting #WritingAnalysis",
                visualData: QualityVisualData(
                    wordCount: wordCount,
                    characterCount: textLength,
                    suggestionCount: analysis.improvementSuggestions.count
                )
            ))
        }
        
        return insights
    }
    
    private func generateGrowthInsights(_ progress: [SkillArea: SkillProgress]) -> [ShareableInsight] {
        var insights: [ShareableInsight] = []
        
        // Recent practice insight
        let recentlyPracticed = progress.values.filter { 
            Date().timeIntervalSince($0.lastPracticed) < 7 * 24 * 3600 // Within last week
        }
        
        if recentlyPracticed.count >= 3 {
            insights.append(ShareableInsight(
                id: UUID(),
                type: .growth,
                title: "Active Learner! 📈",
                description: "Practiced \(recentlyPracticed.count) different writing skills this week - staying sharp!",
                metrics: [
                    "Skills Practiced": "\(recentlyPracticed.count)",
                    "This Week": "Active"
                ],
                shareText: "📈 Staying sharp! Practiced \(recentlyPracticed.count) different writing skills this week. Continuous improvement is the key! #WritingPractice #ActiveLearning",
                visualData: GrowthVisualData(
                    recentSkillsPracticed: recentlyPracticed.count,
                    timeframe: "This Week"
                )
            ))
        }
        
        return insights
    }
    
    // MARK: - Drawing Helpers
    
    private func getColorsForType(_ type: ShareableInsight.InsightType) -> [NSColor] {
        switch type {
        case .progress:
            return [NSColor.systemBlue, NSColor.systemTeal]
        case .improvement:
            return [NSColor.systemGreen, NSColor.systemMint]
        case .achievement:
            return [NSColor.systemOrange, NSColor.systemYellow]
        case .quality:
            return [NSColor.systemPurple, NSColor.systemPink]
        case .growth:
            return [NSColor.systemIndigo, NSColor.systemBlue]
        }
    }
    
    private func drawBranding(in rect: NSRect) {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 18, weight: .semibold),
            .foregroundColor: NSColor.white
        ]
        
        let brandText = "Writing Coach"
        let attributedString = NSAttributedString(string: brandText, attributes: attributes)
        
        let textSize = attributedString.size()
        let textRect = NSRect(
            x: rect.maxX - textSize.width,
            y: rect.minY + (rect.height - textSize.height) / 2,
            width: textSize.width,
            height: textSize.height
        )
        
        attributedString.draw(in: textRect)
    }
    
    private func drawInsightContent(_ insight: ShareableInsight, in rect: NSRect) {
        var currentY = rect.maxY - 40
        
        // Title
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 32, weight: .bold),
            .foregroundColor: NSColor.white
        ]
        
        let titleString = NSAttributedString(string: insight.title, attributes: titleAttributes)
        let titleSize = titleString.size()
        let titleRect = NSRect(
            x: rect.minX,
            y: currentY - titleSize.height,
            width: rect.width,
            height: titleSize.height
        )
        
        titleString.draw(in: titleRect)
        currentY -= titleSize.height + 30
        
        // Description
        let descAttributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 18, weight: .medium),
            .foregroundColor: NSColor.white.withAlphaComponent(0.9)
        ]
        
        let descString = NSAttributedString(string: insight.description, attributes: descAttributes)
        let descSize = descString.size()
        let descRect = NSRect(
            x: rect.minX,
            y: currentY - descSize.height,
            width: rect.width,
            height: descSize.height
        )
        
        descString.draw(in: descRect)
        currentY -= descSize.height + 40
        
        // Metrics
        let metricsAttributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 16, weight: .medium),
            .foregroundColor: NSColor.white.withAlphaComponent(0.8)
        ]
        
        for (key, value) in insight.metrics {
            let metricText = "\(key): \(value)"
            let metricString = NSAttributedString(string: metricText, attributes: metricsAttributes)
            let metricSize = metricString.size()
            let metricRect = NSRect(
                x: rect.minX,
                y: currentY - metricSize.height,
                width: rect.width,
                height: metricSize.height
            )
            
            metricString.draw(in: metricRect)
            currentY -= metricSize.height + 10
        }
    }
    
    private func drawFooter(in rect: NSRect) {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 14, weight: .regular),
            .foregroundColor: NSColor.white.withAlphaComponent(0.7)
        ]
        
        let footerText = "Enhanced by Foundation Models"
        let attributedString = NSAttributedString(string: footerText, attributes: attributes)
        
        let textSize = attributedString.size()
        let textRect = NSRect(
            x: rect.minX + (rect.width - textSize.width) / 2,
            y: rect.minY + (rect.height - textSize.height) / 2,
            width: textSize.width,
            height: textSize.height
        )
        
        attributedString.draw(in: textRect)
    }
    
    // MARK: - Sharing Helpers
    
    private func shareImage(_ image: NSImage, with text: String) async {
        // Save image to temporary location
        guard let imageData = image.tiffRepresentation,
              let bitmapRep = NSBitmapImageRep(data: imageData),
              let pngData = bitmapRep.representation(using: .png, properties: [:]) else {
            return
        }
        
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("writing_insight_\(Date().timeIntervalSince1970)")
            .appendingPathExtension("png")
        
        try? pngData.write(to: tempURL)
        
        // Share via system share sheet
        let sharingService = NSSharingService(named: .postOnTwitter) ?? 
                           NSSharingService(named: .postOnFacebook) ??
                           NSSharingService(named: .sendViaAirDrop)
        
        sharingService?.perform(withItems: [text, tempURL])
    }
    
    private func shareText(_ text: String) async {
        let sharingService = NSSharingService(named: .postOnTwitter) ?? 
                           NSSharingService(named: .copyToPasteboard)
        
        sharingService?.perform(withItems: [text])
    }
}

// MARK: - Supporting Data Models

struct ShareableInsight: Identifiable {
    let id: UUID
    let type: InsightType
    let title: String
    let description: String
    let metrics: [String: String]
    let shareText: String
    let visualData: any ShareableVisualData
    
    enum InsightType: String, CaseIterable {
        case progress = "Progress"
        case improvement = "Improvement"
        case achievement = "Achievement"
        case quality = "Quality"
        case growth = "Growth"
    }
}

enum ShareFormat {
    case image
    case text
    case link
}

// MARK: - Visual Data Protocols

protocol ShareableVisualData {}

struct ProgressVisualData: ShareableVisualData {
    let percentage: Double
    let skillBreakdown: [SkillArea: Double]
}

struct SkillMasteryVisualData: ShareableVisualData {
    let skillArea: SkillArea
    let level: Double
    let sessionsCompleted: Int
}

struct ReadabilityVisualData: ShareableVisualData {
    let grade: Double
    let label: String
    let sentenceLength: Double
    let vocabularyDiversity: Double
}

struct VocabularyVisualData: ShareableVisualData {
    let diversity: Double
    let averageWordLength: Double
}

struct MultiSkillVisualData: ShareableVisualData {
    let focusAreas: [EnhancedWritingAnalysisOptions.ImprovementFocus]
    let suggestionCount: Int
}

struct ConsistencyVisualData: ShareableVisualData {
    let totalSessions: Int
    let skillCount: Int
}

struct QualityVisualData: ShareableVisualData {
    let wordCount: Int
    let characterCount: Int
    let suggestionCount: Int
}

struct GrowthVisualData: ShareableVisualData {
    let recentSkillsPracticed: Int
    let timeframe: String
}
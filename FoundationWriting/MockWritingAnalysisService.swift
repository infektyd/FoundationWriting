import Foundation
import SwiftUI

/// Mock implementation of WritingAnalysisService for development and testing
class MockWritingAnalysisService: EnhancedWritingAnalysisService {
    /// Simulates network delay and analysis generation
    private func simulateDelay() async throws {
        try await Task.sleep(for: .seconds(Double.random(in: 0.5...2.0)))
    }
    
    /// Analyze writing with mock implementation
    func analyzeWriting(
        _ text: String, 
        options: EnhancedWritingAnalysisOptions
    ) async throws -> EnhancedWritingAnalysis {
        // Simulate network delay
        try await simulateDelay()
        
        // Validate input
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw WritingAnalysisError.emptyInput
        }
        
        // Generate mock improvement suggestions
        let suggestions = generateMockSuggestions(for: text, options: options)
        
        return EnhancedWritingAnalysis(
            metrics: .init(
                fleschKincaidGrade: calculateOverallScore(text) * 10.0, // Example scaling to a grade
                fleschKincaidLabel: "Mock Grade",
                averageSentenceLength: Double(text.split { $0.isWhitespace }.count) / Double(max(text.split { ".!?".contains($0) }.count, 1)),
                averageWordLength: text.split { $0.isWhitespace }.map { Double($0.count) }.reduce(0, +) / Double(max(text.split { $0.isWhitespace }.count, 1)),
                vocabularyDiversity: 0.7 // Mock value
            ),
            assessment: "This is a mock assessment of your writing.",
            improvementSuggestions: suggestions,
            methodology: "Mock analysis methodology.",
            timestamp: Date()
        )
    }
    
    /// Generate personalized learning roadmap
    func generateLearningRoadmap(
        from analysis: EnhancedWritingAnalysis, 
        timeframe: Int
    ) async throws -> PersonalizedLearningRoadmap {
        // Simulate network delay
        try await simulateDelay()
        
        return PersonalizedLearningRoadmap(
            modules: [
                .init(
                    title: "Sentence Structure Improvement",
                    objectives: [
                        "Enhance sentence variety",
                        "Improve grammatical complexity"
                    ],
                    estimatedTime: Double(timeframe * 3600), // Convert weeks to seconds
                    difficulty: 0.6,
                    exercises: [
                        .init(
                            description: "Sentence Transformation Exercise",
                            instructions: "Take simple sentences and combine them into more complex structures",
                            expectedOutcome: "More sophisticated writing style",
                            resources: analysis.improvementSuggestions.first?.resources ?? []
                        )
                    ]
                )
            ],
            totalDuration: Double(timeframe * 3600),
            personalizedInsights: [
                "writing_complexity": calculateWritingComplexity(analysis)
            ]
        )
    }
    
    /// Provide deep contextual reasoning for a suggestion
    func exploreContextualReasoning(
        _ suggestion: EnhancedWritingAnalysis.ImprovementSuggestion, 
        context: [String : Any]
    ) async throws -> ContextualReasoning {
        // Simulate network delay
        try await simulateDelay()
        
        return ContextualReasoning(
            linguisticPrinciples: [
                "Varied sentence structure improves readability",
                "Complex sentences can convey nuanced ideas"
            ],
            cognitiveInsights: [
                "Sentence variety engages the reader's attention",
                "Linguistic complexity reflects deeper thinking"
            ],
            practicalApplications: [
                "Combine related ideas into more sophisticated sentences",
                "Use subordinate clauses to add depth"
            ],
            additionalContext: context
        )
    }
    
    // MARK: - Private Helper Methods for Mock Generation
    
    private func generateMockSuggestions(
        for text: String, 
        options: EnhancedWritingAnalysisOptions
    ) -> [EnhancedWritingAnalysis.ImprovementSuggestion] {
        let complexityFactor = options.writerLevel.suggestionComplexity
        
        return [
            .init(
                title: "Enhance Sentence Variety",
                area: .style,
                description: "Improve writing by varying sentence structure",
                beforeExample: "The cat sat on the mat. It was warm.",
                afterExample: "Settling comfortably on the warm mat, the cat basked in the gentle sunlight.",
                priority: 0.7 * complexityFactor,
                learningEffort: 0.6 * complexityFactor,
                resources: [
                    .init(
                        title: "Style: Toward Clarity and Grace", 
                        author: "Joseph M. Williams", 
                        type: .book, 
                        relevanceScore: 0.9
                    )
                ],
                contextualInsights: [
                    "sentence_complexity": calculateSentenceComplexity(text)
                ]
            )
        ]
    }
    
    private func calculateOverallScore(_ text: String) -> Double {
        // Simple scoring based on text characteristics
        let wordCount = text.split { $0.isWhitespace }.count
        let sentenceCount = text.split { ".!?".contains($0) }.count
        
        // Basic scoring algorithm
        let baseScore = min(Double(wordCount) / 100.0, 1.0)
        let sentenceVariety = 1.0 - (1.0 / Double(sentenceCount + 1))
        
        return (baseScore + sentenceVariety) / 2.0
    }
    
    private func generateStrengths(_ text: String) -> [String] {
        var strengths: [String] = []
        
        if text.contains(",") { strengths.append("Uses complex sentence structures") }
        if text.contains("however") || text.contains("moreover") { strengths.append("Employs transitional phrases") }
        if text.count > 200 { strengths.append("Demonstrates sustained writing ability") }
        
        return strengths.isEmpty ? ["Clear communication"] : strengths
    }
    
    private func generateAreasForImprovement(_ text: String) -> [String] {
        var improvements: [String] = []
        
        let sentenceCount = text.split(whereSeparator: { ".!?".contains($0) }).count
        if sentenceCount < 3 { improvements.append("Sentence variety") }
        
        if text.split(whereSeparator: { $0.isWhitespace }).count < 50 { improvements.append("Depth of content") }
        
        return improvements.isEmpty ? ["Continue refining writing skills"] : improvements
    }
    
    private func calculateSentenceComplexity(_ text: String) -> Double {
        let sentences = text.split { ".!?".contains($0) }
        let avgWordCount = sentences.map { $0.split { $0.isWhitespace }.count }.reduce(0, +) / sentences.count
        
        return min(Double(avgWordCount) / 20.0, 1.0)
    }
    
    private func calculateWritingComplexity(_ analysis: EnhancedWritingAnalysis) -> Double {
        let suggestionComplexity = analysis.improvementSuggestions.map { $0.priority }.reduce(0, +)
        let overallScore = analysis.metrics.fleschKincaidGrade / 10.0
        
        return (suggestionComplexity + overallScore) / 2.0
    }
}


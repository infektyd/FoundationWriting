//
//  EnhancedWritingAnalysisService.swift
//  FoundationWriting
//
//  Created by Hans Axelsson on 7/13/25.
//
import Foundation

/// A protocol defining the contract for an advanced writing analysis service
public protocol EnhancedWritingAnalysisService {
    /// Analyzes a piece of writing and provides comprehensive feedback
    /// - Parameters:
    ///   - text: The text to be analyzed
    ///   - options: Configuration options for the analysis
    /// - Returns: A detailed writing analysis
    /// - Throws: WritingAnalysisError for various potential failure scenarios
    func analyzeWriting(
        _ text: String,
        options: EnhancedWritingAnalysisOptions
    ) async throws -> EnhancedWritingAnalysis
    
    /// Generates a personalized learning roadmap based on writing analysis
    /// - Parameters:
    ///   - analysis: The writing analysis to base the roadmap on
    ///   - timeframe: The duration for the learning roadmap (in weeks)
    /// - Returns: A customized learning plan
    /// - Throws: WritingAnalysisError for various potential failure scenarios
    func generateLearningRoadmap(
        from analysis: EnhancedWritingAnalysis,
        timeframe: Int
    ) async throws -> PersonalizedLearningRoadmap
    
    /// Provides deep contextual reasoning for a specific writing improvement suggestion
    /// - Parameters:
    ///   - suggestion: The specific improvement suggestion to explore
    ///   - context: Additional contextual information
    /// - Returns: Detailed contextual reasoning
    /// - Throws: WritingAnalysisError for various potential failure scenarios
    func exploreContextualReasoning(
        _ suggestion: EnhancedWritingAnalysis.ImprovementSuggestion,
        context: [String: Any]
    ) async throws -> ContextualReasoning
}

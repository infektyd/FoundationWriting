//
//  EnhancedWritingAnalysis.swift
//  FoundationWriting
//
//  Created by Hans Axelsson on 7/13/25.
//
import Foundation

public struct EnhancedWritingAnalysis: Codable {
    public struct ImprovementSuggestion: Identifiable, Codable {
        public let id: UUID
        public let title: String
        public let area: EnhancedWritingAnalysisOptions.ImprovementFocus
        public let description: String
        public let beforeExample: String
        public let afterExample: String
        public let priority: Double
        public let learningEffort: Double
        public let resources: [ResourceReference]
        public let contextualInsights: [String: String] // Changed from Any to String for Codable
        
        public init(title: String, area: EnhancedWritingAnalysisOptions.ImprovementFocus, description: String, beforeExample: String, afterExample: String, priority: Double, learningEffort: Double, resources: [ResourceReference], contextualInsights: [String: String] = [:]) {
            self.id = UUID()
            self.title = title
            self.area = area
            self.description = description
            self.beforeExample = beforeExample
            self.afterExample = afterExample
            self.priority = priority
            self.learningEffort = learningEffort
            self.resources = resources
            self.contextualInsights = contextualInsights
        }
    }
    
    public struct ResourceReference: Codable {
        public let title: String
        public let author: String
        public let type: ResourceType
        public let relevanceScore: Double
        
        public enum ResourceType: String, Codable {
            case book
            case article
            case video
            case course
            case podcast
        }
        
        public init(title: String, author: String, type: ResourceType, relevanceScore: Double) {
            self.title = title
            self.author = author
            self.type = type
            self.relevanceScore = relevanceScore
        }
    }
    
    public struct ReadabilityMetrics: Codable {
        public let fleschKincaidGrade: Double
        public let fleschKincaidLabel: String
        public let averageSentenceLength: Double
        public let averageWordLength: Double
        public let vocabularyDiversity: Double
        
        public init(fleschKincaidGrade: Double, fleschKincaidLabel: String, averageSentenceLength: Double, averageWordLength: Double, vocabularyDiversity: Double) {
            self.fleschKincaidGrade = fleschKincaidGrade
            self.fleschKincaidLabel = fleschKincaidLabel
            self.averageSentenceLength = averageSentenceLength
            self.averageWordLength = averageWordLength
            self.vocabularyDiversity = vocabularyDiversity
        }
    }
    
    public let metrics: ReadabilityMetrics
    public let assessment: String
    public let improvementSuggestions: [ImprovementSuggestion]
    public let methodology: String
    public let timestamp: Date
    
    public init(metrics: ReadabilityMetrics, assessment: String, improvementSuggestions: [ImprovementSuggestion], methodology: String, timestamp: Date) {
        self.metrics = metrics
        self.assessment = assessment
        self.improvementSuggestions = improvementSuggestions
        self.methodology = methodology
        self.timestamp = timestamp
    }
}

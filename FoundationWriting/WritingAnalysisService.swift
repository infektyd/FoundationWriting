@_exported import Foundation

// WritingAnalysisService.swift - Protocol and minimal stub implementations for Writing Coach
// Created because ContentView.swift depends on these types

import Foundation

// MARK: - Protocols and Types

public struct WritingAnalysisOptions {
    public var temperature: Double
    public var strictness: Double
    public var maxTokens: Int
    public var targetStyle: String?
    public init(temperature: Double, strictness: Double = 0.5, maxTokens: Int = 2048, targetStyle: String? = nil) {
        self.temperature = temperature
        self.strictness = strictness
        self.maxTokens = maxTokens
        self.targetStyle = targetStyle
    }
}

public enum WritingAnalysisError: Error, LocalizedError {
    case emptyInput
    case tokenLimitExceeded
    case networkError(Error)
    case modelUnavailable
    case invalidResponse(String)
    case responseParsingFailure(String)
    case other(String)
    
    public var errorDescription: String? {
        switch self {
        case .emptyInput:
            return "No text provided for analysis"
        case .tokenLimitExceeded:
            return "Text exceeds maximum token limit"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .modelUnavailable:
            return "Analysis model is currently unavailable"
        case .invalidResponse(let details):
            return "Invalid response received: \(details)"
        case .responseParsingFailure(let details):
            return "Failed to parse response: \(details)"
        case .other(let message):
            return message
        }
    }
}

public protocol WritingAnalysisService {
    func analyzeWriting(_ text: String, options: WritingAnalysisOptions) async throws -> WritingAnalysis
    func exploreItemReasoning(_ item: WritingAnalysis.ImprovementSuggestion, options: WritingAnalysisOptions) async throws -> String
}

// MARK: - WritingAnalysis Model (minimal for compilation)

public struct WritingAnalysis {
    public struct Metrics {
        public let fleschKincaidGrade: Double
        public let fleschKincaidLabel: String
        public init(fleschKincaidGrade: Double, fleschKincaidLabel: String) {
            self.fleschKincaidGrade = fleschKincaidGrade
            self.fleschKincaidLabel = fleschKincaidLabel
        }
    }
    public struct ImprovementSuggestion {
        public struct Resource {
            public enum ResourceType { case book }
            public let authorName: String
            public let workTitle: String
            public let type: ResourceType
            public init(authorName: String, workTitle: String, type: ResourceType) {
                self.authorName = authorName
                self.workTitle = workTitle
                self.type = type
            }
        }
        public let title: String
        public let summary: String
        public let beforeExample: String
        public let afterExample: String
        public let resources: [Resource]
        public init(title: String, summary: String, beforeExample: String, afterExample: String, resources: [Resource]) {
            self.title = title
            self.summary = summary
            self.beforeExample = beforeExample
            self.afterExample = afterExample
            self.resources = resources
        }
    }
    public let metrics: Metrics
    public let assessment: String
    public let improvementSuggestions: [ImprovementSuggestion]
    public let methodology: String
    public init(metrics: Metrics, assessment: String, improvementSuggestions: [ImprovementSuggestion], methodology: String) {
        self.metrics = metrics
        self.assessment = assessment
        self.improvementSuggestions = improvementSuggestions
        self.methodology = methodology
    }
}


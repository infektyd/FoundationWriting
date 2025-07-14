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
    case responseParsingFailure(String)
    case other(String)
    
    public var errorDescription: String? {
        switch self {
        case .responseParsingFailure(let msg): return "Parsing failure: \(msg)"
        case .other(let msg): return msg
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

// MARK: - Utility for Flesch-Kincaid

fileprivate extension String {
    var estimatedSyllableCount: Int {
        let vowels = CharacterSet(charactersIn: "aeiouyAEIOUY")
        var count = 0
        var previousWasVowel = false
        for scalar in unicodeScalars {
            let isVowel = vowels.contains(scalar)
            if isVowel && !previousWasVowel { count += 1 }
            previousWasVowel = isVowel
        }
        return max(count, 1)
    }
    var wordCount: Int {
        split { $0.isWhitespace || $0 == "\n" }.count
    }
    var sentenceCount: Int {
        split { ".!?".contains($0) }.count
    }
}

fileprivate func fleschKincaidGradeLevel(for text: String) -> (Double, String) {
    let sentences = max(text.sentenceCount, 1)
    let words = max(text.wordCount, 1)
    let syllables = text.split { $0.isWhitespace || $0 == "\n" }
        .map { String($0).estimatedSyllableCount }
        .reduce(0, +)
    let fk = 0.39 * Double(words) / Double(sentences) + 11.8 * Double(syllables) / Double(words) - 15.59
    let grade = (fk * 10).rounded() / 10
    let label: String
    switch grade {
    case ..<5: label = "Elementary"
    case ..<8: label = "Intermediate"
    case ..<12: label = "Advanced"
    default: label = "Scholarly"
    }
    return (grade, label)
}

// MARK: - Mock Implementation

public class MockWritingAnalysisService: WritingAnalysisService {
    public init() {}
    public func analyzeWriting(_ text: String, options: WritingAnalysisOptions) async throws -> WritingAnalysis {
        // Compute metrics
        let (fkGrade, fkLabel) = fleschKincaidGradeLevel(for: text)
        
        // Make up an assessment
        let assessment: String
        if fkGrade < 5 {
            assessment = "Your writing is easy to read and suitable for a broad audience."
        } else if fkGrade < 8 {
            assessment = "Your writing is clear and mostly accessible. Consider simplifying complex sentences."
        } else if fkGrade < 12 {
            assessment = "Your writing is advanced. To reach a wider audience, use shorter sentences and simpler words."
        } else {
            assessment = "Your writing is scholarly and may be challenging for most readers."
        }

        // Two sample plan items
        let suggestions: [WritingAnalysis.ImprovementSuggestion] = [
            .init(
                title: "Clarify Sentences",
                summary: "Break up long sentences to improve readability.",
                beforeExample: "Despite the fact that he was tired, he continued working until the project was finally completed late at night, after many hours.",
                afterExample: "He was tired, but he continued working. The project was completed late at night after many hours.",
                resources: [
                    .init(authorName: "Steven Pinker", workTitle: "The Sense of Style", type: .book)
                ]
            ),
            .init(
                title: "Use Active Voice",
                summary: "Favor active voice over passive for stronger prose.",
                beforeExample: "The ball was thrown by the boy.",
                afterExample: "The boy threw the ball.",
                resources: [
                    .init(authorName: "William Strunk Jr.", workTitle: "The Elements of Style", type: .book)
                ]
            )
        ]

        // Methodology
        let methodology = "The analysis uses Flesch-Kincaid readability metrics and stylistic patterns to assess writing level and suggest improvements."

        return WritingAnalysis(
            metrics: .init(fleschKincaidGrade: fkGrade, fleschKincaidLabel: fkLabel),
            assessment: assessment,
            improvementSuggestions: suggestions,
            methodology: methodology
        )
    }
    public func exploreItemReasoning(_ item: WritingAnalysis.ImprovementSuggestion, options: WritingAnalysisOptions) async throws -> String {
        switch item.title {
        case "Clarify Sentences":
            return "Long sentences can tire readers and obscure meaning. Shorter, clearer sentences make your writing more accessible and easier to follow."
        case "Use Active Voice":
            return "Active voice creates direct, clear sentences and makes your writing more engaging. Passive voice can be vague or wordy."
        default:
            return "This suggestion will improve the clarity and readability of your text."
        }
    }
}

// MARK: - Foundation Implementation (Stub)

public class FoundationModelsAnalysisService: WritingAnalysisService {
    public init() {}
    public func analyzeWriting(_ text: String, options: WritingAnalysisOptions) async throws -> WritingAnalysis {
        // Just call mock for now
        return try await MockWritingAnalysisService().analyzeWriting(text, options: options)
    }
    public func exploreItemReasoning(_ item: WritingAnalysis.ImprovementSuggestion, options: WritingAnalysisOptions) async throws -> String {
        return try await MockWritingAnalysisService().exploreItemReasoning(item, options: options)
    }
}

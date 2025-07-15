//
//  EnhancedWritingAnalysisOptions.swift
//  FoundationWriting
//
//  Created by Hans Axelsson on 7/13/25.
//
import Foundation

public struct EnhancedWritingAnalysisOptions: Codable {
    public enum AnalysisMode: String, CaseIterable, Codable {
        case academic = "Academic Writing"
        case creative = "Creative Writing"
        case technical = "Technical Documentation"
        case business = "Business Communication"
        case personal = "Personal Correspondence"
        case scientific = "Scientific Writing"
        case journalistic = "Journalistic Style"
    }
    
    public enum ImprovementFocus: String, CaseIterable, Codable {
        case grammar
        case style
        case clarity
        case vocabulary
        case structure
        case tone
        case creativity
    }
    
    public enum WriterLevel: String, CaseIterable, Codable {
        case beginner
        case intermediate
        case advanced
        case professional
        
        public var suggestionComplexity: Double {
            switch self {
            case .beginner: return 0.3
            case .intermediate: return 0.5
            case .advanced: return 0.7
            case .professional: return 0.9
            }
        }
    }
    
    public var analysisMode: AnalysisMode
    public var writerLevel: WriterLevel
    public var improvementFoci: Set<ImprovementFocus>
    public var temperature: Double
    public var maxTokens: Int
    
    public static func createDefault() -> EnhancedWritingAnalysisOptions {
        return EnhancedWritingAnalysisOptions(
            analysisMode: .academic,
            writerLevel: .intermediate,
            improvementFoci: [.grammar, .style, .clarity],
            temperature: 0.5,
            maxTokens: 2048
        )
    }
}

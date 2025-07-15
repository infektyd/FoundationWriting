//
//  ContextualReasoning.swift
//  FoundationWriting
//
//  Created by Hans Axelsson on 7/13/25.
//
import Foundation

public struct ContextualReasoning {
    public let linguisticPrinciples: [String]
    public let cognitiveInsights: [String]
    public let practicalApplications: [String]
    public let additionalContext: [String: Any]
    
    public init(linguisticPrinciples: [String], cognitiveInsights: [String], practicalApplications: [String], additionalContext: [String: Any]) {
        self.linguisticPrinciples = linguisticPrinciples
        self.cognitiveInsights = cognitiveInsights
        self.practicalApplications = practicalApplications
        self.additionalContext = additionalContext
    }
}

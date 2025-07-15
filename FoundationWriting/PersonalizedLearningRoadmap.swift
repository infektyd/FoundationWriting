//
//  PersonalizedLearningRoadmap.swift
//  FoundationWriting
//
//  Created by Hans Axelsson on 7/13/25.
//
import Foundation

public struct PersonalizedLearningRoadmap: Codable {
    public struct LearningModule: Codable {
        public let title: String
        public let objectives: [String]
        public let estimatedTime: TimeInterval
        public let difficulty: Double
        public let exercises: [LearningExercise]
        
        public init(title: String, objectives: [String], estimatedTime: TimeInterval, difficulty: Double, exercises: [LearningExercise]) {
            self.title = title
            self.objectives = objectives
            self.estimatedTime = estimatedTime
            self.difficulty = difficulty
            self.exercises = exercises
        }
    }
    
    public struct LearningExercise: Codable {
        public let description: String
        public let instructions: String
        public let expectedOutcome: String
        public let resources: [EnhancedWritingAnalysis.ResourceReference]
        
        public init(description: String, instructions: String, expectedOutcome: String, resources: [EnhancedWritingAnalysis.ResourceReference]) {
            self.description = description
            self.instructions = instructions
            self.expectedOutcome = expectedOutcome
            self.resources = resources
        }
    }
    
    public let modules: [LearningModule]
    public let totalDuration: TimeInterval
    public let personalizedInsights: [String: String]
    
    public init(modules: [LearningModule], totalDuration: TimeInterval, personalizedInsights: [String: String]) {
        self.modules = modules
        self.totalDuration = totalDuration
        self.personalizedInsights = personalizedInsights
    }
}

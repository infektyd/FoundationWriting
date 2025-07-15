//
//  EnhancedContentViewModel.swift
//  FoundationWriting
//
//  Created by Hans Axelsson on 7/15/25.
//

import SwiftUI
import Foundation
import Combine

@MainActor
class EnhancedContentViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var userInput: String = ""
    @Published var isAnalyzing: Bool = false
    @Published var isRealTimeEnabled: Bool = true
    @Published var highlights: [TextHighlight] = []
    @Published var hoveredHighlight: TextHighlight?
    @Published var currentAnalysis: EnhancedWritingAnalysis?
    @Published var currentRoadmap: PersonalizedLearningRoadmap?
    @Published var lastAnalyzed: Date?
    
    // MARK: - Managers and Services
    let analysisService: any EnhancedWritingAnalysisService
    let configManager: ConfigurationManager
    let learningEngine: AdaptiveLearningEngine
    let realTimeManager: RealTimeAnalysisManager
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Computed Properties
    var wordCount: Int {
        userInput.split { $0.isWhitespace }.count
    }
    
    // MARK: - Initialization
    init(
        analysisService: any EnhancedWritingAnalysisService = MockWritingAnalysisService(),
        configManager: ConfigurationManager = ConfigurationManager(),
        learningEngine: AdaptiveLearningEngine = AdaptiveLearningEngine(),
        realTimeManager: RealTimeAnalysisManager = RealTimeAnalysisManager()
    ) {
        self.analysisService = analysisService
        self.configManager = configManager
        self.learningEngine = learningEngine
        self.realTimeManager = realTimeManager
        
        setupBindings()
    }
    
    // MARK: - Setup
    private func setupBindings() {
        // Bind real-time analysis
        realTimeManager.$currentAnalysis
            .assign(to: &$currentAnalysis)
        
        realTimeManager.$highlightedRanges
            .assign(to: &$highlights)
        
        realTimeManager.$isAnalyzing
            .assign(to: &$isAnalyzing)
        
        // Bind learning roadmap
        learningEngine.$currentRoadmap
            .assign(to: &$currentRoadmap)
    }
    
    // MARK: - Public Methods
    func performManualAnalysis() async {
        guard !userInput.isEmpty else { return }
        
        isAnalyzing = true
        defer { isAnalyzing = false }
        
        do {
            let options = EnhancedWritingAnalysisOptions.createDefault()
            let analysis = try await analysisService.analyzeWriting(userInput, options: options)
            currentAnalysis = analysis
            lastAnalyzed = Date()
            
            // Generate learning roadmap
            let roadmap = try await learningEngine.generateAdaptiveRoadmap(from: analysis)
            currentRoadmap = roadmap
            
        } catch {
            print("Analysis failed: \(error)")
        }
    }
    
    func onTextChange(_ newText: String) {
        userInput = newText
        
        if isRealTimeEnabled {
            let options = configManager.currentConfig.analysisOptions
            realTimeManager.analyzeText(newText, with: options)
        }
    }
    
    func onHighlightHover(_ highlight: TextHighlight?) {
        hoveredHighlight = highlight
    }
}

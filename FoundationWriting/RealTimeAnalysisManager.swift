//
//  RealTimeAnalysisManager.swift
//  FoundationWriting
//
//  Created by Hans Axelsson on 7/15/25.
//
import Foundation
import Combine

/// Manages real-time writing analysis with intelligent debouncing
@MainActor
class RealTimeAnalysisManager: ObservableObject {
    @Published var currentAnalysis: EnhancedWritingAnalysis?
    @Published var isAnalyzing: Bool = false
    @Published var highlightedRanges: [TextHighlight] = []
    
    private let analysisService: any EnhancedWritingAnalysisService
    private let debounceInterval: TimeInterval = 1.5
    private var analysisTask: Task<Void, Never>?
    private var cancellables = Set<AnyCancellable>()
    
    init(analysisService: any EnhancedWritingAnalysisService = MockWritingAnalysisService()) {
        self.analysisService = analysisService
    }
    
    /// Triggers debounced analysis for the provided text
    func analyzeText(_ text: String, with options: EnhancedWritingAnalysisOptions) {
        // Cancel any existing analysis task
        analysisTask?.cancel()
        
        // Don't analyze empty or very short text
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              text.count > 10 else {
            clearAnalysis()
            return
        }
        
        // Start new debounced analysis
        analysisTask = Task { [weak self] in
            // Wait for debounce interval
            try? await Task.sleep(for: .seconds(debounceInterval))
            
            // Check if task was cancelled during debounce
            guard !Task.isCancelled else { return }
            
            await self?.performAnalysis(text: text, options: options)
        }
    }
    
    /// Performs the actual analysis
    private func performAnalysis(text: String, options: EnhancedWritingAnalysisOptions) async {
        isAnalyzing = true
        
        do {
            let analysis = try await analysisService.analyzeWriting(text, options: options)
            
            // Only update if task wasn't cancelled
            guard !Task.isCancelled else { return }
            
            currentAnalysis = analysis
            highlightedRanges = generateHighlights(from: analysis, in: text)
            
        } catch {
            print("Analysis failed: \(error.localizedDescription)")
            // Keep previous analysis on failure
        }
        
        isAnalyzing = false
    }
    
    /// Generates text highlighting information from analysis
    private func generateHighlights(from analysis: EnhancedWritingAnalysis, in text: String) -> [TextHighlight] {
        var highlights: [TextHighlight] = []
        
        for suggestion in analysis.improvementSuggestions {
            // Find potential highlight ranges for each suggestion
            if let range = findTextRange(for: suggestion.beforeExample, in: text) {
                highlights.append(
                    TextHighlight(
                        range: range,
                        type: mapSuggestionToHighlightType(suggestion.area),
                        suggestion: suggestion,
                        priority: suggestion.priority
                    )
                )
            }
        }
        
        return highlights.sorted { $0.priority > $1.priority }
    }
    
    /// Maps improvement areas to highlight types
    private func mapSuggestionToHighlightType(_ area: EnhancedWritingAnalysisOptions.ImprovementFocus) -> TextHighlight.HighlightType {
        switch area {
        case .grammar:
            return .grammar
        case .style:
            return .style
        case .clarity:
            return .clarity
        case .vocabulary:
            return .vocabulary
        case .structure:
            return .structure
        case .tone:
            return .tone
        case .creativity:
            return .creativity
        }
    }
    
    /// Finds text ranges for highlighting (simplified implementation)
    private func findTextRange(for example: String, in text: String) -> NSRange? {
        // Simple implementation - in production, use more sophisticated text matching
        if let range = text.range(of: example) {
            return NSRange(range, in: text)
        }
        return nil
    }
    
    /// Clears current analysis and highlights
    private func clearAnalysis() {
        currentAnalysis = nil
        highlightedRanges = []
        isAnalyzing = false
    }
    
    /// Cancels any ongoing analysis
    func cancelAnalysis() {
        analysisTask?.cancel()
        isAnalyzing = false
    }
}

/// Represents a highlighted text range with associated improvement suggestion
struct TextHighlight: Identifiable {
    let id = UUID()
    let range: NSRange
    let type: HighlightType
    let suggestion: EnhancedWritingAnalysis.ImprovementSuggestion
    let priority: Double
    
    enum HighlightType: CaseIterable {
        case grammar
        case style
        case clarity
        case vocabulary
        case structure
        case tone
        case creativity
        
        var color: String {
            switch self {
            case .grammar: return "red"
            case .style: return "blue"
            case .clarity: return "orange"
            case .vocabulary: return "purple"
            case .structure: return "green"
            case .tone: return "pink"
            case .creativity: return "cyan"
            }
        }
        
        var opacity: Double {
            switch self {
            case .grammar: return 0.3
            case .style: return 0.25
            case .clarity: return 0.3
            case .vocabulary: return 0.25
            case .structure: return 0.2
            case .tone: return 0.25
            case .creativity: return 0.2
            }
        }
    }
}
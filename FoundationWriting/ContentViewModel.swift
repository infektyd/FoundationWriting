import SwiftUI
import Foundation

@MainActor
class ContentViewModel: ObservableObject {
    @Published var userInput: String = ""
    @Published var analysisResult: String = "Your analysis will appear here."
    @Published var improvementSuggestions: [String] = []
    @Published var learningRoadmap: String = "Your personalized learning roadmap will be shown here."
    private var writingService: any EnhancedWritingAnalysisService
    
    init(writingService: any EnhancedWritingAnalysisService = MockWritingAnalysisService()) {
        self.writingService = writingService
    }
    
    func performAnalysis() async {
        guard !userInput.isEmpty else {
            analysisResult = "Please enter some text for analysis."
            improvementSuggestions = []
            return
        }
        
        do {
            let options = EnhancedWritingAnalysisOptions.createDefault()
            let analysis = try await writingService.analyzeWriting(userInput, options: options)
            analysisResult = analysis.assessment
            improvementSuggestions = analysis.improvementSuggestions.map { $0.title }
        } catch {
            analysisResult = "Analysis failed: \(error.localizedDescription)"
            improvementSuggestions = []
        }
    }
    
    func generateLearningRoadmap() async {
        guard !userInput.isEmpty else { return }
        
        do {
            let options = EnhancedWritingAnalysisOptions.createDefault()
            let analysis = try await writingService.analyzeWriting(userInput, options: options)
            let roadmap = try await writingService.generateLearningRoadmap(from: analysis, timeframe: 4)
            learningRoadmap = roadmap.modules.map { $0.title }.joined(separator: ", ")
        } catch {
            learningRoadmap = "Failed to generate learning roadmap: \(error.localizedDescription)"
        }
    }
}

import SwiftUI
import Foundation

@MainActor
@Observable
class ContentViewModel: ObservableObject {
    @Published var userInput: String = ""
    @Published var analysisResult: String = "Your analysis will appear here."
    private var writingService: MockWritingAnalysisService
    
    init(writingService: MockWritingAnalysisService = MockWritingAnalysisService()) {
        self.writingService = writingService
    }
    
    func performAnalysis() async {
        guard !userInput.isEmpty else {
            analysisResult = "Please enter some text for analysis."
            return
        }
        
        do {
            let options = WritingAnalysisOptions(temperature: 0.5) // Configurable if needed
            let analysis = try await writingService.analyzeWriting(userInput, options: options)
            analysisResult = analysis.assessment
        } catch {
            analysisResult = "Analysis failed: \(error.localizedDescription)"
        }
    }
}

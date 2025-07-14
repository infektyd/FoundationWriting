//  ContentView.swift - Writing Coach with Flesch-Kincaid + Mock LLM
//  Stable version for beta development 2025-07-13

import SwiftUI
import Foundation
import Combine
import FoundationWriting

// BETA-WORKAROUND: All FoundationWriting types fully qualified to avoid ambiguity (Xcode 26 beta 3)

// MARK: Helper for Flesch-Kincaid

fileprivate extension String {
    /// Very rough syllable counter - good enough for FK.
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
}

fileprivate struct FKScore {
    let grade: Double
    let description: String

    init(text: String) {
        let sentences = max(text.split { ".!?".contains($0) }.count, 1)
        let words     = max(text.split { $0.isWhitespace || $0 == "\n" }.count, 1)
        let syllables = text.split { $0.isWhitespace || $0 == "\n" }
            .map { String($0).estimatedSyllableCount }
            .reduce(0, +)

        let fk = 0.39 * Double(words) / Double(sentences) + 11.8 * Double(syllables) / Double(words) - 15.59
        grade = fk.rounded(toPlaces: 1)
        switch grade {
        case ..<5:  description = "Elementary"
        case ..<8:  description = "Intermediate"
        case ..<12: description = "Advanced"
        default:    description = "Scholarly"
        }
    }
}

fileprivate extension Double {
    func rounded(toPlaces places: Int) -> Double {
        let p = pow(10.0, Double(places))
        return (self * p).rounded() / p
    }
}

// MARK: Design System

struct UIDesignSystem {
    static let cornerRadius: CGFloat = 16
    static let shadowOpacity: Double = 0.06
    static let blurRadius: CGFloat = 0.5
    
    static func backgroundGradient() -> LinearGradient {
        LinearGradient(
            colors: [
                Color(NSColor.windowBackgroundColor).opacity(0.5),
                Color(NSColor.controlBackgroundColor).opacity(0.4),
                Color.blue.opacity(0.1)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    static func glassOverlay() -> some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.2),
                        Color.blue.opacity(0.1),
                        Color.clear
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .blur(radius: blurRadius)
    }
}

// MARK: Reusable Glassmorphic Background

struct GlassmorphicBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: UIDesignSystem.cornerRadius)
                        .fill(UIDesignSystem.backgroundGradient())
                        .blur(radius: UIDesignSystem.blurRadius)
                    
                    UIDesignSystem.glassOverlay()
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: UIDesignSystem.cornerRadius)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.3),
                                Color.blue.opacity(0.1),
                                Color.clear
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(color: .black.opacity(UIDesignSystem.shadowOpacity), 
                    radius: 15, x: 0, y: 6)
            .clipShape(RoundedRectangle(cornerRadius: UIDesignSystem.cornerRadius))
    }
}

extension View {
    func glassmorphicStyle() -> some View {
        self.modifier(GlassmorphicBackground())
    }
}

// MARK: Error wrapper for alerts

struct ErrorWrapper: Identifiable {
    let id = UUID()
    let message: String
    
    init(_ message: String) {
        self.message = message
    }
}

// MARK: LegacyResponse struct moved outside the extension to avoid nesting in an extension

fileprivate struct LegacyResponse: Encodable {
    let writingLevelAssessment: String
    
    struct LegacyPlanItem: Encodable {
        let title: String
        let summary: String
        let before: String
        let after: String
        
        struct LegacyAuthor: Encodable {
            let name: String
            let work: String
        }
        
        let authors: [LegacyAuthor]
    }
    
    let learningPlan: [LegacyPlanItem]
    let methodology: String
}

// MARK: - Writing Analysis Service (Clean Abstraction)

// Use fully qualified type names from FoundationWriting module

// For backward compatibility with existing code
extension FoundationWriting.WritingAnalysisService {
    func generateResponse(prompt: String, temperature: Double, maxTokens: Int) async throws -> String {
        // This is a compatibility method that wraps the new protocol to support legacy code
        // It extracts a sample text from the prompt and converts the analysis to JSON
        
        // Extract writing sample from the prompt
        let sampleStartMarker = "Writing sample to analyze:"
        let sampleEndMarker = "Provide concrete before/after examples"
        
        guard let sampleStartRange = prompt.range(of: sampleStartMarker),
              let sampleEndRange = prompt.range(of: sampleEndMarker) else {
            throw FoundationWriting.WritingAnalysisError.responseParsingFailure("Could not extract writing sample from prompt")
        }
        
        let sampleStartIndex = prompt.index(sampleStartRange.upperBound, offsetBy: 1)
        let sampleEndIndex = sampleEndRange.lowerBound
        
        guard sampleStartIndex < sampleEndIndex else {
            throw FoundationWriting.WritingAnalysisError.responseParsingFailure("Invalid sample extraction range")
        }
        
        let sample = prompt[sampleStartIndex..<sampleEndIndex].trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Create analysis options
        let options = FoundationWriting.WritingAnalysisOptions(
            temperature: temperature,
            strictness: 0.5,
            maxTokens: maxTokens,
            targetStyle: nil
        )
        
        // Perform analysis using the new protocol
        let analysis = try await analyzeWriting(sample, options: options)
        
        // Convert to legacy JSON format
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted]
        
        // Convert from new model to legacy model
        let legacyPlan = analysis.improvementSuggestions.map { item in
            LegacyResponse.LegacyPlanItem(
                title: item.title,
                summary: item.summary,
                before: item.beforeExample,
                after: item.afterExample,
                authors: item.resources.map { resource in
                    LegacyResponse.LegacyPlanItem.LegacyAuthor(
                        name: resource.authorName,
                        work: resource.workTitle
                    )
                }
            )
        }
        
        let legacyResponse = LegacyResponse(
            writingLevelAssessment: analysis.assessment,
            learningPlan: legacyPlan,
            methodology: analysis.methodology
        )
        
        let data = try encoder.encode(legacyResponse)
        return String(data: data, encoding: .utf8) ?? "{}"
    }
}

// MARK: - LLM Service Implementations

// Removed ambiguous typealiases per instructions

// MARK: Raw JSON models

fileprivate struct RawAuthor: Codable { let name: String; let work: String }
fileprivate struct RawPlanItem: Codable {
    let title: String
    let summary: String
    let before: String
    let after: String
    let authors: [RawAuthor]
}
fileprivate struct RawResponse: Codable {
    let writingLevelAssessment: String
    let learningPlan: [RawPlanItem]
    let methodology: String
}

// MARK: UI models

struct AuthorRef: Identifiable { let id = UUID(); let name, work: String }
struct LearningPlanItem: Identifiable {
    let id = UUID()
    let title, summary, before, after: String
    let authors: [AuthorRef]
}
struct AnalysisResult: Identifiable {
    let id = UUID()
    let fkGrade: Double
    let fkLabel: String
    let assessment: String
    let learningPlan: [LearningPlanItem]
    let methodology: String
}

// MARK: Main ViewModel

@MainActor final class CoachVM: ObservableObject {
    @Published var inputText = ""
    @Published var result: AnalysisResult?
    @Published var isBusy = false
    @Published var error: ErrorWrapper?
    
    // Writing analysis service - easily swappable between mock and real implementation
    private let analysisService: FoundationWriting.WritingAnalysisService
    
    init(analysisService: FoundationWriting.WritingAnalysisService = FoundationWriting.MockWritingAnalysisService()) {
        self.analysisService = analysisService
    }
    
    // Alternative initializer with real implementation when ready
    static func withFoundationModels() -> CoachVM {
        CoachVM(analysisService: FoundationWriting.FoundationModelsAnalysisService())
    }

    func analyze(strictness: Double) async {
        guard !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        isBusy = true; error = nil
        
        do {
            // Create options for analysis
            let options = FoundationWriting.WritingAnalysisOptions(
                temperature: max(0.05, 1 - strictness),
                strictness: strictness,
                maxTokens: 2048
            )
            
            // Use the new protocol to analyze writing
            let analysis = try await analysisService.analyzeWriting(inputText, options: options)
            
            // Convert to legacy result format for UI compatibility
            // (We'll gradually migrate the UI to use WritingAnalysis directly)
            let plan = analysis.improvementSuggestions.map { suggestion in
                LearningPlanItem(
                    title: suggestion.title,
                    summary: suggestion.summary,
                    before: suggestion.beforeExample,
                    after: suggestion.afterExample,
                    authors: suggestion.resources.map { resource in
                        AuthorRef(name: resource.authorName, work: resource.workTitle)
                    }
                )
            }
            
            // Create the final result using our existing UI model
            result = AnalysisResult(
                fkGrade: analysis.metrics.fleschKincaidGrade,
                fkLabel: analysis.metrics.fleschKincaidLabel,
                assessment: analysis.assessment,
                learningPlan: plan,
                methodology: analysis.methodology
            )
            
        } catch let analysisError as FoundationWriting.WritingAnalysisError {
            self.error = ErrorWrapper(analysisError.localizedDescription)
        } catch {
            self.error = ErrorWrapper(error.localizedDescription)
        }
        
        isBusy = false
    }
    
    // Add a new method to get detailed reasoning for a learning plan item
    func getDetailedReasoning(for item: LearningPlanItem) async -> String? {
        do {
            // Convert from our UI model to the new model
            let resources = item.authors.map { author in
                FoundationWriting.WritingAnalysis.ImprovementSuggestion.Resource(
                    authorName: author.name,
                    workTitle: author.work,
                    type: FoundationWriting.WritingAnalysis.ImprovementSuggestion.Resource.ResourceType.book
                )
            }
            
            let suggestion = FoundationWriting.WritingAnalysis.ImprovementSuggestion(
                title: item.title,
                summary: item.summary,
                beforeExample: item.before,
                afterExample: item.after,
                resources: resources
            )
            
            // Use service to get detailed reasoning
            return try await analysisService.exploreItemReasoning(
                suggestion,
                options: FoundationWriting.WritingAnalysisOptions(temperature: 0.7)
            )
        } catch {
            // Just return nil for now - we could handle this better in the future
            return nil
        }
    }
}

// MARK: Main View

struct ContentView: View {
    @StateObject private var vm = CoachVM()

    var body: some View {
        HStack(spacing: 0) {
            // LEFT - Input sidebar with fixed width constraints
            SidebarControls(text: $vm.inputText, isBusy: vm.isBusy) {
                vm.analyze(strictness: 0.5)
            }
            .frame(minWidth: 300, idealWidth: 340, maxWidth: 400)

            Divider()

            // RIGHT - Analysis results taking remaining space
            if let res = vm.result {
                AnalysisPane(result: res)
                    .layoutPriority(1)  // Ensures this view gets remaining width
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                // Placeholder when no analysis has been done yet
                VStack {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    Text("Enter text and tap Analyze")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .alert(item: $vm.error) { (errorWrapper: ErrorWrapper) in
            Alert(
                title: Text("Analysis Error"),
                message: Text(errorWrapper.message),
                dismissButton: .default(Text("OK"))
            )
        }
    }
}

// MARK: Sub-components

struct SidebarControls: View {
    @Binding var text: String
    let isBusy: Bool
    let onAnalyze: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Writing Sample")
                    .font(.headline)
                TextEditor(text: $text)
                    .font(.system(.body, design: .monospaced))
                    .scrollContentBackground(.hidden)
                    .background(Color(.textBackgroundColor))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color(.separatorColor), lineWidth: 1)
                    )
            }
            
            Button(action: onAnalyze) {
                HStack {
                    if isBusy {
                        ProgressView()
                            .scaleEffect(0.8)
                            .progressViewStyle(CircularProgressViewStyle())
                    }
                    Text(isBusy ? "Analyzing..." : "Analyze Writing")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(isBusy || text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            
            Spacer()
        }
        .padding()
        .glassmorphicStyle()
    }
}

struct AnalysisPane: View {
    let result: AnalysisResult
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Writing Level Assessment
                SectionHeader("🖋️ Writing Level Assessment")
                VStack(alignment: .leading, spacing: 8) {
                    Text(result.assessment)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    HStack {
                        Text("Flesch-Kincaid Grade:")
                            .fontWeight(.medium)
                        Text("\(result.fkGrade, specifier: "%.1f")")
                            .foregroundColor(.primary)
                        Text("(\(result.fkLabel))")
                            .foregroundColor(.secondary)
                    }
                    .font(.subheadline)
                }

                // Learning Plan
                SectionHeader("📚 Personalized Learning Plan")
                ForEach(result.learningPlan) { item in
                    LearningCard(item: item)
                }

                // Methodology
                SectionHeader("🔬 Analysis Methodology")
                Text(result.methodology)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding()
        }
        .glassmorphicStyle()
    }
}

struct SectionHeader: View {
    var title: String
    init(_ t: String) { title = t }
    var body: some View {
        Text(title)
            .font(.title2.bold())
            .foregroundColor(.primary)
    }
}
struct LearningCard: View {
    @StateObject private var detailVM = DetailViewModel()
    let item: LearningPlanItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Title section with enhanced depth
            Button(action: {
                detailVM.toggleExpanded()
            }) {
                HStack {
                    Text(item.title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    Spacer()
                    Image(systemName: detailVM.isExpanded ? "chevron.down" : "chevron.right")
                        .foregroundColor(.secondary)
                        .animation(.spring(response: 0.3), value: detailVM.isExpanded)
                }
            }
            .buttonStyle(.plain)
            
            Divider()
            
            // Content with more pronounced 3D styling
            VStack(alignment: .leading, spacing: 8) {
                Text(item.summary)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.vertical, 4)
                
                // Example improvement section
                VStack(alignment: .leading, spacing: 8) {
                    Text("Example Improvement")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.primary)
                    
                    HStack(alignment: .top) {
                        // Before and After examples
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundColor(.red)
                                Text("Before:")
                                    .font(.caption.weight(.medium))
                            }
                            Text(item.before)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .italic()
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundColor(.green)
                                Text("After:")
                                    .font(.caption.weight(.medium))
                            }
                            Text(item.after)
                                .font(.caption)
                                .foregroundColor(.primary)
                                .italic()
                        }
                    }
                }
                .padding(.vertical, 8)
                
                // Recommended resources
                VStack(alignment: .leading, spacing: 4) {
                    Text("Recommended Resources")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.primary)
                    
                    ForEach(item.authors) { author in
                        HStack {
                            Image(systemName: "book.fill")
                                .foregroundColor(.secondary)
                                .imageScale(.small)
                            VStack(alignment: .leading) {
                                Text(author.name)
                                    .font(.caption)
                                    .foregroundColor(.primary)
                                Text(author.work)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 2)
                    }
                }
                
                // Expanded reasoning section (new feature)
                if detailVM.isExpanded {
                    VStack(alignment: .leading, spacing: 12) {
                        Divider()
                            .padding(.vertical, 4)
                        
                        if detailVM.isLoading {
                            HStack {
                                Spacer()
                                ProgressView("Loading detailed explanation...")
                                    .progressViewStyle(CircularProgressViewStyle())
                                Spacer()
                            }
                            .padding()
                        } else if let reasoning = detailVM.detailedReasoning {
                            Text("Detailed Explanation")
                                .font(.headline)
                                .padding(.bottom, 4)
                            
                            Text(.init(reasoning))
                                .font(.subheadline)
                                .lineSpacing(1.3)
                        } else {
                            Button(action: {
                                Task { 
                                    await detailVM.loadDetailedReasoning(for: item) 
                                }
                            }) {
                                HStack {
                                    Spacer()
                                    Label("Load Detailed Explanation", systemImage: "lightbulb.fill")
                                    Spacer()
                                }
                                .padding(.vertical, 8)
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    }
                    .transition(.opacity)
                    .animation(.easeInOut, value: detailVM.isExpanded)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: 500)
        .glassmorphicStyle()
        .padding(.horizontal, 8)
        .transition(.asymmetric(
            insertion: .scale.combined(with: .opacity),
            removal: .scale.combined(with: .opacity)
        ))
    }
}

// ViewModel for managing the detailed reasoning state of a learning card
class DetailViewModel: ObservableObject {
    @Published var isExpanded = false
    @Published var isLoading = false
    @Published var detailedReasoning: String?
    
    func toggleExpanded() {
        withAnimation {
            isExpanded.toggle()
        }
    }
    
    func loadDetailedReasoning(for item: LearningPlanItem) async {
        guard detailedReasoning == nil && !isLoading else { return }
        
        // Update UI state
        await MainActor.run {
            isLoading = true
        }
        
        // Access the shared ViewModel to get the detailed reasoning
        if let vm = findViewModel(),
           let reasoning = await vm.getDetailedReasoning(for: item) {
            await MainActor.run {
                self.detailedReasoning = reasoning
                self.isLoading = false
            }
        } else {
            // Fallback if the service isn't available
            await MainActor.run {
                self.detailedReasoning = "Unable to load detailed reasoning at this time."
                self.isLoading = false
            }
        }
    }
    
    // Helper to find the CoachVM in the environment
    private func findViewModel() -> CoachVM? {
        // This is a simple implementation for demo purposes
        // In a real app, you might use a more robust dependency injection approach
        return (NSApplication.shared.windows.first?.contentViewController as? NSHostingController<ContentView>)?.rootView.vm
    }
}


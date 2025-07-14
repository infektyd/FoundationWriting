//  ContentView.swift - Writing Coach with Flesch-Kincaid + Mock LLM
//  Stable version for beta development 2025-07-13

import SwiftUI
import Foundation
import Combine

// MARK: Ensure conformance to new Observable pattern
@MainActor
@Observable
class FoundationWritingServiceAdapter: FoundationWriting.WritingAnalysisService {
    private let enhanced: EnhancedWritingAnalysisService = FoundationModelsAnalysisService()
    // Existing implementation looks good
    // Ensure methods use async/await correctly
    func analyzeWriting(_ text: String, options: FoundationWriting.WritingAnalysisOptions) async throws -> FoundationWriting.WritingAnalysis {
        // Convert legacy to enhanced options (as much as possible)
        let enhancedOptions = EnhancedWritingAnalysisOptions(
            analysisMode: .academic,
            writerLevel: .intermediate, // Or map more accurately
            improvementFoci: [.grammar, .style, .clarity],
            temperature: options.temperature,
            maxTokens: options.maxTokens
        )
        let enhancedResult = try await enhanced.analyzeWriting(text, options: enhancedOptions)
        // Convert enhancedResult to legacy WritingAnalysis. Map only supported fields.
        let metrics = FoundationWriting.WritingAnalysis.Metrics(
            fleschKincaidGrade: enhancedResult.metrics.fleschKincaidGrade,
            fleschKincaidLabel: enhancedResult.metrics.fleschKincaidLabel
        )
        let suggestions = enhancedResult.improvementSuggestions.map { s in
            FoundationWriting.WritingAnalysis.ImprovementSuggestion(
                title: s.title,
                summary: s.description,
                beforeExample: s.beforeExample,
                afterExample: s.afterExample,
                resources: s.resources.map { r in
                    FoundationWriting.WritingAnalysis.ImprovementSuggestion.Resource(
                        authorName: r.author,
                        workTitle: r.title,
                        type: .book // Map type as needed
                    )
                }
            )
        }
        return FoundationWriting.WritingAnalysis(
            metrics: metrics,
            assessment: enhancedResult.assessment,
            improvementSuggestions: suggestions,
            methodology: enhancedResult.methodology
        )
    }
    
    func exploreItemReasoning(_ item: FoundationWriting.WritingAnalysis.ImprovementSuggestion, options: FoundationWriting.WritingAnalysisOptions) async throws -> String {
        // Convert to enhanced suggestion
        let enhancedSuggestion = EnhancedWritingAnalysis.ImprovementSuggestion(
            title: item.title,
            area: .style, // Or use a default
            description: item.summary,
            beforeExample: item.beforeExample,
            afterExample: item.afterExample,
            priority: 0.5,
            learningEffort: 0.5,
            resources: item.resources.map { r in
                EnhancedWritingAnalysis.ResourceReference(
                    title: r.workTitle,
                    author: r.authorName,
                    type: .book,
                    relevanceScore: 1.0
                )
            },
            contextualInsights: [:]
        )
        // Enhanced API may expect a context dictionary
        let result = try await enhanced.exploreContextualReasoning(enhancedSuggestion, context: [:])
        // Return a formatted string (combine key points)
        return ["Principles:" + result.linguisticPrinciples.joined(separator: ", "),
                "Cognitive: " + result.cognitiveInsights.joined(separator: ", "),
                "Applications: " + result.practicalApplications.joined(separator: ", ")].joined(separator: "\n")
    }
}

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

// MARK: UI Design System

struct UIDesignSystem {
    static let cornerRadius: CGFloat = 16
    static let shadowOpacity: Double = 0.06
    static let blurRadius: CGFloat = 0.5
    
    // Use new color API with higher opacity for better contrast in middle pane
    static func backgroundGradient() -> LinearGradient {
        LinearGradient(
            colors: [
                Color(.windowBackgroundColor).opacity(0.85), // increased opacity
                Color(.controlBackgroundColor).opacity(0.75), // increased opacity
                Color.blue.opacity(0.14) // slight increase
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    // Ensure view modifiers use new syntax
    static func glassOverlay() -> some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius)) // Use .clipShape instead of .cornerRadius
    }
}

// MARK: Reusable Glassmorphic Background

// Update to use new SwiftUI modifiers and allow optional strong background overlay for text-heavy panes
struct GlassmorphicBackground: ViewModifier {
    var strongBackground: Bool = false // default false
    
    func body(content: Content) -> some View {
        content
            .background(
                ZStack {
                    // Use new color and shape APIs
                    RoundedRectangle(cornerRadius: UIDesignSystem.cornerRadius)
                        .fill(UIDesignSystem.backgroundGradient())
                        .blur(radius: 2.0) // increased blur
                    
                    if strongBackground {
                        // TODO: Add solid background behind content for improved readability in text-heavy panes
                        Color(.textBackgroundColor)
                            .opacity(0.80)
                            .clipShape(RoundedRectangle(cornerRadius: UIDesignSystem.cornerRadius))
                    }
                    
                    UIDesignSystem.glassOverlay()
                }
            )
            .overlay(
                // Ensure modern shape and gradient usage
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
            .shadow(color: .black.opacity(0.12), // increased shadow opacity
                    radius: 15, x: 0, y: 6)
            .clipShape(RoundedRectangle(cornerRadius: UIDesignSystem.cornerRadius))
    }
}

extension View {
    /// Glassmorphic style modifier with optional strong background overlay for better text contrast.
    /// - Parameter strongBackground: When true, adds a semi-opaque solid background behind content.
    /// - Returns: A view with glassmorphic styling applied.
    func glassmorphicStyle(strongBackground: Bool = false) -> some View {
        self.modifier(GlassmorphicBackground(strongBackground: strongBackground))
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

// Ensure encoding compatibility
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
// Ensure async/await and modern error handling
extension FoundationWriting.WritingAnalysisService {
    func generateResponse(prompt: String, temperature: Double, maxTokens: Int) async throws -> String {
        // Defensive programming with availability check
        if #available(macOS 26.0, *) {
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
        } else {
            // Fallback mechanism
            throw WritingAnalysisError.modelUnavailable
        }
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
    let fkLabel, assessment, methodology: String
    let learningPlan: [LearningPlanItem]
}

// MARK: Main ViewModel

@MainActor
final class CoachVM: ObservableObject {
    @Published var inputText = ""
    @Published var result: AnalysisResult?
    @Published var isBusy = false
    @Published var error: ErrorWrapper?
    
    // Private service with protocol abstraction
    private let analysisService: FoundationWriting.WritingAnalysisService
    
    init(analysisService: FoundationWriting.WritingAnalysisService) {
        self.analysisService = analysisService
    }
    
    // Alternative initializers using defensive programming
    static func withFoundationModels() -> CoachVM {
        // Defensive initialization
        if #available(macOS 26.0, *) {
            return CoachVM(analysisService: FoundationWritingServiceAdapter())
        } else {
            return CoachVM.initiate()
        }
    }

    static func initiate() -> CoachVM {
        CoachVM(analysisService: FoundationWritingServiceAdapter())
    }

    // Async method with modern error handling
    func analyze(strictness: Double) async {
        guard !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        isBusy = true
        error = nil
        
        do {
            let options = FoundationWriting.WritingAnalysisOptions(
                temperature: max(0.05, 1 - strictness),
                strictness: strictness,
                maxTokens: 2048
            )
            
            let analysis = try await analysisService.analyzeWriting(inputText, options: options)
            
            // Convert to UI model
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
            
            result = AnalysisResult(
                fkGrade: analysis.metrics.fleschKincaidGrade,
                fkLabel: analysis.metrics.fleschKincaidLabel,
                assessment: analysis.assessment,
                methodology: analysis.methodology,
                learningPlan: plan
            )
            
        } catch let analysisError as FoundationWriting.WritingAnalysisError {
            self.error = ErrorWrapper(analysisError.localizedDescription)
        } catch {
            self.error = ErrorWrapper(error.localizedDescription)
        }
        
        isBusy = false
    }
    
    // Add detailed reasoning method with error handling
    func getDetailedReasoning(for item: LearningPlanItem) async -> String? {
        do {
            let resources = item.authors.map { author in
                FoundationWriting.WritingAnalysis.ImprovementSuggestion.Resource(
                    authorName: author.name,
                    workTitle: author.work,
                    type: .book
                )
            }
            
            let suggestion = FoundationWriting.WritingAnalysis.ImprovementSuggestion(
                title: item.title,
                summary: item.summary,
                beforeExample: item.before,
                afterExample: item.after,
                resources: resources
            )
            
            return try await analysisService.exploreItemReasoning(
                suggestion,
                options: FoundationWriting.WritingAnalysisOptions(temperature: 0.7)
            )
        } catch {
            // Graceful error handling
            return nil
        }
    }
}

// MARK: - New LLM Chat ViewModel and Service

/// Mock LLM Service for generating responses.
/// TODO: Replace with real LLM API integration when stable.
class LLMService {
    func generateResponse(_ input: String) async throws -> String {
        // Simulate network or processing delay
        try await Task.sleep(nanoseconds: 700_000_000) // 0.7 seconds
        
        // TODO: Replace mock response with actual API call
        return "Echo: \(input)"
    }
}

/// ViewModel managing chat interaction with the LLM.
/// Uses a simple array of strings for messages and input text.
@MainActor
final class LLMChatVM: ObservableObject {
    var messages: [String] = []
    var input: String = ""
    var isBusy = false
    
    private let service: LLMService
    
    init(service: LLMService = LLMService()) {
        self.service = service
    }
    
    /// Sends the current input message and fetches a reply.
    /// Handles errors gracefully.
    func sendMessage() async {
        let trimmedInput = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedInput.isEmpty else { return }
        
        isBusy = true
        
        // Append user message
        messages.append("You: \(trimmedInput)")
        input = ""
        
        do {
            // Fetch reply from service
            let reply = try await service.generateResponse(trimmedInput)
            messages.append("Foundation Model: \(reply)")
        } catch {
            messages.append("Error: \(error.localizedDescription)")
        }
        
        isBusy = false
    }
}

// MARK: - LLM Chat View

/// A SwiftUI view providing a chat interface to interact with the Foundation LLM.
/// Styled to match other panes with a strong glassmorphic background.
struct LLMChatPane: View {
    @StateObject private var vm = LLMChatVM()
    
    var body: some View {
        VStack(spacing: 8) {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(Array(vm.messages.enumerated()), id: \.offset) { _, message in
                            Text(message)
                                .font(.body)
                                .foregroundColor(message.hasPrefix("You:") ? .primary : (message.hasPrefix("Error:") ? .red : .blue))
                                .frame(maxWidth: .infinity, alignment: message.hasPrefix("You:") ? .trailing : .leading)
                                .padding(6)
                                .background(message.hasPrefix("You:") ? Color.blue.opacity(0.15) : Color.gray.opacity(0.15))
                                .cornerRadius(8)
                                .id(message)
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 8)
                }
                .onChange(of: vm.messages.count) {
                    if let last = vm.messages.last {
                        withAnimation {
                            proxy.scrollTo(last, anchor: .bottom)
                        }
                    }
                }
            }
            
            Divider()
            
            // Input area with text editor and send button
            HStack {
                TextEditor(text: $vm.input)
                    .frame(minHeight: 36, maxHeight: 100)
                    .font(.system(.body, design: .monospaced))
                    .scrollContentBackground(.hidden)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color(.separatorColor), lineWidth: 1)
                    )
                
                Button(action: {
                    Task { await vm.sendMessage() }
                }) {
                    if vm.isBusy {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                            .frame(width: 32, height: 32)
                    } else {
                        Image(systemName: "paperplane.fill")
                            .font(.title3)
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(vm.isBusy || vm.input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding([.horizontal, .bottom], 8)
        }
        .glassmorphicStyle(strongBackground: true)
        .frame(minWidth: 340, idealWidth: 400, maxWidth: 450)
    }
}

// MARK: Updated ContentView with three-column layout including LLMChatPane

struct ContentView: View {
    /// Initialize CoachVM eagerly for main-actor safety
    @StateObject private var vm = CoachVM.initiate()
    
    var body: some View {
        HStack(spacing: 0) {
            // LEFT - Input sidebar with fixed width constraints
            SidebarControls(text: Binding(
                get: { vm.inputText },
                set: { vm.inputText = $0 }
            ), isBusy: vm.isBusy, vm: vm)
            .frame(minWidth: 300, idealWidth: 340, maxWidth: 400)
            
            Divider()
            
            // CENTER - Analysis results taking remaining space
            if let res = vm.result {
                AnalysisPane(result: res, vm: vm)
                    .layoutPriority(1)  // Ensures this view gets remaining width
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .glassmorphicStyle(strongBackground: true)
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
                .glassmorphicStyle(strongBackground: true)
            }
            
            Divider()
            
            // RIGHT - LLM Chat Pane for interactive chat with Foundation Model
            LLMChatPane()
                .frame(minWidth: 340, idealWidth: 400, maxWidth: 450)
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
    let vm: CoachVM  // Non-optional now
    
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
            
            Button(action: {
                Task { @MainActor in
                    await vm.analyze(strictness: 0.5)
                }
            }) {
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
    let vm: CoachVM
    
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
                    LearningCard(item: item, vm: vm)
                }

                // Methodology
                SectionHeader("🔬 Analysis Methodology")
                Text(result.methodology)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding()
        }
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
    let item: LearningPlanItem
    let vm: CoachVM
    @StateObject private var detailVM: DetailViewModel
    
    init(item: LearningPlanItem, vm: CoachVM) {
        self.item = item
        self.vm = vm
        _detailVM = StateObject(wrappedValue: DetailViewModel(vm: vm))
    }
    
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
                            Button(action: loadDetailAsync) {
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
    
    private func loadDetailAsync() {
        Task { await detailVM.loadDetailedReasoning(for: item) }
    }
}

// ViewModel for managing the detailed reasoning state of a learning card
class DetailViewModel: ObservableObject {
    var isExpanded = false
    var isLoading = false
    var detailedReasoning: String?
    
    private(set) var vm: CoachVM
    
    init(vm: CoachVM) {
        self.vm = vm
    }
    
    func toggleExpanded() {
        withAnimation {
            isExpanded.toggle()
        }
    }
    
    func loadDetailedReasoning(for item: LearningPlanItem) async {
        guard detailedReasoning == nil && !isLoading else { return }
        
        await MainActor.run {
            isLoading = true
        }
        
        if let reasoning = await vm.getDetailedReasoning(for: item) {
            await MainActor.run {
                detailedReasoning = reasoning
                isLoading = false
            }
        } else {
            await MainActor.run {
                detailedReasoning = "Unable to load detailed reasoning at this time."
                isLoading = false
            }
        }
    }
}


//
//  EnhancedContentView.swift
//  FoundationWriting
//
//  Created by Hans Axelsson on 7/15/25.
//
import SwiftUI
#if canImport(AppKit)
import AppKit
#endif

/// Enhanced main content view with Phase 1 MVP features
@MainActor
struct EnhancedContentView: View {
    @StateObject private var viewModel = EnhancedContentViewModel()
    @State private var showingConfiguration = false
    @State private var selectedTab = 0
    
    var body: some View {
        HStack(spacing: 0) {
            // Main editing area
            VStack(spacing: 0) {
                // Toolbar
                toolbarView
                
                // Text editing area with real-time highlighting
                textEditingArea
                
                // Status bar
                statusBar
            }
            .frame(minWidth: 400)
            
            // Sidebar with feedback and analysis
            sidebarView
                .frame(minWidth: 300, maxWidth: 400)
        }
        .background(.regularMaterial)
        .sheet(isPresented: $showingConfiguration) {
            AdvancedConfigurationView()
        }
        .onAppear {
            setupBindings()
        }
    }
    
    // MARK: - Toolbar
    
    private var toolbarView: some View {
        HStack {
            // Title
            Text("Writing Coach")
                .font(.title2)
                .fontWeight(.semibold)
            
            Spacer()
            
            // Real-time toggle
            Toggle("Real-time", isOn: $viewModel.isRealTimeEnabled)
                .toggleStyle(SwitchToggleStyle())
                .font(.caption)
            
            // Configuration button
            Button(action: { showingConfiguration = true }) {
                Image(systemName: "gear")
                    .font(.title3)
            }
            .buttonStyle(PlainButtonStyle())
            
            // Analysis button
            Button("Analyze") {
                Task {
                    await viewModel.performManualAnalysis()
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(viewModel.userInput.isEmpty)
        }
        .padding()
        .background(.bar)
    }
    
    // MARK: - Text Editing Area
    
    private var textEditingArea: some View {
        VStack(spacing: 0) {
            // Enhanced text editor with highlighting
            ZStack(alignment: .topLeading) {
                EnhancedTextEditor(
                    text: $viewModel.userInput,
                    highlights: $viewModel.highlights,
                    onTextChange: viewModel.onTextChange,
                    onHighlightHover: viewModel.onHighlightHover
                )
                
                // Contextual feedback overlay
                if let highlight = viewModel.hoveredHighlight {
                    ContextualFeedbackPanel(
                        highlight: highlight,
                        analysisService: viewModel.analysisService
                    )
                    .offset(x: 20, y: 20)
                    .zIndex(1)
                    .transition(.opacity.combined(with: .scale))
                }
            }
        }
        .background(Color.clear)
    }
    
    // MARK: - Status Bar
    
    private var statusBar: some View {
        HStack {
            // Word count
            Label("\(viewModel.wordCount) words", systemImage: "doc.text")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
            
            // Analysis status
            if viewModel.isAnalyzing {
                HStack(spacing: 4) {
                    ProgressView()
                        .scaleEffect(0.7)
                    Text("Analyzing...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } else if let lastAnalyzed = viewModel.lastAnalyzed {
                Text("Last analyzed: \(lastAnalyzed, formatter: timeFormatter)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Highlight count
            if !viewModel.highlights.isEmpty {
                Label("\(viewModel.highlights.count) suggestions", systemImage: "lightbulb")
                    .font(.caption)
                    .foregroundColor(.blue)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(.bar)
    }
    
    // MARK: - Sidebar
    
    private var sidebarView: some View {
        VStack(spacing: 0) {
            // Tab picker
            Picker("View", selection: $selectedTab) {
                Text("Analysis").tag(0)
                Text("Progress").tag(1)
                Text("Roadmap").tag(2)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()
            
            // Tab content
            TabView(selection: $selectedTab) {
                // Analysis tab
                ScrollView {
                    LazyVStack(spacing: 16) {
                        if let analysis = viewModel.currentAnalysis {
                            AnalysisResultsView(analysis: analysis)
                        } else {
                            EmptyAnalysisView()
                        }
                    }
                    .padding()
                }
                .tag(0)
                
                // Progress tab
                ScrollView {
                    LazyVStack(spacing: 16) {
                        LearningProgressView(learningEngine: viewModel.learningEngine)
                    }
                    .padding()
                }
                .tag(1)
                
                // Roadmap tab
                ScrollView {
                    LazyVStack(spacing: 16) {
                        if let roadmap = viewModel.currentRoadmap {
                            LearningRoadmapDetailView(roadmap: roadmap)
                        } else {
                            EmptyRoadmapView()
                        }
                    }
                    .padding()
                }
                .tag(2)
            }
            .tabViewStyle(.automatic)
        }
        .background(.regularMaterial)
    }
    
    // MARK: - Helper Methods
    
    private func setupBindings() {
        // Bind real-time settings to view model
        viewModel.isRealTimeEnabled = viewModel.configManager.currentConfig.realTimeSettings.enabled
    }
    
    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }
}

// MARK: - Supporting Views

/// Analysis results display view
struct AnalysisResultsView: View {
    let analysis: EnhancedWritingAnalysis
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Overall assessment
            VStack(alignment: .leading, spacing: 8) {
                Text("Overall Assessment")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text(analysis.assessment)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(.regularMaterial)
                    )
            }
            
            // Readability metrics
            ReadabilityMetricsView(metrics: analysis.metrics)
            
            // Improvement suggestions
            if !analysis.improvementSuggestions.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Improvement Suggestions")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    LazyVStack(spacing: 8) {
                        ForEach(analysis.improvementSuggestions) { suggestion in
                            SuggestionCardView(suggestion: suggestion)
                        }
                    }
                }
            }
        }
    }
}

/// Readability metrics display
struct ReadabilityMetricsView: View {
    let metrics: EnhancedWritingAnalysis.ReadabilityMetrics
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Readability Metrics")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 4) {
                MetricRow(title: "Grade Level", value: String(format: "%.1f", metrics.fleschKincaidGrade))
                MetricRow(title: "Reading Level", value: metrics.fleschKincaidLabel)
                MetricRow(title: "Avg. Sentence Length", value: String(format: "%.1f words", metrics.averageSentenceLength))
                MetricRow(title: "Vocabulary Diversity", value: String(format: "%.0f%%", metrics.vocabularyDiversity * 100))
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(.regularMaterial)
            )
        }
    }
}

struct MetricRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
        }
    }
}

/// Individual suggestion card
struct SuggestionCardView: View {
    let suggestion: EnhancedWritingAnalysis.ImprovementSuggestion
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(suggestion.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Text("\(Int(suggestion.priority * 100))%")
                    .font(.caption)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill(colorForArea(suggestion.area).opacity(0.2))
                    )
                    .foregroundColor(colorForArea(suggestion.area))
            }
            
            Text(suggestion.description)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(.regularMaterial)
                .stroke(colorForArea(suggestion.area).opacity(0.3), lineWidth: 1)
        )
    }
    
    private func colorForArea(_ area: EnhancedWritingAnalysisOptions.ImprovementFocus) -> Color {
        switch area {
        case .grammar: return .red
        case .style: return .blue
        case .clarity: return .orange
        case .vocabulary: return .purple
        case .structure: return .green
        case .tone: return .pink
        case .creativity: return .cyan
        }
    }
}

/// Empty state views
struct EmptyAnalysisView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.largeTitle)
                .foregroundColor(.secondary)
            
            Text("Start Writing to See Analysis")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("Type in the editor to get real-time feedback or click 'Analyze' for detailed insights.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

struct EmptyRoadmapView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "map")
                .font(.largeTitle)
                .foregroundColor(.secondary)
            
            Text("Learning Roadmap")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("Complete an analysis to generate your personalized learning path.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

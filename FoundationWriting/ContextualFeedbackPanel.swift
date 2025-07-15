//
//  ContextualFeedbackPanel.swift
//  FoundationWriting
//
//  Created by Hans Axelsson on 7/15/25.
//
import SwiftUI

/// Contextual feedback panel that appears on hover with detailed explanations
struct ContextualFeedbackPanel: View {
    let highlight: TextHighlight?
    let analysisService: any EnhancedWritingAnalysisService
    
    @State private var contextualReasoning: ContextualReasoning?
    @State private var isLoading = false
    
    var body: some View {
        Group {
            if let highlight = highlight {
                VStack(alignment: .leading, spacing: 12) {
                    // Header
                    HStack {
                        Image(systemName: iconForHighlightType(highlight.type))
                            .foregroundColor(colorForHighlightType(highlight.type))
                        
                        Text(highlight.suggestion.title)
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Spacer()
                        
                        Text("\(Int(highlight.priority * 100))% priority")
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(colorForHighlightType(highlight.type).opacity(0.2))
                            )
                    }
                    
                    // Description
                    Text(highlight.suggestion.description)
                        .font(.body)
                        .foregroundColor(.secondary)
                    
                    // Before/After Examples
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Before", systemImage: "xmark.circle")
                            .font(.caption)
                            .foregroundColor(.red)
                        
                        Text(highlight.suggestion.beforeExample)
                            .font(.body)
                            .padding(8)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color.red.opacity(0.1))
                                    .stroke(Color.red.opacity(0.3), lineWidth: 1)
                            )
                        
                        Label("After", systemImage: "checkmark.circle")
                            .font(.caption)
                            .foregroundColor(.green)
                        
                        Text(highlight.suggestion.afterExample)
                            .font(.body)
                            .padding(8)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color.green.opacity(0.1))
                                    .stroke(Color.green.opacity(0.3), lineWidth: 1)
                            )
                    }
                    
                    // Contextual Reasoning
                    if isLoading {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("Loading deeper insights...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    } else if let reasoning = contextualReasoning {
                        ContextualReasoningView(reasoning: reasoning)
                    }
                    
                    // Learning Effort Indicator
                    HStack {
                        Text("Learning effort:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        ProgressView(value: highlight.suggestion.learningEffort, total: 1.0)
                            .progressViewStyle(LinearProgressViewStyle())
                            .frame(width: 60)
                        
                        Text("\(Int(highlight.suggestion.learningEffort * 100))%")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    // Resources
                    if !highlight.suggestion.resources.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Recommended Resources")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.secondary)
                            
                            ForEach(highlight.suggestion.resources.prefix(2), id: \.title) { resource in
                                HStack {
                                    Image(systemName: iconForResourceType(resource.type))
                                        .foregroundColor(.blue)
                                        .frame(width: 12)
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(resource.title)
                                            .font(.caption)
                                            .fontWeight(.medium)
                                        
                                        Text("by \(resource.author)")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    Text("\(Int(resource.relevanceScore * 100))%")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.regularMaterial)
                        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                )
                .frame(maxWidth: 320)
                .onAppear {
                    loadContextualReasoning()
                }
            }
        }
    }
    
    private func loadContextualReasoning() {
        guard let highlight = highlight else { return }
        
        isLoading = true
        
        Task {
            do {
                let reasoning = try await analysisService.exploreContextualReasoning(
                    highlight.suggestion,
                    context: [:]
                )
                
                await MainActor.run {
                    self.contextualReasoning = reasoning
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                }
            }
        }
    }
    
    private func iconForHighlightType(_ type: TextHighlight.HighlightType) -> String {
        switch type {
        case .grammar: return "textformat.abc"
        case .style: return "paintbrush"
        case .clarity: return "eye"
        case .vocabulary: return "book"
        case .structure: return "rectangle.3.group"
        case .tone: return "speaker.wave.2"
        case .creativity: return "lightbulb"
        }
    }
    
    private func colorForHighlightType(_ type: TextHighlight.HighlightType) -> Color {
        switch type {
        case .grammar: return .red
        case .style: return .blue
        case .clarity: return .orange
        case .vocabulary: return .purple
        case .structure: return .green
        case .tone: return .pink
        case .creativity: return .cyan
        }
    }
    
    private func iconForResourceType(_ type: EnhancedWritingAnalysis.ResourceReference.ResourceType) -> String {
        switch type {
        case .book: return "book"
        case .article: return "doc.text"
        case .video: return "play.rectangle"
        case .course: return "graduationcap"
        case .podcast: return "mic"
        }
    }
}

/// Displays contextual reasoning information
struct ContextualReasoningView: View {
    let reasoning: ContextualReasoning
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Why This Matters")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
            
            ForEach(reasoning.linguisticPrinciples.prefix(2), id: \.self) { principle in
                HStack(alignment: .top, spacing: 6) {
                    Image(systemName: "lightbulb.fill")
                        .foregroundColor(.yellow)
                        .frame(width: 12)
                    
                    Text(principle)
                        .font(.caption)
                        .foregroundColor(.primary)
                }
            }
            
            if !reasoning.practicalApplications.isEmpty {
                Text("How to Apply")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                    .padding(.top, 4)
                
                ForEach(reasoning.practicalApplications.prefix(1), id: \.self) { application in
                    HStack(alignment: .top, spacing: 6) {
                        Image(systemName: "arrow.right.circle.fill")
                            .foregroundColor(.blue)
                            .frame(width: 12)
                        
                        Text(application)
                            .font(.caption)
                            .foregroundColor(.primary)
                    }
                }
            }
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.blue.opacity(0.05))
                .stroke(Color.blue.opacity(0.2), lineWidth: 1)
        )
    }
}
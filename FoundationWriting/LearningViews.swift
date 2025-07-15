//
//  LearningViews.swift
//  FoundationWriting
//
//  Created by Hans Axelsson on 7/15/25.
//
import SwiftUI

/// Learning progress visualization view
struct LearningProgressView: View {
    @ObservedObject var learningEngine: AdaptiveLearningEngine
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Overall progress header
            VStack(alignment: .leading, spacing: 8) {
                Text("Learning Progress")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                if !learningEngine.skillProgress.isEmpty {
                    let overallProgress = calculateOverallProgress()
                    
                    HStack {
                        Text("Overall Level")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text("\(Int(overallProgress * 100))%")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    
                    ProgressView(value: overallProgress)
                        .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                }
            }
            
            // Skill progress cards
            if learningEngine.skillProgress.isEmpty {
                EmptyProgressView()
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(Array(learningEngine.skillProgress.keys.sorted(by: { $0.rawValue < $1.rawValue })), id: \.self) { skillArea in
                        if let progress = learningEngine.skillProgress[skillArea] {
                            SkillProgressCard(progress: progress)
                        }
                    }
                }
            }
            
            // Recent sessions
            if !learningEngine.learningHistory.isEmpty {
                RecentSessionsView(sessions: Array(learningEngine.learningHistory.suffix(5)))
            }
        }
    }
    
    private func calculateOverallProgress() -> Double {
        let values = learningEngine.skillProgress.values.map { $0.progressPercentage }
        guard !values.isEmpty else { return 0.0 }
        return values.reduce(0, +) / Double(values.count)
    }
}

/// Individual skill progress card
struct SkillProgressCard: View {
    let progress: SkillProgress
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(progress.skillArea.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Text("\(Int(progress.progressPercentage * 100))%")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(colorForProgress(progress.progressPercentage))
            }
            
            ProgressView(value: progress.progressPercentage)
                .progressViewStyle(LinearProgressViewStyle(tint: colorForProgress(progress.progressPercentage)))
            
            HStack {
                Label("\(progress.sessionsCompleted) sessions", systemImage: "clock")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("Last: \(progress.lastPracticed, formatter: relativeDateFormatter)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(.regularMaterial)
        )
    }
    
    private func colorForProgress(_ progress: Double) -> Color {
        switch progress {
        case 0.8...: return .green
        case 0.5...: return .orange
        default: return .red
        }
    }
    
    private var relativeDateFormatter: RelativeDateTimeFormatter {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter
    }
}

/// Recent learning sessions view
struct RecentSessionsView: View {
    let sessions: [LearningSession]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Recent Sessions")
                .font(.headline)
                .fontWeight(.semibold)
            
            LazyVStack(spacing: 6) {
                ForEach(sessions) { session in
                    SessionRowView(session: session)
                }
            }
        }
    }
}

/// Individual session row
struct SessionRowView: View {
    let session: LearningSession
    
    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(colorForSkill(session.skillArea))
                .frame(width: 8, height: 8)
            
            Text(session.skillArea.displayName)
                .font(.caption)
                .fontWeight(.medium)
            
            Spacer()
            
            Text("\(Int(session.performanceScore * 100))%")
                .font(.caption)
                .foregroundColor(colorForPerformance(session.performanceScore))
            
            Text(session.completedAt, formatter: timeFormatter)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
    
    private func colorForSkill(_ skill: SkillArea) -> Color {
        switch skill {
        case .grammar: return .red
        case .style: return .blue
        case .clarity: return .orange
        case .vocabulary: return .purple
        case .structure: return .green
        case .tone: return .pink
        case .creativity: return .cyan
        }
    }
    
    private func colorForPerformance(_ score: Double) -> Color {
        switch score {
        case 0.8...: return .green
        case 0.6...: return .orange
        default: return .red
        }
    }
    
    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter
    }
}

/// Empty progress state
struct EmptyProgressView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.largeTitle)
                .foregroundColor(.secondary)
            
            Text("No Progress Yet")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("Complete some writing exercises to start tracking your progress.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

// MARK: - Learning Roadmap Detail View

/// Detailed learning roadmap view
struct LearningRoadmapDetailView: View {
    let roadmap: PersonalizedLearningRoadmap
    @State private var expandedModules: Set<String> = []
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Roadmap header
            VStack(alignment: .leading, spacing: 8) {
                Text("Learning Roadmap")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                HStack {
                    Label("Duration", systemImage: "clock")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(formatDuration(roadmap.totalDuration))
                        .font(.caption)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    Label("\(roadmap.modules.count) modules", systemImage: "book")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Personalized insights
            if !roadmap.personalizedInsights.isEmpty {
                PersonalizedInsightsView(insights: roadmap.personalizedInsights)
            }
            
            // Learning modules
            LazyVStack(spacing: 12) {
                ForEach(Array(roadmap.modules.enumerated()), id: \.offset) { index, module in
                    LearningModuleCard(
                        module: module,
                        moduleIndex: index + 1,
                        isExpanded: expandedModules.contains(module.title),
                        onToggleExpansion: {
                            if expandedModules.contains(module.title) {
                                expandedModules.remove(module.title)
                            } else {
                                expandedModules.insert(module.title)
                            }
                        }
                    )
                }
            }
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let weeks = Int(duration / (7 * 24 * 3600))
        if weeks > 0 {
            return "\(weeks) week\(weeks == 1 ? "" : "s")"
        } else {
            let days = Int(duration / (24 * 3600))
            return "\(days) day\(days == 1 ? "" : "s")"
        }
    }
}

/// Personalized insights display
struct PersonalizedInsightsView: View {
    let insights: [String: Any]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Personalized Insights")
                .font(.subheadline)
                .fontWeight(.semibold)
            
            VStack(spacing: 6) {
                if let focusAreas = insights["focusAreas"] as? [String] {
                    InsightRow(
                        icon: "target",
                        title: "Focus Areas",
                        value: focusAreas.joined(separator: ", ")
                    )
                }
                
                if let weeklyGoal = insights["weeklyGoal"] as? String {
                    InsightRow(
                        icon: "calendar.badge.clock",
                        title: "This Week",
                        value: weeklyGoal
                    )
                }
                
                if let improvementRate = insights["estimatedImprovementRate"] as? Double {
                    InsightRow(
                        icon: "chart.line.uptrend.xyaxis",
                        title: "Expected Progress",
                        value: "\(Int(improvementRate * 100))% improvement"
                    )
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(.regularMaterial)
            )
        }
    }
}

/// Individual insight row
struct InsightRow: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 16)
            
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

/// Learning module card with expansion
struct LearningModuleCard: View {
    let module: PersonalizedLearningRoadmap.LearningModule
    let moduleIndex: Int
    let isExpanded: Bool
    let onToggleExpansion: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Module header
            Button(action: onToggleExpansion) {
                HStack {
                    // Module number badge
                    Text("\(moduleIndex)")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .frame(width: 20, height: 20)
                        .background(Circle().fill(.blue))
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(module.title)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                        
                        HStack {
                            Text(formatTime(module.estimatedTime))
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            
                            Text("•")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            
                            DifficultyIndicator(difficulty: module.difficulty)
                        }
                    }
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
            }
            .buttonStyle(PlainButtonStyle())
            
            // Expanded content
            if isExpanded {
                VStack(alignment: .leading, spacing: 12) {
                    Divider()
                    
                    // Objectives
                    if !module.objectives.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Learning Objectives")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.secondary)
                            
                            ForEach(module.objectives, id: \.self) { objective in
                                HStack(alignment: .top, spacing: 6) {
                                    Text("•")
                                        .font(.caption)
                                        .foregroundColor(.blue)
                                    
                                    Text(objective)
                                        .font(.caption)
                                        .foregroundColor(.primary)
                                }
                            }
                        }
                    }
                    
                    // Exercises
                    if !module.exercises.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Exercises")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.secondary)
                            
                            ForEach(Array(module.exercises.enumerated()), id: \.offset) { _, exercise in
                                ExerciseCard(exercise: exercise)
                            }
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(.regularMaterial)
                .stroke(Color.blue.opacity(0.2), lineWidth: 1)
        )
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let hours = Int(time / 3600)
        let minutes = Int((time.truncatingRemainder(dividingBy: 3600)) / 60)
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

/// Difficulty indicator
struct DifficultyIndicator: View {
    let difficulty: Double
    
    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<5) { index in
                Circle()
                    .fill(index < Int(difficulty * 5) ? difficultyColor : Color.gray.opacity(0.3))
                    .frame(width: 4, height: 4)
            }
            
            Text(difficultyText)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
    
    private var difficultyColor: Color {
        switch difficulty {
        case 0..<0.3: return .green
        case 0.3..<0.7: return .orange
        default: return .red
        }
    }
    
    private var difficultyText: String {
        switch difficulty {
        case 0..<0.3: return "Easy"
        case 0.3..<0.7: return "Medium"
        default: return "Hard"
        }
    }
}

/// Exercise card
struct ExerciseCard: View {
    let exercise: PersonalizedLearningRoadmap.LearningExercise
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button(action: { isExpanded.toggle() }) {
                HStack {
                    Text(exercise.description)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            if isExpanded {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Instructions")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                    
                    Text(exercise.instructions)
                        .font(.caption2)
                        .foregroundColor(.primary)
                    
                    Text("Expected Outcome")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                        .padding(.top, 4)
                    
                    Text(exercise.expectedOutcome)
                        .font(.caption2)
                        .foregroundColor(.primary)
                }
                .padding(.top, 4)
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
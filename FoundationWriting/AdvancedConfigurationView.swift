//
//  AdvancedConfigurationView.swift
//  FoundationWriting
//
//  Created by Hans Axelsson on 7/15/25.
//
import SwiftUI

/// Advanced configuration view for customizing analysis and learning preferences
struct AdvancedConfigurationView: View {
    @StateObject private var configManager = ConfigurationManager()
    @State private var showingPresetCreation = false
    @State private var newPresetName = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Configuration Presets
                ConfigurationPresetsSection(
                    configManager: configManager,
                    showingPresetCreation: $showingPresetCreation,
                    newPresetName: $newPresetName
                )
                
                ScrollView {
                    LazyVStack(spacing: 24) {
                        // Analysis Configuration
                        AnalysisConfigurationSection(config: $configManager.currentConfig)
                        
                        // Learning Preferences
                        LearningPreferencesSection(config: $configManager.currentConfig)
                        
                        // Writer Profile
                        WriterProfileSection(config: $configManager.currentConfig)
                        
                        // Real-time Settings
                        RealTimeSettingsSection(config: $configManager.currentConfig)
                        
                        // Export Preferences
                        ExportPreferencesSection(config: $configManager.currentConfig)
                    }
                    .padding(.horizontal)
                }
                
                // Save/Reset Actions
                ConfigurationActionsSection(configManager: configManager)
            }
            .navigationTitle("Advanced Configuration")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Reset to Default") {
                        configManager.resetToDefault()
                    }
                }
            }
        }
        .sheet(isPresented: $showingPresetCreation) {
            PresetCreationSheet(
                configManager: configManager,
                presetName: $newPresetName,
                isPresented: $showingPresetCreation
            )
        }
    }
}

/// Configuration presets management section
struct ConfigurationPresetsSection: View {
    @ObservedObject var configManager: ConfigurationManager
    @Binding var showingPresetCreation: Bool
    @Binding var newPresetName: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Configuration Presets", systemImage: "slider.horizontal.3")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button(action: { showingPresetCreation = true }) {
                    Label("New Preset", systemImage: "plus.circle")
                        .font(.caption)
                }
            }
            
            if configManager.presets.isEmpty {
                Text("No custom presets. Create one to save your configuration.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.vertical, 8)
            } else {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 8) {
                    ForEach(configManager.presets, id: \.name) { preset in
                        PresetCard(
                            preset: preset,
                            isSelected: configManager.currentPreset?.name == preset.name,
                            onSelect: { configManager.loadPreset(preset) },
                            onDelete: { configManager.deletePreset(preset) }
                        )
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.regularMaterial)
        )
        .padding(.horizontal)
    }
}

/// Individual preset card
struct PresetCard: View {
    let preset: ConfigurationPreset
    let isSelected: Bool
    let onSelect: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(preset.name)
                    .font(.caption)
                    .fontWeight(.medium)
                    .lineLimit(1)
                
                Spacer()
                
                if !preset.isBuiltIn {
                    Button(action: onDelete) {
                        Image(systemName: "trash")
                            .font(.caption2)
                            .foregroundColor(.red)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            
            Text(preset.description)
                .font(.caption2)
                .foregroundColor(.secondary)
                .lineLimit(2)
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isSelected ? Color.blue.opacity(0.2) : Color.gray.opacity(0.1))
                .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 1)
        )
        .onTapGesture(perform: onSelect)
    }
}

/// Analysis configuration section
struct AnalysisConfigurationSection: View {
    @Binding var config: WritingCoachConfiguration
    
    var body: some View {
        ConfigurationSectionCard(title: "Analysis Settings", icon: "brain.head.profile") {
            VStack(spacing: 16) {
                // Analysis Mode
                VStack(alignment: .leading, spacing: 8) {
                    Text("Analysis Mode")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Picker("Analysis Mode", selection: $config.analysisOptions.analysisMode) {
                        ForEach(EnhancedWritingAnalysisOptions.AnalysisMode.allCases, id: \.self) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                // Writer Level
                VStack(alignment: .leading, spacing: 8) {
                    Text("Writer Level")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Picker("Writer Level", selection: $config.analysisOptions.writerLevel) {
                        ForEach(EnhancedWritingAnalysisOptions.WriterLevel.allCases, id: \.self) { level in
                            Text(level.rawValue.capitalized).tag(level)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
                
                // Improvement Focus Areas
                VStack(alignment: .leading, spacing: 8) {
                    Text("Focus Areas")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 8) {
                        ForEach(EnhancedWritingAnalysisOptions.ImprovementFocus.allCases, id: \.self) { focus in
                            ToggleButton(
                                title: focus.rawValue.capitalized,
                                isSelected: config.analysisOptions.improvementFoci.contains(focus)
                            ) {
                                if config.analysisOptions.improvementFoci.contains(focus) {
                                    config.analysisOptions.improvementFoci.remove(focus)
                                } else {
                                    config.analysisOptions.improvementFoci.insert(focus)
                                }
                            }
                        }
                    }
                }
                
                // Analysis Parameters
                AnalysisParametersView(config: $config)
            }
        }
    }
}

/// Analysis parameters slider controls
struct AnalysisParametersView: View {
    @Binding var config: WritingCoachConfiguration
    
    var body: some View {
        VStack(spacing: 12) {
            SliderControl(
                title: "Analysis Sensitivity",
                value: $config.analysisOptions.temperature,
                range: 0.1...1.0,
                description: "Higher values provide more detailed feedback"
            )
            
            SliderControl(
                title: "Maximum Analysis Length",
                value: Binding(
                    get: { Double(config.analysisOptions.maxTokens) },
                    set: { config.analysisOptions.maxTokens = Int($0) }
                ),
                range: 500...4000,
                description: "Maximum text length for analysis"
            )
        }
    }
}

/// Reusable slider control
struct SliderControl: View {
    let title: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let description: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Text(String(format: "%.1f", value))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Slider(value: $value, in: range)
                .accentColor(.blue)
            
            Text(description)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}

/// Toggle button for focus areas
struct ToggleButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(isSelected ? Color.blue : Color.gray.opacity(0.2))
                )
                .foregroundColor(isSelected ? .white : .primary)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

/// Learning preferences section
struct LearningPreferencesSection: View {
    @Binding var config: WritingCoachConfiguration
    
    var body: some View {
        ConfigurationSectionCard(title: "Learning Preferences", icon: "graduationcap") {
            VStack(spacing: 16) {
                // Learning Pace
                VStack(alignment: .leading, spacing: 8) {
                    Text("Learning Pace")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Picker("Learning Pace", selection: $config.learningPreferences.preferredLearningPace) {
                        ForEach(UserLearningPreferences.LearningPace.allCases, id: \.self) { pace in
                            Text(pace.rawValue.capitalized).tag(pace)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                // Daily Time Commitment
                SliderControl(
                    title: "Daily Time Commitment (minutes)",
                    value: Binding(
                        get: { config.learningPreferences.dailyTimeCommitment / 60 },
                        set: { config.learningPreferences.dailyTimeCommitment = $0 * 60 }
                    ),
                    range: 10...120,
                    description: "How much time you want to spend learning daily"
                )
                
                // Reminder Settings
                Toggle("Daily Reminders", isOn: $config.learningPreferences.reminderEnabled)
                    .font(.subheadline)
            }
        }
    }
}

/// Writer profile section
struct WriterProfileSection: View {
    @Binding var config: WritingCoachConfiguration
    
    var body: some View {
        ConfigurationSectionCard(title: "Writer Profile", icon: "person.circle") {
            VStack(spacing: 16) {
                // Writing Experience
                VStack(alignment: .leading, spacing: 8) {
                    Text("Writing Experience")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Picker("Experience", selection: $config.writerProfile.experienceLevel) {
                        ForEach(WriterProfile.ExperienceLevel.allCases, id: \.self) { level in
                            Text(level.displayName).tag(level)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
                
                // Primary Writing Types
                VStack(alignment: .leading, spacing: 8) {
                    Text("Primary Writing Types")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                        ForEach(WriterProfile.WritingType.allCases, id: \.self) { type in
                            ToggleButton(
                                title: type.displayName,
                                isSelected: config.writerProfile.primaryWritingTypes.contains(type)
                            ) {
                                if config.writerProfile.primaryWritingTypes.contains(type) {
                                    config.writerProfile.primaryWritingTypes.remove(type)
                                } else {
                                    config.writerProfile.primaryWritingTypes.insert(type)
                                }
                            }
                        }
                    }
                }
                
                // Goals
                VStack(alignment: .leading, spacing: 8) {
                    Text("Primary Goal")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Picker("Goal", selection: $config.writerProfile.primaryGoal) {
                        ForEach(WriterProfile.WritingGoal.allCases, id: \.self) { goal in
                            Text(goal.displayName).tag(goal)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
            }
        }
    }
}

/// Real-time settings section
struct RealTimeSettingsSection: View {
    @Binding var config: WritingCoachConfiguration
    
    var body: some View {
        ConfigurationSectionCard(title: "Real-time Analysis", icon: "bolt.circle") {
            VStack(spacing: 16) {
                Toggle("Enable Real-time Analysis", isOn: $config.realTimeSettings.enabled)
                    .font(.subheadline)
                
                if config.realTimeSettings.enabled {
                    SliderControl(
                        title: "Analysis Delay (seconds)",
                        value: $config.realTimeSettings.debounceInterval,
                        range: 0.5...5.0,
                        description: "How long to wait after typing stops before analyzing"
                    )
                    
                    Toggle("Show Inline Highlights", isOn: $config.realTimeSettings.showInlineHighlights)
                        .font(.subheadline)
                    
                    Toggle("Show Hover Explanations", isOn: $config.realTimeSettings.showHoverExplanations)
                        .font(.subheadline)
                }
            }
        }
    }
}

/// Export preferences section
struct ExportPreferencesSection: View {
    @Binding var config: WritingCoachConfiguration
    
    var body: some View {
        ConfigurationSectionCard(title: "Export & Sharing", icon: "square.and.arrow.up") {
            VStack(spacing: 16) {
                // Export Format
                VStack(alignment: .leading, spacing: 8) {
                    Text("Default Export Format")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Picker("Format", selection: $config.exportSettings.defaultFormat) {
                        ForEach(ExportSettings.ExportFormat.allCases, id: \.self) { format in
                            Text(format.displayName).tag(format)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                // Include Options
                VStack(alignment: .leading, spacing: 8) {
                    Text("Include in Export")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Toggle("Original Text", isOn: $config.exportSettings.includeOriginalText)
                        Toggle("Analysis Results", isOn: $config.exportSettings.includeAnalysis)
                        Toggle("Improvement Suggestions", isOn: $config.exportSettings.includeSuggestions)
                        Toggle("Learning Progress", isOn: $config.exportSettings.includeLearningProgress)
                    }
                    .font(.subheadline)
                }
            }
        }
    }
}

/// Configuration actions section
struct ConfigurationActionsSection: View {
    @ObservedObject var configManager: ConfigurationManager
    
    var body: some View {
        HStack(spacing: 16) {
            Button("Export Configuration") {
                configManager.exportConfiguration()
            }
            .buttonStyle(.bordered)
            
            Button("Import Configuration") {
                configManager.importConfiguration()
            }
            .buttonStyle(.bordered)
            
            Spacer()
            
            Button("Save Changes") {
                configManager.saveCurrentConfiguration()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}

/// Reusable configuration section card
struct ConfigurationSectionCard<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label(title, systemImage: icon)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
            }
            
            content
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.regularMaterial)
        )
    }
}

/// Sheet for creating new configuration presets
struct PresetCreationSheet: View {
    @ObservedObject var configManager: ConfigurationManager
    @Binding var presetName: String
    @Binding var isPresented: Bool
    @State private var presetDescription = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                TextField("Preset Name", text: $presetName)
                    .textFieldStyle(.roundedBorder)
                
                TextField("Description (optional)", text: $presetDescription, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(3)
                
                Text("This will save your current configuration as a reusable preset.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            .padding()
            .navigationTitle("New Preset")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isPresented = false
                        presetName = ""
                        presetDescription = ""
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        configManager.createPreset(name: presetName, description: presetDescription)
                        isPresented = false
                        presetName = ""
                        presetDescription = ""
                    }
                    .disabled(presetName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

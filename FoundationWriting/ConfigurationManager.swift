//
//  ConfigurationManager.swift
//  FoundationWriting
//
//  Created by Hans Axelsson on 7/15/25.
//
import Foundation
import SwiftUI
import Combine

/// Manages application configuration and user preferences
class ConfigurationManager: ObservableObject {
    @Published var currentConfig: WritingCoachConfiguration
    @Published var presets: [ConfigurationPreset] = []
    @Published var currentPreset: ConfigurationPreset?
    
    private let userDefaults = UserDefaults.standard
    private let configKey = "WritingCoachConfiguration"
    private let presetsKey = "ConfigurationPresets"
    
    init() {
        self.currentConfig = Self.loadConfiguration() ?? Self.defaultConfiguration()
        self.presets = Self.loadPresets()
        
        // Add built-in presets if none exist
        if presets.isEmpty {
            addBuiltInPresets()
        }
    }
    
    /// Saves the current configuration to UserDefaults
    func saveCurrentConfiguration() {
        if let encoded = try? JSONEncoder().encode(currentConfig) {
            userDefaults.set(encoded, forKey: configKey)
        }
    }
    
    /// Resets configuration to default values
    func resetToDefault() {
        currentConfig = Self.defaultConfiguration()
        currentPreset = nil
        saveCurrentConfiguration()
    }
    
    /// Creates a new preset from current configuration
    func createPreset(name: String, description: String = "") {
        let preset = ConfigurationPreset(
            id: UUID(),
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            description: description.trimmingCharacters(in: .whitespacesAndNewlines),
            configuration: currentConfig,
            isBuiltIn: false,
            createdAt: Date()
        )
        
        presets.append(preset)
        savePresets()
    }
    
    /// Loads a configuration preset
    func loadPreset(_ preset: ConfigurationPreset) {
        currentConfig = preset.configuration
        currentPreset = preset
        saveCurrentConfiguration()
    }
    
    /// Deletes a custom preset
    func deletePreset(_ preset: ConfigurationPreset) {
        guard !preset.isBuiltIn else { return }
        
        presets.removeAll { $0.id == preset.id }
        
        if currentPreset?.id == preset.id {
            currentPreset = nil
        }
        
        savePresets()
    }
    
    /// Exports configuration to file
    func exportConfiguration() {
        // Implementation for exporting configuration
        // This would typically show a save panel
        print("Export configuration functionality would be implemented here")
    }
    
    /// Imports configuration from file
    func importConfiguration() {
        // Implementation for importing configuration
        // This would typically show an open panel
        print("Import configuration functionality would be implemented here")
    }
    
    // MARK: - Private Methods
    
    private static func loadConfiguration() -> WritingCoachConfiguration? {
        guard let data = UserDefaults.standard.data(forKey: "WritingCoachConfiguration"),
              let config = try? JSONDecoder().decode(WritingCoachConfiguration.self, from: data) else {
            return nil
        }
        return config
    }
    
    private static func loadPresets() -> [ConfigurationPreset] {
        guard let data = UserDefaults.standard.data(forKey: "ConfigurationPresets"),
              let presets = try? JSONDecoder().decode([ConfigurationPreset].self, from: data) else {
            return []
        }
        return presets
    }
    
    private func savePresets() {
        if let encoded = try? JSONEncoder().encode(presets) {
            userDefaults.set(encoded, forKey: presetsKey)
        }
    }
    
    private func addBuiltInPresets() {
        let presets = [
            createAcademicPreset(),
            createCreativePreset(),
            createBusinessPreset(),
            createBeginnerPreset()
        ]
        
        self.presets.append(contentsOf: presets)
        savePresets()
    }
    
    private static func defaultConfiguration() -> WritingCoachConfiguration {
        return WritingCoachConfiguration(
            analysisOptions: EnhancedWritingAnalysisOptions.createDefault(),
            learningPreferences: UserLearningPreferences(),
            writerProfile: WriterProfile(),
            realTimeSettings: RealTimeSettings(),
            exportSettings: ExportSettings()
        )
    }
    
    // MARK: - Built-in Presets
    
    private func createAcademicPreset() -> ConfigurationPreset {
        var config = Self.defaultConfiguration()
        config.analysisOptions.analysisMode = .academic
        config.analysisOptions.writerLevel = .advanced
        config.analysisOptions.improvementFoci = [.clarity, .structure, .grammar]
        config.analysisOptions.temperature = 0.3
        
        return ConfigurationPreset(
            id: UUID(),
            name: "Academic Writing",
            description: "Optimized for scholarly and research writing",
            configuration: config,
            isBuiltIn: true,
            createdAt: Date()
        )
    }
    
    private func createCreativePreset() -> ConfigurationPreset {
        var config = Self.defaultConfiguration()
        config.analysisOptions.analysisMode = .creative
        config.analysisOptions.writerLevel = .intermediate
        config.analysisOptions.improvementFoci = [.creativity, .style, .tone]
        config.analysisOptions.temperature = 0.8
        
        return ConfigurationPreset(
            id: UUID(),
            name: "Creative Writing",
            description: "For fiction, poetry, and creative expression",
            configuration: config,
            isBuiltIn: true,
            createdAt: Date()
        )
    }
    
    private func createBusinessPreset() -> ConfigurationPreset {
        var config = Self.defaultConfiguration()
        config.analysisOptions.analysisMode = .business
        config.analysisOptions.writerLevel = .professional
        config.analysisOptions.improvementFoci = [.clarity, .tone, .structure]
        config.analysisOptions.temperature = 0.4
        
        return ConfigurationPreset(
            id: UUID(),
            name: "Business Communication",
            description: "For professional emails, reports, and proposals",
            configuration: config,
            isBuiltIn: true,
            createdAt: Date()
        )
    }
    
    private func createBeginnerPreset() -> ConfigurationPreset {
        var config = Self.defaultConfiguration()
        config.analysisOptions.analysisMode = .personal
        config.analysisOptions.writerLevel = .beginner
        config.analysisOptions.improvementFoci = [.grammar, .clarity, .vocabulary]
        config.analysisOptions.temperature = 0.6
        config.learningPreferences.preferredLearningPace = .relaxed
        
        return ConfigurationPreset(
            id: UUID(),
            name: "Beginner Friendly",
            description: "Gentle introduction to writing improvement",
            configuration: config,
            isBuiltIn: true,
            createdAt: Date()
        )
    }
}

// MARK: - Configuration Data Models

/// Main configuration structure
struct WritingCoachConfiguration: Codable {
    var analysisOptions: EnhancedWritingAnalysisOptions
    var learningPreferences: UserLearningPreferences
    var writerProfile: WriterProfile
    var realTimeSettings: RealTimeSettings
    var exportSettings: ExportSettings
}

/// Configuration preset for saving/loading different setups
struct ConfigurationPreset: Codable, Identifiable {
    let id: UUID
    let name: String
    let description: String
    let configuration: WritingCoachConfiguration
    let isBuiltIn: Bool
    let createdAt: Date
}

/// Writer profile information
struct WriterProfile: Codable {
    var experienceLevel: ExperienceLevel = .intermediate
    var primaryWritingTypes: Set<WritingType> = [.academic]
    var primaryGoal: WritingGoal = .improveClarity
    
    enum ExperienceLevel: String, CaseIterable, Codable {
        case beginner, intermediate, advanced, professional
        
        var displayName: String {
            switch self {
            case .beginner: return "Beginner"
            case .intermediate: return "Intermediate"
            case .advanced: return "Advanced"
            case .professional: return "Professional"
            }
        }
    }
    
    enum WritingType: String, CaseIterable, Codable {
        case academic, creative, business, technical, journalistic, personal
        
        var displayName: String {
            switch self {
            case .academic: return "Academic"
            case .creative: return "Creative"
            case .business: return "Business"
            case .technical: return "Technical"
            case .journalistic: return "Journalism"
            case .personal: return "Personal"
            }
        }
    }
    
    enum WritingGoal: String, CaseIterable, Codable {
        case improveClarity, enhanceStyle, fixGrammar, expandVocabulary, structureBetter, adjustTone
        
        var displayName: String {
            switch self {
            case .improveClarity: return "Improve Clarity"
            case .enhanceStyle: return "Enhance Style"
            case .fixGrammar: return "Fix Grammar"
            case .expandVocabulary: return "Expand Vocabulary"
            case .structureBetter: return "Better Structure"
            case .adjustTone: return "Adjust Tone"
            }
        }
    }
}

/// Real-time analysis settings
struct RealTimeSettings: Codable {
    var enabled: Bool = true
    var debounceInterval: Double = 1.5
    var showInlineHighlights: Bool = true
    var showHoverExplanations: Bool = true
    var minimumTextLength: Int = 10
}

/// Export and sharing settings
struct ExportSettings: Codable {
    var defaultFormat: ExportFormat = .pdf
    var includeOriginalText: Bool = true
    var includeAnalysis: Bool = true
    var includeSuggestions: Bool = true
    var includeLearningProgress: Bool = false
    
    enum ExportFormat: String, CaseIterable, Codable {
        case pdf, markdown, text, html
        
        var displayName: String {
            switch self {
            case .pdf: return "PDF"
            case .markdown: return "Markdown"
            case .text: return "Plain Text"
            case .html: return "HTML"
            }
        }
    }
}

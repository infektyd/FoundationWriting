//
//  LocalizationManager.swift
//  FoundationWriting
//
//  Created by Hans Axelsson on 7/15/25.
//
import Foundation
import SwiftUI

/// Manages multi-language support and localization for the Writing Coach app
@MainActor
class LocalizationManager: ObservableObject {
    @Published var currentLanguage: SupportedLanguage = .english
    @Published var availableLanguages: [SupportedLanguage] = SupportedLanguage.allCases
    @Published var isRTLLanguage: Bool = false
    
    private var localizedStrings: [String: String] = [:]
    private let userDefaults = UserDefaults.standard
    private let languageKey = "SelectedLanguage"
    
    init() {
        loadSavedLanguage()
        loadLocalizedStrings()
        updateLayoutDirection()
    }
    
    /// Changes the app language and reloads localized content
    func changeLanguage(to language: SupportedLanguage) {
        currentLanguage = language
        saveLanguagePreference()
        loadLocalizedStrings()
        updateLayoutDirection()
        
        // Notify the app about language change
        NotificationCenter.default.post(
            name: .languageDidChange,
            object: language
        )
    }
    
    /// Returns localized string for the given key
    func localizedString(for key: LocalizationKey, arguments: CVarArg...) -> String {
        let keyString = key.rawValue
        
        if let localizedString = localizedStrings[keyString] {
            if arguments.isEmpty {
                return localizedString
            } else {
                return String(format: localizedString, arguments: arguments)
            }
        }
        
        // Fallback to English if translation is missing
        return getFallbackString(for: key, arguments: arguments)
    }
    
    /// Returns localized string with interpolation support
    func localizedString(for key: LocalizationKey, interpolations: [String: String] = [:]) -> String {
        var result = localizedString(for: key)
        
        for (placeholder, value) in interpolations {
            result = result.replacingOccurrences(of: "{\(placeholder)}", with: value)
        }
        
        return result
    }
    
    /// Returns writing analysis localized for the current language
    func localizeAnalysis(_ analysis: EnhancedWritingAnalysis) -> LocalizedAnalysis {
        return LocalizedAnalysis(
            originalAnalysis: analysis,
            localizedAssessment: localizeAssessment(analysis.assessment),
            localizedSuggestions: analysis.improvementSuggestions.map { localizeSuggestion($0) },
            localizedMethodology: localizeMethodology(analysis.methodology),
            language: currentLanguage
        )
    }
    
    /// Returns writing exercise localized for the current language
    func localizeExercise(_ exercise: WritingExercise) -> LocalizedExercise {
        return LocalizedExercise(
            originalExercise: exercise,
            localizedTitle: localizeExerciseTitle(exercise),
            localizedDescription: localizeExerciseDescription(exercise),
            localizedInstructions: localizeExerciseInstructions(exercise),
            localizedObjectives: exercise.objectives.map { localizeObjective($0) },
            language: currentLanguage
        )
    }
    
    /// Checks if text analysis is supported for the current language
    func isAnalysisSupportedForCurrentLanguage() -> Bool {
        return currentLanguage.supportsAdvancedAnalysis
    }
    
    /// Returns appropriate writing rules for the current language
    func getWritingRulesForCurrentLanguage() -> WritingRules {
        return WritingRules.rules(for: currentLanguage)
    }
    
    /// Formats numbers according to current language locale
    func formatNumber(_ number: Double, style: NumberFormatterStyle = .decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = style
        formatter.locale = currentLanguage.locale
        return formatter.string(from: NSNumber(value: number)) ?? "\(number)"
    }
    
    /// Formats dates according to current language locale
    func formatDate(_ date: Date, style: DateFormatter.Style = .medium) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = style
        formatter.locale = currentLanguage.locale
        return formatter.string(from: date)
    }
    
    /// Returns currency formatter for current language
    func formatCurrency(_ amount: Double, currencyCode: String? = nil) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = currentLanguage.locale
        
        if let currencyCode = currencyCode {
            formatter.currencyCode = currencyCode
        }
        
        return formatter.string(from: NSNumber(value: amount)) ?? "\(amount)"
    }
    
    // MARK: - Private Methods
    
    private func loadSavedLanguage() {
        if let languageCode = userDefaults.string(forKey: languageKey),
           let language = SupportedLanguage(rawValue: languageCode) {
            currentLanguage = language
        } else {
            // Use system language if available, otherwise default to English
            currentLanguage = detectSystemLanguage()
        }
    }
    
    private func saveLanguagePreference() {
        userDefaults.set(currentLanguage.rawValue, forKey: languageKey)
    }
    
    private func detectSystemLanguage() -> SupportedLanguage {
        let systemLanguageCode = Locale.current.languageCode ?? "en"
        
        for language in SupportedLanguage.allCases {
            if language.rawValue.hasPrefix(systemLanguageCode) {
                return language
            }
        }
        
        return .english // Fallback
    }
    
    private func loadLocalizedStrings() {
        guard let path = Bundle.main.path(forResource: currentLanguage.localizationFile, ofType: "json"),
              let data = try? Data(contentsOf: URL(fileURLWithPath: path)),
              let strings = try? JSONSerialization.jsonObject(with: data) as? [String: String] else {
            
            // Load fallback strings if localization file is missing
            loadFallbackStrings()
            return
        }
        
        localizedStrings = strings
    }
    
    private func loadFallbackStrings() {
        // Load English as fallback
        localizedStrings = EnglishStrings.strings
    }
    
    private func updateLayoutDirection() {
        isRTLLanguage = currentLanguage.isRightToLeft
    }
    
    private func getFallbackString(for key: LocalizationKey, arguments: [CVarArg]) -> String {
        let fallback = EnglishStrings.strings[key.rawValue] ?? key.rawValue
        
        if arguments.isEmpty {
            return fallback
        } else {
            return String(format: fallback, arguments: arguments)
        }
    }
    
    // MARK: - Analysis Localization
    
    private func localizeAssessment(_ assessment: String) -> String {
        // For now, return the original assessment
        // In a full implementation, this would translate or adapt the assessment
        return assessment
    }
    
    private func localizeSuggestion(_ suggestion: EnhancedWritingAnalysis.ImprovementSuggestion) -> LocalizedSuggestion {
        return LocalizedSuggestion(
            originalSuggestion: suggestion,
            localizedTitle: localizeSuggestionTitle(suggestion),
            localizedDescription: localizeSuggestionDescription(suggestion),
            localizedBeforeExample: localizeExample(suggestion.beforeExample),
            localizedAfterExample: localizeExample(suggestion.afterExample),
            language: currentLanguage
        )
    }
    
    private func localizeMethodology(_ methodology: String) -> String {
        // Translate methodology description
        return methodology
    }
    
    private func localizeSuggestionTitle(_ suggestion: EnhancedWritingAnalysis.ImprovementSuggestion) -> String {
        // Translate suggestion titles based on improvement area
        let key = "suggestion_title_\(suggestion.area.rawValue)"
        return localizedStrings[key] ?? suggestion.title
    }
    
    private func localizeSuggestionDescription(_ suggestion: EnhancedWritingAnalysis.ImprovementSuggestion) -> String {
        // Translate suggestion descriptions
        let key = "suggestion_description_\(suggestion.area.rawValue)"
        return localizedStrings[key] ?? suggestion.description
    }
    
    private func localizeExample(_ example: String) -> String {
        // For now, return the original example
        // In a full implementation, examples would be language-specific
        return example
    }
    
    // MARK: - Exercise Localization
    
    private func localizeExerciseTitle(_ exercise: WritingExercise) -> String {
        let key = "exercise_title_\(exercise.type.rawValue)"
        return localizedStrings[key] ?? exercise.title
    }
    
    private func localizeExerciseDescription(_ exercise: WritingExercise) -> String {
        let key = "exercise_description_\(exercise.type.rawValue)"
        return localizedStrings[key] ?? exercise.description
    }
    
    private func localizeExerciseInstructions(_ exercise: WritingExercise) -> String {
        let key = "exercise_instructions_\(exercise.type.rawValue)"
        return localizedStrings[key] ?? exercise.instructions
    }
    
    private func localizeObjective(_ objective: String) -> String {
        // Translate common objectives
        let key = "objective_\(objective.lowercased().replacingOccurrences(of: " ", with: "_"))"
        return localizedStrings[key] ?? objective
    }
}

// MARK: - Supported Languages

enum SupportedLanguage: String, CaseIterable, Codable {
    case english = "en"
    case spanish = "es"
    case french = "fr"
    case german = "de"
    case italian = "it"
    case portuguese = "pt"
    case dutch = "nl"
    case russian = "ru"
    case japanese = "ja"
    case korean = "ko"
    case chinese = "zh"
    case arabic = "ar"
    case hebrew = "he"
    
    var displayName: String {
        switch self {
        case .english: return "English"
        case .spanish: return "Español"
        case .french: return "Français"
        case .german: return "Deutsch"
        case .italian: return "Italiano"
        case .portuguese: return "Português"
        case .dutch: return "Nederlands"
        case .russian: return "Русский"
        case .japanese: return "日本語"
        case .korean: return "한국어"
        case .chinese: return "中文"
        case .arabic: return "العربية"
        case .hebrew: return "עברית"
        }
    }
    
    var nativeName: String {
        return displayName
    }
    
    var localizationFile: String {
        return "Localizable_\(rawValue)"
    }
    
    var locale: Locale {
        return Locale(identifier: rawValue)
    }
    
    var isRightToLeft: Bool {
        return [.arabic, .hebrew].contains(self)
    }
    
    var supportsAdvancedAnalysis: Bool {
        // Advanced analysis currently supported for these languages
        return [.english, .spanish, .french, .german, .italian].contains(self)
    }
    
    var flagEmoji: String {
        switch self {
        case .english: return "🇺🇸"
        case .spanish: return "🇪🇸"
        case .french: return "🇫🇷"
        case .german: return "🇩🇪"
        case .italian: return "🇮🇹"
        case .portuguese: return "🇵🇹"
        case .dutch: return "🇳🇱"
        case .russian: return "🇷🇺"
        case .japanese: return "🇯🇵"
        case .korean: return "🇰🇷"
        case .chinese: return "🇨🇳"
        case .arabic: return "🇸🇦"
        case .hebrew: return "🇮🇱"
        }
    }
    
    var writingDirection: LayoutDirection {
        return isRightToLeft ? .rightToLeft : .leftToRight
    }
}

// MARK: - Localization Keys

enum LocalizationKey: String, CaseIterable {
    // General UI
    case appTitle = "app_title"
    case loading = "loading"
    case error = "error"
    case cancel = "cancel"
    case save = "save"
    case delete = "delete"
    case edit = "edit"
    case done = "done"
    case retry = "retry"
    
    // Analysis
    case analysisTitle = "analysis_title"
    case analysisInProgress = "analysis_in_progress"
    case analysisComplete = "analysis_complete"
    case analysisError = "analysis_error"
    case readabilityLevel = "readability_level"
    case improvementSuggestions = "improvement_suggestions"
    case noSuggestions = "no_suggestions"
    
    // Writing Areas
    case grammar = "grammar"
    case style = "style"
    case clarity = "clarity"
    case vocabulary = "vocabulary"
    case structure = "structure"
    case tone = "tone"
    case creativity = "creativity"
    
    // Exercises
    case exercises = "exercises"
    case startExercise = "start_exercise"
    case completeExercise = "complete_exercise"
    case exerciseInstructions = "exercise_instructions"
    case exerciseObjectives = "exercise_objectives"
    case exerciseFeedback = "exercise_feedback"
    
    // Progress
    case progress = "progress"
    case skillLevel = "skill_level"
    case experiencePoints = "experience_points"
    case achievements = "achievements"
    case badges = "badges"
    case streak = "streak"
    
    // Export
    case export = "export"
    case exportToPDF = "export_to_pdf"
    case exportToMarkdown = "export_to_markdown"
    case share = "share"
    case shareInsight = "share_insight"
    
    // Settings
    case settings = "settings"
    case language = "language"
    case accessibility = "accessibility"
    case notifications = "notifications"
    case privacy = "privacy"
    
    // Accessibility
    case fontSize = "font_size"
    case highContrast = "high_contrast"
    case reduceMotion = "reduce_motion"
    case voiceOver = "voice_over"
    case colorBlindFriendly = "color_blind_friendly"
    
    // Time
    case minute = "minute"
    case minutes = "minutes"
    case hour = "hour"
    case hours = "hours"
    case day = "day"
    case days = "days"
    case week = "week"
    case weeks = "weeks"
    
    // Numbers
    case wordCount = "word_count"
    case characterCount = "character_count"
    case sentenceCount = "sentence_count"
    case paragraphCount = "paragraph_count"
}

// MARK: - Writing Rules by Language

struct WritingRules {
    let sentenceLengthTarget: ClosedRange<Double>
    let readabilityTarget: ClosedRange<Double>
    let vocabularyDiversityTarget: Double
    let commonErrors: [String]
    let stylePreferences: [String]
    let punctuationRules: [String]
    
    static func rules(for language: SupportedLanguage) -> WritingRules {
        switch language {
        case .english:
            return WritingRules(
                sentenceLengthTarget: 15...25,
                readabilityTarget: 8...12,
                vocabularyDiversityTarget: 0.7,
                commonErrors: ["run-on sentences", "passive voice overuse", "comma splices"],
                stylePreferences: ["active voice", "parallel structure", "varied sentence beginnings"],
                punctuationRules: ["Oxford comma recommended", "em dash for interruptions"]
            )
            
        case .spanish:
            return WritingRules(
                sentenceLengthTarget: 18...28,
                readabilityTarget: 9...13,
                vocabularyDiversityTarget: 0.65,
                commonErrors: ["subjunctive mood errors", "gender agreement", "ser vs estar"],
                stylePreferences: ["descriptive language", "complex sentences", "formal register"],
                punctuationRules: ["inverted question marks", "inverted exclamation marks"]
            )
            
        case .french:
            return WritingRules(
                sentenceLengthTarget: 20...30,
                readabilityTarget: 10...14,
                vocabularyDiversityTarget: 0.68,
                commonErrors: ["agreement errors", "liaison mistakes", "false friends"],
                stylePreferences: ["elegant expressions", "logical progression", "precise vocabulary"],
                punctuationRules: ["guillemets for quotes", "spacing before punctuation"]
            )
            
        case .german:
            return WritingRules(
                sentenceLengthTarget: 22...32,
                readabilityTarget: 11...15,
                vocabularyDiversityTarget: 0.72,
                commonErrors: ["case errors", "word order", "compound word formation"],
                stylePreferences: ["compound sentences", "precise terminology", "formal structure"],
                punctuationRules: ["commas before subordinate clauses", "capitalization of nouns"]
            )
            
        default:
            // Default to English rules for unsupported languages
            return rules(for: .english)
        }
    }
}

// MARK: - Localized Data Models

struct LocalizedAnalysis {
    let originalAnalysis: EnhancedWritingAnalysis
    let localizedAssessment: String
    let localizedSuggestions: [LocalizedSuggestion]
    let localizedMethodology: String
    let language: SupportedLanguage
}

struct LocalizedSuggestion {
    let originalSuggestion: EnhancedWritingAnalysis.ImprovementSuggestion
    let localizedTitle: String
    let localizedDescription: String
    let localizedBeforeExample: String
    let localizedAfterExample: String
    let language: SupportedLanguage
}

struct LocalizedExercise {
    let originalExercise: WritingExercise
    let localizedTitle: String
    let localizedDescription: String
    let localizedInstructions: String
    let localizedObjectives: [String]
    let language: SupportedLanguage
}

// MARK: - English Strings (Fallback)

struct EnglishStrings {
    static let strings: [String: String] = [
        // General UI
        "app_title": "Writing Coach",
        "loading": "Loading...",
        "error": "Error",
        "cancel": "Cancel",
        "save": "Save",
        "delete": "Delete",
        "edit": "Edit",
        "done": "Done",
        "retry": "Retry",
        
        // Analysis
        "analysis_title": "Writing Analysis",
        "analysis_in_progress": "Analyzing your writing...",
        "analysis_complete": "Analysis complete",
        "analysis_error": "Analysis failed",
        "readability_level": "Readability Level",
        "improvement_suggestions": "Improvement Suggestions",
        "no_suggestions": "No suggestions at this time",
        
        // Writing Areas
        "grammar": "Grammar",
        "style": "Style",
        "clarity": "Clarity",
        "vocabulary": "Vocabulary",
        "structure": "Structure",
        "tone": "Tone",
        "creativity": "Creativity",
        
        // Exercises
        "exercises": "Exercises",
        "start_exercise": "Start Exercise",
        "complete_exercise": "Complete Exercise",
        "exercise_instructions": "Instructions",
        "exercise_objectives": "Objectives",
        "exercise_feedback": "Feedback",
        
        // Progress
        "progress": "Progress",
        "skill_level": "Skill Level",
        "experience_points": "Experience Points",
        "achievements": "Achievements",
        "badges": "Badges",
        "streak": "Streak",
        
        // Export
        "export": "Export",
        "export_to_pdf": "Export to PDF",
        "export_to_markdown": "Export to Markdown",
        "share": "Share",
        "share_insight": "Share Insight",
        
        // Settings
        "settings": "Settings",
        "language": "Language",
        "accessibility": "Accessibility",
        "notifications": "Notifications",
        "privacy": "Privacy",
        
        // Accessibility
        "font_size": "Font Size",
        "high_contrast": "High Contrast",
        "reduce_motion": "Reduce Motion",
        "voice_over": "VoiceOver",
        "color_blind_friendly": "Color Blind Friendly",
        
        // Time
        "minute": "minute",
        "minutes": "minutes",
        "hour": "hour",
        "hours": "hours",
        "day": "day",
        "days": "days",
        "week": "week",
        "weeks": "weeks",
        
        // Numbers
        "word_count": "Word Count",
        "character_count": "Character Count",
        "sentence_count": "Sentence Count",
        "paragraph_count": "Paragraph Count"
    ]
}

// MARK: - Notification Names

extension Notification.Name {
    static let languageDidChange = Notification.Name("LanguageDidChange")
}
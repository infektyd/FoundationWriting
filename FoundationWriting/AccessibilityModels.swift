//
//  AccessibilityModels.swift
//  FoundationWriting
//
//  Created by Hans Axelsson on 7/15/25.
//
import Foundation
import SwiftUI

// MARK: - Accessibility Settings

struct AccessibilitySettings: Codable {
    var fontSize: AccessibilityFontSize = .medium
    var highContrast: Bool = false
    var reduceMotion: Bool = false
    var colorBlindFriendly: Bool = false
    var keyboardNavigation: Bool = true
    var audioDescriptions: Bool = false
    var colorScheme: AccessibilityColorScheme = .system
    var dyslexiaFriendly: Bool = false
    var focusIndicatorStyle: FocusIndicatorStyle = .standard
    var speechRate: SpeechRate = .normal
    var magnificationLevel: MagnificationLevel = .normal
    
    // Reading assistance
    var readingGuide: Bool = false
    var wordHighlighting: Bool = false
    var sentenceHighlighting: Bool = false
    var phoneticsSupport: Bool = false
    
    // Motor accessibility
    var stickyKeys: Bool = false
    var slowKeys: Bool = false
    var mouseKeys: Bool = false
    var dwellClick: Bool = false
    
    // Cognitive assistance
    var simplifiedInterface: Bool = false
    var extendedTimeouts: Bool = false
    var confirmationDialogs: Bool = true
    var progressIndicators: Bool = true
}

enum AccessibilityFontSize: String, Codable, CaseIterable {
    case extraSmall = "extra_small"
    case small = "small"
    case medium = "medium"
    case large = "large"
    case extraLarge = "extra_large"
    case accessibility1 = "accessibility_1"
    case accessibility2 = "accessibility_2"
    case accessibility3 = "accessibility_3"
    
    var displayName: String {
        switch self {
        case .extraSmall: return "Extra Small"
        case .small: return "Small"
        case .medium: return "Medium"
        case .large: return "Large"
        case .extraLarge: return "Extra Large"
        case .accessibility1: return "Accessibility Large"
        case .accessibility2: return "Accessibility Extra Large"
        case .accessibility3: return "Accessibility Maximum"
        }
    }
    
    var scaleFactor: CGFloat {
        switch self {
        case .extraSmall: return 0.8
        case .small: return 0.9
        case .medium: return 1.0
        case .large: return 1.2
        case .extraLarge: return 1.4
        case .accessibility1: return 1.6
        case .accessibility2: return 1.8
        case .accessibility3: return 2.0
        }
    }
    
    var fontSize: CGFloat {
        return 14 * scaleFactor
    }
}

enum AccessibilityColorScheme: String, Codable, CaseIterable {
    case system = "system"
    case light = "light"
    case dark = "dark"
    case highContrastLight = "high_contrast_light"
    case highContrastDark = "high_contrast_dark"
    case colorBlindFriendly = "color_blind_friendly"
    
    var displayName: String {
        switch self {
        case .system: return "System"
        case .light: return "Light"
        case .dark: return "Dark"
        case .highContrastLight: return "High Contrast Light"
        case .highContrastDark: return "High Contrast Dark"
        case .colorBlindFriendly: return "Color Blind Friendly"
        }
    }
    
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light, .highContrastLight, .colorBlindFriendly: return .light
        case .dark, .highContrastDark: return .dark
        }
    }
}

enum FocusIndicatorStyle: String, Codable, CaseIterable {
    case standard = "standard"
    case bold = "bold"
    case colorful = "colorful"
    case highContrast = "high_contrast"
    
    var displayName: String {
        return rawValue.capitalized
    }
    
    var borderWidth: CGFloat {
        switch self {
        case .standard: return 2
        case .bold: return 4
        case .colorful: return 3
        case .highContrast: return 4
        }
    }
    
    var color: Color {
        switch self {
        case .standard: return .blue
        case .bold: return .blue
        case .colorful: return .orange
        case .highContrast: return .primary
        }
    }
}

enum SpeechRate: String, Codable, CaseIterable {
    case verySlow = "very_slow"
    case slow = "slow"
    case normal = "normal"
    case fast = "fast"
    case veryFast = "very_fast"
    
    var displayName: String {
        switch self {
        case .verySlow: return "Very Slow"
        case .slow: return "Slow"
        case .normal: return "Normal"
        case .fast: return "Fast"
        case .veryFast: return "Very Fast"
        }
    }
    
    var rate: Float {
        switch self {
        case .verySlow: return 0.3
        case .slow: return 0.5
        case .normal: return 0.7
        case .fast: return 0.9
        case .veryFast: return 1.0
        }
    }
}

enum MagnificationLevel: String, Codable, CaseIterable {
    case normal = "normal"
    case medium = "medium"
    case large = "large"
    case extraLarge = "extra_large"
    
    var displayName: String {
        switch self {
        case .normal: return "Normal"
        case .medium: return "Medium"
        case .large: return "Large"
        case .extraLarge: return "Extra Large"
        }
    }
    
    var scaleFactor: CGFloat {
        switch self {
        case .normal: return 1.0
        case .medium: return 1.25
        case .large: return 1.5
        case .extraLarge: return 2.0
        }
    }
}

// MARK: - Accessibility Elements

enum AccessibilityElement {
    case analysisResult(EnhancedWritingAnalysis)
    case suggestionCard(EnhancedWritingAnalysis.ImprovementSuggestion)
    case progressIndicator(Double)
    case skillLevel(SkillArea, Int)
    case exerciseCard(WritingExercise)
    case achievementBadge(Achievement)
    case textHighlight(TextHighlight)
    case exportButton(ExportSettings.ExportFormat)
    case configurationOption(String, String)
    case customElement(String)
}

enum AudioDescriptionContent {
    case analysisResults(EnhancedWritingAnalysis)
    case improvementSuggestions([EnhancedWritingAnalysis.ImprovementSuggestion])
    case learningProgress([SkillArea: SkillProgress])
    case exerciseInstructions(WritingExercise)
    case writeAssistance(String, [TextHighlight])
}

enum AccessibilityFeature: String, CaseIterable {
    case voiceOver = "voice_over"
    case reduceMotion = "reduce_motion"
    case highContrast = "high_contrast"
    case largeText = "large_text"
    case screenReader = "screen_reader"
    case colorBlindFriendly = "color_blind_friendly"
    case keyboardNavigation = "keyboard_navigation"
    case audioDescriptions = "audio_descriptions"
    
    var displayName: String {
        switch self {
        case .voiceOver: return "VoiceOver"
        case .reduceMotion: return "Reduce Motion"
        case .highContrast: return "High Contrast"
        case .largeText: return "Large Text"
        case .screenReader: return "Screen Reader"
        case .colorBlindFriendly: return "Color Blind Friendly"
        case .keyboardNavigation: return "Keyboard Navigation"
        case .audioDescriptions: return "Audio Descriptions"
        }
    }
    
    var description: String {
        switch self {
        case .voiceOver: return "Provides spoken descriptions of screen content"
        case .reduceMotion: return "Minimizes animations and transitions"
        case .highContrast: return "Increases color contrast for better visibility"
        case .largeText: return "Increases text size for easier reading"
        case .screenReader: return "Compatible with screen reading software"
        case .colorBlindFriendly: return "Uses patterns and shapes in addition to colors"
        case .keyboardNavigation: return "Full keyboard navigation support"
        case .audioDescriptions: return "Provides audio descriptions of visual content"
        }
    }
}

// MARK: - Visual Elements (for alternative descriptions)

enum VisualElement {
    case chart(ChartData)
    case graph(GraphData)
    case progressBar(Double, String)
    case colorIndicator(NSColor, String)
    case badge(Badge)
    case diagram(String)
}

enum ChartData {
    case skillProgress([SkillArea: Double])
    case performanceTrend([Double])
    case timeSpent([Double])
}

enum GraphData {
    case readabilityOverTime([CGPoint])
    case vocabularyDiversity([CGPoint])
    case writingFrequency(Double)
}

// MARK: - Keyboard Navigation

struct KeyboardShortcut {
    let key: String
    let modifiers: [KeyModifier]
    let action: String
    let description: String
    
    enum KeyModifier: String, CaseIterable {
        case command = "cmd"
        case option = "opt"
        case control = "ctrl"
        case shift = "shift"
        
        var symbol: String {
            switch self {
            case .command: return "⌘"
            case .option: return "⌥"
            case .control: return "⌃"
            case .shift: return "⇧"
            }
        }
    }
    
    var displayString: String {
        let modifierString = modifiers.map { $0.symbol }.joined()
        return "\(modifierString)\(key.uppercased())"
    }
}

// MARK: - Color Blind Support

enum ColorBlindType: String, CaseIterable {
    case protanopia = "protanopia"     // Red-blind
    case deuteranopia = "deuteranopia" // Green-blind
    case tritanopia = "tritanopia"     // Blue-blind
    case achromatopsia = "achromatopsia" // Complete color blindness
    
    var displayName: String {
        switch self {
        case .protanopia: return "Protanopia (Red-blind)"
        case .deuteranopia: return "Deuteranopia (Green-blind)"
        case .tritanopia: return "Tritanopia (Blue-blind)"
        case .achromatopsia: return "Achromatopsia (Complete)"
        }
    }
    
    var description: String {
        switch self {
        case .protanopia: return "Difficulty distinguishing red and green colors"
        case .deuteranopia: return "Difficulty distinguishing red and green colors"
        case .tritanopia: return "Difficulty distinguishing blue and yellow colors"
        case .achromatopsia: return "Complete inability to see colors"
        }
    }
}

struct ColorBlindFriendlyPalette {
    let primary: Color
    let secondary: Color
    let accent: Color
    let warning: Color
    let error: Color
    let success: Color
    
    static let standard = ColorBlindFriendlyPalette(
        primary: Color(red: 0.0, green: 0.45, blue: 0.74),      // Blue
        secondary: Color(red: 0.35, green: 0.35, blue: 0.35),   // Gray
        accent: Color(red: 0.9, green: 0.6, blue: 0.0),         // Orange
        warning: Color(red: 0.9, green: 0.6, blue: 0.0),        // Orange
        error: Color(red: 0.8, green: 0.4, blue: 0.4),          // Light Red
        success: Color(red: 0.0, green: 0.6, blue: 0.5)         // Teal
    )
    
    static let deuteranopia = ColorBlindFriendlyPalette(
        primary: Color(red: 0.0, green: 0.45, blue: 0.74),      // Blue
        secondary: Color(red: 0.35, green: 0.35, blue: 0.35),   // Gray
        accent: Color(red: 0.8, green: 0.4, blue: 0.0),         // Dark Orange
        warning: Color(red: 0.8, green: 0.4, blue: 0.0),        // Dark Orange
        error: Color(red: 0.6, green: 0.2, blue: 0.2),          // Dark Red
        success: Color(red: 0.2, green: 0.4, blue: 0.6)         // Blue-teal
    )
    
    static let protanopia = ColorBlindFriendlyPalette(
        primary: Color(red: 0.0, green: 0.45, blue: 0.74),      // Blue
        secondary: Color(red: 0.35, green: 0.35, blue: 0.35),   // Gray
        accent: Color(red: 0.9, green: 0.6, blue: 0.0),         // Orange
        warning: Color(red: 0.9, green: 0.6, blue: 0.0),        // Orange
        error: Color(red: 0.4, green: 0.4, blue: 0.8),          // Purple-blue
        success: Color(red: 0.2, green: 0.6, blue: 0.8)         // Light Blue
    )
    
    static let tritanopia = ColorBlindFriendlyPalette(
        primary: Color(red: 0.8, green: 0.2, blue: 0.2),        // Red
        secondary: Color(red: 0.35, green: 0.35, blue: 0.35),   // Gray
        accent: Color(red: 0.2, green: 0.6, blue: 0.2),         // Green
        warning: Color(red: 0.8, green: 0.4, blue: 0.0),        // Orange
        error: Color(red: 0.8, green: 0.2, blue: 0.2),          // Red
        success: Color(red: 0.2, green: 0.6, blue: 0.2)         // Green
    )
}

// MARK: - Dyslexia Support

struct DyslexiaFriendlySettings {
    var font: DyslexiaFriendlyFont = .openDyslexic
    var lineSpacing: LineSpacing = .increased
    var characterSpacing: CharacterSpacing = .normal
    var wordSpacing: WordSpacing = .increased
    var backgroundColor: Color = Color(.controlBackgroundColor)
    var textColor: Color = Color(.labelColor)
    var highlightColor: Color = Color.yellow.opacity(0.3)
    
    enum DyslexiaFriendlyFont: String, CaseIterable {
        case openDyslexic = "OpenDyslexic"
        case dyslexie = "Dyslexie"
        case comic = "Comic Sans MS"
        case verdana = "Verdana"
        case arial = "Arial"
        
        var displayName: String {
            switch self {
            case .openDyslexic: return "OpenDyslexic"
            case .dyslexie: return "Dyslexie"
            case .comic: return "Comic Sans MS"
            case .verdana: return "Verdana"
            case .arial: return "Arial"
            }
        }
    }
    
    enum LineSpacing: String, CaseIterable {
        case normal = "normal"
        case increased = "increased"
        case double = "double"
        
        var multiplier: CGFloat {
            switch self {
            case .normal: return 1.0
            case .increased: return 1.5
            case .double: return 2.0
            }
        }
    }
    
    enum CharacterSpacing: String, CaseIterable {
        case tight = "tight"
        case normal = "normal"
        case loose = "loose"
        
        var spacing: CGFloat {
            switch self {
            case .tight: return -0.5
            case .normal: return 0.0
            case .loose: return 1.0
            }
        }
    }
    
    enum WordSpacing: String, CaseIterable {
        case normal = "normal"
        case increased = "increased"
        case wide = "wide"
        
        var spacing: CGFloat {
            switch self {
            case .normal: return 0.0
            case .increased: return 2.0
            case .wide: return 4.0
            }
        }
    }
}

// MARK: - Screen Reader Support

struct ScreenReaderContent {
    let element: String
    let label: String
    let hint: String?
    let value: String?
    let traits: [ScreenReaderTrait]
    
    enum ScreenReaderTrait: String {
        case button = "button"
        case link = "link"
        case header = "header"
        case textField = "text_field"
        case staticText = "static_text"
        case image = "image"
        case selected = "selected"
        case disabled = "disabled"
    }
}

// MARK: - Motor Accessibility

struct MotorAccessibilitySettings {
    var dwellTime: TimeInterval = 1.0
    var clickAndHoldDuration: TimeInterval = 0.5
    var doubleClickSpeed: TimeInterval = 0.5
    var dragThreshold: CGFloat = 10.0
    var buttonSize: ButtonSize = .normal
    var touchTarget: TouchTargetSize = .normal
    
    enum ButtonSize: String, CaseIterable {
        case small = "small"
        case normal = "normal"
        case large = "large"
        case extraLarge = "extra_large"
        
        var size: CGSize {
            switch self {
            case .small: return CGSize(width: 32, height: 32)
            case .normal: return CGSize(width: 44, height: 44)
            case .large: return CGSize(width: 56, height: 56)
            case .extraLarge: return CGSize(width: 72, height: 72)
            }
        }
    }
    
    enum TouchTargetSize: String, CaseIterable {
        case compact = "compact"
        case normal = "normal"
        case comfortable = "comfortable"
        case spacious = "spacious"
        
        var padding: CGFloat {
            switch self {
            case .compact: return 4
            case .normal: return 8
            case .comfortable: return 12
            case .spacious: return 16
            }
        }
    }
}

// MARK: - Cognitive Accessibility

struct CognitiveAccessibilitySettings {
    var simplifyInterface: Bool = false
    var showProgressIndicators: Bool = true
    var useConfirmationDialogs: Bool = true
    var extendTimeouts: Bool = false
    var provideHelp: Bool = true
    var useIcons: Bool = true
    var groupRelatedItems: Bool = true
    var minimizeDistractions: Bool = false
    
    var timeoutMultiplier: Double {
        return extendTimeouts ? 3.0 : 1.0
    }
    
    var interfaceComplexity: InterfaceComplexity {
        return simplifyInterface ? .simple : .standard
    }
    
    enum InterfaceComplexity {
        case simple
        case standard
        case advanced
    }
}
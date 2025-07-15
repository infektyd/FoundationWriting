//
//  GamificationModels.swift
//  FoundationWriting
//
//  Created by Hans Axelsson on 7/15/25.
//
import Foundation
import GameKit

// MARK: - User Profile

struct GamifiedUserProfile: Codable {
    var level: Int = 1
    var experiencePoints: Int = 0
    var totalSessions: Int = 0
    var totalWordsAnalyzed: Int = 0
    var joinDate: Date = Date()
    
    var skillLevels: [SkillArea: GamifiedSkillData] = [:]
    var earnedAchievements: [Achievement] = []
    var earnedBadges: Set<Badge> = []
    var completedChallenges: [WritingChallenge] = []
    var unlockedFeatures: Set<UnlockableFeature> = []
    
    // Computed properties
    var experienceToNextLevel: Int {
        let nextLevelExp = Int(pow(Double(level + 1), 2) * 200)
        let currentLevelExp = Int(pow(Double(level), 2) * 200)
        return nextLevelExp - experiencePoints
    }
    
    var levelProgress: Double {
        let currentLevelExp = Int(pow(Double(level), 2) * 200)
        let nextLevelExp = Int(pow(Double(level + 1), 2) * 200)
        let progressInLevel = experiencePoints - currentLevelExp
        let totalLevelExp = nextLevelExp - currentLevelExp
        
        return Double(progressInLevel) / Double(totalLevelExp)
    }
    
    var averageSkillLevel: Double {
        guard !skillLevels.isEmpty else { return 1.0 }
        let totalLevels = skillLevels.values.map { Double($0.level) }.reduce(0, +)
        return totalLevels / Double(skillLevels.count)
    }
    
    var totalAchievementPoints: Int {
        return earnedAchievements.map { $0.experienceReward }.reduce(0, +)
    }
}

struct GamifiedSkillData: Codable {
    var level: Int
    var experiencePoints: Int
    var sessionsCompleted: Int
    
    var experienceToNextLevel: Int {
        let nextLevelExp = level * 100
        return nextLevelExp - (experiencePoints % 100)
    }
    
    var levelProgress: Double {
        let progressInLevel = experiencePoints % 100
        return Double(progressInLevel) / 100.0
    }
}

// MARK: - Achievements

struct Achievement: Codable, Identifiable {
    let id: UUID
    let title: String
    let description: String
    let type: AchievementType
    let iconName: String
    let experienceReward: Int
    let unlockedAt: Date
    
    var gameKitIdentifier: String {
        return "achievement_\(type.rawValue)_\(id.uuidString.prefix(8))"
    }
}

enum AchievementType: String, Codable, CaseIterable {
    case firstTime = "first_time"
    case milestone = "milestone"
    case performance = "performance"
    case consistency = "consistency"
    case levelUp = "level_up"
    case skillMastery = "skill_mastery"
    case readability = "readability"
    case vocabulary = "vocabulary"
    case creativity = "creativity"
    case efficiency = "efficiency"
    case social = "social"
    case challenge = "challenge"
    
    var displayName: String {
        switch self {
        case .firstTime: return "First Time"
        case .milestone: return "Milestone"
        case .performance: return "Performance"
        case .consistency: return "Consistency"
        case .levelUp: return "Level Up"
        case .skillMastery: return "Skill Mastery"
        case .readability: return "Readability"
        case .vocabulary: return "Vocabulary"
        case .creativity: return "Creativity"
        case .efficiency: return "Efficiency"
        case .social: return "Social"
        case .challenge: return "Challenge"
        }
    }
    
    var color: String {
        switch self {
        case .firstTime: return "green"
        case .milestone: return "blue"
        case .performance: return "orange"
        case .consistency: return "purple"
        case .levelUp: return "gold"
        case .skillMastery: return "red"
        case .readability: return "teal"
        case .vocabulary: return "indigo"
        case .creativity: return "pink"
        case .efficiency: return "mint"
        case .social: return "cyan"
        case .challenge: return "brown"
        }
    }
}

// MARK: - Badges

enum Badge: String, Codable, CaseIterable {
    // Writing Skill Badges
    case grammarGuru = "grammar_guru"
    case styleSpecialist = "style_specialist"
    case clarityChampion = "clarity_champion"
    case vocabularyVirtuoso = "vocabulary_virtuoso"
    case structureSensei = "structure_sensei"
    case toneMaster = "tone_master"
    case creativityKing = "creativity_king"
    
    // Performance Badges
    case perfectionist = "perfectionist"
    case fastWriter = "fast_writer"
    case marathonWriter = "marathon_writer"
    case consistent = "consistent"
    case improver = "improver"
    
    // Achievement Badges
    case earlyAdopter = "early_adopter"
    case veteran = "veteran"
    case challenger = "challenger"
    case mentor = "mentor"
    case collaborator = "collaborator"
    
    // Special Badges
    case skillSpecialist = "skill_specialist"
    case allRounder = "all_rounder"
    case trendsetter = "trendsetter"
    case community = "community"
    
    var displayName: String {
        switch self {
        case .grammarGuru: return "Grammar Guru"
        case .styleSpecialist: return "Style Specialist"
        case .clarityChampion: return "Clarity Champion"
        case .vocabularyVirtuoso: return "Vocabulary Virtuoso"
        case .structureSensei: return "Structure Sensei"
        case .toneMaster: return "Tone Master"
        case .creativityKing: return "Creativity King"
        case .perfectionist: return "Perfectionist"
        case .fastWriter: return "Fast Writer"
        case .marathonWriter: return "Marathon Writer"
        case .consistent: return "Consistent"
        case .improver: return "Improver"
        case .earlyAdopter: return "Early Adopter"
        case .veteran: return "Veteran"
        case .challenger: return "Challenger"
        case .mentor: return "Mentor"
        case .collaborator: return "Collaborator"
        case .skillSpecialist: return "Skill Specialist"
        case .allRounder: return "All Rounder"
        case .trendsetter: return "Trendsetter"
        case .community: return "Community"
        }
    }
    
    var description: String {
        switch self {
        case .grammarGuru: return "Master of grammatical excellence"
        case .styleSpecialist: return "Expert in writing style and flow"
        case .clarityChampion: return "Makes complex ideas crystal clear"
        case .vocabularyVirtuoso: return "Wields words with precision and flair"
        case .structureSensei: return "Architect of well-organized writing"
        case .toneMaster: return "Controls tone and voice masterfully"
        case .creativityKing: return "Brings imagination to every sentence"
        case .perfectionist: return "Achieves excellence in every session"
        case .fastWriter: return "Completes challenges with lightning speed"
        case .marathonWriter: return "Endures long writing sessions"
        case .consistent: return "Practices writing regularly"
        case .improver: return "Shows continuous improvement"
        case .earlyAdopter: return "Among the first to try new features"
        case .veteran: return "Long-time dedicated user"
        case .challenger: return "Completes difficult challenges"
        case .mentor: return "Helps others improve their writing"
        case .collaborator: return "Works well with others"
        case .skillSpecialist: return "Focuses on specific skill development"
        case .allRounder: return "Excels across all writing areas"
        case .trendsetter: return "Influences writing trends"
        case .community: return "Active community member"
        }
    }
    
    var iconName: String {
        switch self {
        case .grammarGuru: return "textformat.abc"
        case .styleSpecialist: return "paintbrush.fill"
        case .clarityChampion: return "eye.fill"
        case .vocabularyVirtuoso: return "book.fill"
        case .structureSensei: return "rectangle.3.group.fill"
        case .toneMaster: return "speaker.wave.2.fill"
        case .creativityKing: return "lightbulb.fill"
        case .perfectionist: return "star.fill"
        case .fastWriter: return "bolt.fill"
        case .marathonWriter: return "timer"
        case .consistent: return "calendar.badge.clock"
        case .improver: return "chart.line.uptrend.xyaxis"
        case .earlyAdopter: return "leaf.fill"
        case .veteran: return "shield.fill"
        case .challenger: return "target"
        case .mentor: return "person.2.fill"
        case .collaborator: return "person.3.fill"
        case .skillSpecialist: return "graduationcap.fill"
        case .allRounder: return "checkmark.seal.fill"
        case .trendsetter: return "flame.fill"
        case .community: return "heart.fill"
        }
    }
    
    var rarity: BadgeRarity {
        switch self {
        case .grammarGuru, .styleSpecialist, .clarityChampion, .vocabularyVirtuoso, .structureSensei, .toneMaster, .creativityKing:
            return .rare
        case .perfectionist, .marathonWriter, .veteran, .mentor, .allRounder:
            return .epic
        case .fastWriter, .consistent, .improver, .skillSpecialist:
            return .common
        case .earlyAdopter, .challenger, .collaborator, .trendsetter, .community:
            return .uncommon
        }
    }
}

enum BadgeRarity: String, Codable {
    case common = "common"
    case uncommon = "uncommon" 
    case rare = "rare"
    case epic = "epic"
    case legendary = "legendary"
    
    var color: String {
        switch self {
        case .common: return "gray"
        case .uncommon: return "green"
        case .rare: return "blue"
        case .epic: return "purple"
        case .legendary: return "orange"
        }
    }
    
    var displayName: String {
        return rawValue.capitalized
    }
}

// MARK: - Challenges

struct WritingChallenge: Codable, Identifiable {
    let id: UUID
    let title: String
    let description: String
    let type: ChallengeType
    let difficulty: ChallengeDifficulty
    let requirements: Requirements
    let rewards: Rewards
    let createdDate: Date
    
    var startDate: Date?
    var completedDate: Date?
    var isActive: Bool = false
    var progress: Progress = Progress()
    
    var isCompleted: Bool {
        switch type {
        case .timed:
            return progress.sessionsCompleted >= (requirements.exerciseCount ?? 1)
        case .skillFocus:
            return progress.exercisesCompleted >= (requirements.exerciseCount ?? 3)
        case .consistency:
            return progress.consecutiveDays >= (requirements.consecutiveDays ?? 7)
        case .wordCount:
            return progress.wordsWritten >= (requirements.minimumWords ?? 1000)
        }
    }
    
    var progressPercentage: Double {
        switch type {
        case .timed:
            let target = Double(requirements.exerciseCount ?? 1)
            return Double(progress.sessionsCompleted) / target
        case .skillFocus:
            let target = Double(requirements.exerciseCount ?? 3)
            return Double(progress.exercisesCompleted) / target
        case .consistency:
            let target = Double(requirements.consecutiveDays ?? 7)
            return Double(progress.consecutiveDays) / target
        case .wordCount:
            let target = Double(requirements.minimumWords ?? 1000)
            return Double(progress.wordsWritten) / target
        }
    }
    
    struct Requirements: Codable {
        var minimumWords: Int?
        var maximumWords: Int?
        var timeLimit: TimeInterval?
        var exerciseCount: Int?
        var consecutiveDays: Int?
        var targetSkills: [SkillArea] = []
    }
    
    struct Rewards: Codable {
        let experiencePoints: Int
        let badge: Badge?
        let unlockableContent: String?
    }
    
    struct Progress: Codable {
        var sessionsCompleted: Int = 0
        var exercisesCompleted: Int = 0
        var wordsWritten: Int = 0
        var consecutiveDays: Int = 0
        var timeSpent: TimeInterval = 0
    }
}

enum ChallengeType: String, Codable, CaseIterable {
    case timed = "timed"
    case skillFocus = "skill_focus"
    case consistency = "consistency"
    case wordCount = "word_count"
    
    var displayName: String {
        switch self {
        case .timed: return "Timed Challenge"
        case .skillFocus: return "Skill Focus"
        case .consistency: return "Consistency"
        case .wordCount: return "Word Count"
        }
    }
    
    var iconName: String {
        switch self {
        case .timed: return "timer"
        case .skillFocus: return "target"
        case .consistency: return "calendar.badge.clock"
        case .wordCount: return "doc.text"
        }
    }
}

enum ChallengeDifficulty: String, Codable, CaseIterable {
    case easy = "easy"
    case medium = "medium"
    case hard = "hard"
    case expert = "expert"
    
    var displayName: String {
        return rawValue.capitalized
    }
    
    var color: String {
        switch self {
        case .easy: return "green"
        case .medium: return "orange"
        case .hard: return "red"
        case .expert: return "purple"
        }
    }
    
    var experienceMultiplier: Double {
        switch self {
        case .easy: return 1.0
        case .medium: return 1.5
        case .hard: return 2.0
        case .expert: return 3.0
        }
    }
}

// MARK: - Unlockable Features

enum UnlockableFeature: String, Codable, CaseIterable {
    case advancedAnalytics = "advanced_analytics"
    case customChallenges = "custom_challenges"
    case mentorMode = "mentor_mode"
    case collaborativeWriting = "collaborative_writing"
    case premiumThemes = "premium_themes"
    case exportTemplates = "export_templates"
    case aiTutor = "ai_tutor"
    case communityFeed = "community_feed"
    
    var displayName: String {
        switch self {
        case .advancedAnalytics: return "Advanced Analytics"
        case .customChallenges: return "Custom Challenges"
        case .mentorMode: return "Mentor Mode"
        case .collaborativeWriting: return "Collaborative Writing"
        case .premiumThemes: return "Premium Themes"
        case .exportTemplates: return "Export Templates"
        case .aiTutor: return "AI Tutor"
        case .communityFeed: return "Community Feed"
        }
    }
    
    var description: String {
        switch self {
        case .advancedAnalytics: return "Detailed insights and progress tracking"
        case .customChallenges: return "Create your own writing challenges"
        case .mentorMode: return "Provide guidance to other writers"
        case .collaborativeWriting: return "Work on documents with others"
        case .premiumThemes: return "Beautiful visual themes"
        case .exportTemplates: return "Professional report templates"
        case .aiTutor: return "Personal AI writing assistant"
        case .communityFeed: return "Share progress with the community"
        }
    }
    
    var requiredLevel: Int {
        switch self {
        case .advancedAnalytics: return 5
        case .customChallenges: return 10
        case .mentorMode: return 15
        case .collaborativeWriting: return 20
        case .premiumThemes: return 8
        case .exportTemplates: return 12
        case .aiTutor: return 25
        case .communityFeed: return 7
        }
    }
}

// MARK: - Leaderboard

struct LeaderboardEntry: Codable {
    let rank: Int
    let score: Int
    let playerName: String
}

struct WeeklyStats: Codable {
    let totalSessions: Int
    let totalExperience: Int
    let skillsImproved: Set<SkillArea>
    let challengesCompleted: Int
    let averagePerformance: Double
}

// MARK: - Streak Tracking

struct StreakData: Codable {
    var currentStreak: Int = 0
    var longestStreak: Int = 0
    var lastSessionDate: Date?
    
    mutating func updateStreak(for date: Date) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: date)
        
        if let lastDate = lastSessionDate {
            let lastSessionDay = calendar.startOfDay(for: lastDate)
            let daysBetween = calendar.dateComponents([.day], from: lastSessionDay, to: today).day ?? 0
            
            if daysBetween == 1 {
                // Consecutive day
                currentStreak += 1
            } else if daysBetween > 1 {
                // Streak broken
                currentStreak = 1
            }
            // Same day doesn't change streak
        } else {
            // First session ever
            currentStreak = 1
        }
        
        lastSessionDate = date
        longestStreak = max(longestStreak, currentStreak)
    }
}
//
//  GamificationEngine.swift
//  FoundationWriting
//
//  Created by Hans Axelsson on 7/15/25.
//
import Foundation
import SwiftUI
import GameKit
import Combine

/// Manages gamification features including badges, achievements, and challenges
@MainActor
class GamificationEngine: ObservableObject {
    @Published var userProfile: GamifiedUserProfile
    @Published var availableChallenges: [WritingChallenge] = []
    @Published var activeChallenges: [WritingChallenge] = []
    @Published var recentAchievements: [Achievement] = []
    @Published var leaderboardEnabled = false
    @Published var weeklyRanking: LeaderboardEntry?
    
    private let learningEngine: AdaptiveLearningEngine
    private let achievementNotificationHandler: AchievementNotificationHandler
    
    init(learningEngine: AdaptiveLearningEngine) {
        self.learningEngine = learningEngine
        self.userProfile = Self.loadUserProfile() ?? GamifiedUserProfile()
        self.achievementNotificationHandler = AchievementNotificationHandler()
        
        setupGameCenter()
        generateWeeklyChallenges()
    }
    
    /// Records a writing session and updates gamification metrics
    func recordWritingSession(
        _ session: LearningSession,
        analysis: EnhancedWritingAnalysis
    ) async {
        // Update user profile
        userProfile.totalSessions += 1
        userProfile.totalWordsAnalyzed += estimateWordCount(from: analysis)
        userProfile.experiencePoints += calculateExperiencePoints(for: session, analysis: analysis)
        
        // Update skill-specific progress
        updateSkillProgress(for: session.skillArea, session: session)
        
        // Check for level up
        if checkForLevelUp() {
            await handleLevelUp()
        }
        
        // Check achievements
        let newAchievements = checkForNewAchievements(session: session, analysis: analysis)
        for achievement in newAchievements {
            await awardAchievement(achievement)
        }
        
        // Update challenge progress
        updateChallengeProgress(session: session, analysis: analysis)
        
        // Save progress
        saveUserProfile()
    }
    
    /// Starts a new writing challenge
    func startChallenge(_ challenge: WritingChallenge) {
        var updatedChallenge = challenge
        updatedChallenge.startDate = Date()
        updatedChallenge.isActive = true
        
        activeChallenges.append(updatedChallenge)
        
        // Remove from available challenges
        availableChallenges.removeAll { $0.id == challenge.id }
        
        saveUserProfile()
    }
    
    /// Generates daily writing challenges
    func generateDailyChallenges() {
        let today = Calendar.current.startOfDay(for: Date())
        
        // Don't generate if we already have challenges for today
        let todaysChallenges = availableChallenges.filter { challenge in
            Calendar.current.isDate(challenge.createdDate, inSameDayAs: today)
        }
        
        guard todaysChallenges.isEmpty else { return }
        
        var newChallenges: [WritingChallenge] = []
        
        // Quick writing challenge
        newChallenges.append(WritingChallenge(
            id: UUID(),
            title: "Flash Fiction Friday",
            description: "Write a 100-word story in under 15 minutes",
            type: .timed,
            difficulty: .easy,
            requirements: WritingChallenge.Requirements(
                minimumWords: 100,
                maximumWords: 100,
                timeLimit: 15 * 60,
                targetSkills: [.creativity, .style]
            ),
            rewards: WritingChallenge.Rewards(
                experiencePoints: 50,
                badge: .fastWriter,
                unlockableContent: nil
            ),
            createdDate: today
        ))
        
        // Skill-specific challenge
        let weakestSkill = findWeakestSkill()
        newChallenges.append(WritingChallenge(
            id: UUID(),
            title: "Skill Builder: \(weakestSkill.displayName)",
            description: "Complete 3 exercises focusing on \(weakestSkill.displayName.lowercased())",
            type: .skillFocus,
            difficulty: .medium,
            requirements: WritingChallenge.Requirements(
                exerciseCount: 3,
                targetSkills: [weakestSkill]
            ),
            rewards: WritingChallenge.Rewards(
                experiencePoints: 75,
                badge: .skillSpecialist,
                unlockableContent: "Advanced \(weakestSkill.displayName) Techniques"
            ),
            createdDate: today
        ))
        
        // Consistency challenge
        newChallenges.append(WritingChallenge(
            id: UUID(),
            title: "Daily Dedication",
            description: "Practice writing for 7 consecutive days",
            type: .consistency,
            difficulty: .hard,
            requirements: WritingChallenge.Requirements(
                consecutiveDays: 7,
                targetSkills: []
            ),
            rewards: WritingChallenge.Rewards(
                experiencePoints: 200,
                badge: .consistent,
                unlockableContent: "Habit Mastery Course"
            ),
            createdDate: today
        ))
        
        availableChallenges.append(contentsOf: newChallenges)
    }
    
    /// Shares achievement to Game Center
    func shareAchievementToGameCenter(_ achievement: Achievement) async {
        guard GKLocalPlayer.local.isAuthenticated else { return }
        
        let gcAchievement = GKAchievement(identifier: achievement.gameKitIdentifier)
        gcAchievement.percentComplete = 100.0
        gcAchievement.showsCompletionBanner = true
        
        do {
            try await GKAchievement.report([gcAchievement])
        } catch {
            print("Failed to report achievement to Game Center: \(error)")
        }
    }
    
    /// Updates leaderboard with current score
    func updateLeaderboard() async {
        guard GKLocalPlayer.local.isAuthenticated else { return }
        
        let score = GKScore(leaderboardIdentifier: "writing_experience_points")
        score.value = Int64(userProfile.experiencePoints)
        
        do {
            try await GKScore.report([score])
            await loadLeaderboardData()
        } catch {
            print("Failed to update leaderboard: \(error)")
        }
    }
    
    // MARK: - Private Methods
    
    private func setupGameCenter() {
        GKLocalPlayer.local.authenticateHandler = { [weak self] viewController, error in
            if let viewController = viewController {
                // Present authentication view controller
                // This would typically be handled by the main app
                print("Game Center authentication required")
            } else if let error = error {
                print("Game Center authentication failed: \(error)")
                self?.leaderboardEnabled = false
            } else {
                print("Game Center authenticated successfully")
                self?.leaderboardEnabled = true
                Task {
                    await self?.loadLeaderboardData()
                }
            }
        }
    }
    
    private func generateWeeklyChallenges() {
        // Generate challenges for the week
        generateDailyChallenges()
    }
    
    private func calculateExperiencePoints(
        for session: LearningSession,
        analysis: EnhancedWritingAnalysis
    ) -> Int {
        var points = 10 // Base points
        
        // Performance bonus
        points += Int(session.performanceScore * 20)
        
        // Time bonus
        let timeMinutes = session.timeSpent / 60
        points += min(Int(timeMinutes), 30) // Max 30 points for time
        
        // Difficulty bonus
        if analysis.improvementSuggestions.count >= 3 {
            points += 15 // Complex analysis bonus
        }
        
        // Skill improvement bonus
        if session.performanceScore >= 0.8 {
            points += 25 // High performance bonus
        }
        
        return points
    }
    
    private func estimateWordCount(from analysis: EnhancedWritingAnalysis) -> Int {
        // Estimate based on metrics
        let sentences = max(Int(analysis.metrics.averageSentenceLength > 0 ? 1 : 0), 1)
        return Int(analysis.metrics.averageSentenceLength * Double(sentences))
    }
    
    private func updateSkillProgress(for skillArea: SkillArea, session: LearningSession) {
        var skillData = userProfile.skillLevels[skillArea] ?? GamifiedSkillData(
            level: 1,
            experiencePoints: 0,
            sessionsCompleted: 0
        )
        
        skillData.experiencePoints += calculateSkillExperience(for: session)
        skillData.sessionsCompleted += 1
        
        // Check for skill level up
        let newLevel = calculateSkillLevel(from: skillData.experiencePoints)
        if newLevel > skillData.level {
            skillData.level = newLevel
            // Could trigger skill-specific achievements here
        }
        
        userProfile.skillLevels[skillArea] = skillData
    }
    
    private func calculateSkillExperience(for session: LearningSession) -> Int {
        return Int(session.performanceScore * 30) + Int(session.timeSpent / 120) // Base on performance and time
    }
    
    private func calculateSkillLevel(from experience: Int) -> Int {
        // Experience curve: level = sqrt(experience / 100)
        return max(1, Int(sqrt(Double(experience) / 100.0)))
    }
    
    private func checkForLevelUp() -> Bool {
        let newLevel = calculateUserLevel(from: userProfile.experiencePoints)
        if newLevel > userProfile.level {
            userProfile.level = newLevel
            return true
        }
        return false
    }
    
    private func calculateUserLevel(from experience: Int) -> Int {
        // Progressive leveling curve
        return max(1, Int(sqrt(Double(experience) / 200.0)))
    }
    
    private func handleLevelUp() async {
        // Award level up achievement
        let achievement = Achievement(
            id: UUID(),
            title: "Level Up!",
            description: "Reached level \(userProfile.level)",
            type: .levelUp,
            iconName: "star.fill",
            experienceReward: 50,
            unlockedAt: Date()
        )
        
        await awardAchievement(achievement)
        
        // Unlock new features or content based on level
        unlockContentForLevel(userProfile.level)
    }
    
    private func unlockContentForLevel(_ level: Int) {
        switch level {
        case 5:
            userProfile.unlockedFeatures.insert(.advancedAnalytics)
        case 10:
            userProfile.unlockedFeatures.insert(.customChallenges)
        case 15:
            userProfile.unlockedFeatures.insert(.mentorMode)
        case 20:
            userProfile.unlockedFeatures.insert(.collaborativeWriting)
        default:
            break
        }
    }
    
    private func checkForNewAchievements(
        session: LearningSession,
        analysis: EnhancedWritingAnalysis
    ) -> [Achievement] {
        var achievements: [Achievement] = []
        
        // First session achievement
        if userProfile.totalSessions == 1 {
            achievements.append(Achievement(
                id: UUID(),
                title: "First Steps",
                description: "Completed your first writing analysis",
                type: .firstTime,
                iconName: "pencil.circle.fill",
                experienceReward: 25,
                unlockedAt: Date()
            ))
        }
        
        // Session milestones
        let sessionMilestones = [10, 25, 50, 100, 250, 500]
        if sessionMilestones.contains(userProfile.totalSessions) {
            achievements.append(Achievement(
                id: UUID(),
                title: "Session Milestone",
                description: "Completed \(userProfile.totalSessions) writing sessions",
                type: .milestone,
                iconName: "target",
                experienceReward: userProfile.totalSessions >= 100 ? 200 : 100,
                unlockedAt: Date()
            ))
        }
        
        // Perfect performance achievement
        if session.performanceScore >= 0.95 {
            achievements.append(Achievement(
                id: UUID(),
                title: "Perfect Performance",
                description: "Achieved 95%+ performance in a session",
                type: .performance,
                iconName: "star.circle.fill",
                experienceReward: 100,
                unlockedAt: Date()
            ))
        }
        
        // High readability achievement
        if analysis.metrics.fleschKincaidGrade >= 8 && analysis.metrics.fleschKincaidGrade <= 12 {
            let existingAchievement = userProfile.earnedAchievements.contains { $0.type == .readability }
            if !existingAchievement {
                achievements.append(Achievement(
                    id: UUID(),
                    title: "Perfect Readability",
                    description: "Achieved optimal readability level",
                    type: .readability,
                    iconName: "eye.fill",
                    experienceReward: 75,
                    unlockedAt: Date()
                ))
            }
        }
        
        // Vocabulary diversity achievement
        if analysis.metrics.vocabularyDiversity >= 0.8 {
            let existingAchievement = userProfile.earnedAchievements.contains { $0.type == .vocabulary }
            if !existingAchievement {
                achievements.append(Achievement(
                    id: UUID(),
                    title: "Vocabulary Virtuoso",
                    description: "Achieved 80%+ vocabulary diversity",
                    type: .vocabulary,
                    iconName: "book.fill",
                    experienceReward: 75,
                    unlockedAt: Date()
                ))
            }
        }
        
        return achievements
    }
    
    private func awardAchievement(_ achievement: Achievement) async {
        userProfile.earnedAchievements.append(achievement)
        userProfile.experiencePoints += achievement.experienceReward
        recentAchievements.insert(achievement, at: 0)
        
        // Keep only recent achievements (last 10)
        if recentAchievements.count > 10 {
            recentAchievements.removeLast()
        }
        
        // Show notification
        await achievementNotificationHandler.showAchievementNotification(achievement)
        
        // Share to Game Center if enabled
        if leaderboardEnabled {
            await shareAchievementToGameCenter(achievement)
        }
        
        saveUserProfile()
    }
    
    private func updateChallengeProgress(
        session: LearningSession,
        analysis: EnhancedWritingAnalysis
    ) {
        for index in activeChallenges.indices {
            var challenge = activeChallenges[index]
            
            switch challenge.type {
            case .timed:
                if challenge.requirements.targetSkills.contains(session.skillArea) {
                    challenge.progress.sessionsCompleted += 1
                }
                
            case .skillFocus:
                if challenge.requirements.targetSkills.contains(session.skillArea) {
                    challenge.progress.exercisesCompleted += 1
                }
                
            case .consistency:
                // Update consecutive days if session was today
                let today = Calendar.current.startOfDay(for: Date())
                let sessionDate = Calendar.current.startOfDay(for: session.completedAt)
                
                if Calendar.current.isDate(sessionDate, inSameDayAs: today) {
                    challenge.progress.consecutiveDays += 1
                }
                
            case .wordCount:
                let wordCount = estimateWordCount(from: analysis)
                challenge.progress.wordsWritten += wordCount
            }
            
            // Check if challenge is completed
            if challenge.isCompleted {
                challenge.completedDate = Date()
                challenge.isActive = false
                
                // Award challenge rewards
                userProfile.experiencePoints += challenge.rewards.experiencePoints
                
                if let badge = challenge.rewards.badge {
                    userProfile.earnedBadges.insert(badge)
                }
                
                // Move to completed challenges
                activeChallenges.remove(at: index)
                userProfile.completedChallenges.append(challenge)
                break
            } else {
                activeChallenges[index] = challenge
            }
        }
    }
    
    private func findWeakestSkill() -> SkillArea {
        var lowestLevel = Int.max
        var weakestSkill: SkillArea = .grammar
        
        for skill in SkillArea.allCases {
            let skillData = userProfile.skillLevels[skill]
            let level = skillData?.level ?? 1
            
            if level < lowestLevel {
                lowestLevel = level
                weakestSkill = skill
            }
        }
        
        return weakestSkill
    }
    
    private func loadLeaderboardData() async {
        guard GKLocalPlayer.local.isAuthenticated else { return }
        
        do {
            let leaderboard = try await GKLeaderboard.loadLeaderboards(IDs: ["writing_experience_points"]).first
            if let scores = try await leaderboard?.loadEntries(for: .global, timeScope: .week, range: NSRange(location: 1, length: 1)).1,
               let playerScore = scores.first {
                
                weeklyRanking = LeaderboardEntry(
                    rank: playerScore.rank,
                    score: playerScore.rank,
                    playerName: playerScore.player.displayName
                )
            }
        } catch {
            print("Failed to load leaderboard data: \(error)")
        }
    }
    
    // MARK: - Persistence
    
    private static func loadUserProfile() -> GamifiedUserProfile? {
        guard let data = UserDefaults.standard.data(forKey: "GamifiedUserProfile"),
              let profile = try? JSONDecoder().decode(GamifiedUserProfile.self, from: data) else {
            return nil
        }
        return profile
    }
    
    private func saveUserProfile() {
        if let encoded = try? JSONEncoder().encode(userProfile) {
            UserDefaults.standard.set(encoded, forKey: "GamifiedUserProfile")
        }
    }
}

// MARK: - Achievement Notification Handler

@MainActor
class AchievementNotificationHandler: ObservableObject {
    func showAchievementNotification(_ achievement: Achievement) async {
        // In a real app, this would show a toast notification or banner
        print("🏆 Achievement Unlocked: \(achievement.title)")
        print("   \(achievement.description)")
        print("   +\(achievement.experienceReward) XP")
    }
}

//
//  InteractiveExerciseEngine.swift
//  FoundationWriting
//
//  Created by Hans Axelsson on 7/15/25.
//
import Foundation
import SwiftUI

/// Manages interactive writing exercises and skill-building activities
@MainActor
class InteractiveExerciseEngine: ObservableObject {
    @Published var availableExercises: [WritingExercise] = []
    @Published var currentExercise: WritingExercise?
    @Published var exerciseResults: [ExerciseResult] = []
    @Published var isGeneratingExercise = false
    
    private let analysisService: any EnhancedWritingAnalysisService
    private let gamificationEngine: GamificationEngine
    
    init(
        analysisService: any EnhancedWritingAnalysisService,
        gamificationEngine: GamificationEngine
    ) {
        self.analysisService = analysisService
        self.gamificationEngine = gamificationEngine
        
        generateDailyExercises()
    }
    
    /// Generates personalized exercises based on user's skill gaps
    func generatePersonalizedExercises(
        based on: EnhancedWritingAnalysis,
        skillProgress: [SkillArea: SkillProgress]
    ) async throws {
        
        isGeneratingExercise = true
        defer { isGeneratingExercise = false }
        
        var exercises: [WritingExercise] = []
        
        // Generate exercises for each improvement suggestion
        for suggestion in on.improvementSuggestions.prefix(3) {
            let exercise = try await generateExerciseForSuggestion(suggestion)
            exercises.append(exercise)
        }
        
        // Generate exercises for weakest skills
        let weakestSkills = findWeakestSkills(in: skillProgress)
        for skill in weakestSkills.prefix(2) {
            let exercise = generateSkillSpecificExercise(for: skill)
            exercises.append(exercise)
        }
        
        // Generate creative exercises
        exercises.append(generateCreativeExercise())
        
        availableExercises = exercises
    }
    
    /// Starts a specific exercise
    func startExercise(_ exercise: WritingExercise) {
        currentExercise = exercise
    }
    
    /// Submits exercise completion and evaluates performance
    func submitExercise(
        _ exercise: WritingExercise,
        userResponse: String,
        timeSpent: TimeInterval
    ) async throws -> ExerciseResult {
        
        // Analyze the user's response
        let analysisOptions = EnhancedWritingAnalysisOptions.createDefault()
        let analysis = try await analysisService.analyzeWriting(userResponse, options: analysisOptions)
        
        // Evaluate performance based on exercise objectives
        let performance = evaluatePerformance(
            exercise: exercise,
            userResponse: userResponse,
            analysis: analysis,
            timeSpent: timeSpent
        )
        
        // Create result
        let result = ExerciseResult(
            id: UUID(),
            exerciseId: exercise.id,
            userResponse: userResponse,
            analysis: analysis,
            performance: performance,
            timeSpent: timeSpent,
            completedAt: Date(),
            feedback: generateFeedback(for: exercise, performance: performance, analysis: analysis)
        )
        
        exerciseResults.append(result)
        
        // Record session for gamification
        let session = LearningSession(
            skillArea: exercise.targetSkill,
            performanceScore: performance.overallScore,
            timeSpent: timeSpent,
            completedAt: Date(),
            exerciseType: exercise.type.rawValue
        )
        
        await gamificationEngine.recordWritingSession(session, analysis: analysis)
        
        // Clear current exercise
        currentExercise = nil
        
        return result
    }
    
    /// Generates daily practice exercises
    func generateDailyExercises() {
        let today = Calendar.current.startOfDay(for: Date())
        
        // Don't regenerate if we already have exercises for today
        let todaysExercises = availableExercises.filter { exercise in
            Calendar.current.isDate(exercise.createdDate, inSameDayAs: today)
        }
        
        guard todaysExercises.isEmpty else { return }
        
        var exercises: [WritingExercise] = []
        
        // Quick warm-up exercise
        exercises.append(generateWarmUpExercise())
        
        // Skill rotation exercises
        for skill in SkillArea.allCases.shuffled().prefix(3) {
            exercises.append(generateSkillSpecificExercise(for: skill))
        }
        
        // Creative challenge
        exercises.append(generateCreativeExercise())
        
        // Timed challenge
        exercises.append(generateTimedExercise())
        
        availableExercises.append(contentsOf: exercises)
    }
    
    // MARK: - Exercise Generation
    
    private func generateExerciseForSuggestion(_ suggestion: EnhancedWritingAnalysis.ImprovementSuggestion) async throws -> WritingExercise {
        let exerciseType: WritingExercise.ExerciseType
        let instructions: String
        let objectives: [String]
        
        switch suggestion.area {
        case .grammar:
            exerciseType = .grammar
            instructions = "Rewrite the following sentences to correct any grammatical errors:\n\n\(suggestion.beforeExample)"
            objectives = ["Identify grammatical errors", "Apply correct grammar rules", "Improve sentence structure"]
            
        case .style:
            exerciseType = .style
            instructions = "Rewrite this passage to improve its style and flow:\n\n\(suggestion.beforeExample)"
            objectives = ["Enhance writing style", "Improve sentence variety", "Create better flow"]
            
        case .clarity:
            exerciseType = .clarity
            instructions = "Make this text clearer and more concise:\n\n\(suggestion.beforeExample)"
            objectives = ["Eliminate ambiguity", "Use precise language", "Improve clarity"]
            
        case .vocabulary:
            exerciseType = .vocabulary
            instructions = "Replace generic words with more specific alternatives in this text:\n\n\(suggestion.beforeExample)"
            objectives = ["Expand vocabulary usage", "Use precise words", "Avoid repetition"]
            
        case .structure:
            exerciseType = .structure
            instructions = "Reorganize this text for better logical flow:\n\n\(suggestion.beforeExample)"
            objectives = ["Improve organization", "Create logical flow", "Use effective transitions"]
            
        case .tone:
            exerciseType = .tone
            instructions = "Adjust the tone of this text to be more appropriate for a professional audience:\n\n\(suggestion.beforeExample)"
            objectives = ["Match tone to audience", "Maintain consistency", "Convey appropriate emotion"]
            
        case .creativity:
            exerciseType = .creative
            instructions = "Add creative elements to make this text more engaging:\n\n\(suggestion.beforeExample)"
            objectives = ["Use vivid imagery", "Add creative comparisons", "Engage the reader"]
        }
        
        return WritingExercise(
            id: UUID(),
            title: "Targeted Practice: \(suggestion.title)",
            description: "Practice exercise based on your specific improvement area",
            type: exerciseType,
            targetSkill: mapImprovementAreaToSkill(suggestion.area),
            difficulty: calculateDifficulty(from: suggestion.priority),
            instructions: instructions,
            objectives: objectives,
            expectedOutcome: "Improved \(suggestion.area.rawValue) in your writing",
            timeEstimate: TimeInterval(suggestion.learningEffort * 30 * 60), // Convert to minutes
            createdDate: Date(),
            sampleResponse: suggestion.afterExample
        )
    }
    
    private func generateSkillSpecificExercise(for skill: SkillArea) -> WritingExercise {
        switch skill {
        case .grammar:
            return WritingExercise(
                id: UUID(),
                title: "Grammar Challenge",
                description: "Practice identifying and correcting grammatical errors",
                type: .grammar,
                targetSkill: skill,
                difficulty: .medium,
                instructions: """
                Edit the following sentences to correct any grammatical errors. Pay attention to:
                - Subject-verb agreement
                - Punctuation
                - Sentence fragments
                - Run-on sentences
                
                Sentences to edit:
                1. The team are working on there project.
                2. Between you and I, this is a difficult task.
                3. She don't like the new policy changes.
                4. The presentation went good, everyone were impressed.
                5. Its important to proofread you're work carefully.
                """,
                objectives: [
                    "Identify common grammatical errors",
                    "Apply correct grammar rules",
                    "Improve overall writing accuracy"
                ],
                expectedOutcome: "Error-free sentences with proper grammar",
                timeEstimate: 900, // 15 minutes
                createdDate: Date(),
                sampleResponse: """
                1. The team is working on their project.
                2. Between you and me, this is a difficult task.
                3. She doesn't like the new policy changes.
                4. The presentation went well; everyone was impressed.
                5. It's important to proofread your work carefully.
                """
            )
            
        case .style:
            return WritingExercise(
                id: UUID(),
                title: "Style Enhancement",
                description: "Transform bland writing into engaging prose",
                type: .style,
                targetSkill: skill,
                difficulty: .medium,
                instructions: """
                Rewrite the following paragraph to make it more engaging and stylistically interesting:
                
                "The meeting was at 9 AM. We talked about the budget. Everyone had opinions. Some people agreed. Others did not agree. The boss made the final decision. The meeting ended at 10 AM."
                
                Focus on:
                - Varying sentence length and structure
                - Using active voice
                - Adding descriptive details
                - Creating better flow between sentences
                """,
                objectives: [
                    "Vary sentence structure",
                    "Use active voice effectively", 
                    "Create engaging prose",
                    "Improve rhythm and flow"
                ],
                expectedOutcome: "More engaging and varied writing style",
                timeEstimate: 1200, // 20 minutes
                createdDate: Date(),
                sampleResponse: "At precisely 9 AM, our budget meeting commenced with an animated discussion that quickly revealed divided opinions across the room. While some team members enthusiastically supported the proposed allocations, others voiced strong reservations. After an hour of spirited debate, our boss synthesized the various perspectives and announced the final decision, bringing the session to a decisive close."
            )
            
        case .clarity:
            return WritingExercise(
                id: UUID(),
                title: "Clarity Challenge",
                description: "Make complex ideas crystal clear",
                type: .clarity,
                targetSkill: skill,
                difficulty: .medium,
                instructions: """
                Simplify and clarify the following complex sentence while maintaining all the important information:
                
                "The implementation of the new software system, which has been under consideration by the IT department for several months due to various technical and budgetary constraints that needed to be addressed before moving forward, will commence next quarter following the completion of staff training programs."
                
                Break it into clearer, more digestible sentences.
                """,
                objectives: [
                    "Break down complex sentences",
                    "Use simple, clear language",
                    "Maintain all important information",
                    "Improve readability"
                ],
                expectedOutcome: "Clear, easy-to-understand writing",
                timeEstimate: 600, // 10 minutes
                createdDate: Date(),
                sampleResponse: "The IT department has spent several months evaluating a new software system. They needed to resolve technical and budgetary constraints before proceeding. Once staff training is complete, the implementation will begin next quarter."
            )
            
        case .vocabulary:
            return WritingExercise(
                id: UUID(),
                title: "Vocabulary Expansion",
                description: "Replace generic words with precise alternatives",
                type: .vocabulary,
                targetSkill: skill,
                difficulty: .medium,
                instructions: """
                Replace the underlined generic words with more specific, precise alternatives:
                
                "The *big* company had a *good* meeting about their *nice* product. The *people* were *happy* about the *things* they discussed. The *stuff* they talked about was *important* for the *business*."
                
                Choose words that:
                - Are more specific and descriptive
                - Match the professional context
                - Vary in complexity and style
                - Enhance meaning rather than just replace
                """,
                objectives: [
                    "Use precise vocabulary",
                    "Avoid generic words",
                    "Match words to context",
                    "Enhance meaning through word choice"
                ],
                expectedOutcome: "More sophisticated and precise language",
                timeEstimate: 900, // 15 minutes
                createdDate: Date(),
                sampleResponse: "The multinational corporation conducted a productive meeting regarding their innovative product line. The executives were enthusiastic about the strategies they discussed. The initiatives they explored were crucial for the company's market expansion."
            )
            
        case .structure:
            return WritingExercise(
                id: UUID(),
                title: "Structure Improvement",
                description: "Organize ideas for maximum impact",
                type: .structure,
                targetSkill: skill,
                difficulty: .hard,
                instructions: """
                Reorganize the following jumbled paragraph into a logical sequence:
                
                "Additionally, proper training reduces workplace accidents. Employee training programs are essential for business success. Furthermore, trained employees are more productive and efficient. Companies that invest in training see higher profits. Without training, employees make more mistakes and work slower. Most importantly, training improves employee satisfaction and retention."
                
                Create a well-structured paragraph with:
                - A clear topic sentence
                - Logical progression of ideas
                - Appropriate transitions
                - A strong conclusion
                """,
                objectives: [
                    "Create logical organization",
                    "Use effective transitions",
                    "Structure arguments clearly",
                    "Build to a strong conclusion"
                ],
                expectedOutcome: "Well-organized, logical writing flow",
                timeEstimate: 1200, // 20 minutes
                createdDate: Date(),
                sampleResponse: "Employee training programs are essential for business success. First, trained employees are more productive and efficient, while untrained workers tend to make more mistakes and work slower. Additionally, proper training reduces workplace accidents, creating a safer work environment. Furthermore, companies that invest in comprehensive training programs see higher profits as a direct result. Most importantly, training improves employee satisfaction and retention, creating a positive cycle of organizational growth."
            )
            
        case .tone:
            return WritingExercise(
                id: UUID(),
                title: "Tone Mastery",
                description: "Adapt your writing tone for different audiences",
                type: .tone,
                targetSkill: skill,
                difficulty: .medium,
                instructions: """
                Rewrite the following message for three different audiences:
                
                Original: "Hey, the project deadline got moved up and we need to work faster to finish everything on time."
                
                1. For your team members (collaborative tone)
                2. For senior management (professional tone)
                3. For external clients (diplomatic tone)
                
                Adjust vocabulary, formality, and approach for each audience.
                """,
                objectives: [
                    "Adapt tone to audience",
                    "Maintain appropriate formality",
                    "Choose suitable vocabulary",
                    "Convey the same message effectively"
                ],
                expectedOutcome: "Audience-appropriate communication",
                timeEstimate: 1200, // 20 minutes
                createdDate: Date(),
                sampleResponse: """
                1. Team: "Quick update everyone - we've got an accelerated timeline for the project. Let's sync up to prioritize tasks and ensure we hit our new deadline together."
                
                2. Management: "I'm writing to inform you that we've adjusted our project timeline to meet the advanced deadline. Our team is implementing optimization strategies to ensure timely delivery."
                
                3. Client: "We're pleased to inform you that we're working to deliver your project ahead of schedule. Our team is committed to maintaining our high standards while meeting your accelerated timeline."
                """
            )
            
        case .creativity:
            return WritingExercise(
                id: UUID(),
                title: "Creative Expression",
                description: "Unleash your creative writing potential",
                type: .creative,
                targetSkill: skill,
                difficulty: .medium,
                instructions: """
                Write a short story (150-200 words) that begins with this sentence:
                "The last thing Sarah expected to find in her grandmother's attic was a map."
                
                Use:
                - Vivid sensory details
                - Creative metaphors or similes
                - Engaging dialogue (if applicable)
                - An unexpected twist or revelation
                - Show, don't tell
                """,
                objectives: [
                    "Use creative storytelling techniques",
                    "Employ vivid imagery",
                    "Create engaging narratives",
                    "Develop creative voice"
                ],
                expectedOutcome: "An engaging, creative piece of writing",
                timeEstimate: 1800, // 30 minutes
                createdDate: Date(),
                sampleResponse: "The last thing Sarah expected to find in her grandmother's attic was a map. Dust motes danced in the amber light filtering through the small window as she unfolded the yellowed parchment. Strange symbols dotted the familiar streets of her hometown, and a red X marked her own house. 'For my dear Sarah,' read the faded inscription, 'when you're ready to see the magic that's always been there.' As she traced the mysterious route with her finger, the paper began to glow softly, and Sarah realized her grandmother's stories about hidden doorways to other worlds weren't just fairy tales after all."
            )
        }
    }
    
    private func generateWarmUpExercise() -> WritingExercise {
        let prompts = [
            "Describe your perfect writing environment in exactly 50 words.",
            "Write about a color without naming it, using only sensory descriptions.",
            "Create a sentence that starts with each letter of your first name.",
            "Describe the sound of silence in three different ways.",
            "Write a conversation between two objects in your room."
        ]
        
        let selectedPrompt = prompts.randomElement()!
        
        return WritingExercise(
            id: UUID(),
            title: "Daily Warm-Up",
            description: "A quick exercise to get your creative juices flowing",
            type: .warmUp,
            targetSkill: .creativity,
            difficulty: .easy,
            instructions: selectedPrompt,
            objectives: [
                "Practice daily writing",
                "Warm up creative thinking",
                "Build writing consistency"
            ],
            expectedOutcome: "Improved writing readiness and creativity",
            timeEstimate: 300, // 5 minutes
            createdDate: Date()
        )
    }
    
    private func generateCreativeExercise() -> WritingExercise {
        let themes = [
            "Write about a world where colors have sounds",
            "Describe a conversation between past and future you",
            "Create a story told entirely through text messages",
            "Write about the last bookstore on Earth",
            "Describe a museum exhibit of forgotten emotions"
        ]
        
        let selectedTheme = themes.randomElement()!
        
        return WritingExercise(
            id: UUID(),
            title: "Creative Challenge",
            description: "Push your creative boundaries",
            type: .creative,
            targetSkill: .creativity,
            difficulty: .medium,
            instructions: "\(selectedTheme)\n\nWrite 200-300 words exploring this concept. Focus on unique perspectives and creative expression.",
            objectives: [
                "Explore creative concepts",
                "Develop unique voice",
                "Practice imaginative writing",
                "Experiment with style"
            ],
            expectedOutcome: "Enhanced creative writing skills",
            timeEstimate: 1800, // 30 minutes
            createdDate: Date()
        )
    }
    
    private func generateTimedExercise() -> WritingExercise {
        return WritingExercise(
            id: UUID(),
            title: "Speed Writing",
            description: "Write quickly to overcome perfectionism",
            type: .timed,
            targetSkill: .style,
            difficulty: .medium,
            instructions: """
            Write continuously for 10 minutes about "A day that changed everything."
            
            Rules:
            - Don't stop writing
            - Don't edit as you go
            - If you get stuck, write "I'm stuck" until ideas come
            - Focus on flow, not perfection
            """,
            objectives: [
                "Overcome perfectionism",
                "Practice continuous writing",
                "Develop writing fluency",
                "Generate raw material"
            ],
            expectedOutcome: "Improved writing fluency and confidence",
            timeEstimate: 600, // 10 minutes
            createdDate: Date()
        )
    }
    
    // MARK: - Performance Evaluation
    
    private func evaluatePerformance(
        exercise: WritingExercise,
        userResponse: String,
        analysis: EnhancedWritingAnalysis,
        timeSpent: TimeInterval
    ) -> ExercisePerformance {
        
        var scores: [String: Double] = [:]
        var overallScore: Double = 0
        
        // Evaluate based on exercise type
        switch exercise.type {
        case .grammar:
            scores["Grammar Accuracy"] = evaluateGrammarAccuracy(analysis)
            scores["Clarity"] = evaluateClarity(analysis)
            overallScore = (scores["Grammar Accuracy"]! + scores["Clarity"]!) / 2
            
        case .style:
            scores["Style Variety"] = evaluateStyleVariety(analysis)
            scores["Flow"] = evaluateFlow(userResponse)
            scores["Engagement"] = evaluateEngagement(userResponse)
            overallScore = scores.values.reduce(0, +) / Double(scores.count)
            
        case .clarity:
            scores["Clarity"] = evaluateClarity(analysis)
            scores["Conciseness"] = evaluateConciseness(userResponse)
            scores["Readability"] = evaluateReadability(analysis)
            overallScore = scores.values.reduce(0, +) / Double(scores.count)
            
        case .vocabulary:
            scores["Vocabulary Diversity"] = analysis.metrics.vocabularyDiversity
            scores["Word Precision"] = evaluateWordPrecision(userResponse)
            overallScore = scores.values.reduce(0, +) / Double(scores.count)
            
        case .structure:
            scores["Organization"] = evaluateOrganization(userResponse)
            scores["Transitions"] = evaluateTransitions(userResponse)
            scores["Logic"] = evaluateLogic(userResponse)
            overallScore = scores.values.reduce(0, +) / Double(scores.count)
            
        case .tone:
            scores["Tone Consistency"] = evaluateToneConsistency(userResponse)
            scores["Audience Appropriateness"] = evaluateAudienceAppropriiateness(userResponse)
            overallScore = scores.values.reduce(0, +) / Double(scores.count)
            
        case .creative:
            scores["Creativity"] = evaluateCreativity(userResponse)
            scores["Imagery"] = evaluateImagery(userResponse)
            scores["Originality"] = evaluateOriginality(userResponse)
            overallScore = scores.values.reduce(0, +) / Double(scores.count)
            
        case .warmUp, .timed:
            scores["Completion"] = userResponse.isEmpty ? 0.0 : 1.0
            scores["Effort"] = min(timeSpent / exercise.timeEstimate, 1.0)
            overallScore = scores.values.reduce(0, +) / Double(scores.count)
        }
        
        // Time efficiency bonus/penalty
        let timeEfficiency = calculateTimeEfficiency(actual: timeSpent, expected: exercise.timeEstimate)
        
        return ExercisePerformance(
            overallScore: overallScore,
            skillScores: scores,
            timeEfficiency: timeEfficiency,
            improvementAreas: identifyImprovementAreas(scores: scores, analysis: analysis)
        )
    }
    
    private func generateFeedback(
        for exercise: WritingExercise,
        performance: ExercisePerformance,
        analysis: EnhancedWritingAnalysis
    ) -> ExerciseFeedback {
        
        var strengths: [String] = []
        var improvements: [String] = []
        var tips: [String] = []
        
        // Analyze performance scores
        for (skill, score) in performance.skillScores {
            if score >= 0.8 {
                strengths.append("Excellent \(skill.lowercased())")
            } else if score < 0.6 {
                improvements.append("Focus on improving \(skill.lowercased())")
            }
        }
        
        // Add specific tips based on exercise type
        switch exercise.type {
        case .grammar:
            if performance.skillScores["Grammar Accuracy"] ?? 0 < 0.7 {
                tips.append("Review basic grammar rules and practice with shorter sentences first")
            }
            
        case .style:
            if performance.skillScores["Style Variety"] ?? 0 < 0.7 {
                tips.append("Try varying your sentence openings and lengths")
            }
            
        case .clarity:
            if performance.skillScores["Clarity"] ?? 0 < 0.7 {
                tips.append("Break complex ideas into smaller, clearer sentences")
            }
            
        case .vocabulary:
            if performance.skillScores["Vocabulary Diversity"] ?? 0 < 0.7 {
                tips.append("Challenge yourself to use synonyms and avoid repetition")
            }
            
        case .structure:
            if performance.skillScores["Organization"] ?? 0 < 0.7 {
                tips.append("Create an outline before writing to improve organization")
            }
            
        case .tone:
            if performance.skillScores["Tone Consistency"] ?? 0 < 0.7 {
                tips.append("Identify your target audience before writing and stick to appropriate language")
            }
            
        case .creative:
            if performance.skillScores["Creativity"] ?? 0 < 0.7 {
                tips.append("Don't be afraid to take risks and explore unusual ideas")
            }
            
        case .warmUp, .timed:
            tips.append("Regular practice will help improve your writing fluency")
        }
        
        // Generate overall feedback message
        let overallMessage: String
        if performance.overallScore >= 0.9 {
            overallMessage = "Outstanding work! You've mastered this exercise."
        } else if performance.overallScore >= 0.8 {
            overallMessage = "Excellent performance! You're on the right track."
        } else if performance.overallScore >= 0.7 {
            overallMessage = "Good effort! A few improvements will make this even better."
        } else if performance.overallScore >= 0.6 {
            overallMessage = "You're making progress! Focus on the improvement areas."
        } else {
            overallMessage = "This is challenging material. Don't give up - practice makes perfect!"
        }
        
        return ExerciseFeedback(
            overallMessage: overallMessage,
            strengths: strengths,
            improvementAreas: improvements,
            tips: tips,
            nextSteps: generateNextSteps(for: exercise, performance: performance)
        )
    }
    
    // MARK: - Helper Methods
    
    private func findWeakestSkills(in progress: [SkillArea: SkillProgress]) -> [SkillArea] {
        return progress.sorted { $0.value.currentLevel < $1.value.currentLevel }
                      .prefix(3)
                      .map { $0.key }
    }
    
    private func mapImprovementAreaToSkill(_ area: EnhancedWritingAnalysisOptions.ImprovementFocus) -> SkillArea {
        switch area {
        case .grammar: return .grammar
        case .style: return .style
        case .clarity: return .clarity
        case .vocabulary: return .vocabulary
        case .structure: return .structure
        case .tone: return .tone
        case .creativity: return .creativity
        }
    }
    
    private func calculateDifficulty(from priority: Double) -> WritingExercise.Difficulty {
        switch priority {
        case 0.8...: return .hard
        case 0.6..<0.8: return .medium
        default: return .easy
        }
    }
    
    // MARK: - Evaluation Methods (Simplified implementations)
    
    private func evaluateGrammarAccuracy(_ analysis: EnhancedWritingAnalysis) -> Double {
        // Count grammar-related suggestions and penalize
        let grammarIssues = analysis.improvementSuggestions.filter { $0.area == .grammar }.count
        return max(0.0, 1.0 - Double(grammarIssues) * 0.2)
    }
    
    private func evaluateClarity(_ analysis: EnhancedWritingAnalysis) -> Double {
        // Base on readability grade - optimal range is 8-12
        let grade = analysis.metrics.fleschKincaidGrade
        if grade >= 8 && grade <= 12 {
            return 1.0
        } else {
            let deviation = min(abs(grade - 10), 5)
            return max(0.0, 1.0 - deviation * 0.1)
        }
    }
    
    private func evaluateStyleVariety(_ analysis: EnhancedWritingAnalysis) -> Double {
        // Simplified - based on sentence length variety
        let avgLength = analysis.metrics.averageSentenceLength
        if avgLength > 10 && avgLength < 25 {
            return 0.8
        }
        return 0.6
    }
    
    private func evaluateFlow(_ text: String) -> Double {
        // Simplified - check for transition words
        let transitions = ["however", "therefore", "furthermore", "additionally", "meanwhile", "consequently"]
        let hasTransitions = transitions.contains { text.lowercased().contains($0) }
        return hasTransitions ? 0.8 : 0.6
    }
    
    private func evaluateEngagement(_ text: String) -> Double {
        // Simplified - check for engaging elements
        let engagingElements = ["!", "?", "\"", "'"]
        let hasEngagement = engagingElements.contains { text.contains($0) }
        return hasEngagement ? 0.8 : 0.6
    }
    
    private func evaluateConciseness(_ text: String) -> Double {
        // Simplified - ratio of content words to total words
        let words = text.split { $0.isWhitespace }.count
        let fillerWords = ["very", "really", "quite", "rather", "somewhat"]
        let fillerCount = fillerWords.reduce(0) { count, filler in
            count + text.lowercased().components(separatedBy: filler).count - 1
        }
        return max(0.0, 1.0 - Double(fillerCount) / Double(words))
    }
    
    private func evaluateReadability(_ analysis: EnhancedWritingAnalysis) -> Double {
        return evaluateClarity(analysis) // Same logic for now
    }
    
    private func evaluateWordPrecision(_ text: String) -> Double {
        // Simplified - penalize for generic words
        let genericWords = ["thing", "stuff", "good", "bad", "nice", "big", "small"]
        let genericCount = genericWords.reduce(0) { count, generic in
            count + text.lowercased().components(separatedBy: generic).count - 1
        }
        let totalWords = text.split { $0.isWhitespace }.count
        return max(0.0, 1.0 - Double(genericCount) / Double(totalWords) * 5)
    }
    
    private func evaluateOrganization(_ text: String) -> Double {
        // Simplified - check for clear structure indicators
        let structureWords = ["first", "second", "finally", "in conclusion", "to begin"]
        let hasStructure = structureWords.contains { text.lowercased().contains($0) }
        return hasStructure ? 0.9 : 0.7
    }
    
    private func evaluateTransitions(_ text: String) -> Double {
        return evaluateFlow(text) // Same logic
    }
    
    private func evaluateLogic(_ text: String) -> Double {
        // Simplified - assume logical if well-organized
        return evaluateOrganization(text)
    }
    
    private func evaluateToneConsistency(_ text: String) -> Double {
        // Simplified implementation
        return 0.8 // Default good score
    }
    
    private func evaluateAudienceAppropriiateness(_ text: String) -> Double {
        // Simplified implementation
        return 0.8 // Default good score
    }
    
    private func evaluateCreativity(_ text: String) -> Double {
        // Check for creative elements like metaphors, unusual word combinations
        let creativeIndicators = ["like", "as if", "reminded", "seemed", "appeared"]
        let hasCreativity = creativeIndicators.contains { text.lowercased().contains($0) }
        return hasCreativity ? 0.9 : 0.7
    }
    
    private func evaluateImagery(_ text: String) -> Double {
        // Check for sensory words
        let sensoryWords = ["bright", "soft", "loud", "sweet", "rough", "smooth", "warm", "cold"]
        let hasSensory = sensoryWords.contains { text.lowercased().contains($0) }
        return hasSensory ? 0.9 : 0.6
    }
    
    private func evaluateOriginality(_ text: String) -> Double {
        // Simplified - assume originality based on length and complexity
        return min(1.0, Double(text.count) / 200.0)
    }
    
    private func calculateTimeEfficiency(actual: TimeInterval, expected: TimeInterval) -> Double {
        let ratio = actual / expected
        if ratio <= 1.0 {
            return 1.0 // Completed within expected time
        } else if ratio <= 1.5 {
            return 0.8 // Took 50% longer
        } else {
            return 0.6 // Took much longer
        }
    }
    
    private func identifyImprovementAreas(scores: [String: Double], analysis: EnhancedWritingAnalysis) -> [String] {
        var areas: [String] = []
        
        for (skill, score) in scores {
            if score < 0.7 {
                areas.append(skill)
            }
        }
        
        // Add areas from analysis suggestions
        for suggestion in analysis.improvementSuggestions.prefix(2) {
            areas.append(suggestion.area.rawValue.capitalized)
        }
        
        return Array(Set(areas)) // Remove duplicates
    }
    
    private func generateNextSteps(for exercise: WritingExercise, performance: ExercisePerformance) -> [String] {
        var steps: [String] = []
        
        if performance.overallScore >= 0.8 {
            steps.append("Try a more advanced exercise in the same area")
            steps.append("Apply these skills to a longer writing piece")
        } else {
            steps.append("Practice similar exercises to reinforce these skills")
            steps.append("Review the feedback and focus on improvement areas")
        }
        
        steps.append("Continue daily writing practice")
        
        return steps
    }
}
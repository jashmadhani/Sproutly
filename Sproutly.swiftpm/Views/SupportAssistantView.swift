//
//  SupportAssistantView.swift
//  Sproutly
//
//  Created by Jash Madhani on 19/02/26.
//

import SwiftUI
import SwiftData

/// Empathetic AI Support Assistant that replaces the journal.
/// Uses on-device rule-based response engine — no API needed.
/// Context-aware: knows child age, milestones, domain status.
/// Response pattern: Reassurance → Normalization → Activities → Pediatric mention.
struct SupportAssistantView: View {
    let milestones: [Milestone]
    let correctedAge: Int
    let nightMode: Bool
    
    @State private var question: String = ""
    @State private var response: AssistantResponse? = nil
    @State private var responseOpacity: Double = 0
    @FocusState private var isInputFocused: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(Theme.accentBlue(for: nightMode).opacity(0.12))
                        .frame(width: 36, height: 36)
                    
                    Image(systemName: "sparkles")
                        .font(.system(size: 16))
                        .foregroundStyle(Theme.accentBlue(for: nightMode))
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Ask Sproutly")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Theme.textPrimary(for: nightMode))
                    
                    Text("Share a question or concern")
                        .font(.caption2)
                        .foregroundStyle(Theme.textSecondary(for: nightMode))
                }
                
                Spacer()
            }
            
            // Input field
            HStack(spacing: 10) {
                TextField("e.g. My child isn't walking yet...", text: $question, axis: .vertical)
                    .lineLimit(1...4)
                    .font(.subheadline)
                    .foregroundStyle(Theme.textPrimary(for: nightMode))
                    .focused($isInputFocused)
                
                if !question.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Button {
                        generateResponse()
                        isInputFocused = false
                    } label: {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.title2)
                            .foregroundStyle(Theme.accentBlue(for: nightMode))
                    }
                    .buttonStyle(.plain)
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Theme.textPrimary(for: nightMode).opacity(0.03))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Theme.accentBlue(for: nightMode).opacity(isInputFocused ? 0.2 : 0.08), lineWidth: 1)
            )
            .animation(.easeInOut(duration: 0.25), value: question.isEmpty)
            
            // Response area
            if let resp = response {
                VStack(alignment: .leading, spacing: 12) {
                    // Reassurance
                    Text(resp.reassurance)
                        .font(.subheadline)
                        .foregroundStyle(Theme.textPrimary(for: nightMode))
                        .fixedSize(horizontal: false, vertical: true)
                    
                    // Activity suggestions
                    if !resp.activities.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Gentle ideas to try:")
                                .font(.caption.weight(.medium))
                                .foregroundStyle(Theme.accentBlue(for: nightMode))
                            
                            ForEach(resp.activities, id: \.self) { activity in
                                HStack(alignment: .top, spacing: 8) {
                                    Text("•")
                                        .font(.caption)
                                        .foregroundStyle(Theme.growthGreen(for: nightMode))
                                    Text(activity)
                                        .font(.caption)
                                        .foregroundStyle(Theme.textSecondary(for: nightMode))
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                        }
                    }
                    
                    // Pediatric note (when appropriate)
                    if let pediatric = resp.pediatricNote {
                        Text(pediatric)
                            .font(.caption2)
                            .foregroundStyle(Theme.textSecondary(for: nightMode).opacity(0.8))
                            .padding(.top, 4)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Theme.growthGreen(for: nightMode).opacity(nightMode ? 0.06 : 0.05))
                )
                .opacity(responseOpacity)
                .animation(.easeInOut(duration: 0.4), value: responseOpacity)
            }
        }
        .warmCard(nightMode: nightMode)
    }
    
    // MARK: - Response Generation
    
    private func generateResponse() {
        let q = question.lowercased()
        let resp = AssistantEngine.generateResponse(
            question: q,
            correctedAge: correctedAge,
            milestones: milestones
        )
        
        responseOpacity = 0
        response = resp
        
        withAnimation(.easeInOut(duration: 0.4)) {
            responseOpacity = 1
        }
    }
}

// MARK: - Assistant Response Model

struct AssistantResponse {
    let reassurance: String
    let activities: [String]
    let pediatricNote: String?
}

// MARK: - Rule-Based Response Engine

/// On-device response engine using keyword matching + domain context.
/// Randomizes phrasing and branches by age.
enum AssistantEngine {
    
    static func generateResponse(
        question: String,
        correctedAge: Int,
        milestones: [Milestone]
    ) -> AssistantResponse {
        
        // 1. Detect domain from keywords
        let domain = detectDomain(from: question)
        
        // 2. Check completions for that domain
        let domainMilestones = milestones.filter {
            $0.category == (domain?.rawValue ?? "") && $0.ageMonth <= correctedAge + 2
        }
        let total = domainMilestones.count
        let completed = domainMilestones.filter(\.isCompleted).count
        _ = total - completed
        
        // 3. Determine concern level
        // If unobserved > 50% of age-appropriate milestones, higher concern
        let isConcern = total > 0 && (Double(completed) / Double(total) < 0.5)
        
        // 4. Generate response
        switch domain {
        case .grossMotor:
            return grossMotorResponse(age: correctedAge, isConcern: isConcern)
        case .fineMotor:
            return fineMotorResponse(age: correctedAge, isConcern: isConcern)
        case .language:
            return languageResponse(age: correctedAge, isConcern: isConcern)
        case .cognitive:
            return cognitiveResponse(age: correctedAge, isConcern: isConcern)
        case .socialEmotional:
            return socialEmotionalResponse(age: correctedAge, isConcern: isConcern)
        case .none:
            return generalResponse(age: correctedAge)
        }
    }
    
    // MARK: - Domain Detection
    
    private static func detectDomain(from question: String) -> MilestoneCategory? {
        let q = question.lowercased()
        
        if q.contains("walk") || q.contains("crawl") || q.contains("stand") || q.contains("run")
            || q.contains("sit") || q.contains("roll") || q.contains("step") || q.contains("climb")
            || q.contains("jump") || q.contains("move") || q.contains("motor") {
            return .grossMotor
        }
        if q.contains("grab") || q.contains("pinch") || q.contains("stack") || q.contains("draw")
            || q.contains("write") || q.contains("scissor") || q.contains("hand") || q.contains("finger")
            || q.contains("hold") || q.contains("spoon") || q.contains("fork") {
            return .fineMotor
        }
        if q.contains("talk") || q.contains("speak") || q.contains("word") || q.contains("babbl")
            || q.contains("speech") || q.contains("language") || q.contains("say") || q.contains("sound")
            || q.contains("sentence") || q.contains("name") || q.contains("point") || q.contains("quiet") {
            return .language
        }
        if q.contains("think") || q.contains("learn") || q.contains("puzzle") || q.contains("count")
            || q.contains("color") || q.contains("shape") || q.contains("pretend") || q.contains("play")
            || q.contains("understand") || q.contains("know") || q.contains("memory") {
            return .cognitive
        }
        if q.contains("social") || q.contains("friend") || q.contains("emotion") || q.contains("cry")
            || q.contains("tantrum") || q.contains("share") || q.contains("anxious") || q.contains("scared")
            || q.contains("behav") || q.contains("aggressive") || q.contains("hit") || q.contains("shy") {
            return .socialEmotional
        }
        
        return nil
    }
    
    // MARK: - Domain Responses
    
    private static func grossMotorResponse(age: Int, isConcern: Bool) -> AssistantResponse {
        var reassurances: [String] = []
        var activities: [String] = []
        
        if age < 12 {
            reassurances = [
                "Early movement milestones like rolling and sitting often happen in bursts. Your little one is building core strength every time they wiggle.",
                "Babies develop mobility on their own unique timeline. Some are keen observers before they become movers.",
                "It's completely normal for infants to focus on other skills like babbling before mastering crawling or walking."
            ]
            activities = [
                "Tummy time is still the best way to build core strength",
                "Place vivid toys just out of reach to encourage reaching and scooting",
                "Let them practice sitting with support from pillows"
            ]
        } else if age < 24 {
            reassurances = [
                "Walking typically emerges between 9 and 18 months—a huge window of 'normal'. Your child is likely building the confidence they need.",
                "Toddlers are learning balance, coordination, and courage all at once. Wobbly steps are a beautiful part of the process.",
                "Gross motor skills at this age are all about exploration. Even climbing on cushions counts as practice."
            ]
            activities = [
                "Create safe obstacle courses with cushions and blankets",
                "Practice walking while holding a toy (it distracts from the wobble!)",
                "Push-toys or sturdy boxes can give great walking support"
            ]
        } else {
            reassurances = [
                "Active play looks different for every child. Some are climbers, some are runners, and some are careful observers.",
                "Coordination keeps refining well into the school years. Running, jumping, and balancing are complex skills.",
                "Building strength happens naturally through play. As long as they are moving, they are learning."
            ]
            activities = [
                "Visit a playground to practice climbing and sliding",
                "Play 'STOP and GO' games to practice body control",
                "Kick a ball back and forth to build balance"
            ]
        }
        
        return AssistantResponse(
            reassurance: reassurances.randomElement()!,
            activities: activities.shuffled().prefix(3).map { $0 },
            pediatricNote: isConcern ? "Since you're noticing some delays in movement, a quick chat with your pediatrician can offer peace of mind and specific guidance. 💛" : nil
        )
    }
    
    private static func fineMotorResponse(age: Int, isConcern: Bool) -> AssistantResponse {
        let reassurances = [
            "Fine motor skills develop as hand muscles grow stronger. It's intricate work for little hands!",
            "From grasping to drawing, hand coordination takes patience. Every attempt is brain-building.",
            "Using hands to explore is how children learn about the physical world. Messy play is great practice."
        ]
        
        var activities: [String] = []
        if age < 18 {
             activities = [
                "Offer finger foods to practice the pincer grasp",
                "Let them bang blocks together or stack cups",
                "Poke holes in playdough with fingers"
            ]
        } else {
             activities = [
                "Stringing large beads or pasta",
                "Using tongs to pick up cotton balls",
                "Scribbling with chunky crayons"
            ]
        }
        
        return AssistantResponse(
            reassurance: reassurances.randomElement()!,
            activities: activities.shuffled().prefix(3).map { $0 },
            pediatricNote: isConcern ? "Fine motor skills can sometimes benefit from simple occupational therapy tips—your pediatrician can let you know if that's helpful. 💛" : nil
        )
    }
    
    private static func languageResponse(age: Int, isConcern: Bool) -> AssistantResponse {
        var reassurances: [String] = []
        var pediatric: String? = nil
        
        if age < 18 {
            reassurances = [
                "Language starts with understanding. If they are looking when you point or responding to their name, they are communicating!",
                "Babbling, gestures, and pointing are all 'pre-words'. They count just as much as spoken words right now.",
                "Some children focus on motor skills first, then have a 'language explosion' later. It's a common pattern."
            ]
            if isConcern {
                pediatric = "If they aren't babbling or gesturing yet, a hearing screening is a routine first step your pediatrician might suggest. 💛"
            }
        } else {
            reassurances = [
                "Vocabulary grows at different rates. Combining words and following instructions are big steps, even with fewer spoken words.",
                "Clarity of speech takes years to refine. What matters most now is the attempt to connect.",
                "You are their best interpreter. Your back-and-forth conversations are building their brain pathways."
            ]
            if isConcern {
                pediatric = "Since language is so key to connection, sharing your observations with your pediatrician is a great idea. Early speech checks are supportive and common. 💛"
            }
        }
        
        let activities = [
            "Narrate your day—'I'm washing the apple, now I'm drying it'",
            "Read rhyming books to help them hear the sounds of language",
            "Pause after asking a question to give them space to respond",
            "Sing songs with hand motions like 'Itsy Bitsy Spider'"
        ]
        
        return AssistantResponse(
            reassurance: reassurances.randomElement()!,
            activities: activities.shuffled().prefix(3).map { $0 },
            pediatricNote: pediatric
        )
    }
    
    private static func cognitiveResponse(age: Int, isConcern: Bool) -> AssistantResponse {
        let reassurances = [
            "Cognitive growth is often hidden. Curiosity, memory, and problem-solving are happening even during quiet play.",
            "Children learn by testing. Dropping, banging, and hiding things are all scientific experiments to them.",
            "Understanding how the world works is a huge job. Your child is building a map of their world every day."
        ]
        
        let activities = [
            "Play Peek-a-Boo to teach object permanence",
            "Hide a toy under a blanket and let them find it",
            "Sort toys by color or shape together",
            "Read books with simple stories and ask 'what happens next?'"
        ]
        
        return AssistantResponse(
            reassurance: reassurances.randomElement()!,
            activities: activities.shuffled().prefix(3).map { $0 },
            pediatricNote: isConcern ? "Your pediatrician can help assess cognitive development during well-child visits. It's always okay to ask. 💛" : nil
        )
    }
    
    private static func socialEmotionalResponse(age: Int, isConcern: Bool) -> AssistantResponse {
        var reassurances: [String] = []
        
        if age < 24 {
             reassurances = [
                "Big feelings are normal for little people. Their emotional brain is growing faster than their logical brain.",
                "Separation anxiety or stranger shyness are actually signs of strong, healthy attachment to you.",
                "Tantrums are often communication when words aren't enough. They aren't 'bad behavior'—they are distress."
            ]
        } else {
             reassurances = [
                "Learning to share and take turns is a long process. Parallel play (playing near others) is perfect for this age.",
                "Empathy is a complex skill. Modeling kindness is the best way to teach it over time.",
                "Testing boundaries is how children learn rules. It's exhausting but a normal sign of growing independence."
            ]
        }
        
        let activities = [
            "Name feelings: 'You look sad that the blocks fell'",
            "Practice taking turns rolling a ball",
            "Cuddle and read books about feelings",
            "Role-play with dolls or stuffed animals"
        ]
        
        return AssistantResponse(
            reassurance: reassurances.randomElement()!,
            activities: activities.shuffled().prefix(3).map { $0 },
            pediatricNote: isConcern ? "If certain behaviors are worrying you or happening often, your pediatrician is a wonderful partner to discuss strategies. 💛" : nil
        )
    }
    
    private static func generalResponse(age: Int) -> AssistantResponse {
        let reassurances = [
            "Every child grows at their own beautiful pace. You're doing a great job by simply paying attention.",
            "Development isn't a race. It's a journey with many scenic stops along the way.",
            "Trust your instincts. You know your child best, and your love is their most important fuel."
        ]
        
        let activities = [
            "Spend 10 minutes of uninterrupted floor time together",
            "Go for a walk and look for colors or sounds",
            "Read a favorite book together for the 100th time!",
            "Sing songs during transitions (like bath time or cleanup)"
        ]
            
        return AssistantResponse(
            reassurance: reassurances.randomElement()!,
            activities: activities.shuffled().prefix(3).map { $0 },
            pediatricNote: "Your pediatrician is always there for any questions, big or small. Well-child visits are perfect for these conversations. 💛"
        )
    }
}

import Foundation

/// When something (an achievement or a button style) becomes available.
/// Everything is derived from the two persisted numbers, so no extra data is stored.
enum UnlockRule: Equatable {
    case always
    case bestRun(Int)
    case totalPresses(Int)

    func isMet(by stats: PressStats) -> Bool {
        switch self {
        case .always: return true
        case .bestRun(let target): return stats.personalBest >= target
        case .totalPresses(let target): return stats.totalPresses >= target
        }
    }

    /// (current, target) for locked-item progress, nil when there is nothing to track.
    func progress(for stats: PressStats) -> (current: Int, target: Int)? {
        switch self {
        case .always: return nil
        case .bestRun(let target): return (min(stats.personalBest, target), target)
        case .totalPresses(let target): return (min(stats.totalPresses, target), target)
        }
    }

    var requirementText: String {
        switch self {
        case .always: return "Included"
        case .bestRun(let target): return "Reach a run of \(target.formatted())"
        case .totalPresses(let target): return "Press \(target.formatted()) times in total"
        }
    }
}

struct Achievement: Equatable, Identifiable {
    let id: String
    let title: String
    let detail: String
    let rule: UnlockRule

    static let all: [Achievement] = [
        Achievement(id: "first-press", title: "Weak Moment", detail: "Press the button once.", rule: .totalPresses(1)),
        Achievement(id: "run-10", title: "Double Digits", detail: "Reach a run of 10.", rule: .bestRun(10)),
        Achievement(id: "run-25", title: "Not An Accident", detail: "Reach a run of 25.", rule: .bestRun(25)),
        Achievement(id: "run-50", title: "Fifty Warnings", detail: "Reach a run of 50.", rule: .bestRun(50)),
        Achievement(id: "run-100", title: "Triple Digits", detail: "Reach a run of 100.", rule: .bestRun(100)),
        Achievement(id: "run-250", title: "Committed", detail: "Reach a run of 250.", rule: .bestRun(250)),
        Achievement(id: "run-500", title: "Beyond Reason", detail: "Reach a run of 500.", rule: .bestRun(500)),
        Achievement(id: "run-1000", title: "The Button Knows Your Name", detail: "Reach a run of 1,000.", rule: .bestRun(1000)),
        Achievement(id: "total-100", title: "Habit Forming", detail: "Press 100 times in total.", rule: .totalPresses(100)),
        Achievement(id: "total-500", title: "Regular", detail: "Press 500 times in total.", rule: .totalPresses(500)),
        Achievement(id: "total-2500", title: "Landmark", detail: "Press 2,500 times in total.", rule: .totalPresses(2500)),
        Achievement(id: "total-10000", title: "Unreasonable", detail: "Press 10,000 times in total.", rule: .totalPresses(10_000)),
    ]

    /// Achievements that this change of stats unlocked (each fires exactly once).
    static func newlyUnlocked(before: PressStats, after: PressStats) -> [Achievement] {
        all.filter { $0.rule.isMet(by: after) && !$0.rule.isMet(by: before) }
    }
}

struct AchievementStatus: Identifiable, Equatable {
    let achievement: Achievement
    let isUnlocked: Bool
    let progress: (current: Int, target: Int)?

    var id: String { achievement.id }

    static func == (lhs: AchievementStatus, rhs: AchievementStatus) -> Bool {
        lhs.achievement == rhs.achievement && lhs.isUnlocked == rhs.isUnlocked
            && lhs.progress?.current == rhs.progress?.current && lhs.progress?.target == rhs.progress?.target
    }

    static func statuses(for stats: PressStats) -> [AchievementStatus] {
        Achievement.all.map {
            let unlocked = $0.rule.isMet(by: stats)
            return AchievementStatus(achievement: $0, isUnlocked: unlocked, progress: unlocked ? nil : $0.rule.progress(for: stats))
        }
    }
}

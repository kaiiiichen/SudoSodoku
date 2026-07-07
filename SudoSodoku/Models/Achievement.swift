import Foundation

/// The twelve achievements of v2.0 — all binary unlocks, no progress bars.
enum Achievement: String, CaseIterable, Identifiable {
    case helloWorld = "hello_world"
    case uptime10 = "uptime_10"
    case uptime50 = "uptime_50"
    case uptime100 = "uptime_100"
    case rootPrivileges = "root_privileges"
    case cleanCommit = "clean_commit"
    case overclocked = "overclocked"
    case rankSudoer = "rank_sudoer"
    case rankSysAdmin = "rank_sysadmin"
    case rankKernelHacker = "rank_kernel_hacker"
    case rankArchitect = "rank_architect"
    case incidentReported = "incident_reported"

    var id: String { rawValue }

    var gameCenterID: String { "\(AppConstants.achievementPrefix).\(rawValue)" }

    var title: String {
        switch self {
        case .helloWorld: return "HELLO_WORLD"
        case .uptime10: return "UPTIME_10"
        case .uptime50: return "UPTIME_50"
        case .uptime100: return "UPTIME_100"
        case .rootPrivileges: return "ROOT_PRIVILEGES"
        case .cleanCommit: return "CLEAN_COMMIT"
        case .overclocked: return "OVERCLOCKED"
        case .rankSudoer: return "RANK: SUDOER"
        case .rankSysAdmin: return "RANK: SYS_ADMIN"
        case .rankKernelHacker: return "RANK: KERNEL_HACKER"
        case .rankArchitect: return "THE_ARCHITECT"
        case .incidentReported: return "INCIDENT_REPORTED"
        }
    }

    var detail: String {
        switch self {
        case .helloWorld: return "First grid breached."
        case .uptime10: return "10 systems compromised."
        case .uptime50: return "50 systems compromised."
        case .uptime100: return "100 systems compromised."
        case .rootPrivileges: return "First MASTER grid cracked."
        case .cleanCommit: return "Solved with zero undos."
        case .overclocked: return "Solved in under 3 minutes."
        case .rankSudoer: return "ELO 1400 reached."
        case .rankSysAdmin: return "ELO 1600 reached."
        case .rankKernelHacker: return "ELO 1800 reached."
        case .rankArchitect: return "Top of the ladder. ELO 2000."
        case .incidentReported: return "You were not in the sudoers file."
        }
    }

    /// Secret achievements show masked details until unlocked.
    var isSecret: Bool { self == .incidentReported }
}

/// Everything a victory needs to be judged against the achievement list.
struct VictoryContext {
    let difficulty: Difficulty
    let undoCount: Int
    let playDuration: TimeInterval
    let newRating: Int
    let totalSolved: Int
}

extension Achievement {
    /// Pure evaluation: which achievements does this victory satisfy?
    /// (Deduplication against already-unlocked ones happens in the manager.)
    static func satisfied(by context: VictoryContext) -> [Achievement] {
        var earned: [Achievement] = []

        if context.totalSolved >= 1 { earned.append(.helloWorld) }
        if context.totalSolved >= 10 { earned.append(.uptime10) }
        if context.totalSolved >= 50 { earned.append(.uptime50) }
        if context.totalSolved >= 100 { earned.append(.uptime100) }

        if context.difficulty == .master { earned.append(.rootPrivileges) }
        if context.undoCount == 0 { earned.append(.cleanCommit) }
        if context.playDuration > 0 && context.playDuration < 180 { earned.append(.overclocked) }

        if context.newRating >= 1400 { earned.append(.rankSudoer) }
        if context.newRating >= 1600 { earned.append(.rankSysAdmin) }
        if context.newRating >= 1800 { earned.append(.rankKernelHacker) }
        if context.newRating >= 2000 { earned.append(.rankArchitect) }

        return earned
    }
}

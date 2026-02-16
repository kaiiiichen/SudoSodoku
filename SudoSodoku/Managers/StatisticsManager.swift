import Foundation
import SwiftUI
import Combine

class StatisticsManager: ObservableObject {
    static let shared = StatisticsManager()
    
    // MARK: - Published Properties
    @Published var personalBests: [Difficulty: GameRecord] = [:]
    @Published var overallStats: OverallStats = OverallStats(
        totalGames: 0,
        solvedGames: 0,
        totalUndos: 0,
        bestLogicalEfficiency: 0
    )
    
    init() {
        refreshData()
    }
    
    // MARK: - Data Refresh
    
    func refreshData() {
        personalBests = getAllDifficultyBests()
        overallStats = getOverallStats()
    }
    
    // MARK: - Personal Best Records
    
    /// Get personal best records for specified difficulty (sorted by logical efficiency)
    func getPersonalBests(for difficulty: Difficulty, limit: Int = 10) -> [GameRecord] {
        let records = StorageManager.shared.records
            .filter { $0.difficulty == difficulty.rawValue && $0.isSolved }
            .sorted { first, second in
                first.logicalEfficiency > second.logicalEfficiency
            }
        
        return Array(records.prefix(limit))
    }
    
    /// Get best logical efficiency record for specified difficulty
    func getBestLogicalEfficiency(for difficulty: Difficulty) -> GameRecord? {
        return StorageManager.shared.records
            .filter { $0.difficulty == difficulty.rawValue && $0.isSolved }
            .max { $0.logicalEfficiency < $1.logicalEfficiency }
    }
    
    /// Get overview of best records for all difficulties
    func getAllDifficultyBests() -> [Difficulty: GameRecord] {
        var bests: [Difficulty: GameRecord] = [:]
        
        for difficulty in Difficulty.allCases {
            if let best = getPersonalBests(for: difficulty, limit: 1).first {
                bests[difficulty] = best
            }
        }
        
        return bests
    }
    
    // MARK: - Statistics & Analytics
    
    /// Get overall statistics data
    func getOverallStats() -> OverallStats {
        let records = StorageManager.shared.records
        let solvedRecords = records.filter { $0.isSolved }
        
        return OverallStats(
            totalGames: records.count,
            solvedGames: solvedRecords.count,
            totalUndos: solvedRecords.reduce(0) { $0 + $1.undoCount },
            bestLogicalEfficiency: solvedRecords.max { $0.logicalEfficiency < $1.logicalEfficiency }?.logicalEfficiency ?? 0
        )
    }
    
    /// Get difficulty distribution statistics
    func getDifficultyDistribution() -> [Difficulty: Int] {
        var distribution: [Difficulty: Int] = [:]
        
        for difficulty in Difficulty.allCases {
            let count = StorageManager.shared.records
                .filter { $0.difficulty == difficulty.rawValue && $0.isSolved }
                .count
            distribution[difficulty] = count
        }
        
        return distribution
    }
    
    /// Get recent completion records
    func getRecentCompletions(limit: Int = 20) -> [GameRecord] {
        return StorageManager.shared.records
            .filter { $0.isSolved }
            .sorted { $0.lastPlayedTime > $1.lastPlayedTime }
            .prefix(limit)
            .map { $0 }
    }
    
    /// Get progress trend data (for chart display)
    func getProgressTrend(days: Int = 30) -> [ProgressDataPoint] {
        let calendar = Calendar.current
        let endDate = Date()
        let startDate = calendar.date(byAdding: .day, value: -days, to: endDate) ?? endDate
        
        var dataPoints: [ProgressDataPoint] = []
        var currentDate = startDate
        
        while currentDate <= endDate {
            let dayRecords = StorageManager.shared.records.filter { record in
                calendar.isDate(record.lastPlayedTime, inSameDayAs: currentDate)
            }
            
            let solvedCount = dayRecords.filter { $0.isSolved }.count
            let avgEfficiency = dayRecords.filter { $0.isSolved }
                .reduce(0.0) { $0 + Double($1.logicalEfficiency) } / Double(max(solvedCount, 1))
            
            dataPoints.append(ProgressDataPoint(
                date: currentDate,
                gamesPlayed: dayRecords.count,
                gamesSolved: solvedCount,
                averageEfficiency: solvedCount > 0 ? avgEfficiency : nil
            ))
            
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }
        
        return dataPoints
    }
    
    // MARK: - Helper Methods
}

// MARK: - Data Structures

struct OverallStats {
    let totalGames: Int
    let solvedGames: Int
    let totalUndos: Int
    let bestLogicalEfficiency: Int
    
    var winRate: Double {
        guard totalGames > 0 else { return 0 }
        return Double(solvedGames) / Double(totalGames)
    }
    
    var averageUndosPerGame: Double {
        guard solvedGames > 0 else { return 0 }
        return Double(totalUndos) / Double(solvedGames)
    }
}

struct ProgressDataPoint {
    let date: Date
    let gamesPlayed: Int
    let gamesSolved: Int
    let averageEfficiency: Double?
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd"
        return formatter.string(from: date)
    }
    
    var formattedAverageEfficiency: String {
        guard let efficiency = averageEfficiency else { return "--" }
        return String(format: "%.0f", efficiency)
    }
}

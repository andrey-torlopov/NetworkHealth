import Foundation

// MARK: - History API

public extension NetworkHealthCoordinator {

    /// Returns recent snapshots from history
    /// - Parameter limit: Maximum number of snapshots to return (default: 50)
    /// - Returns: Array of snapshots, sorted by timestamp (newest first)
    func recentSnapshots(limit: Int = 50) async -> [NetworkQualitySnapshot] {
        await measurementHistory.getSnapshots(limit: limit)
    }

    /// Returns snapshots within a date range
    /// - Parameters:
    ///   - from: Start date (inclusive)
    ///   - to: End date (inclusive)
    /// - Returns: Array of snapshots within the date range
    func snapshots(from: Date, to: Date) async -> [NetworkQualitySnapshot] {
        await measurementHistory.getSnapshots(from: from, to: to)
    }

    /// Returns aggregated statistics for a date range
    /// - Parameters:
    ///   - from: Start date
    ///   - to: End date
    /// - Returns: Network statistics for the period
    func statistics(from: Date, to: Date) async -> NetworkStatistics {
        await measurementHistory.getStatistics(from: from, to: to)
    }

    /// Returns the total number of snapshots in history
    func historyCount() async -> Int {
        await measurementHistory.count()
    }

    /// Clears all measurement history
    func clearHistory() async {
        await measurementHistory.clear()
    }
}

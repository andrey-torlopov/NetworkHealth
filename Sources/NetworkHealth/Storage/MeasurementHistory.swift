import Foundation

/// In-memory storage for network quality snapshots with automatic cleanup
public actor MeasurementHistory {

    // MARK: - Configuration

    public struct Configuration: Sendable {
        /// Maximum number of snapshots to keep in memory
        public let maxSize: Int

        /// Maximum age of snapshots to keep (in seconds)
        public let maxAge: TimeInterval

        /// Whether to store detailed metrics (bytes, durations)
        public let storeDetailedMetrics: Bool

        public init(
            maxSize: Int = 500,
            maxAge: TimeInterval = 7 * 24 * 60 * 60, // 7 days
            storeDetailedMetrics: Bool = true
        ) {
            self.maxSize = max(1, maxSize)
            self.maxAge = max(60, maxAge) // At least 1 minute
            self.storeDetailedMetrics = storeDetailedMetrics
        }
    }

    // MARK: - Properties

    private let configuration: Configuration
    private let dateProvider: () -> Date
    private var snapshots: [NetworkQualitySnapshot] = []

    // MARK: - Initialization

    public init(
        configuration: Configuration = Configuration(),
        dateProvider: @escaping () -> Date = Date.init
    ) {
        self.configuration = configuration
        self.dateProvider = dateProvider
    }

    // MARK: - Public API

    /// Adds a snapshot to the history
    func add(_ snapshot: NetworkQualitySnapshot) {
        let processedSnapshot = configuration.storeDetailedMetrics
            ? snapshot
            : snapshot.withoutDetailedMetrics()

        snapshots.append(processedSnapshot)

        // Cleanup old and excess snapshots
        cleanup()
    }

    /// Returns all snapshots, optionally filtered by date range
    func getSnapshots(
        from startDate: Date? = nil,
        to endDate: Date? = nil,
        limit: Int? = nil
    ) -> [NetworkQualitySnapshot] {
        var filtered = snapshots

        // Filter by date range
        if let startDate = startDate {
            filtered = filtered.filter { $0.timestamp >= startDate }
        }

        if let endDate = endDate {
            filtered = filtered.filter { $0.timestamp <= endDate }
        }

        // Sort by timestamp (newest first)
        filtered.sort { $0.timestamp > $1.timestamp }

        // Apply limit
        if let limit = limit {
            filtered = Array(filtered.prefix(limit))
        }

        return filtered
    }

    /// Returns the most recent snapshot
    func getLatest() -> NetworkQualitySnapshot? {
        snapshots.max(by: { $0.timestamp < $1.timestamp })
    }

    /// Returns statistics for the specified date range
    func getStatistics(
        from startDate: Date,
        to endDate: Date
    ) -> NetworkStatistics {
        let filtered = getSnapshots(from: startDate, to: endDate)
        let period = DateInterval(start: startDate, end: endDate)
        return NetworkStatistics.from(snapshots: filtered, period: period)
    }

    /// Returns the total number of snapshots stored
    func count() -> Int {
        snapshots.count
    }

    /// Clears all snapshots
    func clear() {
        snapshots.removeAll()
    }

    // MARK: - Private Helpers

    private func cleanup() {
        let now = dateProvider()
        let cutoffDate = now.addingTimeInterval(-configuration.maxAge)

        // Remove snapshots older than maxAge
        snapshots.removeAll { $0.timestamp < cutoffDate }

        // If still over limit, remove oldest snapshots
        if snapshots.count > configuration.maxSize {
            // Sort by timestamp (oldest first)
            snapshots.sort { $0.timestamp < $1.timestamp }

            // Remove excess
            let excessCount = snapshots.count - configuration.maxSize
            snapshots.removeFirst(excessCount)
        }
    }
}

// MARK: - Snapshot Extensions

private extension NetworkQualitySnapshot {
    /// Returns a copy of the snapshot without detailed metrics
    func withoutDetailedMetrics() -> NetworkQualitySnapshot {
        NetworkQualitySnapshot(
            id: id,
            timestamp: timestamp,
            connectionType: connectionType,
            isExpensive: isExpensive,
            quality: quality,
            latency: latency,
            downloadSpeedMbps: downloadSpeedMbps,
            uploadSpeedMbps: uploadSpeedMbps,
            bytesDownloaded: nil,
            bytesUploaded: nil,
            downloadDuration: nil,
            uploadDuration: nil
        )
    }
}

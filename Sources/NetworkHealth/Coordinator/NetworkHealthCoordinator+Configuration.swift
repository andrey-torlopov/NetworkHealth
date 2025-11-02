import Foundation

// MARK: - Configuration

public extension NetworkHealthCoordinator {
    /// Configuration for NetworkQualityChecker
    struct Configuration: Sendable {
        /// Optional speed tester for active measurements
        public let speedTester: (any SpeedTester)?

        /// Minimum interval between speed checks (in seconds)
        public let minimumSpeedCheckInterval: TimeInterval

        /// Latency threshold (in milliseconds) after which a connection is considered poor
        public let poorLatencyThreshold: Double

        /// Configuration for measurement history storage
        public let historyConfiguration: MeasurementHistory.Configuration

        /// Whether to automatically store snapshots to history
        public let autoStoreSnapshots: Bool

        public init(
            speedTester: (any SpeedTester)? = nil,
            minimumSpeedCheckInterval: TimeInterval = 120,
            poorLatencyThreshold: Double = 1500,
            historyConfiguration: MeasurementHistory.Configuration = .init(),
            autoStoreSnapshots: Bool = true
        ) {
            self.speedTester = speedTester
            self.minimumSpeedCheckInterval = max(1, minimumSpeedCheckInterval)
            self.poorLatencyThreshold = max(100, poorLatencyThreshold)
            self.historyConfiguration = historyConfiguration
            self.autoStoreSnapshots = autoStoreSnapshots
        }
    }
}

// MARK: - State

public extension NetworkHealthCoordinator {
    /// Current state of network quality
    struct State: Equatable, Sendable {
        /// Type of network connection
        public let connectionType: ConnectionRawData

        /// Assessed network quality
        public let quality: NetworkQuality

        /// Whether the connection is expensive (e.g., cellular with limited data)
        public let isExpensive: Bool

        public init(
            connectionType: ConnectionRawData,
            quality: NetworkQuality,
            isExpensive: Bool
        ) {
            self.connectionType = connectionType
            self.quality = quality
            self.isExpensive = isExpensive
        }
    }
}

// MARK: - DateProvider

/// Type alias for dependency injection of date provider
public typealias DateProvider = @Sendable () -> Date

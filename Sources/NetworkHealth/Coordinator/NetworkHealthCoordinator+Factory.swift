import Foundation

// MARK: - Factory Methods

public extension NetworkHealthCoordinator {

    /// Creates a basic network quality checker without speed testing
    /// - Returns: NetworkHealthCoordinator configured for connection type monitoring only
    static func basic() -> NetworkHealthCoordinator {
        NetworkHealthCoordinator()
    }

    /// Creates a network quality checker with custom configuration
    /// - Parameters:
    ///   - speedTester: Custom speed tester implementation
    ///   - interval: Minimum interval between speed tests in seconds (default: 120)
    ///   - historyMaxSize: Maximum number of snapshots to keep (default: 500)
    ///   - historyMaxAge: Maximum age of snapshots in seconds (default: 7 days)
    ///   - autoStoreSnapshots: Whether to automatically store snapshots (default: true)
    /// - Returns: NetworkHealthCoordinator with custom configuration
    static func custom(
        speedTester: (any SpeedTester)?,
        interval: TimeInterval = 120,
        historyMaxSize: Int = 500,
        historyMaxAge: TimeInterval = 7 * 24 * 60 * 60,
        autoStoreSnapshots: Bool = true
    ) -> NetworkHealthCoordinator {
        let historyConfig = MeasurementHistory.Configuration(
            maxSize: historyMaxSize,
            maxAge: historyMaxAge,
            storeDetailedMetrics: true
        )

        let configuration = Configuration(
            speedTester: speedTester,
            minimumSpeedCheckInterval: interval,
            historyConfiguration: historyConfig,
            autoStoreSnapshots: autoStoreSnapshots
        )

        return NetworkHealthCoordinator(configuration: configuration)
    }
}

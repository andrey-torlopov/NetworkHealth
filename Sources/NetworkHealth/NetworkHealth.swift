 import Foundation

/// Simplified facade for network quality monitoring.
/// Provides three main usage patterns:
/// 1. Stream - continuous monitoring via AsyncStream
/// 2. Snapshot - one-time quality check
/// 3. Observable - SwiftUI/UIKit friendly monitoring
///
/// Example usage:
/// ```swift
/// // Stream mode
/// for await state in NetworkHealth.stream() {
///     print("Quality: \(state.quality)")
/// }
///
/// // Snapshot mode
/// let snapshot = await NetworkHealth.snapshot()
/// print("Current quality: \(snapshot.quality)")
///
/// // Observable mode (SwiftUI)
/// @State private var health = NetworkHealth.observable()
/// ```
public enum NetworkHealth {

    // MARK: - Stream Mode (Continuous Monitoring)

    /// Creates an AsyncStream that continuously monitors network quality.
    /// This is the simplest way to track network changes in real-time.
    ///
    /// **Note:** Stream mode monitors connection type changes (WiFi, LTE, 5G, etc.) and determines
    /// quality based on the connection type. Speed measurements are performed internally when a speed
    /// tester is provided, but are NOT directly exposed in the stream. Use `detailedSnapshot()` for
    /// one-time measurements with explicit speed metrics, or `observable()` with `performMeasurement()`
    /// to get speed test results.
    ///
    /// - Parameters:
    ///   - speedTester: Optional speed tester implementation (default: nil, no speed tests)
    ///   - speedTestInterval: Minimum interval between speed tests in seconds (default: 120)
    /// - Returns: AsyncStream that yields network state updates
    ///
    /// Example:
    /// ```swift
    /// // Basic monitoring (connection type and quality based on type)
    /// for await state in NetworkHealth.stream() {
    ///     print("Quality: \(state.quality)")
    ///     print("Connection: \(state.connectionType)")
    ///     print("Is expensive: \(state.isExpensive)")
    /// }
    ///
    /// // With speed testing (improves quality accuracy internally)
    /// let myTester = MyCustomSpeedTester()
    /// for await state in NetworkHealth.stream(
    ///     speedTester: myTester,
    ///     speedTestInterval: 60
    /// ) {
    ///     // Quality now considers actual speed measurements
    ///     print("Quality: \(state.quality)")
    ///
    ///     // Note: Speed metrics are not available in stream mode.
    ///     // Use detailedSnapshot() or observable().performMeasurement() for explicit metrics.
    /// }
    /// ```
    public static func stream(
        speedTester: (any SpeedTester)? = nil,
        speedTestInterval: TimeInterval = 120
    ) -> AsyncStream<NetworkHealthState> {
        let checker = createChecker(
            speedTester: speedTester,
            speedTestInterval: speedTestInterval
        )

        return AsyncStream { continuation in
            let task = Task {
                for await state in await checker.stateStream() {
                    let healthState = NetworkHealthState(from: state, checker: checker)
                    continuation.yield(healthState)
                }
            }

            continuation.onTermination = { _ in
                task.cancel()
                Task {
                    await checker.stopMonitoring()
                }
            }
        }
    }

    // MARK: - Snapshot Mode (One-Time Check)

    /// Performs a quick one-time check of current network quality.
    /// Returns immediately with current state based on system network path.
    /// Does not perform speed tests.
    ///
    /// Example:
    /// ```swift
    /// let snapshot = await NetworkHealth.snapshot()
    /// if snapshot.quality >= .good {
    ///     startDownload()
    /// }
    /// ```
    public static func snapshot() async -> NetworkHealthState {
        let checker = NetworkHealthCoordinator()

        // Give it a moment to get the first path update
        try? await Task.sleep(nanoseconds: 100_000_000) // 100ms

        let state = await checker.currentState()
        await checker.stopMonitoring()

        return NetworkHealthState(from: state, checker: nil)
    }

    /// Performs a detailed one-time check including speed test.
    /// This takes longer (several seconds) but provides accurate measurements.
    ///
    /// - Parameter speedTester: Speed tester implementation to use for measurements
    /// - Returns: Detailed snapshot with speed measurements
    /// - Throws: NetworkQualityError if measurement fails
    ///
    /// Example:
    /// ```swift
    /// do {
    ///     let myTester = MyCustomSpeedTester()
    ///     let detailed = try await NetworkHealth.detailedSnapshot(
    ///         speedTester: myTester
    ///     )
    ///     print("Latency: \(detailed.latency ?? 0)ms")
    ///     print("Download: \(detailed.downloadSpeedMbps ?? 0) Mbps")
    /// } catch {
    ///     print("Measurement failed: \(error)")
    /// }
    /// ```
    public static func detailedSnapshot(
        speedTester: any SpeedTester
    ) async throws -> NetworkQualitySnapshot {
        let checker = NetworkHealthCoordinator.custom(
            speedTester: speedTester,
            interval: 1
        )

        // Give it a moment to initialize
        try await Task.sleep(nanoseconds: 100_000_000) // 100ms

        let snapshot = try await checker.performDetailedMeasurement()
        await checker.stopMonitoring()

        return snapshot
    }

    // MARK: - Observable Mode (SwiftUI/UIKit)

    /// Creates an observable object for SwiftUI/UIKit integration.
    /// Use this when you need to bind network state to UI components.
    ///
    /// - Parameters:
    ///   - speedTester: Optional speed tester implementation (default: nil, no speed tests)
    ///   - speedTestInterval: Minimum interval between speed tests in seconds (default: 120)
    /// - Returns: Observable monitor instance
    ///
    /// Example:
    /// ```swift
    /// @State private var health = NetworkHealth.observable()
    ///
    /// var body: some View {
    ///     VStack {
    ///         Text("Quality: \(health.currentQuality.description)")
    ///         Text("Connection: \(health.connectionType.description)")
    ///     }
    /// }
    /// ```
    public static func observable(
        speedTester: (any SpeedTester)? = nil,
        speedTestInterval: TimeInterval = 120
    ) -> NetworkQualityMonitor {
        let checker = createChecker(
            speedTester: speedTester,
            speedTestInterval: speedTestInterval
        )
        return NetworkQualityMonitor(checker: checker)
    }

    // MARK: - Health Check Mode (Operation Requirements)

    /// Checks if current network quality meets requirements for a specific operation.
    ///
    /// - Parameter requirement: The operation requirement to check
    /// - Returns: Health check result with pass/fail status
    ///
    /// Example:
    /// ```swift
    /// let check = await NetworkHealth.check(requirement: .videoStreaming)
    /// if check.passed {
    ///     startVideoStream()
    /// } else {
    ///     showWarning(check.reason ?? "Network quality too low")
    /// }
    /// ```
    public static func check(requirement: OperationRequirement) async -> HealthCheckResult {
        let checker = NetworkHealthCoordinator()

        // Give it a moment to get the first path update
        try? await Task.sleep(nanoseconds: 100_000_000) // 100ms

        let state = await checker.currentState()
        await checker.stopMonitoring()

        return requirement.evaluate(state: state)
    }

    /// Checks if current network quality meets custom requirements.
    ///
    /// - Parameters:
    ///   - minimumQuality: Minimum acceptable quality level
    ///   - requireWiFi: Whether WiFi/Ethernet is required (default: false)
    ///   - allowExpensive: Whether expensive connections are allowed (default: true)
    /// - Returns: Health check result with pass/fail status
    ///
    /// Example:
    /// ```swift
    /// let check = await NetworkHealth.check(
    ///     minimumQuality: .good,
    ///     requireWiFi: true,
    ///     allowExpensive: false
    /// )
    /// if check.passed {
    ///     uploadLargeFile()
    /// }
    /// ```
    public static func check(
        minimumQuality: NetworkQuality,
        requireWiFi: Bool = false,
        allowExpensive: Bool = true
    ) async -> HealthCheckResult {
        let requirement = OperationRequirement.custom(
            minimumQuality: minimumQuality,
            requireWiFi: requireWiFi,
            allowExpensive: allowExpensive
        )
        return await check(requirement: requirement)
    }

    /// Quick check if network is good enough for a specific operation type.
    ///
    /// Example:
    /// ```swift
    /// if await NetworkHealth.isGoodEnoughFor(.videoStreaming) {
    ///     startVideo()
    /// }
    /// ```
    public static func isGoodEnoughFor(_ requirement: OperationRequirement) async -> Bool {
        let result = await check(requirement: requirement)
        return result.passed
    }

    // MARK: - Private Helpers

    private static func createChecker(
        speedTester: (any SpeedTester)?,
        speedTestInterval: TimeInterval
    ) -> NetworkHealthCoordinator {
        if let speedTester = speedTester {
            return NetworkHealthCoordinator.custom(
                speedTester: speedTester,
                interval: speedTestInterval
            )
        } else {
            return NetworkHealthCoordinator()
        }
    }
}

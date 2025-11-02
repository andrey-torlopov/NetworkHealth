 import Foundation
import Nevod

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
    /// - Parameters:
    ///   - includeSpeedTests: Whether to perform periodic speed tests (default: false)
    ///   - speedTestInterval: Minimum interval between speed tests in seconds (default: 120)
    ///   - networkProvider: Optional network provider for speed testing
    /// - Returns: AsyncStream that yields network state updates
    ///
    /// Example:
    /// ```swift
    /// // Basic monitoring (no speed tests)
    /// for await state in NetworkHealth.stream() {
    ///     print("Quality: \(state.quality)")
    ///     print("Connection: \(state.connectionType)")
    /// }
    ///
    /// // With speed testing
    /// for await state in NetworkHealth.stream(
    ///     includeSpeedTests: true,
    ///     speedTestInterval: 60
    /// ) {
    ///     if let speed = state.downloadSpeedMbps {
    ///         print("Download: \(speed) Mbps")
    ///     }
    /// }
    /// ```
    public static func stream(
        includeSpeedTests: Bool = false,
        speedTestInterval: TimeInterval = 120,
        networkProvider: NetworkProvider? = nil
    ) -> AsyncStream<NetworkHealthState> {
        let checker = createChecker(
            includeSpeedTests: includeSpeedTests,
            speedTestInterval: speedTestInterval,
            networkProvider: networkProvider
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
    /// - Parameter networkProvider: Network provider for speed testing
    /// - Returns: Detailed snapshot with speed measurements
    /// - Throws: NetworkQualityError if measurement fails
    ///
    /// Example:
    /// ```swift
    /// do {
    ///     let detailed = try await NetworkHealth.detailedSnapshot(
    ///         networkProvider: myProvider
    ///     )
    ///     print("Latency: \(detailed.latency ?? 0)ms")
    ///     print("Download: \(detailed.downloadSpeedMbps ?? 0) Mbps")
    /// } catch {
    ///     print("Measurement failed: \(error)")
    /// }
    /// ```
    public static func detailedSnapshot(
        networkProvider: NetworkProvider
    ) async throws -> NetworkQualitySnapshot {
        let checker = NetworkHealthCoordinator.withSpeedTest(
            testMode: .quick,
            interval: 1,
            networkProvider: networkProvider
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
    ///   - includeSpeedTests: Whether to perform periodic speed tests (default: false)
    ///   - speedTestInterval: Minimum interval between speed tests in seconds (default: 120)
    ///   - networkProvider: Optional network provider for speed testing
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
        includeSpeedTests: Bool = false,
        speedTestInterval: TimeInterval = 120,
        networkProvider: NetworkProvider? = nil
    ) -> NetworkQualityMonitor {
        let checker = createChecker(
            includeSpeedTests: includeSpeedTests,
            speedTestInterval: speedTestInterval,
            networkProvider: networkProvider
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
        includeSpeedTests: Bool,
        speedTestInterval: TimeInterval,
        networkProvider: NetworkProvider?
    ) -> NetworkHealthCoordinator {
        if includeSpeedTests, let networkProvider = networkProvider {
            return NetworkHealthCoordinator.withSpeedTest(
                testMode: .quick,
                interval: speedTestInterval,
                networkProvider: networkProvider
            )
        } else {
            return NetworkHealthCoordinator()
        }
    }
}

// MARK: - NetworkHealthState

/// Simplified state representation for NetworkHealth facade.
/// Combines connection info, quality, and optional measurements.
public struct NetworkHealthState: Sendable, Equatable {
    /// Type of network connection (WiFi, LTE, 5G, etc.)
    public let connectionType: ConnectionRawData

    /// Overall network quality assessment
    public let quality: NetworkQuality

    /// Whether the connection is expensive (e.g., cellular with limited data)
    public let isExpensive: Bool

    /// Round-trip time (latency) in milliseconds (if available)
    public let latency: Double?

    /// Download speed in megabits per second (if available)
    public let downloadSpeedMbps: Double?

    /// Upload speed in megabits per second (if available)
    public let uploadSpeedMbps: Double?

    /// Whether the device is currently online
    public var isOnline: Bool {
        quality != .offline
    }

    /// Whether the connection quality is good enough for heavy operations
    public var isGoodQuality: Bool {
        quality >= .good
    }

    /// Whether the connection is degraded (poor or moderate)
    public var isDegradedQuality: Bool {
        quality == .poor || quality == .moderate
    }

    internal init(from state: NetworkHealthCoordinator.State, checker: NetworkHealthCoordinator?) {
        self.connectionType = state.connectionType
        self.quality = state.quality
        self.isExpensive = state.isExpensive

        // These would need to be exposed from checker if we want them
        // For now, they're nil in basic streaming mode
        self.latency = nil
        self.downloadSpeedMbps = nil
        self.uploadSpeedMbps = nil
    }

    public init(
        connectionType: ConnectionRawData,
        quality: NetworkQuality,
        isExpensive: Bool,
        latency: Double? = nil,
        downloadSpeedMbps: Double? = nil,
        uploadSpeedMbps: Double? = nil
    ) {
        self.connectionType = connectionType
        self.quality = quality
        self.isExpensive = isExpensive
        self.latency = latency
        self.downloadSpeedMbps = downloadSpeedMbps
        self.uploadSpeedMbps = uploadSpeedMbps
    }
}

// MARK: - OperationRequirement

/// Predefined requirements for common operations.
public enum OperationRequirement {
    /// Web browsing, text messaging (Poor or better, any connection)
    case basicBrowsing

    /// Image loading, social media (Moderate or better, any connection)
    case imageLoading

    /// Video streaming, video calls (Good or better, any connection)
    case videoStreaming

    /// Large file downloads (Good or better, preferably WiFi)
    case largeDownload

    /// Large file uploads (Good or better, WiFi required)
    case largeUpload

    /// Custom requirements
    case custom(minimumQuality: NetworkQuality, requireWiFi: Bool, allowExpensive: Bool)

    internal func evaluate(state: NetworkHealthCoordinator.State) -> HealthCheckResult {
        switch self {
        case .basicBrowsing:
            return evaluateBasicBrowsing(state: state)
        case .imageLoading:
            return evaluateImageLoading(state: state)
        case .videoStreaming:
            return evaluateVideoStreaming(state: state)
        case .largeDownload:
            return evaluateLargeDownload(state: state)
        case .largeUpload:
            return evaluateLargeUpload(state: state)
        case .custom(let minQuality, let requireWiFi, let allowExpensive):
            return evaluateCustom(
                state: state,
                minimumQuality: minQuality,
                requireWiFi: requireWiFi,
                allowExpensive: allowExpensive
            )
        }
    }

    private func evaluateBasicBrowsing(state: NetworkHealthCoordinator.State) -> HealthCheckResult {
        if state.quality < .poor {
            return HealthCheckResult(passed: false, reason: "Network is offline")
        }
        return HealthCheckResult(passed: true, reason: nil)
    }

    private func evaluateImageLoading(state: NetworkHealthCoordinator.State) -> HealthCheckResult {
        if state.quality < .moderate {
            return HealthCheckResult(passed: false, reason: "Network quality too low for image loading")
        }
        return HealthCheckResult(passed: true, reason: nil)
    }

    private func evaluateVideoStreaming(state: NetworkHealthCoordinator.State) -> HealthCheckResult {
        if state.quality < .good {
            return HealthCheckResult(passed: false, reason: "Network quality too low for video streaming")
        }
        return HealthCheckResult(passed: true, reason: nil)
    }

    private func evaluateLargeDownload(state: NetworkHealthCoordinator.State) -> HealthCheckResult {
        if state.quality < .good {
            return HealthCheckResult(passed: false, reason: "Network quality too low for large downloads")
        }

        if state.isExpensive && state.connectionType.isCellular {
            return HealthCheckResult(
                passed: true,
                reason: "Warning: Using cellular data for large download"
            )
        }

        return HealthCheckResult(passed: true, reason: nil)
    }

    private func evaluateLargeUpload(state: NetworkHealthCoordinator.State) -> HealthCheckResult {
        if state.quality < .good {
            return HealthCheckResult(passed: false, reason: "Network quality too low for large uploads")
        }

        if state.connectionType.isCellular {
            return HealthCheckResult(passed: false, reason: "WiFi required for large uploads")
        }

        return HealthCheckResult(passed: true, reason: nil)
    }

    private func evaluateCustom(
        state: NetworkHealthCoordinator.State,
        minimumQuality: NetworkQuality,
        requireWiFi: Bool,
        allowExpensive: Bool
    ) -> HealthCheckResult {
        if state.quality < minimumQuality {
            return HealthCheckResult(
                passed: false,
                reason: "Network quality below minimum (\(minimumQuality.description))"
            )
        }

        if requireWiFi && state.connectionType.isCellular {
            return HealthCheckResult(passed: false, reason: "WiFi required")
        }

        if !allowExpensive && state.isExpensive {
            return HealthCheckResult(passed: false, reason: "Expensive connection not allowed")
        }

        return HealthCheckResult(passed: true, reason: nil)
    }
}

// MARK: - HealthCheckResult

/// Result of a network health check.
public struct HealthCheckResult: Sendable {
    /// Whether the check passed
    public let passed: Bool

    /// Optional reason for failure or warning message
    public let reason: String?

    public init(passed: Bool, reason: String?) {
        self.passed = passed
        self.reason = reason
    }
}

// MARK: - ConnectionRawData Extensions

extension ConnectionRawData {
    var isCellular: Bool {
        if case .cellular = self {
            return true
        }
        return false
    }
}

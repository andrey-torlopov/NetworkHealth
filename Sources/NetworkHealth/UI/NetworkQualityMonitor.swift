import Foundation
import Observation
import Nevod

/// SwiftUI-friendly wrapper for NetworkHealthCoordinator
/// Provides immediate, synchronous access to network quality state
///
/// Usage:
/// ```swift
/// @State private var monitor = NetworkQualityMonitor()
///
/// var body: some View {
///     VStack {
///         Text("Quality: \(monitor.currentQuality.description)")
///         Text("Connection: \(monitor.connectionType.description)")
///     }
/// }
/// ```
@Observable
public final class NetworkQualityMonitor: @unchecked Sendable {

    // MARK: - Published State

    /// Current network quality level
    @MainActor
    public private(set) var currentQuality: NetworkQuality = .offline

    /// Current connection type (WiFi, LTE, 5G, etc.)
    @MainActor
    public private(set) var connectionType: ConnectionRawData = .none

    /// Whether the connection is expensive (e.g., cellular data)
    @MainActor
    public private(set) var isExpensive: Bool = false

    /// Last error that occurred during measurements
    @MainActor
    public private(set) var lastError: NetworkQualityError?

    /// Whether a measurement is currently in progress
    @MainActor
    public private(set) var isMeasuring: Bool = false

    /// Last measurement snapshot (if any)
    @MainActor
    public private(set) var lastSnapshot: NetworkQualitySnapshot?

    // MARK: - Private Properties

    private let checker: NetworkHealthCoordinator
    private var observationTask: Task<Void, Never>?

    // MARK: - Initialization

    /// Creates a monitor with a default NetworkHealthCoordinator
    nonisolated public init() {
        self.checker = NetworkHealthCoordinator()
        startObserving()
    }

    /// Creates a monitor with a custom NetworkHealthCoordinator
    /// - Parameter checker: Custom configured NetworkHealthCoordinator
    nonisolated public init(checker: NetworkHealthCoordinator) {
        self.checker = checker
        startObserving()
    }

    // Note: Task will be automatically cancelled when the object is deallocated

    // MARK: - Public API

    /// Performs a detailed speed measurement
    /// Updates `isMeasuring`, `lastSnapshot`, and `lastError` accordingly
    @MainActor
    public func performMeasurement() async {
        isMeasuring = true
        lastError = nil

        do {
            let snapshot = try await checker.performDetailedMeasurement()
            lastSnapshot = snapshot
        } catch let error as NetworkQualityError {
            lastError = error
        } catch {
            lastError = .measurementFailed(error)
        }

        isMeasuring = false
    }

    /// Forces a quality refresh (bypasses throttling)
    public func refreshQuality() async {
        await checker.refreshQuality()
    }

    /// Stops monitoring network changes
    public func stopMonitoring() async {
        await checker.stopMonitoring()
        observationTask?.cancel()
        observationTask = nil
    }

    // MARK: - Convenience Properties

    /// Whether the device is currently online
    @MainActor
    public var isOnline: Bool {
        currentQuality != .offline
    }

    /// Whether the connection quality is good enough for heavy operations
    @MainActor
    public var isGoodQuality: Bool {
        currentQuality >= .good
    }

    /// Whether the connection is degraded (poor or moderate)
    @MainActor
    public var isDegradedQuality: Bool {
        currentQuality == .poor || currentQuality == .moderate
    }

    // MARK: - Private Helpers

    nonisolated private func startObserving() {
        observationTask = Task { @MainActor [weak self] in
            guard let self else { return }
            await self.observeChanges()
        }
    }

    @MainActor
    private func observeChanges() async {
        for await state in await checker.stateStream() {
            self.currentQuality = state.quality
            self.connectionType = state.connectionType
            self.isExpensive = state.isExpensive
        }
    }
}

// MARK: - Factory Methods

public extension NetworkQualityMonitor {

    /// Creates a monitor with speed testing enabled
    /// - Parameters:
    ///   - testMode: Speed test mode
    ///   - interval: Minimum interval between tests
    ///   - networkProvider: Network provider for speed testing
    /// - Returns: Configured monitor
    static func withSpeedTest(
        testMode: SpeedTestCoreAdapter.TestMode = .quick,
        interval: TimeInterval = 120,
        networkProvider: NetworkProvider
    ) -> NetworkQualityMonitor {
        let checker = NetworkHealthCoordinator.withSpeedTest(
            testMode: testMode,
            interval: interval,
            networkProvider: networkProvider
        )
        return NetworkQualityMonitor(checker: checker)
    }
}

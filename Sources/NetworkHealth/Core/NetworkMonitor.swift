import Foundation
import Network

/// Protocol for network path monitoring (for dependency injection and testing)
public protocol NetworkPathMonitoring: Sendable {
    /// Starts monitoring network path changes
    func start(queue: DispatchQueue)
    /// Stops monitoring
    func cancel()
    /// Current network path
    var currentPath: NWPath { get }
    /// Sets handler called when path updates
    func setPathUpdateHandler(_ handler: @escaping @Sendable (NWPath) -> Void)
}

/// Adapter to make NWPathMonitor conform to NetworkPathMonitoring
public final class NWPathMonitorAdapter: NetworkPathMonitoring, @unchecked Sendable {
    private let monitor: NWPathMonitor

    public init() {
        self.monitor = NWPathMonitor()
    }

    public func start(queue: DispatchQueue) {
        monitor.start(queue: queue)
    }

    public func cancel() {
        monitor.cancel()
    }

    public var currentPath: NWPath {
        monitor.currentPath
    }

    public func setPathUpdateHandler(_ handler: @escaping @Sendable (NWPath) -> Void) {
        monitor.pathUpdateHandler = handler
    }
}

// MARK: - NetworkMonitor

/// Actor responsible for monitoring network path changes
/// Separates network monitoring concerns from business logic
public actor NetworkMonitor {

    // MARK: - Properties

    private var monitor: any NetworkPathMonitoring
    private let monitorQueue: DispatchQueue
    private var continuations: [UUID: AsyncStream<NWPath>.Continuation] = [:]

    // MARK: - Initialization

    public init(
        monitor: any NetworkPathMonitoring = NWPathMonitorAdapter(),
        monitorQueue: DispatchQueue = DispatchQueue(label: "network-monitor")
    ) {
        self.monitor = monitor
        self.monitorQueue = monitorQueue

        // Setup must be called after initialization
        Task { [weak self] in
            guard let self else { return }
            await self.setup()
        }
    }

    private func setup() {
        monitor.setPathUpdateHandler { [weak self] path in
            guard let self else { return }
            Task { @MainActor in
                await self.handlePathUpdate(path)
            }
        }

        monitor.start(queue: monitorQueue)
    }

    deinit {
        monitor.cancel()
    }

    // MARK: - Public API

    /// Returns the current network path
    public func currentPath() -> NWPath {
        monitor.currentPath
    }

    /// Creates a stream that emits network path updates
    /// The stream immediately yields the current path
    public func pathUpdates() -> AsyncStream<NWPath> {
        AsyncStream { continuation in
            Task { [weak self] in
                guard let self else {
                    continuation.finish()
                    return
                }
                await self.registerContinuation(continuation)
            }
        }
    }

    /// Stops monitoring network changes
    public func stopMonitoring() {
        monitor.cancel()
        finishContinuations()
    }

    // MARK: - Private Helpers

    private func handlePathUpdate(_ path: NWPath) {
        for continuation in continuations.values {
            continuation.yield(path)
        }
    }

    private func registerContinuation(_ continuation: AsyncStream<NWPath>.Continuation) {
        let identifier = UUID()
        continuations[identifier] = continuation

        continuation.onTermination = { @Sendable [weak self] _ in
            guard let self else { return }
            Task { await self.removeContinuation(with: identifier) }
        }

        // Yield current path immediately
        continuation.yield(monitor.currentPath)
    }

    private func removeContinuation(with identifier: UUID) {
        continuations.removeValue(forKey: identifier)
    }

    private func finishContinuations() {
        for continuation in continuations.values {
            continuation.finish()
        }
        continuations.removeAll()
    }
}

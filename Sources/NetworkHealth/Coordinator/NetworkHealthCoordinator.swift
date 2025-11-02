import Foundation
import Nevod
import Network

/// Coordinates network quality monitoring by combining network path monitoring,
/// quality evaluation, and optional speed testing.
///
/// This is the main entry point for network quality checking functionality.
/// It acts as a coordinator between NetworkMonitor, QualityEvaluator, and SpeedTester components.
public actor NetworkHealthCoordinator {

    // MARK: - Internal Properties

    internal let networkMonitor: NetworkMonitor
    internal let qualityEvaluator: QualityEvaluator
    internal let configuration: Configuration
    internal let dateProvider: DateProvider

    internal var state: State
    internal var currentPath: NWPath?
    internal var measuredQuality: SpeedTestResult?
    internal var lastSpeedMeasurementDate: Date?
    internal var speedMeasurementTask: Task<Void, Never>?
    internal var speedMeasurementIdentifier: UUID?
    internal var verificationTask: Task<Void, Never>?
    internal var continuations: [UUID: AsyncStream<State>.Continuation]
    internal var measurementHistory: MeasurementHistory
    internal var pathMonitoringTask: Task<Void, Never>?

    // MARK: - Initialization

    /// Simple initializer without speed testing capabilities
    public init() {
        self.init(configuration: Configuration(speedTester: nil))
    }

    public init(
        configuration: Configuration = .init(),
        networkMonitor: NetworkMonitor = NetworkMonitor(),
        qualityEvaluator: QualityEvaluator = QualityEvaluator(),
        dateProvider: @escaping DateProvider = Date.init
    ) {
        self.configuration = configuration
        self.networkMonitor = networkMonitor
        self.qualityEvaluator = qualityEvaluator
        self.dateProvider = dateProvider
        self.state = State(connectionType: .none, quality: .offline, isExpensive: false)
        self.currentPath = nil
        self.measuredQuality = nil
        self.lastSpeedMeasurementDate = nil
        self.speedMeasurementTask = nil
        self.speedMeasurementIdentifier = nil
        self.verificationTask = nil
        self.continuations = [:]
        self.measurementHistory = MeasurementHistory(
            configuration: configuration.historyConfiguration,
            dateProvider: dateProvider
        )
        self.pathMonitoringTask = nil

        // Start observing network path changes after initialization completes
        Task { [weak self] in
            guard let self else { return }
            await self.startMonitoring()
        }
    }

    private func startMonitoring() {
        pathMonitoringTask = Task { [weak self] in
            guard let self else { return }
            await self.observePathChanges()
        }
    }

    deinit {
        pathMonitoringTask?.cancel()
        speedMeasurementTask?.cancel()
        verificationTask?.cancel()
    }

    // MARK: - Public API

    /// Returns the latest known state. The call suspends to respect actor isolation.
    public func currentState() -> State {
        state
    }

    /// Produces a stream of state updates. The stream immediately yields the current state.
    public func stateStream() -> AsyncStream<State> {
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

    /// Stops monitoring the network path and cancels any pending measurements.
    public func stopMonitoring() async {
        await networkMonitor.stopMonitoring()
        pathMonitoringTask?.cancel()
        pathMonitoringTask = nil
        cancelSpeedMeasurement()
        verificationTask?.cancel()
        verificationTask = nil
        finishContinuations()
    }
}

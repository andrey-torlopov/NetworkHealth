import Foundation
import Network

/// Evaluates network quality based on connection type and measurements
/// Pure logic component with no state or side effects
public struct QualityEvaluator: Sendable {

    /// Configuration for quality evaluation
    public struct Configuration: Sendable {
        /// Latency threshold (in ms) after which connection is considered poor
        public let poorLatencyThreshold: Double

        public init(poorLatencyThreshold: Double = 1500) {
            self.poorLatencyThreshold = max(100, poorLatencyThreshold)
        }
    }

    private let configuration: Configuration

    public init(configuration: Configuration = Configuration()) {
        self.configuration = configuration
    }

    // MARK: - Quality Evaluation

    /// Determines overall network quality from all available information
    /// - Parameters:
    ///   - path: Network path from NWPathMonitor
    ///   - connectionType: Determined connection type
    ///   - measurements: Optional speed test measurements
    /// - Returns: Overall network quality assessment
    public func evaluate(
        path: NWPath,
        connectionType: ConnectionRawData,
        measurements: SpeedTestResult?
    ) -> NetworkQuality {
        // 1. If no connection - offline
        guard connectionType != .none else { return .offline }

        // 2. Base quality from connection type
        let baseQuality = NetworkQuality.from(connectionType: connectionType)

        // 3. Consider system constraints
        let pathQuality = qualityFromPath(path)
        let constrainedQuality = min(baseQuality, pathQuality)

        // 4. Consider measurements if available
        if let measurements = measurements {
            let measuredQuality = NetworkQuality.from(
                latency: measurements.latency,
                downloadSpeedMbps: measurements.downloadSpeedMbps,
                uploadSpeedMbps: measurements.uploadSpeedMbps
            )
            return min(constrainedQuality, measuredQuality)
        }

        return constrainedQuality
    }

    /// Determines connection type from network path
    public func determineConnectionType(from path: NWPath) -> ConnectionRawData {
        guard path.status == .satisfied else { return .none }

        if path.usesInterfaceType(.wifi) {
            return .wifi
        }
        if path.usesInterfaceType(.wiredEthernet) {
            return .wiredEthernet
        }
        if path.usesInterfaceType(.cellular) {
            return .cellular(CellularTypeResolver.resolveCellularType())
        }
        if path.usesInterfaceType(.loopback) {
            return .loopback
        }

        return .other
    }

    /// Determines quality from network path properties
    public func qualityFromPath(_ path: NWPath) -> NetworkQuality {
        switch path.status {
        case .satisfied:
            if path.isConstrained {
                return .poor
            }

            // Determine quality by interface type
            if path.usesInterfaceType(.wiredEthernet) {
                return .excellent
            }
            if path.usesInterfaceType(.wifi) {
                return .excellent
            }
            if path.usesInterfaceType(.cellular) {
                let cellularType = CellularTypeResolver.resolveCellularType()
                return NetworkQuality.from(connectionType: .cellular(cellularType))
            }
            if path.usesInterfaceType(.loopback) {
                return .poor
            }

            return .good

        case .unsatisfied, .requiresConnection:
            return .offline

        @unknown default:
            return .offline
        }
    }

    /// Checks if measurements indicate degraded quality
    /// Returns true if quality is below "good" threshold
    public func isDegradedQuality(_ measurements: SpeedTestResult) -> Bool {
        let quality = NetworkQuality.from(
            latency: measurements.latency,
            downloadSpeedMbps: measurements.downloadSpeedMbps,
            uploadSpeedMbps: measurements.uploadSpeedMbps
        )
        return quality != .offline && quality.rawValue < NetworkQuality.good.rawValue
    }
}

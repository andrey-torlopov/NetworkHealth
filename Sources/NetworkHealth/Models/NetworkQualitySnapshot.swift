import Foundation

/// Snapshot of network quality and performance metrics at a specific point in time.
/// Combines connection type, quality assessment, and raw performance measurements.
public struct NetworkQualitySnapshot: Sendable, Identifiable, Codable, Hashable {
    /// Unique identifier for this snapshot
    public let id: UUID

    /// Timestamp when the snapshot was taken
    public let timestamp: Date

    // MARK: - Connection Information

    /// Type of network connection (WiFi, LTE, 5G, etc.)
    public let connectionType: ConnectionRawData

    /// Whether the connection is expensive (e.g., cellular with limited data)
    public let isExpensive: Bool

    // MARK: - Quality Assessment

    /// Overall network quality assessment
    public let quality: NetworkQuality

    // MARK: - Raw Performance Metrics (Optional)

    /// Round-trip time (latency) in milliseconds
    public let latency: Double?

    /// Download speed in megabits per second (Mbps)
    public let downloadSpeedMbps: Double?

    /// Upload speed in megabits per second (Mbps)
    public let uploadSpeedMbps: Double?

    // MARK: - Detailed Metrics (Optional)

    /// Total bytes downloaded during the test
    public let bytesDownloaded: Int?

    /// Total bytes uploaded during the test
    public let bytesUploaded: Int?

    /// Duration of the download test in seconds
    public let downloadDuration: TimeInterval?

    /// Duration of the upload test in seconds
    public let uploadDuration: TimeInterval?

    // MARK: - Initialization

    public init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        connectionType: ConnectionRawData,
        isExpensive: Bool,
        quality: NetworkQuality,
        latency: Double? = nil,
        downloadSpeedMbps: Double? = nil,
        uploadSpeedMbps: Double? = nil,
        bytesDownloaded: Int? = nil,
        bytesUploaded: Int? = nil,
        downloadDuration: TimeInterval? = nil,
        uploadDuration: TimeInterval? = nil
    ) {
        self.id = id
        self.timestamp = timestamp
        self.connectionType = connectionType
        self.isExpensive = isExpensive
        self.quality = quality
        self.latency = latency
        self.downloadSpeedMbps = downloadSpeedMbps
        self.uploadSpeedMbps = uploadSpeedMbps
        self.bytesDownloaded = bytesDownloaded
        self.bytesUploaded = bytesUploaded
        self.downloadDuration = downloadDuration
        self.uploadDuration = uploadDuration
    }
}

// MARK: - Convenience Initializers

public extension NetworkQualitySnapshot {
    /// Creates a snapshot from the current network state without performance measurements
    static func fromState(
        _ state: NetworkHealthCoordinator.State,
        timestamp: Date = Date()
    ) -> NetworkQualitySnapshot {
        NetworkQualitySnapshot(
            timestamp: timestamp,
            connectionType: state.connectionType,
            isExpensive: state.isExpensive,
            quality: state.quality
        )
    }
}

// MARK: - Computed Properties

public extension NetworkQualitySnapshot {
    /// Whether this snapshot includes performance measurements
    var hasMeasurements: Bool {
        latency != nil || downloadSpeedMbps != nil || uploadSpeedMbps != nil
    }

    /// Whether this snapshot includes detailed metrics
    var hasDetailedMetrics: Bool {
        bytesDownloaded != nil || bytesUploaded != nil ||
        downloadDuration != nil || uploadDuration != nil
    }

    /// Download speed in bits per second (bps)
    var downloadSpeedBps: Double? {
        downloadSpeedMbps.map { $0 * 1_000_000 }
    }

    /// Upload speed in bits per second (bps)
    var uploadSpeedBps: Double? {
        uploadSpeedMbps.map { $0 * 1_000_000 }
    }

    /// Average speed in Mbps (if both download and upload are available)
    var averageSpeedMbps: Double? {
        switch (downloadSpeedMbps, uploadSpeedMbps) {
        case (.some(let download), .some(let upload)):
            return (download + upload) / 2
        case (.some(let download), .none):
            return download
        case (.none, .some(let upload)):
            return upload
        case (.none, .none):
            return nil
        }
    }
}

// MARK: - Description

extension NetworkQualitySnapshot: CustomStringConvertible {
    public var description: String {
        var parts: [String] = [
            "NetworkQualitySnapshot(quality: \(quality)",
            "connectionType: \(connectionType)"
        ]

        if let latency = latency {
            parts.append("latency: \(String(format: "%.1f", latency))ms")
        }

        if let download = downloadSpeedMbps {
            parts.append("download: \(String(format: "%.2f", download))Mbps")
        }

        if let upload = uploadSpeedMbps {
            parts.append("upload: \(String(format: "%.2f", upload))Mbps")
        }

        return parts.joined(separator: ", ") + ")"
    }
}

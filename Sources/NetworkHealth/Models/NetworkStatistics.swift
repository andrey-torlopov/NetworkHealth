import Foundation

/// Aggregated network statistics over a period of time
public struct NetworkStatistics: Sendable, Codable, Hashable {
    /// Time period for these statistics
    public let period: DateInterval

    /// Number of measurements included in these statistics
    public let measurementCount: Int

    // MARK: - Latency Statistics

    /// Average latency in milliseconds
    public let averageLatency: Double?

    /// Minimum latency in milliseconds
    public let minLatency: Double?

    /// Maximum latency in milliseconds
    public let maxLatency: Double?

    /// Median latency in milliseconds
    public let medianLatency: Double?

    // MARK: - Download Speed Statistics

    /// Average download speed in Mbps
    public let averageDownloadSpeed: Double?

    /// Minimum download speed in Mbps
    public let minDownloadSpeed: Double?

    /// Maximum download speed in Mbps
    public let maxDownloadSpeed: Double?

    /// Median download speed in Mbps
    public let medianDownloadSpeed: Double?

    // MARK: - Upload Speed Statistics

    /// Average upload speed in Mbps
    public let averageUploadSpeed: Double?

    /// Minimum upload speed in Mbps
    public let minUploadSpeed: Double?

    /// Maximum upload speed in Mbps
    public let maxUploadSpeed: Double?

    /// Median upload speed in Mbps
    public let medianUploadSpeed: Double?

    // MARK: - Quality Distribution

    /// Distribution of quality levels during the period
    /// Key: NetworkQuality, Value: count of measurements at that quality
    public let qualityDistribution: [NetworkQuality: Int]

    /// Most common quality level during the period
    public var dominantQuality: NetworkQuality? {
        qualityDistribution.max(by: { $0.value < $1.value })?.key
    }

    // MARK: - Connection Type Distribution

    /// Distribution of connection types during the period
    public let connectionTypeDistribution: [String: Int]

    // MARK: - Initialization

    public init(
        period: DateInterval,
        measurementCount: Int,
        averageLatency: Double? = nil,
        minLatency: Double? = nil,
        maxLatency: Double? = nil,
        medianLatency: Double? = nil,
        averageDownloadSpeed: Double? = nil,
        minDownloadSpeed: Double? = nil,
        maxDownloadSpeed: Double? = nil,
        medianDownloadSpeed: Double? = nil,
        averageUploadSpeed: Double? = nil,
        minUploadSpeed: Double? = nil,
        maxUploadSpeed: Double? = nil,
        medianUploadSpeed: Double? = nil,
        qualityDistribution: [NetworkQuality: Int] = [:],
        connectionTypeDistribution: [String: Int] = [:]
    ) {
        self.period = period
        self.measurementCount = measurementCount
        self.averageLatency = averageLatency
        self.minLatency = minLatency
        self.maxLatency = maxLatency
        self.medianLatency = medianLatency
        self.averageDownloadSpeed = averageDownloadSpeed
        self.minDownloadSpeed = minDownloadSpeed
        self.maxDownloadSpeed = maxDownloadSpeed
        self.medianDownloadSpeed = medianDownloadSpeed
        self.averageUploadSpeed = averageUploadSpeed
        self.minUploadSpeed = minUploadSpeed
        self.maxUploadSpeed = maxUploadSpeed
        self.medianUploadSpeed = medianUploadSpeed
        self.qualityDistribution = qualityDistribution
        self.connectionTypeDistribution = connectionTypeDistribution
    }
}

// MARK: - Statistics Calculation

public extension NetworkStatistics {
    /// Creates statistics from a collection of snapshots
    static func from(
        snapshots: [NetworkQualitySnapshot],
        period: DateInterval? = nil
    ) -> NetworkStatistics {
        guard !snapshots.isEmpty else {
            let emptyPeriod = period ?? DateInterval(start: Date(), duration: 0)
            return NetworkStatistics(
                period: emptyPeriod,
                measurementCount: 0
            )
        }

        // Determine period
        let timestamps = snapshots.map { $0.timestamp }
        let start = timestamps.min() ?? Date()
        let end = timestamps.max() ?? Date()
        let calculatedPeriod = period ?? DateInterval(start: start, end: end)

        // Extract metrics
        let latencies = snapshots.compactMap { $0.latency }
        let downloadSpeeds = snapshots.compactMap { $0.downloadSpeedMbps }
        let uploadSpeeds = snapshots.compactMap { $0.uploadSpeedMbps }

        // Quality distribution
        var qualityDist: [NetworkQuality: Int] = [:]
        for snapshot in snapshots {
            qualityDist[snapshot.quality, default: 0] += 1
        }

        // Connection type distribution
        var connectionTypeDist: [String: Int] = [:]
        for snapshot in snapshots {
            let typeKey = snapshot.connectionType.description
            connectionTypeDist[typeKey, default: 0] += 1
        }

        return NetworkStatistics(
            period: calculatedPeriod,
            measurementCount: snapshots.count,
            averageLatency: latencies.isEmpty ? nil : latencies.reduce(0, +) / Double(latencies.count),
            minLatency: latencies.min(),
            maxLatency: latencies.max(),
            medianLatency: latencies.median(),
            averageDownloadSpeed: downloadSpeeds.isEmpty ? nil : downloadSpeeds.reduce(0, +) / Double(downloadSpeeds.count),
            minDownloadSpeed: downloadSpeeds.min(),
            maxDownloadSpeed: downloadSpeeds.max(),
            medianDownloadSpeed: downloadSpeeds.median(),
            averageUploadSpeed: uploadSpeeds.isEmpty ? nil : uploadSpeeds.reduce(0, +) / Double(uploadSpeeds.count),
            minUploadSpeed: uploadSpeeds.min(),
            maxUploadSpeed: uploadSpeeds.max(),
            medianUploadSpeed: uploadSpeeds.median(),
            qualityDistribution: qualityDist,
            connectionTypeDistribution: connectionTypeDist
        )
    }
}

// MARK: - Helper Extensions

private extension Array where Element == Double {
    func median() -> Double? {
        guard !isEmpty else { return nil }
        let sorted = self.sorted()
        let count = sorted.count

        if count % 2 == 0 {
            return (sorted[count / 2 - 1] + sorted[count / 2]) / 2
        } else {
            return sorted[count / 2]
        }
    }
}

public extension ConnectionRawData {
    var description: String {
        switch self {
        case .none: return "none"
        case .wifi: return "wifi"
        case .cellular(let type): return "cellular(\(type.rawValue))"
        case .wiredEthernet: return "ethernet"
        case .loopback: return "loopback"
        case .other: return "other"
        }
    }
}

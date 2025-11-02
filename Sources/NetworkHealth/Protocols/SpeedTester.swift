import Foundation

// MARK: - Speed Testing Types

/// Result of speed test measurements
public struct SpeedTestResult: Sendable {
    /// Round-trip time in milliseconds
    public let latency: Double?
    /// Download speed in Mbps
    public let downloadSpeedMbps: Double?
    /// Upload speed in Mbps
    public let uploadSpeedMbps: Double?

    public init(latency: Double?, downloadSpeedMbps: Double?, uploadSpeedMbps: Double?) {
        self.latency = latency
        self.downloadSpeedMbps = downloadSpeedMbps
        self.uploadSpeedMbps = uploadSpeedMbps
    }
}

/// Detailed result with additional metrics
public struct DetailedSpeedTestResult: Sendable {
    /// Round-trip time in milliseconds
    public let latency: Double?
    /// Download speed in Mbps
    public let downloadSpeedMbps: Double?
    /// Upload speed in Mbps
    public let uploadSpeedMbps: Double?

    // Detailed metrics
    /// Total bytes downloaded during test
    public let bytesDownloaded: Int?
    /// Total bytes uploaded during test
    public let bytesUploaded: Int?
    /// Duration of download test
    public let downloadDuration: TimeInterval?
    /// Duration of upload test
    public let uploadDuration: TimeInterval?

    public init(
        latency: Double?,
        downloadSpeedMbps: Double?,
        uploadSpeedMbps: Double?,
        bytesDownloaded: Int? = nil,
        bytesUploaded: Int? = nil,
        downloadDuration: TimeInterval? = nil,
        uploadDuration: TimeInterval? = nil
    ) {
        self.latency = latency
        self.downloadSpeedMbps = downloadSpeedMbps
        self.uploadSpeedMbps = uploadSpeedMbps
        self.bytesDownloaded = bytesDownloaded
        self.bytesUploaded = bytesUploaded
        self.downloadDuration = downloadDuration
        self.uploadDuration = uploadDuration
    }

    /// Converts to basic SpeedTestResult
    public var basicResult: SpeedTestResult {
        SpeedTestResult(
            latency: latency,
            downloadSpeedMbps: downloadSpeedMbps,
            uploadSpeedMbps: uploadSpeedMbps
        )
    }
}

// MARK: - Speed Testing Protocols

/// Protocol for measuring network speed metrics
public protocol SpeedTester: Sendable {
    /// Performs speed test and returns measurements
    func measureSpeed() async throws -> SpeedTestResult
}

/// Extended protocol for speed testers that support detailed measurements
public protocol DetailedSpeedTester: SpeedTester {
    /// Performs detailed speed measurement with additional metrics
    func measureSpeedDetailed() async throws -> DetailedSpeedTestResult
}

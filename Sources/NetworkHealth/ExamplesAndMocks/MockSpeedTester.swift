import Foundation

// MARK: - Mock Speed Tester

/// Mock implementation of SpeedTester for testing and examples.
/// Returns configurable predefined results to simulate various network conditions.
///
/// Example usage:
/// ```swift
/// // Simulate excellent connection
/// let excellentTester = MockSpeedTester(
///     latency: 20,
///     downloadSpeedMbps: 50,
///     uploadSpeedMbps: 30
/// )
///
/// for await state in NetworkHealth.stream(speedTester: excellentTester) {
///     print("Quality: \(state.quality)") // Will be .excellent
/// }
/// ```
public struct MockSpeedTester: SpeedTester {

    // MARK: - Configuration

    /// Predefined result to return
    public let result: SpeedTestResult

    /// Optional delay to simulate measurement time
    public let delay: TimeInterval

    /// Whether to simulate failure
    public let shouldFail: Bool

    // MARK: - Initialization

    /// Creates a mock tester with specific measurements
    /// - Parameters:
    ///   - latency: Round-trip time in milliseconds
    ///   - downloadSpeedMbps: Download speed in Mbps
    ///   - uploadSpeedMbps: Upload speed in Mbps
    ///   - delay: Simulated measurement delay in seconds (default: 0.1)
    ///   - shouldFail: Whether to throw an error (default: false)
    public init(
        latency: Double?,
        downloadSpeedMbps: Double?,
        uploadSpeedMbps: Double?,
        delay: TimeInterval = 0.1,
        shouldFail: Bool = false
    ) {
        self.result = SpeedTestResult(
            latency: latency,
            downloadSpeedMbps: downloadSpeedMbps,
            uploadSpeedMbps: uploadSpeedMbps
        )
        self.delay = delay
        self.shouldFail = shouldFail
    }

    /// Creates a mock tester from a predefined result
    public init(
        result: SpeedTestResult,
        delay: TimeInterval = 0.1,
        shouldFail: Bool = false
    ) {
        self.result = result
        self.delay = delay
        self.shouldFail = shouldFail
    }

    // MARK: - SpeedTester Protocol

    public func measureSpeed() async throws -> SpeedTestResult {
        // Simulate measurement delay
        if delay > 0 {
            try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        }

        // Simulate failure if configured
        if shouldFail {
            throw MockSpeedTestError.simulatedFailure
        }

        return result
    }
}

// MARK: - Mock Error

public enum MockSpeedTestError: Error {
    case simulatedFailure
}

// MARK: - Predefined Configurations

public extension MockSpeedTester {

    /// Simulates excellent 5G connection
    /// - Latency: 15ms
    /// - Download: 100 Mbps
    /// - Upload: 50 Mbps
    static var excellent5G: MockSpeedTester {
        MockSpeedTester(
            latency: 15,
            downloadSpeedMbps: 100,
            uploadSpeedMbps: 50
        )
    }

    /// Simulates good LTE connection
    /// - Latency: 50ms
    /// - Download: 20 Mbps
    /// - Upload: 10 Mbps
    static var goodLTE: MockSpeedTester {
        MockSpeedTester(
            latency: 50,
            downloadSpeedMbps: 20,
            uploadSpeedMbps: 10
        )
    }

    /// Simulates moderate 3G connection
    /// - Latency: 150ms
    /// - Download: 3 Mbps
    /// - Upload: 1 Mbps
    static var moderate3G: MockSpeedTester {
        MockSpeedTester(
            latency: 150,
            downloadSpeedMbps: 3,
            uploadSpeedMbps: 1
        )
    }

    /// Simulates poor 2G connection
    /// - Latency: 500ms
    /// - Download: 0.3 Mbps
    /// - Upload: 0.1 Mbps
    static var poor2G: MockSpeedTester {
        MockSpeedTester(
            latency: 500,
            downloadSpeedMbps: 0.3,
            uploadSpeedMbps: 0.1
        )
    }

    /// Simulates excellent WiFi connection
    /// - Latency: 10ms
    /// - Download: 150 Mbps
    /// - Upload: 80 Mbps
    static var excellentWiFi: MockSpeedTester {
        MockSpeedTester(
            latency: 10,
            downloadSpeedMbps: 150,
            uploadSpeedMbps: 80
        )
    }

    /// Simulates slow/congested WiFi
    /// - Latency: 200ms
    /// - Download: 2 Mbps
    /// - Upload: 1 Mbps
    static var slowWiFi: MockSpeedTester {
        MockSpeedTester(
            latency: 200,
            downloadSpeedMbps: 2,
            uploadSpeedMbps: 1
        )
    }

    /// Simulates measurement failure
    static var failure: MockSpeedTester {
        MockSpeedTester(
            latency: nil,
            downloadSpeedMbps: nil,
            uploadSpeedMbps: nil,
            shouldFail: true
        )
    }
}

// MARK: - Detailed Mock Speed Tester

/// Mock implementation of DetailedSpeedTester with additional metrics
public struct MockDetailedSpeedTester: DetailedSpeedTester {

    public let result: DetailedSpeedTestResult
    public let delay: TimeInterval
    public let shouldFail: Bool

    public init(
        latency: Double?,
        downloadSpeedMbps: Double?,
        uploadSpeedMbps: Double?,
        bytesDownloaded: Int? = nil,
        bytesUploaded: Int? = nil,
        downloadDuration: TimeInterval? = nil,
        uploadDuration: TimeInterval? = nil,
        delay: TimeInterval = 0.1,
        shouldFail: Bool = false
    ) {
        self.result = DetailedSpeedTestResult(
            latency: latency,
            downloadSpeedMbps: downloadSpeedMbps,
            uploadSpeedMbps: uploadSpeedMbps,
            bytesDownloaded: bytesDownloaded,
            bytesUploaded: bytesUploaded,
            downloadDuration: downloadDuration,
            uploadDuration: uploadDuration
        )
        self.delay = delay
        self.shouldFail = shouldFail
    }

    public func measureSpeed() async throws -> SpeedTestResult {
        if delay > 0 {
            try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        }

        if shouldFail {
            throw MockSpeedTestError.simulatedFailure
        }

        return result.basicResult
    }

    public func measureSpeedDetailed() async throws -> DetailedSpeedTestResult {
        if delay > 0 {
            try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        }

        if shouldFail {
            throw MockSpeedTestError.simulatedFailure
        }

        return result
    }
}

// MARK: - Random Mock Speed Tester

/// Mock tester that returns random values within a range.
/// Useful for simulating variable network conditions.
public struct RandomMockSpeedTester: SpeedTester {

    public let latencyRange: ClosedRange<Double>
    public let downloadRange: ClosedRange<Double>
    public let uploadRange: ClosedRange<Double>
    public let delay: TimeInterval

    public init(
        latencyRange: ClosedRange<Double> = 10...100,
        downloadRange: ClosedRange<Double> = 1...50,
        uploadRange: ClosedRange<Double> = 1...20,
        delay: TimeInterval = 0.1
    ) {
        self.latencyRange = latencyRange
        self.downloadRange = downloadRange
        self.uploadRange = uploadRange
        self.delay = delay
    }

    public func measureSpeed() async throws -> SpeedTestResult {
        if delay > 0 {
            try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        }

        return SpeedTestResult(
            latency: Double.random(in: latencyRange),
            downloadSpeedMbps: Double.random(in: downloadRange),
            uploadSpeedMbps: Double.random(in: uploadRange)
        )
    }
}

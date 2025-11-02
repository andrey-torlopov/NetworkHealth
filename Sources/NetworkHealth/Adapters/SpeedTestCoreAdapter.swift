import Foundation
import SpeedTestCore

/// Adapter that bridges SpeedTestCore's SpeedTestManager to NetworkQualityChecker's protocols
public final class SpeedTestCoreAdapter: DetailedSpeedTester {

    // MARK: - Configuration

    public enum TestMode: Sendable {
        /// Quick test: ping + download only (faster, less data usage)
        case quick
        /// Standard test: ping + download + upload (more comprehensive)
        case standard
        /// Full test: all measurements with detailed metrics
        case full
    }

    // MARK: - Properties

    private let manager: SpeedTestManager
    private let testMode: TestMode

    // MARK: - Initialization

    public init(
        manager: SpeedTestManager,
        testMode: TestMode = .quick
    ) {
        self.manager = manager
        self.testMode = testMode
    }

    // MARK: - SpeedTester Protocol

    public func measureSpeed() async throws -> SpeedTestResult {
        switch testMode {
        case .quick:
            return try await performQuickTest()
        case .standard:
            return try await performStandardTest()
        case .full:
            return try await performFullTest()
        }
    }

    // MARK: - Test Implementations

    /// Quick test: ping + download only
    /// Best for frequent monitoring with minimal data usage
    private func performQuickTest() async throws -> SpeedTestResult {
        async let pingResult = manager.performPing()
        async let downloadResult = manager.performDownload()

        let (ping, download) = await (pingResult, downloadResult)

        return SpeedTestResult(
            latency: try? ping.get().rtt,
            downloadSpeedMbps: try? download.get().speedMbps,
            uploadSpeedMbps: nil
        )
    }

    /// Standard test: ping + download + upload
    /// Balanced approach for general quality assessment
    private func performStandardTest() async throws -> SpeedTestResult {
        let fullTest = await manager.performFullTest()

        return SpeedTestResult(
            latency: try? fullTest.ping.get().rtt,
            downloadSpeedMbps: try? fullTest.download.get().speedMbps,
            uploadSpeedMbps: try? fullTest.upload.get().speedMbps
        )
    }

    /// Full test with detailed metrics
    /// Most comprehensive but uses more data and time
    private func performFullTest() async throws -> SpeedTestResult {
        let fullTest = await manager.performFullTest()

        return SpeedTestResult(
            latency: try? fullTest.ping.get().rtt,
            downloadSpeedMbps: try? fullTest.download.get().speedMbps,
            uploadSpeedMbps: try? fullTest.upload.get().speedMbps
        )
    }
}

// MARK: - DetailedSpeedTester Protocol

extension SpeedTestCoreAdapter {
    /// Performs a detailed measurement with all available metrics
    public func measureSpeedDetailed() async throws -> DetailedSpeedTestResult {
        let fullTest = await manager.performFullTest()

        let pingResult = try? fullTest.ping.get()
        let downloadResult = try? fullTest.download.get()
        let uploadResult = try? fullTest.upload.get()

        return DetailedSpeedTestResult(
            latency: pingResult?.rtt,
            downloadSpeedMbps: downloadResult?.speedMbps,
            uploadSpeedMbps: uploadResult?.speedMbps,
            bytesDownloaded: downloadResult?.bytesTransferred,
            bytesUploaded: uploadResult?.bytesTransferred,
            downloadDuration: downloadResult?.duration,
            uploadDuration: uploadResult?.duration
        )
    }
}

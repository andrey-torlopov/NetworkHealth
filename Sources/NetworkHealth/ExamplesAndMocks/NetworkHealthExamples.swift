import Foundation
import SwiftUI

// MARK: - Example 1: Stream Mode (Continuous Monitoring)

/// Example: Basic network monitoring without speed tests
/// This monitors only the connection type (WiFi, LTE, 5G, etc.)
func example1_BasicStreamMonitoring() async {
    for await state in NetworkHealth.stream() {
        print("Quality: \(state.quality.description)")
        print("Connection: \(state.connectionType)")
        print("Is expensive: \(state.isExpensive)")
        print("---")

        // React to quality changes
        if state.quality == .offline {
            print("Network is offline!")
        } else if state.isDegradedQuality {
            print("Warning: Degraded network quality")
        }
    }
}

/// Example: Stream with periodic speed tests using MockSpeedTester
/// This demonstrates how to inject a speed tester to get REAL speed measurements
func example2_StreamWithSpeedTests() async {
    // Create a mock tester that simulates excellent WiFi
    let speedTester = MockSpeedTester.excellentWiFi

    for await state in NetworkHealth.stream(
        speedTester: speedTester,
        speedTestInterval: 60 // Test every 60 seconds
    ) {
        print("Quality: \(state.quality.description)")

        if let download = state.downloadSpeedMbps {
            print("Download speed: \(download) Mbps")
        }

        if let latency = state.latency {
            print("Latency: \(latency)ms")
        }
    }
}

/// Example: Using different mock configurations to simulate various conditions
func example2b_SimulateNetworkConditions() async {
    // You can use different testers:
    // - MockSpeedTester.poor2G
    // - MockSpeedTester.excellent5G
    // - RandomMockSpeedTester for variable conditions

    let randomTester = RandomMockSpeedTester(
        latencyRange: 20...200,
        downloadRange: 1...100,
        uploadRange: 1...50
    )

    for await state in NetworkHealth.stream(
        speedTester: randomTester,
        speedTestInterval: 30
    ) {
        print("Current quality: \(state.quality)")
    }
}

/// Example: Monitor network in a background task
actor NetworkMonitoringService {
    private var monitoringTask: Task<Void, Never>?
    private var currentQuality: NetworkQuality = .offline

    func startMonitoring() {
        guard monitoringTask == nil else { return }

        monitoringTask = Task {
            for await state in NetworkHealth.stream() {
                self.handleStateChange(state)
            }
        }
    }

    func stopMonitoring() {
        monitoringTask?.cancel()
        monitoringTask = nil
    }

    private func handleStateChange(_ state: NetworkHealthState) {
        currentQuality = state.quality

        // Notify other parts of the app
        NotificationCenter.default.post(
            name: .networkQualityChanged,
            object: state
        )
    }
}

extension Notification.Name {
    static let networkQualityChanged = Notification.Name("networkQualityChanged")
}

// MARK: - Example 2: Snapshot Mode (One-Time Check)

/// Example: Quick network check before starting an operation
func example3_QuickSnapshot() async {
    let snapshot = await NetworkHealth.snapshot()

    if snapshot.isOnline {
        print("Network is available: \(snapshot.quality.description)")

        if snapshot.isGoodQuality {
            // Start heavy operation
            print("Starting download...")
        } else {
            print("Network quality is not optimal")
        }
    } else {
        print("No network connection")
    }
}

/// Example: Detailed snapshot with speed test
func example4_DetailedSnapshot() async {
    do {
        print("Running speed test...")

        // Use mock tester for demonstration
        let speedTester = MockSpeedTester.goodLTE

        let snapshot = try await NetworkHealth.detailedSnapshot(
            speedTester: speedTester
        )

        print("Quality: \(snapshot.quality.description)")
        print("Connection: \(snapshot.connectionType)")

        if let latency = snapshot.latency {
            print("Latency: \(String(format: "%.1f", latency))ms")
        }

        if let download = snapshot.downloadSpeedMbps {
            print("Download: \(String(format: "%.2f", download)) Mbps")
        }

        if let upload = snapshot.uploadSpeedMbps {
            print("Upload: \(String(format: "%.2f", upload)) Mbps")
        }
    } catch {
        print("Speed test failed: \(error)")
    }
}

/// Example: Check network before making API call
func example5_PreflightCheck() async throws {
    let snapshot = await NetworkHealth.snapshot()

    guard snapshot.isOnline else {
        throw NetworkError.offline
    }

    if snapshot.isDegradedQuality {
        print("Warning: Network quality is degraded, request may be slow")
    }

    // Proceed with API call
    try await makeAPICall()
}

enum NetworkError: Error {
    case offline
}

func makeAPICall() async throws {
    // Your API call here
}

// MARK: - Example 3: Observable Mode (SwiftUI)

/// Example: SwiftUI View with network monitoring
struct NetworkStatusView: View {
    @State private var health = NetworkHealth.observable()

    var body: some View {
        VStack(spacing: 16) {
            // Quality indicator
            qualityIndicator

            // Connection details
            VStack(alignment: .leading, spacing: 8) {
                Text("Connection: \(health.connectionType.description)")
                Text("Quality: \(health.currentQuality.description)")

                if health.isExpensive {
                    Text("Using cellular data")
                        .foregroundColor(.orange)
                }
            }

            // Action button
            Button("Refresh Quality") {
                Task {
                    await health.refreshQuality()
                }
            }
            .disabled(!health.isOnline)
        }
        .padding()
    }

    @ViewBuilder
    private var qualityIndicator: some View {
        Circle()
            .fill(qualityColor)
            .frame(width: 20, height: 20)
    }

    private var qualityColor: Color {
        switch health.currentQuality {
        case .offline:
            return .gray
        case .poor:
            return .red
        case .moderate:
            return .orange
        case .good:
            return .yellow
        case .excellent:
            return .green
        }
    }
}

/// Example: SwiftUI View with speed testing
struct NetworkSpeedView: View {
    // Create a mock tester for demonstration
    @State private var health = NetworkHealth.observable(
        speedTester: MockSpeedTester.goodLTE,
        speedTestInterval: 60
    )

    var body: some View {
        VStack(spacing: 16) {
            Text("Network Speed Monitor")
                .font(.headline)

            if health.isMeasuring {
                ProgressView("Testing speed...")
            } else if let snapshot = health.lastSnapshot {
                speedResults(snapshot)
            } else {
                Text("No measurements yet")
                    .foregroundColor(.secondary)
            }

            Button("Test Speed Now") {
                Task {
                    await health.performMeasurement()
                }
            }
            .disabled(health.isMeasuring || !health.isOnline)
        }
        .padding()
    }

    @ViewBuilder
    private func speedResults(_ snapshot: NetworkQualitySnapshot) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            if let latency = snapshot.latency {
                Text("Latency: \(String(format: "%.1f", latency))ms")
            }

            if let download = snapshot.downloadSpeedMbps {
                Text("Download: \(String(format: "%.2f", download)) Mbps")
            }

            if let upload = snapshot.uploadSpeedMbps {
                Text("Upload: \(String(format: "%.2f", upload)) Mbps")
            }
        }
    }
}

/// Example: Conditional UI based on network quality
struct VideoPlayerView: View {
    @State private var health = NetworkHealth.observable()
    @State private var isPlaying = false

    var body: some View {
        VStack {
            if isPlaying {
                VideoPlayer()
            } else {
                playButton
            }
        }
    }

    @ViewBuilder
    private var playButton: some View {
        VStack(spacing: 16) {
            Button("Play Video") {
                startPlayback()
            }
            .disabled(!canPlayVideo)

            if !health.isOnline {
                Text("No internet connection")
                    .foregroundColor(.red)
            } else if health.isDegradedQuality {
                Text("Low network quality - video may buffer")
                    .foregroundColor(.orange)
                    .font(.caption)
            }
        }
    }

    private var canPlayVideo: Bool {
        health.isGoodQuality
    }

    private func startPlayback() {
        guard canPlayVideo else { return }
        isPlaying = true
    }
}

struct VideoPlayer: View {
    var body: some View {
        Rectangle()
            .fill(Color.black)
            .overlay(Text("Video Player"))
    }
}

// MARK: - Example 4: Health Check Mode

/// Example: Check if network is good enough for video streaming
func example6_VideoStreamingCheck() async {
    let check = await NetworkHealth.check(requirement: .videoStreaming)

    if check.passed {
        print("Network is good for video streaming")
        startVideoStream()
    } else {
        print("Cannot stream video: \(check.reason ?? "Unknown reason")")
        showQualityWarning(check.reason)
    }
}

/// Example: Check with custom requirements
func example7_CustomRequirements() async {
    let check = await NetworkHealth.check(
        minimumQuality: .good,
        requireWiFi: true,
        allowExpensive: false
    )

    if check.passed {
        uploadLargeFile()
    } else {
        print("Requirements not met: \(check.reason ?? "Unknown")")
    }
}

/// Example: Quick boolean check
func example8_QuickCheck() async {
    if await NetworkHealth.isGoodEnoughFor(.largeDownload) {
        startDownload()
    } else {
        scheduleDownloadForLater()
    }
}

/// Example: Check before multiple operations
func example9_MultipleChecks() async {
    // Check different requirements
    let canBrowse = await NetworkHealth.isGoodEnoughFor(.basicBrowsing)
    let canStream = await NetworkHealth.isGoodEnoughFor(.videoStreaming)
    let canUpload = await NetworkHealth.isGoodEnoughFor(.largeUpload)

    print("Can browse: \(canBrowse)")
    print("Can stream: \(canStream)")
    print("Can upload: \(canUpload)")

    // Adjust UI accordingly
    updateUICapabilities(browse: canBrowse, stream: canStream, upload: canUpload)
}

/// Example: Pre-flight check for different operations
func example10_AdaptiveOperations() async {
    let snapshot = await NetworkHealth.snapshot()

    switch snapshot.quality {
    case .offline:
        print("Offline mode")
        enterOfflineMode()

    case .poor:
        print("Poor connection - text only")
        loadTextContent()

    case .moderate:
        print("Moderate connection - images OK")
        loadImagesWithCache()

    case .good, .excellent:
        print("Good connection - full experience")
        loadFullContent()
    }
}

// MARK: - Example 5: Real-World Use Cases

/// Use case: Download manager that adapts to network quality
actor DownloadManager {
    private var health = NetworkHealth.observable()
    private var downloads: [Download] = []

    func scheduleDownload(_ download: Download) async {
        downloads.append(download)
        await startNextDownloadIfPossible()
    }

    private func startNextDownloadIfPossible() async {
        guard let next = downloads.first(where: { !$0.isStarted }) else { return }

        let canStart: Bool

        switch next.priority {
        case .high:
            // High priority - start if any connection available
            canStart = await NetworkHealth.isGoodEnoughFor(.basicBrowsing)

        case .normal:
            // Normal priority - wait for good connection
            canStart = await NetworkHealth.isGoodEnoughFor(.largeDownload)

        case .low:
            // Low priority - only on WiFi and good quality
            let check = await NetworkHealth.check(
                minimumQuality: .good,
                requireWiFi: true
            )
            canStart = check.passed
        }

        if canStart {
            await startDownload(next)
        }
    }

    private func startDownload(_ download: Download) async {
        print("Starting download: \(download.name)")
        // Implementation
    }
}

struct Download {
    let name: String
    let priority: Priority
    var isStarted: Bool = false

    enum Priority {
        case high, normal, low
    }
}

/// Use case: API client with automatic retry based on network quality
actor APIClient {
    func performRequest<T>(_ request: Request<T>) async throws -> T {
        // Check network before making request
        let snapshot = await NetworkHealth.snapshot()

        guard snapshot.isOnline else {
            throw APIError.offline
        }

        // Adjust timeout based on quality
        let timeout: TimeInterval
        switch snapshot.quality {
        case .excellent, .good:
            timeout = 30
        case .moderate:
            timeout = 60
        case .poor:
            timeout = 120
        case .offline:
            throw APIError.offline
        }

        return try await makeRequest(request, timeout: timeout)
    }

    private func makeRequest<T>(_ request: Request<T>, timeout: TimeInterval) async throws -> T {
        // Implementation
        fatalError("Not implemented")
    }
}

struct Request<T> {
    // Request configuration
}

enum APIError: Error {
    case offline
}

// MARK: - Helper Functions (Stubs)

private func startVideoStream() {
    print("Starting video stream")
}

private func showQualityWarning(_ message: String?) {
    print("Warning: \(message ?? "Low quality")")
}

private func uploadLargeFile() {
    print("Uploading file")
}

private func startDownload() {
    print("Starting download")
}

private func scheduleDownloadForLater() {
    print("Download scheduled for later")
}

private func updateUICapabilities(browse: Bool, stream: Bool, upload: Bool) {
    print("UI capabilities updated")
}

private func enterOfflineMode() {
    print("Entering offline mode")
}

private func loadTextContent() {
    print("Loading text content")
}

private func loadImagesWithCache() {
    print("Loading images with cache")
}

private func loadFullContent() {
    print("Loading full content")
}

# Usage Examples

Real-world examples of using NetworkHealth in various scenarios.

## Table of Contents

1. [Stream Mode Examples](#stream-mode-examples)
2. [Snapshot Mode Examples](#snapshot-mode-examples)
3. [Observable Mode Examples](#observable-mode-examples)
4. [Health Check Examples](#health-check-examples)
5. [Real-World Use Cases](#real-world-use-cases)

---

## Stream Mode Examples

### Example 1: Basic Network Monitoring

Monitor network quality without speed tests:

```swift
func startMonitoring() async {
    for await state in NetworkHealth.stream() {
        print("Quality: \(state.quality.description)")
        print("Connection: \(state.connectionType)")
        print("Is expensive: \(state.isExpensive)")
        
        if state.quality == .offline {
            print("Network is offline!")
        } else if state.isDegradedQuality {
            print("Warning: Degraded network quality")
        }
    }
}
```

### Example 2: Stream with Speed Tests

Monitor with periodic speed measurements:

```swift
func monitorWithSpeedTests(networkProvider: NetworkProvider) async {
    for await state in NetworkHealth.stream(
        includeSpeedTests: true,
        speedTestInterval: 60,
        networkProvider: networkProvider
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
```

### Example 3: Background Monitoring Service

```swift
actor NetworkMonitoringService {
    private var monitoringTask: Task<Void, Never>?
    private var currentQuality: NetworkQuality = .offline
    
    func startMonitoring() {
        guard monitoringTask == nil else { return }
        
        monitoringTask = Task {
            for await state in NetworkHealth.stream() {
                await handleStateChange(state)
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
    
    func getCurrentQuality() -> NetworkQuality {
        currentQuality
    }
}

extension Notification.Name {
    static let networkQualityChanged = Notification.Name("networkQualityChanged")
}
```

---

## Snapshot Mode Examples

### Example 4: Quick Quality Check

```swift
func checkBeforeOperation() async {
    let snapshot = await NetworkHealth.snapshot()
    
    if snapshot.isOnline {
        print("Network available: \(snapshot.quality.description)")
        
        if snapshot.isGoodQuality {
            await startHeavyOperation()
        } else {
            print("Network quality not optimal")
        }
    } else {
        print("No network connection")
    }
}
```

### Example 5: Detailed Snapshot with Speed Test

```swift
func runSpeedTest(networkProvider: NetworkProvider) async {
    do {
        print("Running speed test...")
        let snapshot = try await NetworkHealth.detailedSnapshot(
            networkProvider: networkProvider
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
```

### Example 6: Pre-Flight Check for API Call

```swift
enum APIError: Error {
    case offline
}

func makeAPICall() async throws {
    let snapshot = await NetworkHealth.snapshot()
    
    guard snapshot.isOnline else {
        throw APIError.offline
    }
    
    if snapshot.isDegradedQuality {
        print("Warning: Network quality degraded, request may be slow")
    }
    
    // Proceed with API call
    try await performRequest()
}

func performRequest() async throws {
    // Your API call implementation
}
```

---

## Observable Mode Examples

### Example 7: SwiftUI Network Status View

```swift
import SwiftUI

struct NetworkStatusView: View {
    @State private var health = NetworkHealth.observable()
    
    var body: some View {
        VStack(spacing: 16) {
            // Quality indicator
            HStack {
                Circle()
                    .fill(qualityColor)
                    .frame(width: 20, height: 20)
                
                Text(health.currentQuality.description)
                    .font(.headline)
            }
            
            // Connection details
            VStack(alignment: .leading, spacing: 8) {
                Text("Connection: \(health.connectionType.description)")
                Text("Quality: \(health.currentQuality.description)")
                
                if health.isExpensive {
                    Text("Using cellular data")
                        .foregroundColor(.orange)
                }
            }
            
            // Refresh button
            Button("Refresh Quality") {
                Task {
                    await health.refreshQuality()
                }
            }
            .disabled(!health.isOnline)
        }
        .padding()
    }
    
    private var qualityColor: Color {
        switch health.currentQuality {
        case .offline: return .gray
        case .poor: return .red
        case .moderate: return .orange
        case .good: return .yellow
        case .excellent: return .green
        }
    }
}
```

### Example 8: SwiftUI with Speed Testing

```swift
struct NetworkSpeedView: View {
    @State private var health = NetworkHealth.observable(
        includeSpeedTests: true,
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
            
            if let error = health.lastError {
                Text("Error: \(error.localizedDescription)")
                    .foregroundColor(.red)
                    .font(.caption)
            }
        }
        .padding()
    }
    
    @ViewBuilder
    private func speedResults(_ snapshot: NetworkQualitySnapshot) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            if let latency = snapshot.latency {
                HStack {
                    Text("Latency:")
                    Spacer()
                    Text("\(String(format: "%.1f", latency)) ms")
                        .fontWeight(.semibold)
                }
            }
            
            if let download = snapshot.downloadSpeedMbps {
                HStack {
                    Text("Download:")
                    Spacer()
                    Text("\(String(format: "%.2f", download)) Mbps")
                        .fontWeight(.semibold)
                }
            }
            
            if let upload = snapshot.uploadSpeedMbps {
                HStack {
                    Text("Upload:")
                    Spacer()
                    Text("\(String(format: "%.2f", upload)) Mbps")
                        .fontWeight(.semibold)
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
}
```

### Example 9: Conditional Video Player

```swift
struct VideoPlayerView: View {
    @State private var health = NetworkHealth.observable()
    @State private var isPlaying = false
    
    var body: some View {
        VStack(spacing: 20) {
            if isPlaying {
                videoPlayerContent
            } else {
                playButton
            }
        }
        .padding()
    }
    
    @ViewBuilder
    private var videoPlayerContent: some View {
        VStack {
            // Your video player implementation
            Rectangle()
                .fill(Color.black)
                .aspectRatio(16/9, contentMode: .fit)
                .overlay(
                    Text("Playing...")
                        .foregroundColor(.white)
                )
            
            Button("Stop") {
                isPlaying = false
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
            .padding()
            .background(canPlayVideo ? Color.blue : Color.gray)
            .foregroundColor(.white)
            .cornerRadius(8)
            
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
```

---

## Health Check Examples

### Example 10: Video Streaming Check

```swift
func startVideoStream() async {
    let check = await NetworkHealth.check(requirement: .videoStreaming)
    
    if check.passed {
        print("Network is good for video streaming")
        await playVideo()
    } else {
        print("Cannot stream video: \(check.reason ?? "Unknown reason")")
        showQualityWarning(check.reason)
    }
}

func showQualityWarning(_ message: String?) {
    // Show alert to user
    print("Warning: \(message ?? "Network quality insufficient")")
}

func playVideo() async {
    // Start video playback
}
```

### Example 11: Custom Requirements Check

```swift
func uploadLargeFile() async {
    let check = await NetworkHealth.check(
        minimumQuality: .good,
        requireWiFi: true,
        allowExpensive: false
    )
    
    if check.passed {
        await performUpload()
    } else {
        print("Requirements not met: \(check.reason ?? "Unknown")")
        scheduleUploadForLater()
    }
}

func performUpload() async {
    print("Starting upload...")
}

func scheduleUploadForLater() {
    print("Upload scheduled for better network conditions")
}
```

### Example 12: Multiple Operation Checks

```swift
func updateUICapabilities() async {
    let canBrowse = await NetworkHealth.isGoodEnoughFor(.basicBrowsing)
    let canStream = await NetworkHealth.isGoodEnoughFor(.videoStreaming)
    let canUpload = await NetworkHealth.isGoodEnoughFor(.largeUpload)
    
    print("Can browse: \(canBrowse)")
    print("Can stream: \(canStream)")
    print("Can upload: \(canUpload)")
    
    // Update UI based on capabilities
    updateFeatureFlags(
        browsing: canBrowse,
        streaming: canStream,
        uploading: canUpload
    )
}

func updateFeatureFlags(browsing: Bool, streaming: Bool, uploading: Bool) {
    // Update your UI/feature flags
}
```

### Example 13: Adaptive Content Loading

```swift
func loadContent() async {
    let snapshot = await NetworkHealth.snapshot()
    
    switch snapshot.quality {
    case .offline:
        print("Offline mode")
        showCachedContent()
        
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

func showCachedContent() {
    // Load from cache
}

func loadTextContent() {
    // Load text only
}

func loadImagesWithCache() {
    // Load images with aggressive caching
}

func loadFullContent() {
    // Load all content including videos
}
```

---

## Real-World Use Cases

### Example 14: Download Manager

```swift
actor DownloadManager {
    private var downloads: [Download] = []
    
    func scheduleDownload(_ download: Download) async {
        downloads.append(download)
        await startNextDownloadIfPossible()
    }
    
    private func startNextDownloadIfPossible() async {
        guard let next = downloads.first(where: { !$0.isStarted }) else {
            return
        }
        
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
        } else {
            print("Waiting for better network conditions for: \(next.name)")
        }
    }
    
    private func startDownload(_ download: Download) async {
        print("Starting download: \(download.name)")
        // Implement download logic
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
```

### Example 15: API Client with Adaptive Timeout

```swift
actor APIClient {
    func performRequest<T>(_ request: Request<T>) async throws -> T {
        let snapshot = await NetworkHealth.snapshot()
        
        guard snapshot.isOnline else {
            throw APIError.offline
        }
        
        // Adjust timeout based on quality
        let timeout: TimeInterval = switch snapshot.quality {
        case .excellent, .good: 30
        case .moderate: 60
        case .poor: 120
        case .offline: throw APIError.offline
        }
        
        print("Making request with \(timeout)s timeout based on \(snapshot.quality) quality")
        
        return try await makeRequest(request, timeout: timeout)
    }
    
    private func makeRequest<T>(_ request: Request<T>, timeout: TimeInterval) async throws -> T {
        // Implement actual request with timeout
        fatalError("Implementation needed")
    }
}

struct Request<T> {
    let url: URL
    let method: String
}

enum APIError: Error {
    case offline
    case timeout
}
```

### Example 16: Image Loading Service

```swift
actor ImageLoadingService {
    func loadImage(url: URL) async -> UIImage? {
        let snapshot = await NetworkHealth.snapshot()
        
        guard snapshot.isOnline else {
            return loadCachedImage(url: url)
        }
        
        let quality: ImageQuality = switch snapshot.quality {
        case .offline, .poor:
            .thumbnail
        case .moderate:
            .medium
        case .good, .excellent:
            .full
        }
        
        return await downloadImage(url: url, quality: quality)
    }
    
    private func loadCachedImage(url: URL) -> UIImage? {
        // Load from cache
        nil
    }
    
    private func downloadImage(url: URL, quality: ImageQuality) async -> UIImage? {
        print("Downloading \(quality) quality image")
        // Implement download
        nil
    }
    
    enum ImageQuality {
        case thumbnail, medium, full
    }
}
```

### Example 17: Video Streaming Adapter

```swift
@MainActor
class VideoStreamingManager: ObservableObject {
    @Published var currentBitrate: Int = 1_000_000
    @Published var canStream: Bool = false
    
    private let health = NetworkHealth.observable()
    
    init() {
        Task {
            await monitorAndAdapt()
        }
    }
    
    private func monitorAndAdapt() async {
        for await state in NetworkHealth.stream() {
            adaptBitrate(for: state.quality)
            canStream = state.isGoodQuality
        }
    }
    
    private func adaptBitrate(for quality: NetworkQuality) {
        currentBitrate = switch quality {
        case .offline:
            0
        case .poor:
            500_000      // 0.5 Mbps
        case .moderate:
            2_000_000    // 2 Mbps
        case .good:
            5_000_000    // 5 Mbps
        case .excellent:
            10_000_000   // 10 Mbps
        }
        
        print("Adapted bitrate to: \(currentBitrate / 1_000_000) Mbps")
    }
}
```

---

## Tips and Best Practices

### ✅ DO:

1. **Use appropriate mode for your use case**:
   - Stream: Background monitoring
   - Snapshot: Quick checks
   - Observable: UI binding
   - Health Check: Operation gating

2. **Handle offline state gracefully**:
   ```swift
   if !snapshot.isOnline {
       showOfflineMode()
       return
   }
   ```

3. **Check expensive connections before large operations**:
   ```swift
   if snapshot.isExpensive {
       showCellularWarning()
   }
   ```

4. **Set reasonable speed test intervals** (60-120 seconds):
   ```swift
   NetworkHealth.stream(
       includeSpeedTests: true,
       speedTestInterval: 120  // Good balance
   )
   ```

### ❌ DON'T:

1. **Don't run speed tests too frequently** (wastes battery and data)
2. **Don't ignore offline state** - always handle it
3. **Don't perform heavy operations without checking `isExpensive`**
4. **Don't forget to handle errors** when using detailed snapshots

---

## Next Steps

- 📚 [Complete API Reference](API.md)
- 🔧 [Architecture Overview](Architecture.md)
- 📖 [Quick Start Guide](QuickStart.md)

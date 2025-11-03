<p align="center">
  <img src="Docs/banner.png" alt="NetworkHealth Logo" width="600"/>
</p>

<h1 align="center">NetworkHealth</h1>

<p align="center">
A Swift package for intelligent network quality monitoring with automatic adaptation, speed testing, and comprehensive quality assessment.
</p>

<p align="center">
  <a href="https://swift.org">
    <img src="https://img.shields.io/badge/Swift-6.1+-orange.svg?logo=swift" alt="Swift 6.1+" />
  </a>
  <a href="https://swift.org/package-manager/">
    <img src="https://img.shields.io/badge/SPM-compatible-green.svg?logo=swift" alt="SPM" />
  </a>
  <img src="https://img.shields.io/badge/platforms-iOS%2017%2B%20%7C%20iPadOS%2017%2B-orange.svg" alt="Platforms" />
  <a href="LICENSE">
    <img src="https://img.shields.io/badge/license-MIT-lightgrey.svg" alt="License" />
  </a>
  <img src="https://img.shields.io/badge/concurrency-async%2Fawait%20%7C%20actors-purple.svg" alt="Concurrency" />
</p>
<p align="center">
  <a href="README-ru.md">Русская версия</a>
</p>

## Overview

NetworkHealth provides a simple, intuitive API for monitoring network quality and adapting your app's behavior based on connection characteristics. It automatically detects connection types (WiFi, Cellular, Ethernet), measures speed when needed, and provides quality assessments from Offline to Excellent.

## Key Features

- 🌐 **Connection Detection** - WiFi, Cellular (2G/3G/LTE/5G), Ethernet
- 📊 **Quality Assessment** - Five-level quality scale (Offline to Excellent)
- ⚡ **Speed Testing** - Protocol-based speed testing (implement `SpeedTester` protocol or use SpeedTestCore)
- 📈 **Continuous Monitoring** - Real-time network state updates via AsyncStream
- 🎯 **Operation Requirements** - Predefined checks for common operations
- 💾 **Measurement History** - Automatic snapshot storage and statistics
- 🔄 **SwiftUI Integration** - Observable wrapper for seamless UI updates
- 🧵 **Thread-Safe** - Actor-based architecture for safe concurrency

## Quick Start

### Installation

Add NetworkHealth to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/yourusername/NetworkHealth.git", from: "0.0.1")
]
```

### Basic Usage

#### 1. Snapshot - Quick Check

```swift
import NetworkHealth

// Simple quality check
let snapshot = await NetworkHealth.snapshot()

if snapshot.isGoodQuality {
    startDownload()
} else {
    showLowQualityWarning()
}
```

#### 2. Stream - Continuous Monitoring

```swift
// Real-time monitoring
for await state in NetworkHealth.stream() {
    print("Quality: \(state.quality)")

    if state.isDegradedQuality {
        adaptUIForLowQuality()
    }
}
```

#### 3. Observable - SwiftUI Integration

```swift
struct NetworkStatusView: View {
    @State private var health = NetworkHealth.observable()

    var body: some View {
        HStack {
            Circle()
                .fill(health.isOnline ? .green : .red)
                .frame(width: 10)
            Text(health.currentQuality.description)
        }
    }
}
```

#### 4. Health Check - Operation Gating

```swift
// Check if network meets requirements
if await NetworkHealth.isGoodEnoughFor(.videoStreaming) {
    startVideoPlayer()
} else {
    showBufferingWarning()
}
```

## Quality Levels

| Level | Description | Use Cases |
|-------|-------------|-----------|
| **Offline** | No connection | Offline mode, cached content only |
| **Poor** | 2G, unstable 3G | Text messages, minimal data |
| **Moderate** | 3G, weak LTE | Images, social media feeds |
| **Good** | LTE, 5G, good WiFi | Video streaming, video calls |
| **Excellent** | Fast WiFi, Ethernet | HD video, large file transfers |

## Real-World Examples

### Adaptive Content Loading

```swift
let snapshot = await NetworkHealth.snapshot()

switch snapshot.quality {
case .offline:
    showOfflineContent()
case .poor:
    loadTextOnly()
case .moderate:
    loadImagesWithCompression()
case .good, .excellent:
    loadFullResolutionContent()
}
```

### Download Manager

```swift
actor DownloadManager {
    func scheduleDownload(_ file: File) async {
        switch file.priority {
        case .high:
            // Start immediately if online
            if await NetworkHealth.isGoodEnoughFor(.basicBrowsing) {
                startDownload(file)
            }
        case .normal:
            // Wait for good connection
            if await NetworkHealth.isGoodEnoughFor(.largeDownload) {
                startDownload(file)
            }
        }
    }
}
```

## Speed Testing (Optional)

NetworkHealth supports optional speed testing through the `SpeedTester` protocol. You can implement your own speed testing logic or use existing implementations like SpeedTestCore.

### Implementing Custom Speed Tester

```swift
import NetworkHealth

struct MyCustomSpeedTester: SpeedTester {
    func measureSpeed() async throws -> SpeedTestResult {
        // Your custom implementation
        let latency = try await measureLatency()
        let downloadSpeed = try await measureDownloadSpeed()
        let uploadSpeed = try await measureUploadSpeed()
        
        return SpeedTestResult(
            latency: latency,
            downloadSpeedMbps: downloadSpeed,
            uploadSpeedMbps: uploadSpeed
        )
    }
}
```

### Using Speed Tester

```swift
// Use a mock tester for development/testing
let mockTester = MockSpeedTester.goodLTE

// Stream with automatic speed tests (improves quality accuracy)
for await state in NetworkHealth.stream(
    speedTester: mockTester,
    speedTestInterval: 60
) {
    print("Quality: \(state.quality)")  // Quality considers speed measurements
    
    // Note: For explicit speed metrics, use detailedSnapshot() or observable()
}

// Get detailed speed measurements
let speedTester = MyCustomSpeedTester()
let snapshot = try await NetworkHealth.detailedSnapshot(speedTester: speedTester)
print("Download: \(snapshot.downloadSpeedMbps ?? 0) Mbps")
print("Upload: \(snapshot.uploadSpeedMbps ?? 0) Mbps")
print("Latency: \(snapshot.latency ?? 0) ms")
```

### Available Mock Testers

NetworkHealth includes built-in mocks for testing:
- `MockSpeedTester.excellent5G` - 100 Mbps download
- `MockSpeedTester.goodLTE` - 20 Mbps download
- `MockSpeedTester.moderate3G` - 3 Mbps download
- `MockSpeedTester.poor2G` - 0.3 Mbps download
- `MockSpeedTester.excellentWiFi` - 150 Mbps download

## Documentation

- 📖 [Quick Start Guide](QUICK_START.md)
- 📚 [Detailed Documentation (EN)](Docs/en/README.md)
- 🇷🇺 [Русская документация](Docs/ru/README.md)

## Requirements

- iOS 17.0+ / macOS 15.0+
- Swift 6.1+
- Xcode 16.0+

## License

NetworkHealth is available under the MIT license. See the LICENSE file for more info.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

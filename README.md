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
  <img src="https://img.shields.io/badge/platforms-iOS%2017%2B%20%7C%20iPadOS%2017%2B-bluorange.svg" alt="Platforms" />
  <a href="LICENSE">
    <img src="https://img.shields.io/badge/license-MIT-lightgrey.svg" alt="License" />
  </a>
  <img src="https://img.shields.io/badge/concurrency-async%2Fawait%20%7C%20actors-purple.svg" alt="Concurrency" />
</p>

## Overview

NetworkHealth provides a simple, intuitive API for monitoring network quality and adapting your app's behavior based on connection characteristics. It automatically detects connection types (WiFi, Cellular, Ethernet), measures speed when needed, and provides quality assessments from Offline to Excellent.

## Key Features

- 🌐 **Connection Detection** - WiFi, Cellular (2G/3G/LTE/5G), Ethernet
- 📊 **Quality Assessment** - Five-level quality scale (Offline to Excellent)
- ⚡ **Speed Testing** - Optional integration with SpeedTestCore
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
    .package(url: "https://github.com/yourusername/NetworkHealth.git", from: "1.0.0")
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

```swift
import SpeedTestCore

// Stream with automatic speed tests
for await state in NetworkHealth.stream(
    includeSpeedTests: true,
    speedTestInterval: 60,
    networkProvider: myNetworkProvider
) {
    if let speed = state.downloadSpeedMbps {
        print("Download speed: \(speed) Mbps")
    }
}
```

## Documentation

- 📖 [Quick Start Guide](QUICK_START.md)
- 📚 [Detailed Documentation (EN)](Docs/en/README.md)
- 🇷🇺 [Русская документация](Docs/ru/README.md)

## Requirements

- iOS 15.0+
- Swift 5.9+
- Xcode 15.0+

## License

NetworkHealth is available under the MIT license. See the LICENSE file for more info.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

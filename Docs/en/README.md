# NetworkHealth - Complete Documentation

Welcome to the comprehensive documentation for NetworkHealth, a Swift package for intelligent network quality monitoring.

## Table of Contents

1. [Quick Start](QuickStart.md) - Get up and running in minutes
2. [Installation](Installation.md) - Detailed installation instructions
3. [API Reference](API.md) - Complete API documentation
4. [Architecture](Architecture.md) - Internal architecture and design principles
5. [Examples](Examples.md) - Real-world usage examples
6. [Migration Guide](Migration.md) - Migrating from NetworkHealthCoordinator

## Overview

NetworkHealth provides a simple, powerful API for monitoring network quality and adapting your app's behavior based on connection characteristics. It automatically detects connection types, measures speed when needed, and provides quality assessments.

### Key Features

- **Simple API** - Four intuitive usage patterns (Stream, Snapshot, Observable, Health Check)
- **Quality Assessment** - Five-level quality scale from Offline to Excellent
- **Connection Detection** - WiFi, Cellular (2G/3G/LTE/5G), Ethernet
- **Speed Testing** - Optional integration with SpeedTestCore
- **Real-time Monitoring** - AsyncStream-based continuous updates
- **SwiftUI Integration** - Observable wrapper for seamless UI updates
- **Thread-Safe** - Actor-based architecture for safe concurrency
- **Measurement History** - Automatic snapshot storage and statistics

## Quick Example

```swift
import NetworkHealth

// Simple quality check
let snapshot = await NetworkHealth.snapshot()

if snapshot.isGoodQuality {
    startDownload()
}

// Continuous monitoring
for await state in NetworkHealth.stream() {
    print("Quality: \(state.quality)")
}

// SwiftUI integration
@State private var health = NetworkHealth.observable()

// Operation requirements
if await NetworkHealth.isGoodEnoughFor(.videoStreaming) {
    startVideo()
}
```

## Usage Patterns

### 1. Stream Mode
**When to use**: Background monitoring, reactive UI updates

```swift
for await state in NetworkHealth.stream() {
    adaptToNetworkQuality(state.quality)
}
```

### 2. Snapshot Mode
**When to use**: Pre-flight checks, periodic quality assessment

```swift
let snapshot = await NetworkHealth.snapshot()
guard snapshot.isOnline else { return }
```

### 3. Observable Mode
**When to use**: SwiftUI views, data binding

```swift
@State private var health = NetworkHealth.observable()
```

### 4. Health Check Mode
**When to use**: Operation gating, feature flags

```swift
if await NetworkHealth.isGoodEnoughFor(.videoStreaming) {
    enableFeature()
}
```

## Quality Levels

| Level | Network Type | Latency | Speed | Use Cases |
|-------|-------------|---------|-------|-----------|
| **Offline** | None | - | - | Cached content only |
| **Poor** | 2G, unstable 3G | >1500ms | <1 Mbps | Text messages |
| **Moderate** | 3G, weak LTE | 500-1500ms | 1-5 Mbps | Images, social feeds |
| **Good** | LTE, 5G, WiFi | 100-500ms | 5-10 Mbps | Video streaming |
| **Excellent** | Fast WiFi, Ethernet | <100ms | 10+ Mbps | HD video, large files |

## Getting Started

1. **Installation**: Add NetworkHealth to your project via Swift Package Manager
2. **Quick Start**: Follow the [Quick Start Guide](QuickStart.md)
3. **Integration**: Check out [Examples](Examples.md) for your use case
4. **API Reference**: Explore the full [API documentation](API.md)

## Requirements

- iOS 15.0+
- Swift 5.9+
- Xcode 15.0+

## Support

- 📖 [Quick Start Guide](QuickStart.md)
- 📚 [API Reference](API.md)
- 💡 [Examples](Examples.md)
- 🔧 [Architecture](Architecture.md)

## License

NetworkHealth is available under the MIT license. See the LICENSE file for more info.

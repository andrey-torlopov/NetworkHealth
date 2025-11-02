# Quick Start Guide

Get started with NetworkHealth in under 5 minutes.

## Three Simple Usage Patterns

### 1️⃣ Stream - Continuous Monitoring

Use this when you need to continuously monitor network quality changes in real-time.

```swift
// Basic monitoring
for await state in NetworkHealth.stream() {
    print("Quality: \(state.quality)")
}

// With speed testing
for await state in NetworkHealth.stream(
    includeSpeedTests: true,
    speedTestInterval: 60,
    networkProvider: provider
) {
    print("Speed: \(state.downloadSpeedMbps ?? 0) Mbps")
}
```

**When to use**: Background monitoring, reactive UI updates

---

### 2️⃣ Snapshot - One-Time Check

Use this for quick, one-time network quality checks.

```swift
// Quick check
let snapshot = await NetworkHealth.snapshot()
if snapshot.isGoodQuality {
    startDownload()
}

// Detailed check with speed test
let detailed = try await NetworkHealth.detailedSnapshot(
    networkProvider: provider
)
print("Ping: \(detailed.latency ?? 0)ms")
```

**When to use**: Pre-flight checks, periodic quality assessment

---

### 3️⃣ Observable - For SwiftUI

Use this when you need to bind network state to UI components.

```swift
struct MyView: View {
    @State private var health = NetworkHealth.observable()
    
    var body: some View {
        VStack {
            Text("Quality: \(health.currentQuality.description)")
            
            Button("Test Speed") {
                Task { await health.performMeasurement() }
            }
        }
    }
}
```

**When to use**: SwiftUI views, UIKit data binding

---

### 4️⃣ Health Check - Requirements Validation

Use this to check if network meets requirements for specific operations.

```swift
// Ready for video streaming?
if await NetworkHealth.isGoodEnoughFor(.videoStreaming) {
    startVideo()
}

// Custom requirements
let check = await NetworkHealth.check(
    minimumQuality: .good,
    requireWiFi: true
)
if check.passed {
    uploadLargeFile()
}
```

**When to use**: Operation gating, feature flags

---

## Quality Levels

| Quality | Description | Examples |
|---------|-------------|----------|
| `offline` | No connection | - |
| `poor` | 2G, unstable 3G | Text only |
| `moderate` | Stable 3G, weak LTE | Text + images |
| `good` | LTE, 5G, good WiFi | Video, streaming |
| `excellent` | Fast WiFi, Ethernet | No limitations |

---

## Real-World Examples

### Adaptive Content Loading

```swift
let snapshot = await NetworkHealth.snapshot()

switch snapshot.quality {
case .offline:
    showOfflineMode()
case .poor:
    loadTextOnly()
case .moderate:
    loadWithImages()
case .good, .excellent:
    loadFullContent()
}
```

### Pre-Flight Check for API Request

```swift
guard await NetworkHealth.isGoodEnoughFor(.basicBrowsing) else {
    throw NetworkError.offline
}

try await makeAPICall()
```

### Conditional UI

```swift
var body: some View {
    VideoPlayerView()
        .disabled(!health.isGoodQuality)
    
    if health.isDegradedQuality {
        Text("Low quality - video may buffer")
            .foregroundColor(.orange)
    }
}
```

---

## Important Properties of NetworkHealthState

```swift
state.quality              // .offline, .poor, .moderate, .good, .excellent
state.connectionType       // .wifi, .cellular(.lte), .wiredEthernet, etc.
state.isOnline            // true if quality != .offline
state.isGoodQuality       // true if quality >= .good
state.isDegradedQuality   // true if poor or moderate
state.isExpensive         // true for cellular with data limits
state.latency             // Ping in ms (if measured)
state.downloadSpeedMbps   // Download speed (if measured)
state.uploadSpeedMbps     // Upload speed (if measured)
```

---

## Predefined Operation Requirements

```swift
.basicBrowsing      // Poor or better
.imageLoading       // Moderate or better
.videoStreaming     // Good or better
.largeDownload      // Good or better, preferably WiFi
.largeUpload        // Good or better, requires WiFi
```

---

## Best Practices

✅ **DO**:
- Use `snapshot()` for quick checks
- Check `isExpensive` before large downloads
- Use `stream()` for reactive UI
- Set reasonable test intervals (60-120 sec)

❌ **DON'T**:
- Don't run speed tests too frequently (wastes data and battery)
- Don't forget to handle offline state
- Don't perform heavy operations on cellular without warning

---

## Migration from NetworkHealthCoordinator

### Before (Complex):

```swift
let config = NetworkHealthCoordinator.Configuration(
    speedTester: adapter,
    minimumSpeedCheckInterval: 120
)
let checker = NetworkHealthCoordinator(configuration: config)
for await state in await checker.stateStream() {
    // ...
}
```

### After (Simple):

```swift
for await state in NetworkHealth.stream(
    includeSpeedTests: true,
    speedTestInterval: 120,
    networkProvider: provider
) {
    // ...
}
```

---

## Next Steps

- 📚 [Complete API Reference](API.md)
- 💡 [More Examples](Examples.md)
- 🔧 [Architecture Overview](Architecture.md)
- 📦 [Installation Guide](Installation.md)

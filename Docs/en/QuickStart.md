# Quick Start Guide

Get started with NetworkHealth in under 5 minutes.

## Three Simple Usage Patterns

### 1️⃣ Stream - Continuous Monitoring

Use this when you need to continuously monitor network quality changes in real-time.

```swift
// Basic monitoring (connection type and quality based on type)
for await state in NetworkHealth.stream() {
    print("Quality: \(state.quality)")
    print("Connection: \(state.connectionType)")
}

// With speed testing (improves quality accuracy internally)
let speedTester = MockSpeedTester.goodLTE
for await state in NetworkHealth.stream(
    speedTester: speedTester,
    speedTestInterval: 60
) {
    print("Quality: \(state.quality)")
    // Note: Speed metrics are not exposed in stream mode.
    // Use detailedSnapshot() or observable().performMeasurement() for explicit metrics.
}
```

**When to use**: Background monitoring, reactive UI updates

**Note**: Stream mode focuses on connection type changes. Speed measurements improve quality accuracy but are not directly exposed in the stream.

---

### 2️⃣ Snapshot - One-Time Check

Use this for quick, one-time network quality checks.

```swift
// Quick check (no speed test)
let snapshot = await NetworkHealth.snapshot()
if snapshot.isGoodQuality {
    startDownload()
}

// Detailed check with speed test
let speedTester = MockSpeedTester.goodLTE
let detailed = try await NetworkHealth.detailedSnapshot(
    speedTester: speedTester
)
print("Latency: \(detailed.latency ?? 0)ms")
print("Download: \(detailed.downloadSpeedMbps ?? 0) Mbps")
print("Upload: \(detailed.uploadSpeedMbps ?? 0) Mbps")
```

**When to use**: Pre-flight checks, periodic quality assessment, explicit speed measurements

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
state.latency             // Always nil in stream mode - use detailedSnapshot()
state.downloadSpeedMbps   // Always nil in stream mode - use detailedSnapshot()
state.uploadSpeedMbps     // Always nil in stream mode - use detailedSnapshot()
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

## Migration from Old API

### Before (Old API - Deprecated):

```swift
// Old API with networkProvider parameter
for await state in NetworkHealth.stream(
    includeSpeedTests: true,
    speedTestInterval: 120,
    networkProvider: provider
) {
    // ...
}
```

### After (Current API):

```swift
// New API with speedTester protocol
let speedTester = MyCustomSpeedTester()  // Or use MockSpeedTester
for await state in NetworkHealth.stream(
    speedTester: speedTester,
    speedTestInterval: 120
) {
    // ...
}
```

**Key Changes:**
- Removed `includeSpeedTests` parameter - pass `speedTester` instead
- Replaced `networkProvider` with `speedTester` (protocol-based)
- Speed metrics no longer exposed in stream - use `detailedSnapshot()` or `observable().performMeasurement()`

---

## Next Steps

- 📚 [Complete API Reference](API.md)
- 💡 [More Examples](Examples.md)
- 🔧 [Architecture Overview](Architecture.md)
- 📦 [Installation Guide](Installation.md)

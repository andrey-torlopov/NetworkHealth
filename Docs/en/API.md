# API Reference

Complete API reference for NetworkHealth.

## Table of Contents

- [NetworkHealth (Main API)](#networkhealth-main-api)
- [NetworkHealthState](#networkhealthstate)
- [NetworkQuality](#networkquality)
- [ConnectionRawData](#connectionrawdata)
- [OperationRequirement](#operationrequirement)
- [HealthCheckResult](#healthcheckresult)
- [NetworkQualityMonitor](#networkqualitymonitor)

---

## NetworkHealth (Main API)

The main facade for network quality monitoring.

### Stream Mode

Continuous monitoring with AsyncStream.

```swift
static func stream(
    includeSpeedTests: Bool = false,
    speedTestInterval: TimeInterval = 120,
    networkProvider: NetworkProvider? = nil
) -> AsyncStream<NetworkHealthState>
```

**Parameters:**
- `includeSpeedTests`: Enable automatic speed testing (default: false)
- `speedTestInterval`: Interval between speed tests in seconds (default: 120)
- `networkProvider`: Network provider for speed testing (required if includeSpeedTests is true)

**Returns:** AsyncStream that emits NetworkHealthState on network changes

**Example:**
```swift
for await state in NetworkHealth.stream() {
    print("Quality changed to: \(state.quality)")
}
```

---

### Snapshot Mode

One-time quality check.

#### Quick Snapshot

```swift
static func snapshot() async -> NetworkHealthState
```

Returns current network state without performing speed test.

**Example:**
```swift
let snapshot = await NetworkHealth.snapshot()
if snapshot.isOnline {
    startOperation()
}
```

#### Detailed Snapshot

```swift
static func detailedSnapshot(
    networkProvider: NetworkProvider
) async throws -> NetworkQualitySnapshot
```

Performs speed test and returns detailed snapshot.

**Parameters:**
- `networkProvider`: Network provider for speed testing

**Returns:** Detailed snapshot with speed measurements

**Throws:** 
- `NetworkQualityError.offline` if device is offline
- `NetworkQualityError.measurementFailed` if speed test fails

**Example:**
```swift
do {
    let snapshot = try await NetworkHealth.detailedSnapshot(
        networkProvider: provider
    )
    print("Download: \(snapshot.downloadSpeedMbps ?? 0) Mbps")
} catch {
    print("Failed: \(error)")
}
```

---

### Observable Mode

Observable wrapper for SwiftUI/UIKit.

```swift
static func observable(
    includeSpeedTests: Bool = false,
    speedTestInterval: TimeInterval = 120,
    networkProvider: NetworkProvider? = nil
) -> NetworkQualityMonitor
```

**Parameters:**
- `includeSpeedTests`: Enable automatic speed testing (default: false)
- `speedTestInterval`: Interval between speed tests in seconds (default: 120)
- `networkProvider`: Network provider for speed testing

**Returns:** Observable NetworkQualityMonitor instance

**Example:**
```swift
@State private var health = NetworkHealth.observable()

var body: some View {
    Text("Quality: \(health.currentQuality.description)")
}
```

---

### Health Check Mode

Check if network meets operation requirements.

#### Predefined Requirements

```swift
static func isGoodEnoughFor(
    _ requirement: OperationRequirement
) async -> Bool
```

**Parameters:**
- `requirement`: Predefined operation requirement

**Returns:** true if network meets the requirement

**Example:**
```swift
if await NetworkHealth.isGoodEnoughFor(.videoStreaming) {
    startVideo()
}
```

#### Custom Requirements

```swift
static func check(
    minimumQuality: NetworkQuality,
    requireWiFi: Bool = false,
    allowExpensive: Bool = true
) async -> HealthCheckResult
```

**Parameters:**
- `minimumQuality`: Minimum required quality level
- `requireWiFi`: Require WiFi connection (default: false)
- `allowExpensive`: Allow expensive (cellular) connections (default: true)

**Returns:** HealthCheckResult with pass/fail status and reason

**Example:**
```swift
let check = await NetworkHealth.check(
    minimumQuality: .good,
    requireWiFi: true
)

if check.passed {
    uploadFile()
} else {
    print("Cannot upload: \(check.reason ?? "Unknown")")
}
```

#### Check with Predefined Requirement

```swift
static func check(
    requirement: OperationRequirement
) async -> HealthCheckResult
```

---

## NetworkHealthState

Simplified network state structure.

### Properties

```swift
public struct NetworkHealthState {
    let quality: NetworkQuality
    let connectionType: ConnectionRawData
    let isExpensive: Bool
    let latency: Double?
    let downloadSpeedMbps: Double?
    let uploadSpeedMbps: Double?
}
```

**Properties:**
- `quality`: Current network quality level
- `connectionType`: Type of connection (WiFi, Cellular, etc.)
- `isExpensive`: true for cellular with data limits
- `latency`: Round-trip time in milliseconds (if measured)
- `downloadSpeedMbps`: Download speed in Mbps (if measured)
- `uploadSpeedMbps`: Upload speed in Mbps (if measured)

### Computed Properties

```swift
var isOnline: Bool              // quality != .offline
var isGoodQuality: Bool         // quality >= .good
var isDegradedQuality: Bool     // quality == .poor || .moderate
```

---

## NetworkQuality

Five-level quality assessment.

```swift
public enum NetworkQuality: Int, Comparable, Sendable {
    case offline = 0
    case poor = 1
    case moderate = 2
    case good = 3
    case excellent = 4
}
```

### Quality Criteria

| Level | Latency | Download Speed | Use Cases |
|-------|---------|----------------|-----------|
| **offline** | - | - | No connection |
| **poor** | >1500ms | <1 Mbps | Text only |
| **moderate** | 500-1500ms | 1-5 Mbps | Images, social feeds |
| **good** | 100-500ms | 5-10 Mbps | Video streaming |
| **excellent** | <100ms | 10+ Mbps | HD video, large files |

### Comparison

NetworkQuality is Comparable:

```swift
if quality >= .good {
    enableFeature()
}
```

---

## ConnectionRawData

Connection type information.

```swift
public enum ConnectionRawData: Equatable, Sendable {
    case wifi
    case wiredEthernet
    case cellular(CellularType)
    case unknown
}

public enum CellularType: String, Sendable {
    case twoG = "2G"
    case threeG = "3G"
    case lte = "LTE"
    case fiveG = "5G"
    case unknown
}
```

**Examples:**
```swift
switch state.connectionType {
case .wifi:
    print("Connected via WiFi")
case .cellular(.lte):
    print("Connected via LTE")
case .wiredEthernet:
    print("Connected via Ethernet")
default:
    print("Unknown connection")
}
```

---

## OperationRequirement

Predefined requirements for common operations.

```swift
public enum OperationRequirement {
    case basicBrowsing
    case imageLoading
    case videoStreaming
    case largeDownload
    case largeUpload
    case custom(minimumQuality: NetworkQuality, requireWiFi: Bool, allowExpensive: Bool)
}
```

### Predefined Requirements

| Requirement | Min Quality | WiFi Required | Allows Cellular |
|-------------|-------------|---------------|-----------------|
| `basicBrowsing` | Poor | No | Yes |
| `imageLoading` | Moderate | No | Yes |
| `videoStreaming` | Good | No | Yes |
| `largeDownload` | Good | Preferred | Warning |
| `largeUpload` | Good | Yes | No |

**Example:**
```swift
// Using predefined requirement
if await NetworkHealth.isGoodEnoughFor(.videoStreaming) {
    startVideo()
}

// Custom requirement
if await NetworkHealth.isGoodEnoughFor(.custom(
    minimumQuality: .moderate,
    requireWiFi: false,
    allowExpensive: true
)) {
    loadImages()
}
```

---

## HealthCheckResult

Result of health check with explanation.

```swift
public struct HealthCheckResult {
    public let passed: Bool
    public let reason: String?
}
```

**Properties:**
- `passed`: true if network meets requirements
- `reason`: Explanation if check failed (e.g., "Network quality too low", "WiFi required")

**Example:**
```swift
let check = await NetworkHealth.check(requirement: .videoStreaming)

if !check.passed {
    showAlert("Cannot stream video: \(check.reason ?? "Unknown reason")")
}
```

---

## NetworkQualityMonitor

Observable wrapper for SwiftUI/UIKit integration.

```swift
@Observable
@MainActor
public final class NetworkQualityMonitor {
    public private(set) var currentQuality: NetworkQuality
    public private(set) var connectionType: ConnectionRawData
    public private(set) var isExpensive: Bool
    public private(set) var lastSnapshot: NetworkQualitySnapshot?
    public private(set) var isMeasuring: Bool
    public private(set) var lastError: Error?
}
```

### Properties

- `currentQuality`: Current network quality
- `connectionType`: Current connection type
- `isExpensive`: true for expensive connections
- `lastSnapshot`: Last measurement snapshot (if available)
- `isMeasuring`: true when speed test is in progress
- `lastError`: Last error encountered (if any)

### Computed Properties

```swift
var isOnline: Bool
var isGoodQuality: Bool
var isDegradedQuality: Bool
```

### Methods

#### Refresh Quality

```swift
func refreshQuality() async
```

Updates current quality without speed test.

#### Perform Measurement

```swift
func performMeasurement() async
```

Performs speed test and updates measurements.

### SwiftUI Example

```swift
struct NetworkView: View {
    @State private var health = NetworkHealth.observable(
        includeSpeedTests: true,
        speedTestInterval: 60,
        networkProvider: provider
    )
    
    var body: some View {
        VStack {
            Text("Quality: \(health.currentQuality.description)")
            
            if let snapshot = health.lastSnapshot {
                Text("Speed: \(snapshot.downloadSpeedMbps ?? 0) Mbps")
            }
            
            Button("Test Speed") {
                Task { await health.performMeasurement() }
            }
            .disabled(health.isMeasuring)
            
            if health.isMeasuring {
                ProgressView("Testing...")
            }
        }
    }
}
```

---

## Error Handling

### NetworkQualityError

```swift
public enum NetworkQualityError: Error {
    case offline
    case speedTesterNotConfigured
    case measurementFailed(Error)
    case measurementTimeout
    case invalidConfiguration(String)
}
```

**Error Cases:**
- `offline`: Device has no network connection
- `speedTesterNotConfigured`: Speed tester not provided but required
- `measurementFailed`: Speed measurement failed (with underlying error)
- `measurementTimeout`: Speed test timed out
- `invalidConfiguration`: Configuration is invalid

**Example:**
```swift
do {
    let snapshot = try await NetworkHealth.detailedSnapshot(
        networkProvider: provider
    )
} catch NetworkQualityError.offline {
    showOfflineAlert()
} catch NetworkQualityError.measurementFailed(let error) {
    print("Test failed: \(error)")
} catch {
    print("Unexpected error: \(error)")
}
```

---

## Thread Safety

All NetworkHealth APIs are async and thread-safe. They can be called from any context:

```swift
// From main actor
@MainActor
func updateUI() async {
    let state = await NetworkHealth.snapshot()
    updateQualityIndicator(state.quality)
}

// From background actor
actor DataSync {
    func syncIfPossible() async {
        if await NetworkHealth.isGoodEnoughFor(.largeUpload) {
            await syncData()
        }
    }
}
```

---

## Performance Considerations

- **Stream Mode**: Lightweight, only monitors system network path changes (~100ms updates)
- **Snapshot Mode**: Near-instant (<100ms), no active measurements
- **Detailed Snapshot**: 2-5 seconds depending on network speed
- **Speed Tests**: Use reasonable intervals (60-120 seconds) to conserve battery and data

---

## See Also

- [Quick Start Guide](QuickStart.md)
- [Examples](Examples.md)
- [Architecture](Architecture.md)
- [Migration Guide](Migration.md)

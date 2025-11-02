# Installation Guide

## Swift Package Manager (Recommended)

NetworkHealth is distributed via Swift Package Manager. This is the recommended way to integrate the library into your project.

### Adding to Xcode Project

1. Open your project in Xcode
2. Go to **File → Add Package Dependencies...**
3. Enter the repository URL:
   ```
   https://github.com/yourusername/NetworkHealth.git
   ```
4. Select version rule (e.g., "Up to Next Major Version" from 1.0.0)
5. Click **Add Package**
6. Select the **NetworkHealth** target and click **Add Package**

### Adding to Package.swift

Add NetworkHealth as a dependency in your `Package.swift` file:

```swift
// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "YourPackage",
    platforms: [
        .iOS(.v15)
    ],
    dependencies: [
        .package(url: "https://github.com/yourusername/NetworkHealth.git", from: "0.0.1")
    ],
    targets: [
        .target(
            name: "YourTarget",
            dependencies: ["NetworkHealth"]
        )
    ]
)
```

## Dependencies

NetworkHealth has the following dependencies that will be automatically installed:

### Required Dependencies
- **Foundation** - Built-in framework (no external dependency)
- **Network** - Built-in framework for NWPathMonitor (no external dependency)

### Optional Dependencies
If you want to use speed testing features:

- **SpeedTestCore** - For network speed measurements
- **Nevod** (Core) - Network provider layer

## Installation for Speed Testing

If you want to enable speed testing capabilities, you need to include SpeedTestCore:

```swift
dependencies: [
    .package(url: "https://github.com/yourusername/NetworkHealth.git", from: "0.0.1"),
    .package(url: "https://github.com/yourusername/SpeedTestCore.git", from: "0.0.3")
]
```

Then import both in your code:

```swift
import NetworkHealth
import SpeedTestCore

let networkProvider = NetworkProvider(config: networkConfig)

for await state in NetworkHealth.stream(
    includeSpeedTests: true,
    speedTestInterval: 60,
    networkProvider: networkProvider
) {
    print("Speed: \(state.downloadSpeedMbps ?? 0) Mbps")
}
```

## Verifying Installation

After installation, verify that everything is working:

```swift
import NetworkHealth

// Quick verification
Task {
    let snapshot = await NetworkHealth.snapshot()
    print("NetworkHealth installed successfully!")
    print("Current quality: \(snapshot.quality)")
}
```

## Minimum Requirements

- **iOS**: 15.0 or later
- **Swift**: 5.9 or later
- **Xcode**: 15.0 or later

## Platform Support

Currently supported platforms:
- ✅ iOS 15.0+
- ✅ iPadOS 15.0+

Planned support:
- macOS (coming soon)
- watchOS (coming soon)
- tvOS (coming soon)

## Troubleshooting

### "No such module 'NetworkHealth'"

**Solution**: Make sure you've added the package correctly and it appears in your project's package dependencies. Try cleaning the build folder (Cmd+Shift+K) and rebuilding.

### Package Resolution Fails

**Solution**:
1. Check your internet connection
2. Verify the repository URL is correct
3. Try resolving package versions in Xcode: **File → Packages → Reset Package Caches**

### Build Errors After Adding Package

**Solution**:
1. Ensure your project's iOS deployment target is 15.0 or higher
2. Clean build folder (Cmd+Shift+K)
3. Close and reopen Xcode
4. Delete derived data: `~/Library/Developer/Xcode/DerivedData`

### Speed Testing Not Working

**Solution**: Make sure you've added SpeedTestCore as a dependency and imported it in your code. Speed testing is optional and requires separate installation.

## Updating NetworkHealth

### Xcode
1. Go to **File → Packages → Update to Latest Package Versions**
2. Or right-click on the package in the Project Navigator and select **Update Package**

### Command Line
```bash
swift package update
```

## Uninstalling

### From Xcode Project
1. Select your project in the Project Navigator
2. Select your target
3. Go to **Frameworks, Libraries, and Embedded Content**
4. Find NetworkHealth and click the "-" button

### From Package.swift
Remove the NetworkHealth entry from the `dependencies` array in your `Package.swift` file.

## Next Steps

After installation:
- 📖 [Quick Start Guide](QuickStart.md) - Get started in 5 minutes
- 📚 [API Reference](API.md) - Explore the full API
- 💡 [Examples](Examples.md) - See real-world usage patterns

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
// swift-tools-version: 6.1
import PackageDescription

let package = Package(
    name: "YourPackage",
    platforms: [
        .iOS(.v17),
        .macOS(.v15)
    ],
    dependencies: [
        .package(url: "https://github.com/yourusername/NetworkHealth.git", from: "1.0.0")
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

NetworkHealth has **ZERO external dependencies**! It's a completely standalone library.

### Built-in Dependencies
- **Foundation** - Built-in framework (no external dependency)
- **Network** - Built-in framework for NWPathMonitor (no external dependency)
- **CoreTelephony** - Built-in framework for cellular type detection (iOS only)

### Optional Speed Testing

NetworkHealth supports speed testing through the `SpeedTester` protocol. You can use:

1. **Built-in Mocks** (included, no extra dependencies):
```swift
import NetworkHealth

let mockTester = MockSpeedTester.goodLTE
for await state in NetworkHealth.stream(speedTester: mockTester) {
    print("Quality: \(state.quality)")
}
```

2. **Your Own Implementation** - implement the `SpeedTester` protocol:
```swift
struct MySpeedTester: SpeedTester {
    func measureSpeed() async throws -> SpeedTestResult {
        // Your implementation
    }
}
```

3. **Third-party Libraries** (optional) - integrate any speed testing library by creating an adapter. See `REFACTORING_SUMMARY.md` for examples.

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

- **iOS**: 17.0 or later
- **macOS**: 15.0 or later
- **Swift**: 6.1 or later
- **Xcode**: 16.0 or later

## Platform Support

Currently supported platforms:
- ✅ iOS 17.0+
- ✅ iPadOS 17.0+
- ✅ macOS 15.0+

Future support (planned):
- watchOS (planned)
- tvOS (planned)

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
1. Ensure your project's deployment target meets minimum requirements:
   - iOS 17.0 or higher
   - macOS 15.0 or higher
2. Clean build folder (Cmd+Shift+K)
3. Close and reopen Xcode
4. Delete derived data: `~/Library/Developer/Xcode/DerivedData`

### Speed Testing Not Working

**Solution**: NetworkHealth includes built-in mock speed testers. For production use, implement the `SpeedTester` protocol with your own speed testing logic. See the documentation for examples.

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

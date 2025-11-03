// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "NetworkHealth",
    platforms: [
        .iOS(.v17),
        .macOS(.v15)
    ],
    products: [
        .library(
            name: "NetworkHealth",
            targets: ["NetworkHealth"]
        ),
    ],
    dependencies: [
        // No external dependencies - NetworkHealth is now atomic!
        // Speed testers can be injected via the SpeedTester protocol
    ],
    targets: [
        .target(
            name: "NetworkHealth",
            dependencies: []
        ),
        .testTarget(
            name: "NetworkHealthTests",
            dependencies: ["NetworkHealth"]
        ),
    ]
)

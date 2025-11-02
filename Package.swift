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
        .package(url: "git@github.com:andrey-torlopov/SpeedTestCore.git", from: "0.0.1"),
        .package(url: "git@github.com:andrey-torlopov/Nevod.git", from: "0.0.2")
    ],
    targets: [
        .target(
            name: "NetworkHealth",
            dependencies: [
                .product(name: "SpeedTestCore", package: "SpeedTestCore"),
                .product(name: "Nevod", package: "Nevod"),
            ]
        ),
        .testTarget(
            name: "NetworkHealthTests",
            dependencies: ["NetworkHealth"]
        ),
    ]
)

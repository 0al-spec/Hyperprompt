// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "BenchmarkGenerator",
    platforms: [
        .macOS(.v13)
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "BenchmarkGenerator",
            dependencies: [],
            path: "Sources/BenchmarkGenerator"
        )
    ]
)

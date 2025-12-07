// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Hyperprompt",
    platforms: [
        .macOS(.v12)
    ],
    products: [
        .executable(
            name: "hyperprompt",
            targets: ["CLI"]
        ),
        .library(
            name: "HypercodeGrammar",
            targets: ["HypercodeGrammar"]
        )
    ],
    dependencies: [
        .package(
            url: "https://github.com/apple/swift-argument-parser",
            from: "1.2.0"
        ),
        .package(
            url: "https://github.com/apple/swift-crypto",
            from: "3.0.0"
        ),
        .package(
            url: "https://github.com/SoundBlaster/SpecificationCore",
            from: "1.0.0"
        )
    ],
    targets: [
        // Core module
        .target(
            name: "Core",
            dependencies: [
                .product(name: "Crypto", package: "swift-crypto")
            ]
        ),
        .testTarget(
            name: "CoreTests",
            dependencies: ["Core"]
        ),

        // Parser module
        .target(
            name: "Parser",
            dependencies: ["Core"]
        ),
        .testTarget(
            name: "ParserTests",
            dependencies: ["Parser"]
        ),

        // Resolver module
        .target(
            name: "Resolver",
            dependencies: ["Core", "Parser"]
        ),
        .testTarget(
            name: "ResolverTests",
            dependencies: ["Resolver"]
        ),

        // Emitter module
        .target(
            name: "Emitter",
            dependencies: ["Core", "Parser"]
        ),
        .testTarget(
            name: "EmitterTests",
            dependencies: ["Emitter"]
        ),

        // Statistics module
        .target(
            name: "Statistics",
            dependencies: ["Core"]
        ),
        .testTarget(
            name: "StatisticsTests",
            dependencies: ["Statistics"]
        ),

        // CLI module
        .executableTarget(
            name: "CLI",
            dependencies: [
                "Core",
                "Parser",
                "Resolver",
                "Emitter",
                "Statistics",
                .product(name: "ArgumentParser", package: "swift-argument-parser")
            ]
        ),
        .testTarget(
            name: "CLITests",
            dependencies: ["CLI"]
        ),

        // Integration tests
        .testTarget(
            name: "IntegrationTests",
            dependencies: [
                "Core",
                "Parser",
                "Resolver",
                "Emitter",
                "CLI"
            ]
        ),

        // Hypercode grammar specifications
        .target(
            name: "HypercodeGrammar",
            dependencies: [
                "Core",
                "SpecificationCore"
            ]
        ),
        .testTarget(
            name: "HypercodeGrammarTests",
            dependencies: ["HypercodeGrammar"]
        )
    ]
)

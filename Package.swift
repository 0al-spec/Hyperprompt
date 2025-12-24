// swift-tools-version: 6.2
import PackageDescription

let editorTrait = Trait(
    name: "Editor",
    description: "Enable the EditorEngine module",
    enabledTraits: []
)

let enabledTraits = Set(
    (Context.environment["SWIFT_PACKAGE_TRAITS"] ?? "")
        .split(separator: ",")
        .map { String($0) }
)
let enableAllTraits = Context.environment["SWIFT_ENABLE_ALL_TRAITS"] == "1"
let editorEnabled = enableAllTraits || enabledTraits.contains(editorTrait.name)

var products: [Product] = [
    .executable(
        name: "hyperprompt",
        targets: ["CLI"]
    ),
    .library(
        name: "HypercodeGrammar",
        targets: ["HypercodeGrammar"]
    ),
]

var targets: [Target] = [
        // Core module
        .target(
            name: "Core",
            dependencies: [
                .product(name: "Crypto", package: "swift-crypto"),
                "SpecificationCore",
            ]
        ),
        .testTarget(
            name: "CoreTests",
            dependencies: ["Core"]
        ),

        // Parser module
        .target(
            name: "Parser",
            dependencies: ["Core", "HypercodeGrammar"]
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
                "CompilerDriver",
                "Core",
                "Parser",
                "Resolver",
                "Emitter",
                "Statistics",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ] + (editorEnabled ? ["EditorEngine"] : [])
        ),
        .testTarget(
            name: "CLITests",
            dependencies: [
                "CLI",
                "CompilerDriver",
            ]
        ),

        // Integration tests
        .testTarget(
            name: "IntegrationTests",
            dependencies: [
                "CompilerDriver",
                "Core",
                "Parser",
                "Resolver",
                "Emitter",
            ],
            resources: [
                .copy("Fixtures")
            ]
        ),

        // Hypercode grammar specifications
        .target(
            name: "HypercodeGrammar",
            dependencies: [
                "Core",
                "SpecificationCore",
            ]
        ),
        .testTarget(
            name: "HypercodeGrammarTests",
            dependencies: ["HypercodeGrammar"]
        ),

        // Shared compiler driver module
        .target(
            name: "CompilerDriver",
            dependencies: [
                "Core",
                "Parser",
                "Resolver",
                "Emitter",
                "Statistics",
            ]
        ),

        // Performance tests
        .testTarget(
            name: "PerformanceTests",
            dependencies: [
                "CompilerDriver",
                "Core",
                "Parser",
                "Resolver",
                "Emitter",
            ],
            resources: [
                .copy("Fixtures")
            ]
        ),
    ]

if editorEnabled {
    products.append(
        .library(
            name: "EditorEngine",
            targets: ["EditorEngine"]
        )
    )

    targets.append(
        .target(
            name: "EditorEngine",
            dependencies: [
                "CompilerDriver",
                "Core",
                "HypercodeGrammar",
                "Parser",
                "Resolver",
                "Emitter",
                "Statistics",
                "SpecificationCore",
            ]
        )
    )

    targets.append(
        .testTarget(
            name: "EditorEngineTests",
            dependencies: [
                "CompilerDriver",
                "EditorEngine",
            ]
        )
    )
}

let package = Package(
    name: "Hyperprompt",
    platforms: [
        .macOS(.v12)
    ],
    products: products,
    traits: [editorTrait],
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
        ),
    ],
    targets: targets
)

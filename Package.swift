// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "AgentMeter",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v15)
    ],
    products: [
        .executable(
            name: "AgentMeter",
            targets: ["AgentMeter"]
        ),
        .library(
            name: "AgentMeterCore",
            targets: ["AgentMeterCore"]
        )
    ],
    dependencies: [],
    targets: [
        .target(
            name: "AgentMeterCore",
            dependencies: [],
            path: "Sources/AgentMeterCore"
        ),
        .executableTarget(
            name: "AgentMeter",
            dependencies: ["AgentMeterCore"],
            path: "Sources/AgentMeter",
            resources: [
                .process("Resources")
            ]
        ),
        .testTarget(
            name: "AgentMeterTests",
            dependencies: ["AgentMeterCore", "AgentMeter"],
            path: "Tests/AgentMeterTests"
        )
    ],
    swiftLanguageModes: [.v6]
)

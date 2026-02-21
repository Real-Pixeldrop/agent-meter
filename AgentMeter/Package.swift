// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "AgentMeter",
    platforms: [
        .macOS(.v14)
    ],
    dependencies: [
        .package(url: "https://github.com/stephencelis/SQLite.swift.git", from: "0.15.0"),
    ],
    targets: [
        .executableTarget(
            name: "AgentMeter",
            dependencies: [
                .product(name: "SQLite", package: "SQLite.swift"),
            ],
            path: "Sources/AgentMeter"
        ),
    ]
)

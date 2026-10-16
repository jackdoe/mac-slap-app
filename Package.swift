// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "SlapMe",
    platforms: [.macOS(.v15)],
    targets: [
        .target(name: "SlapCore"),
        .executableTarget(
            name: "SlapMe",
            dependencies: ["SlapCore"],
            swiftSettings: [.defaultIsolation(MainActor.self)]
        ),
        .testTarget(name: "SlapCoreTests", dependencies: ["SlapCore"]),
    ]
)

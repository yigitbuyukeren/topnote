// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "MinikNot",
    platforms: [.macOS(.v13)],
    targets: [
        .target(name: "MinikNotCore"),
        .executableTarget(name: "MinikNot", dependencies: ["MinikNotCore"]),
        .testTarget(name: "MinikNotCoreTests", dependencies: ["MinikNotCore"]),
    ]
)

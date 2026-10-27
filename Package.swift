// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "Topnote",
    platforms: [.macOS(.v13)],
    targets: [
        .target(name: "TopnoteCore"),
        .executableTarget(name: "Topnote", dependencies: ["TopnoteCore"]),
        .testTarget(name: "TopnoteCoreTests", dependencies: ["TopnoteCore"]),
    ]
)

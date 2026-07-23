// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "mactowin",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "mactowin",
            path: "Sources/mactowin"
        ),
        .testTarget(
            name: "mactowinTests",
            dependencies: ["mactowin"],
            path: "Tests/mactowinTests"
        )
    ],
    swiftLanguageModes: [.v5]
)

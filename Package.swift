// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ZoomItMacOS",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(
            name: "ZoomItMacOS",
            targets: ["ZoomItMacOS"]
        ),
    ],
    dependencies: [
        // Add any external dependencies here
    ],
    targets: [
        .executableTarget(
            name: "ZoomItMacOS",
            dependencies: []
        ),
    ]
)

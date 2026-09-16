// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "QuotaBar",
    platforms: [.macOS(.v13)],
    products: [
        .library(name: "QuotaBarCore", targets: ["QuotaBarCore"]),
    ],
    targets: [
        .target(
            name: "QuotaBarCore",
            path: "Sources/QuotaBarCore"
        ),
        .executableTarget(
            name: "QuotaBar",
            dependencies: ["QuotaBarCore"],
            path: "Sources/QuotaBar"
        ),
        .testTarget(
            name: "QuotaBarCoreTests",
            dependencies: ["QuotaBarCore"],
            path: "Tests/QuotaBarCoreTests",
            resources: [.copy("Fixtures")]
        ),
    ]
)

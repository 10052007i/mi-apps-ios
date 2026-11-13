// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MiAppKit",
    platforms: [.iOS(.v16)],
    products: [
        .library(
            name: "MiAppKit",
            targets: ["Core", "FeatureLogin", "FeatureHome", "FeatureSettings"]
        )
    ],
    targets: [
        .target(name: "Core"),
        .target(name: "FeatureLogin", dependencies: ["Core"]),
        .target(name: "FeatureHome", dependencies: ["Core"]),
        .target(name: "FeatureSettings", dependencies: ["Core"])
    ]
)
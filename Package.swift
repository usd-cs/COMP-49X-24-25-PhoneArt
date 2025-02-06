// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "PhoneArt",
    platforms: [
        .macOS(.v12)  // Changed from iOS since we're running in Linux container
    ],
    products: [
        .library(
            name: "PhoneArt",
            targets: ["PhoneArt"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "PhoneArt",
            dependencies: []),
        .testTarget(
            name: "PhoneArtTests",
            dependencies: ["PhoneArt"])
    ]
) 
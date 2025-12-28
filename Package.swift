// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "swift-cull-mac",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(
            name: "SwiftCull",
            targets: ["SwiftCull"]
        )
    ],
    targets: [
        .executableTarget(
            name: "SwiftCull",
            path: "RawImageGallery"
        )
    ]
)

// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ImageCropper",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "ImageCropper", targets: ["ImageCropper"])
    ],
    targets: [
        .executableTarget(
            name: "ImageCropper",
            path: "Sources/ImageCropper"
        )
    ]
)
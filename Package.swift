// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "MDViewer",
    platforms: [.macOS(.v13)],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-cmark", from: "0.9.0"),
    ],
    targets: [
        .executableTarget(
            name: "MDViewer",
            dependencies: [
                .product(name: "cmark-gfm", package: "swift-cmark"),
                .product(name: "cmark-gfm-extensions", package: "swift-cmark"),
            ],
            path: "Sources/MDViewer"
        ),
    ]
)

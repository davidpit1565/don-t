// swift-tools-version:5.9
// Developer convenience only: builds and tests the Foundation-only core
// (DontPress/Core) with `swift test`, including on Linux. The iOS app itself is
// built with DontPress.xcodeproj.
import PackageDescription

let package = Package(
    name: "DontPressCore",
    platforms: [.iOS(.v17), .macOS(.v14)],
    targets: [
        .target(name: "DontPressCore", path: "DontPress/Core"),
        .testTarget(
            name: "DontPressCoreTests",
            dependencies: ["DontPressCore"],
            path: "DontPressTests"
        ),
    ]
)

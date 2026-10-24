// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "YoyoClock",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "YoyoClock", targets: ["MenuBarChime"])
    ],
    targets: [
        .executableTarget(
            name: "MenuBarChime",
            path: "Sources/MenuBarChime"
        )
    ]
)

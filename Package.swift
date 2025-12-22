// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "MacOSMiddleWareSoundProducer",
    platforms: [
        .macOS(.v13)
    ],
    dependencies: [
        // Dependencies go here.
    ],
    targets: [
        // Targets are the basic building blocks of a package.
        .executableTarget(
            name: "MacOSMiddleWareSoundProducer",
            dependencies: [],
            path: "Sources"),
    ]
)

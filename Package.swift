// swift-tools-version:5.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "NetworkTestSuite",
    platforms: [.macOS(.v10_11)],
    dependencies: [
        .package(url: "https://github.com/drewag/Swiftlier.git", from: "6.0.0"),
    ],
    targets: [
        .target(name: "NetworkTestSuite", dependencies: ["Swiftlier"]),
        .testTarget(name: "NetworkTestSuiteTests", dependencies: ["NetworkTestSuite"]),
    ]
)

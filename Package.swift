import PackageDescription

let package = Package(
    name: "NetworkTestSuite",
    dependencies: [
        .Package(url: "https://github.com/drewag/SwiftPlusPlus.git", majorVersion: 1),
    ]
)

import PackageDescription

let package = Package(
    name: "NetworkTestSuite",
    dependencies: [
        .Package(url: "https://github.com/drewag/Swiftlier.git", majorVersion: 4),
    ]
)

// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "swift-rfc-9111",
    platforms: [
        .macOS(.v15),
        .iOS(.v18),
        .tvOS(.v18),
        .watchOS(.v11)
    ],
    products: [
        .library(
            name: "RFC 9111",
            targets: ["RFC 9111"]
        )
    ],
    dependencies: [
        .package(path: "../swift-rfc-9110")
    ],
    targets: [
        .target(
            name: "RFC 9111",
            dependencies: [
                .product(name: "RFC 9110", package: "swift-rfc-9110")
            ],
            swiftSettings: [
                .swiftLanguageMode(.v6),
                .enableUpcomingFeature("ExistentialAny"),
                .enableExperimentalFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "RFC 9111 Tests",
            dependencies: ["RFC 9111"],
            swiftSettings: [
                .swiftLanguageMode(.v6),
                .enableUpcomingFeature("ExistentialAny"),
                .enableExperimentalFeature("StrictConcurrency")
            ]
        )
    ],
    swiftLanguageModes: [.v6]
)

for target in package.targets {
    var settings = target.swiftSettings ?? []
    settings.append(
        .enableUpcomingFeature("MemberImportVisibility")
    )
    target.swiftSettings = settings
}

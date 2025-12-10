// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "swift-rfc-9111",
    platforms: [
        .macOS(.v26),
        .iOS(.v26),
        .tvOS(.v26),
        .watchOS(.v26)
    ],
    products: [
        .library(
            name: "RFC 9111",
            targets: ["RFC 9111"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/swift-standards/swift-rfc-9110", from: "0.1.0")
    ],
    targets: [
        .target(
            name: "RFC 9111",
            dependencies: [
                .product(name: "RFC 9110", package: "swift-rfc-9110")
            ]
        ),
        .testTarget(
            name: "RFC 9111".tests,
            dependencies: ["RFC 9111"]
        )
    ],
    swiftLanguageModes: [.v6]
)

extension String {
    var tests: Self { self + " Tests" }
    var foundation: Self { self + " Foundation" }
}

for target in package.targets where ![.system, .binary, .plugin].contains(target.type) {
    let existing = target.swiftSettings ?? []
    target.swiftSettings = existing + [
        .enableUpcomingFeature("ExistentialAny"),
        .enableUpcomingFeature("InternalImportsByDefault"),
        .enableUpcomingFeature("MemberImportVisibility")
    ]
}

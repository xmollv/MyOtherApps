// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "MyOtherApps",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v26)
    ],
    products: [
        .library(name: "MyOtherApps", targets: ["MyOtherApps"])
    ],
    targets: [
        .target(
            name: "MyOtherApps",
            resources: [
                .process("Resources")
            ]
        )
    ]
)

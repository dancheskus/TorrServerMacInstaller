// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "TorrServerMacInstaller",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "TorrServerMacInstaller",
            targets: ["TorrServerMacInstaller"]
        )
    ],
    targets: [
        .executableTarget(
            name: "TorrServerMacInstaller",
            linkerSettings: [
                .linkedFramework("AppKit"),
                .linkedFramework("ServiceManagement"),
                .linkedFramework("SwiftUI"),
                .linkedFramework("WebKit")
            ]
        )
    ]
)

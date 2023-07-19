// swift-tools-version: 5.8

import PackageDescription

let package = Package(
    name: "SyncTeX",
    platforms: [.iOS("16.0")],
    products: [
        .library(
            name: "SyncTeX",
            targets: ["SyncTeX"])
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
    ],
    targets: [
        .target(
            name: "__Internal_SyncTeX_C",
            dependencies: [],
            exclude: ["include/synctex_parser.h"],
            linkerSettings: [.linkedLibrary("z")],
            plugins: []),
        
        .target(
            name: "SyncTeX",
            dependencies: ["__Internal_SyncTeX_C"],
            path: "Sources/SyncTeX")
        
    ]
)

// swift-tools-version:5.6
import PackageDescription
import Foundation

// Package manifests run on macOS and cannot infer an iOS Simulator destination.
// Opt in before resolving/building a simulator-only package graph.
let simulatorPreview = ProcessInfo.processInfo.environment["EASYIFLY_SIMULATOR"] == "1"

let package = Package(
    name: "EasyIFly",
    platforms: [.iOS(.v12)],
    products: [
        .library(name: "EasyIFly", targets: ["EasyIFly"]),
    ],
    targets: [
        .target(
            name: "EasyIFly",
            dependencies: simulatorPreview ? [] : ["iflyMSC"],
            path: "EasyIFly",
            sources: ["Classes"],
            resources: [
                .process("Assets/EasyIFly.xcassets")
            ]
        ),
    ] + (simulatorPreview ? [] : [
        .binaryTarget(
            name: "iflyMSC",
            url: "https://github.com/duanbhu/EasyIFly/releases/download/1.0.0/iflyMSC.xcframework.zip",
            checksum: "88cb56ecd657210d7d53afc977753f92c97ad5deddf2e557883df98bee3cd491"
        ),
    ])
)

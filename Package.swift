// swift-tools-version:5.6
import PackageDescription

let package = Package(
    name: "EasyIFly",
    platforms: [.iOS(.v12)],
    products: [
        .library(name: "EasyIFly", targets: ["EasyIFly"]),
    ],
    targets: [
        .target(
            name: "EasyIFly",
            dependencies: ["iflyMSC"],
            path: "EasyIFly",
            sources: ["Classes"],
            resources: [
                .process("Assets/EasyIFly.xcassets")
            ]
        ),
        .binaryTarget(
            name: "iflyMSC",
            url: "https://github.com/duanbhu/EasyIFly/releases/download/1.0.0/iflyMSC.xcframework.zip",
            checksum: "88cb56ecd657210d7d53afc977753f92c97ad5deddf2e557883df98bee3cd491"
        ),
    ]
)

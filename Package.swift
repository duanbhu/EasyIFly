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
            checksum: "6871a20922ce25777bce81cb810d9346d0e88f82172b83d97ab7ac8118c1f47c"
        ),
    ]
)

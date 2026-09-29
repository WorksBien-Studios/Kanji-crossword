// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "KanjiCrosswordUI",
    platforms: [
        .iOS(.v18),
        .macOS(.v15)
    ],
    products: [
        .library(name: "KanjiCrosswordUI", targets: ["KanjiCrosswordUI"])
    ],
    dependencies: [
        .package(
            url: "https://github.com/lrodeveloperr/ios-18-shell.git",
            revision: "c082e90f9fc92970ef127792dfba2dd9cdffd710"
        ),
        .package(path: "../runtime")
    ],
    targets: [
        .target(
            name: "KanjiCrosswordUI",
            dependencies: [
                .product(name: "iOS18Shell", package: "ios-18-shell"),
                .product(name: "KanjiGameCore", package: "runtime"),
                .product(name: "KanjiPersistence", package: "runtime"),
                .product(name: "KanjiCommerce", package: "runtime")
            ]
        ),
        .testTarget(
            name: "KanjiCrosswordUITests",
            dependencies: [
                "KanjiCrosswordUI",
                .product(name: "KanjiGameCore", package: "runtime"),
                .product(name: "KanjiCommerce", package: "runtime")
            ]
        )
    ]
)

// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "KanjiCrosswordRuntime",
    platforms: [
        .iOS(.v18),
        .macOS(.v15)
    ],
    products: [
        .library(name: "KanjiGameCore", targets: ["KanjiGameCore"]),
        .library(name: "KanjiPersistence", targets: ["KanjiPersistence"]),
        .library(name: "KanjiCommerce", targets: ["KanjiCommerce"]),
        .executable(name: "KanjiContentCheck", targets: ["KanjiContentCheck"])
    ],
    targets: [
        .target(name: "KanjiGameCore"),
        .target(
            name: "KanjiPersistence",
            dependencies: ["KanjiGameCore"]
        ),
        .target(name: "KanjiCommerce"),
        .executableTarget(
            name: "KanjiContentCheck",
            dependencies: ["KanjiGameCore"]
        ),
        .testTarget(
            name: "KanjiGameCoreTests",
            dependencies: ["KanjiGameCore"]
        ),
        .testTarget(
            name: "KanjiPersistenceTests",
            dependencies: ["KanjiGameCore", "KanjiPersistence"]
        ),
        .testTarget(
            name: "KanjiCommerceTests",
            dependencies: ["KanjiCommerce"]
        )
    ]
)

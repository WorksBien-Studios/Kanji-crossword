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
        .library(name: "KanjiPersistence", targets: ["KanjiPersistence"])
    ],
    targets: [
        .target(name: "KanjiGameCore"),
        .target(
            name: "KanjiPersistence",
            dependencies: ["KanjiGameCore"]
        ),
        .testTarget(
            name: "KanjiGameCoreTests",
            dependencies: ["KanjiGameCore"]
        ),
        .testTarget(
            name: "KanjiPersistenceTests",
            dependencies: ["KanjiGameCore", "KanjiPersistence"]
        )
    ]
)

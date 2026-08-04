// swift-tools-version:5.9
import PackageDescription

// RaoBotKit — shared brand + infrastructure for all RaoBot games.
// One source of truth: add this package to each game, `import RaoBotKit`.
let package = Package(
    name: "RaoBotKit",
    // macOS is declared only so `swift test` runs on the host machine — the
    // games themselves ship iOS-only.
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "RaoBotKit", targets: ["RaoBotKit"]),
    ],
    targets: [
        .target(name: "RaoBotKit"),
        .testTarget(name: "RaoBotKitTests", dependencies: ["RaoBotKit"]),
    ]
)

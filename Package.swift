// swift-tools-version:5.9
import PackageDescription

// RaoBotKit — shared brand + infrastructure for all RaoBot games.
// One source of truth: add this package to each game, `import RaoBotKit`.
let package = Package(
    name: "RaoBotKit",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "RaoBotKit", targets: ["RaoBotKit"]),
    ],
    targets: [
        .target(name: "RaoBotKit"),
    ]
)

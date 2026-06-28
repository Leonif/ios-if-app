// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Redux",
    platforms: [.iOS(.v16)],
    products: [
        .library(name: "Redux", targets: ["Redux"]),
    ],
    targets: [
        .target(name: "Redux"),
    ]
)

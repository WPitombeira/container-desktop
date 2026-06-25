// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ContainerDesktop",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "ContainerDesktop", targets: ["ContainerDesktop"])
    ],
    targets: [
        .executableTarget(
            name: "ContainerDesktop",
            dependencies: [],
            path: "src"
        ),
        .testTarget(
            name: "ContainerDesktopTests",
            dependencies: ["ContainerDesktop"],
            path: "Tests"
        )
    ]
)

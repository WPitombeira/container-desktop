// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ContainerDesktop",
    platforms: [
        .macOS("26.0")
    ],
    products: [
        .executable(name: "ContainerDesktop", targets: ["ContainerDesktop"]),
        .executable(name: "AuraMCP", targets: ["AuraMCP"])
    ],
    targets: [
        .executableTarget(
            name: "ContainerDesktop",
            dependencies: ["AuraMCPKit"],
            path: "src",
            exclude: ["MCP"]
        ),
        .target(
            name: "AuraMCPKit",
            dependencies: [],
            path: "src/MCP"
        ),
        .executableTarget(
            name: "AuraMCP",
            dependencies: ["AuraMCPKit"],
            path: "mcp"
        ),
        .testTarget(
            name: "ContainerDesktopTests",
            dependencies: ["ContainerDesktop"],
            path: "Tests/AuraTests"
        ),
        .testTarget(
            name: "AuraMCPKitTests",
            dependencies: ["AuraMCPKit"],
            path: "Tests/AuraMCPKitTests"
        )
    ]
)

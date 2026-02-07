// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MintCheckOBD2",
    platforms: [
        .macOS(.v12)
    ],
    products: [
        .executable(
            name: "mintcheck-obd2",
            targets: ["MintCheckOBD2"]
        ),
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "MintCheckOBD2",
            dependencies: [],
            linkerSettings: [
                .linkedFramework("IOBluetooth", .when(platforms: [.macOS])),
                .linkedFramework("IOBluetoothUI", .when(platforms: [.macOS])),
            ]
        ),
    ]
)

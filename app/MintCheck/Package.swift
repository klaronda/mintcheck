// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "MintCheck",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "MintCheck",
            targets: ["MintCheck"]),
    ],
    dependencies: [
        // Supabase Swift SDK
        .package(url: "https://github.com/supabase-community/supabase-swift.git", from: "2.0.0"),
    ],
    targets: [
        .target(
            name: "MintCheck",
            dependencies: [
                .product(name: "Supabase", package: "supabase-swift"),
            ],
            path: "MintCheck"
        ),
    ]
)

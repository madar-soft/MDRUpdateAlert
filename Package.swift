// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "MDRUpdateAlert",
    platforms: [
        .iOS(.v15),
        .macOS(.v10_15)
    ],
    products: [
        .library(name: "MDRUpdateAlert",
                 targets: ["MDRUpdateAlert"])
    ],
    dependencies: [
        .package(url: "https://github.com/firebase/firebase-ios-sdk.git", from: "12.8.0")
    ],
    targets: [
        .target(name: "MDRUpdateAlert",
                dependencies: [.product(name: "FirebaseRemoteConfig", package: "firebase-ios-sdk")],
                path: "Sources",
                resources: [])
    ],
    swiftLanguageModes: [.v5]
)

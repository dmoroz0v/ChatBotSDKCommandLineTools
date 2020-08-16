// swift-tools-version:5.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ChatBotSDKCommandLineTools",
    products: [
        .library(
            name: "ChatBotSDKCommandLineTools",
            targets: ["ChatBotSDKCommandLineTools"]
        ),
        .executable(name: "chat-bot-sdk",
                    targets: ["chat-bot-sdk"]
        )
    ],
    dependencies: [
    ],
    targets: [
        .target(
            name: "ChatBotSDKCommandLineTools",
            dependencies: []
        ),
        .target(
            name: "chat-bot-sdk",
            dependencies: ["ChatBotSDKCommandLineTools"]
        ),
    ]
)

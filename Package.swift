// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "TodayTodo",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "TodayTodo", targets: ["TodayTodo"])
    ],
    targets: [
        .target(
            name: "TodayTodoCore",
            path: "Sources",
            exclude: ["AppMain"],
            swiftSettings: [
                .swiftLanguageMode(.v5)
            ]
        ),
        .executableTarget(
            name: "TodayTodo",
            dependencies: ["TodayTodoCore"],
            path: "Sources/AppMain",
            swiftSettings: [
                .swiftLanguageMode(.v5)
            ]
        ),
        .testTarget(
            name: "TodayTodoTests",
            dependencies: ["TodayTodoCore"],
            path: "Tests/TodayTodoTests",
            swiftSettings: [
                .swiftLanguageMode(.v5)
            ]
        )
    ]
)

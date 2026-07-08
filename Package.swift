// swift-tools-version: 5.9
import PackageDescription

let appleLinkerSettings: [LinkerSetting] = [
    .linkedFramework("AudioToolbox"),
    .linkedFramework("AVFoundation"),
    .linkedFramework("CoreFoundation"),
    .linkedFramework("CoreMedia"),
    .linkedFramework("CoreVideo"),
    .linkedFramework("Foundation"),
    .linkedFramework("IOSurface"),
    .linkedFramework("Metal"),
    .linkedFramework("QuartzCore"),
    .linkedFramework("Security"),
    .linkedFramework("VideoToolbox"),
    .linkedFramework("UIKit", .when(platforms: [.iOS, .tvOS, .macCatalyst])),
    .linkedLibrary("c++"),
    .linkedLibrary("iconv"),
    .linkedLibrary("xml2"),
    .linkedLibrary("z"),
]

let package = Package(
    name: "iBaiFFmpeg",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v15),
        .macOS(.v12),
        .macCatalyst(.v14),
        .tvOS(.v15),
    ],
    products: [
        .library(name: "FFmpegShim", targets: ["FFmpegShim"]),
        .library(name: "Libavcodec", targets: ["Libavcodec"]),
        .library(name: "Libavfilter", targets: ["Libavfilter"]),
        .library(name: "Libavformat", targets: ["Libavformat"]),
        .library(name: "Libavutil", targets: ["Libavutil"]),
        .library(name: "Libswresample", targets: ["Libswresample"]),
        .library(name: "Libswscale", targets: ["Libswscale"]),
    ],
    targets: [
        .target(
            name: "FFmpegShim",
            dependencies: [
                "Libavutil",
                "Libavcodec",
                "Libavformat",
                "Libavfilter",
                "Libswresample",
                "Libswscale",
            ],
            path: "Sources/FFmpegShim",
            publicHeadersPath: "include",
            cSettings: [
                .headerSearchPath("include"),
            ],
            linkerSettings: appleLinkerSettings
        ),
        .binaryTarget(name: "Libavcodec", path: "Artifacts/Libavcodec.xcframework"),
        .binaryTarget(name: "Libavfilter", path: "Artifacts/Libavfilter.xcframework"),
        .binaryTarget(name: "Libavformat", path: "Artifacts/Libavformat.xcframework"),
        .binaryTarget(name: "Libavutil", path: "Artifacts/Libavutil.xcframework"),
        .binaryTarget(name: "Libswresample", path: "Artifacts/Libswresample.xcframework"),
        .binaryTarget(name: "Libswscale", path: "Artifacts/Libswscale.xcframework"),
    ]
)

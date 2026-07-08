# iBaiFFmpeg

[English README](README.md) · 中文

自建 **LGPL FFmpeg** 二进制依赖库。本仓库从 `Vendor/ffmpeg` 源码出发，使用经过审计的 `Config/` 编译选项进行交叉编译，将产物打包为 `Libav*.xcframework`，并通过 `FFmpegShim` 暴露给 Swift 使用。

## 进度

| 阶段   | 说明                                  | 状态                                                                                                           |
| ------ | ------                                | ------                                                                                                         |
| 1      | `Vendor/ffmpeg` 子模块（上游 FFmpeg） | 已完成 — `n8.1.2`                                                                                              |
| 2      | 仅 LGPL 的 `Config/` configure 选项   | 已完成                                                                                                         |
| 3      | 交叉编译脚本 + xcframework            | **已完成** — iOS / macOS / Mac Catalyst (arm64) / tvOS                                                         |
| 4      | SPM `Package.swift` + `FFmpegShim`    | **已完成**                                                                                                     |
| 5      | iBai 集成（`../iBaiFFmpeg`）          | **已完成** — 本地 SPM，所有活跃 target                                                                         |
| 6      | 每次发布的合规归档                    | **已完成** — 见 iBai 侧 `Scripts/collect-compliance-evidence.sh` + 本仓库 `Scripts/make-lgpl-source-bundle.sh` |

## 仓库结构

```
iBaiFFmpeg/
├── Config/                 # LGPL configure 选项（阶段 2）
├── Scripts/
│   ├── build-all.sh        # ios + macos + maccatalyst + tvos
│   ├── build-ios.sh
│   ├── build-macos.sh
│   ├── build-maccatalyst.sh
│   ├── build-tvos.sh
│   ├── build-slice.sh      # 单平台/架构静态库构建
│   ├── make-xcframework.sh # 在 Artifacts/ 中生成 Lib*.xcframework
│   ├── load-ffmpeg-config.sh
│   ├── patch-videotoolbox.sh
│   └── verify-lgpl-build.sh
├── Vendor/ffmpeg/          # git 子模块
├── build/                  #（gitignore）各 slice 与临时文件
└── Artifacts/              #（gitignore）Libav*.xcframework
```

## 阶段 3 — 构建 xcframework

前置条件：**Xcode**；若需构建 x86_64 slice，还需安装 `nasm`（`brew install nasm`）。

```bash
git submodule update --init --recursive

# iOS 真机 + 模拟器（首次构建耗时较长；每个 slice 约 30–60 分钟）
Scripts/build-ios.sh

# 可选：构建全部 Apple 平台
Scripts/build-all.sh

# 或仅构建单个 slice 做冒烟测试
Scripts/build-slice.sh iphoneos arm64
Scripts/verify-lgpl-build.sh build/scratch/ios-arm64/config.h
```

产物位于 `Artifacts/`：

- `Libavcodec.xcframework`
- `Libavformat.xcframework`
- `Libavutil.xcframework`
- `Libavfilter.xcframework`
- `Libswresample.xcframework`
- `Libswscale.xcframework`

### 环境变量

| 变量                       | 默认值   | 含义                                                                    |
| ------                     | -------- | ------                                                                  |
| `IOS_MIN_VERSION`          | `15.0`   | iOS 最低部署版本                                                        |
| `MACOS_MIN_VERSION`        | `12.0`   | macOS 最低部署版本                                                      |
| `TVOS_MIN_VERSION`         | `15.0`   | tvOS 最低部署版本                                                       |
| `BUILD_IOS_X86_SIMULATOR`  | `1`      | 是否构建 x86_64 iOS 模拟器 slice                                        |
| `BUILD_MACOS_X86_64`       | `1`      | 是否构建 Intel macOS slice                                              |
| `BUILD_MACCATALYST_X86_64` | `0`      | 是否构建 Intel Mac Catalyst slice（当前 iPhoneOS SDK 不支持；仅 arm64） |
| `BUILD_TVOS_X86_SIMULATOR` | `1`      | 是否构建 x86_64 tvOS 模拟器 slice                                       |

执行 `Scripts/build-all.sh` 后支持的 xcframework slice：

| 平台         | Slice                                                          |
| ------       | -------                                                        |
| iOS          | `ios-arm64`、`ios-arm64-simulator`（可选 x86_64 模拟器）       |
| macOS        | `macos-arm64`（可选 `macos-x86_64`）                           |
| Mac Catalyst | `ios-arm64-maccatalyst`（当前 Xcode SDK 不支持 x86_64 macabi） |
| tvOS         | `tvos-arm64`、`tvos-arm64-simulator`（可选 x86_64 模拟器）     |

## Swift Package Manager 集成

本仓库提供以下 SPM 产品：

| 产品                                          | 说明                                               |
| ------                                        | ------                                             |
| `FFmpegShim`                                  | 推荐入口；聚合各 Libav 库并配置 Apple 系统框架链接 |
| `Libavcodec` / `Libavformat` / `Libavutil` 等 | 按需单独引用底层 xcframework                       |

支持平台：iOS 15+、macOS 12+、Mac Catalyst 14+、tvOS 15+。

在 iBai 或宿主 App 的 Xcode 工程中，添加本地包引用指向本仓库根目录即可。

## LGPL 合规

分发包含本仓库 FFmpeg 二进制的 App 时，须按 [LGPL v3](https://www.gnu.org/licenses/lgpl-3.0.html) 提供对应源码。

生成本仓库的源码归档包：

```bash
Scripts/make-lgpl-source-bundle.sh
```

归档内容包含：`Config/`、构建脚本、`Package.swift`，以及 `Vendor/ffmpeg` 在构建时对应的 git 提交。

configure 选项的设计说明与合规检查步骤见 [`Config/README.md`](Config/README.md)。

## 许可证

- **本仓库的构建配置与脚本**：专有 / 项目内部（iBai）。
- **由 `Vendor/ffmpeg` 编译出的 FFmpeg 二进制**：[LGPL v3](https://www.gnu.org/licenses/lgpl-3.0.html) — 分发 App 时须按 LGPL 提供源码。

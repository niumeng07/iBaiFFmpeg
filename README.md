# iBaiFFmpeg

Self-built **LGPL FFmpeg** binaries for [iBai](https://github.com/niumeng07/iBai). This repo prebuilt dependency: FFmpeg is compiled from `Vendor/ffmpeg` with audited `Config/` flags, packaged as `Libav*.xcframework`, and exposed to Swift via `FFmpegShim`.

Clone to `../iBaiFFmpeg` for local Xcode SPM integration (`XCLocalSwiftPackageReference`).

## Status

| Phase | Description | Status |
|-------|-------------|--------|
| 1 | `Vendor/ffmpeg` submodule (upstream FFmpeg) | Done — `n8.1.2` |
| 2 | LGPL-only `Config/` configure flags | Done |
| 3 | Cross-compile scripts + xcframeworks | **Done** — iOS / macOS / Mac Catalyst (arm64) / tvOS |
| 4 | SPM `Package.swift` + `FFmpegShim` | **Done** |
| 5 | iBai integration (`../iBaiFFmpeg`) | **Done** — local SPM, all active targets |
| 6 | Compliance archive per release | **Done** — see `Scripts/collect-compliance-evidence.sh` (iBai) + `Scripts/make-lgpl-source-bundle.sh` |

## Repository layout

```
iBaiFFmpeg/
├── Config/                 # LGPL configure flags (phase 2)
├── Scripts/
│   ├── build-all.sh        # ios + macos + maccatalyst + tvos
│   ├── build-ios.sh
│   ├── build-macos.sh
│   ├── build-maccatalyst.sh
│   ├── build-tvos.sh
│   ├── build-slice.sh      # one platform/arch static build
│   ├── make-xcframework.sh # Lib*.xcframework in Artifacts/
│   ├── load-ffmpeg-config.sh
│   ├── patch-videotoolbox.sh
│   └── verify-lgpl-build.sh
├── Vendor/ffmpeg/          # git submodule
├── build/                  # (gitignored) thin slices + scratch
└── Artifacts/              # (gitignored) Libav*.xcframework
```

## Phase 3 — build xcframeworks

Prerequisites: **Xcode**, `nasm` (for x86_64 slices: `brew install nasm`).

```bash
git submodule update --init --recursive

# iOS device + simulator (long-running; ~30–60 min per slice on first build)
Scripts/build-ios.sh

# Optional: all Apple targets
Scripts/build-all.sh

# Or one slice for smoke test
Scripts/build-slice.sh iphoneos arm64
Scripts/verify-lgpl-build.sh build/scratch/ios-arm64/config.h
```

Outputs land in `Artifacts/`:

- `Libavcodec.xcframework`
- `Libavformat.xcframework`
- `Libavutil.xcframework`
- `Libavfilter.xcframework`
- `Libswresample.xcframework`
- `Libswscale.xcframework`

Environment overrides:

| Variable | Default | Meaning |
|----------|---------|---------|
| `IOS_MIN_VERSION` | `15.0` | iOS deployment target |
| `MACOS_MIN_VERSION` | `12.0` | macOS deployment target |
| `TVOS_MIN_VERSION` | `15.0` | tvOS deployment target |
| `BUILD_IOS_X86_SIMULATOR` | `1` | Build x86_64 iOS simulator slice |
| `BUILD_MACOS_X86_64` | `1` | Build Intel macOS slice |
| `BUILD_MACCATALYST_X86_64` | `0` | Build Intel Mac Catalyst slice (unsupported on current iPhoneOS SDK; arm64 only) |
| `BUILD_TVOS_X86_SIMULATOR` | `1` | Build x86_64 tvOS simulator slice |

Supported xcframework slices (after `Scripts/build-all.sh`):

| Platform | Slices |
|----------|--------|
| iOS | `ios-arm64`, `ios-arm64-simulator` (+ optional x86_64 sim) |
| macOS | `macos-arm64` (+ optional `macos-x86_64`) |
| Mac Catalyst | `ios-arm64-maccatalyst` (x86_64 macabi not available on current Xcode SDK) |
| tvOS | `tvos-arm64`, `tvos-arm64-simulator` (+ optional x86_64 sim) |

## License

- **This repo's build configs & scripts**: proprietary / project-internal (iBai).
- **FFmpeg binaries** produced from `Vendor/ffmpeg`: [LGPL v3](https://www.gnu.org/licenses/lgpl-3.0.html) — source must be offered per LGPL when distributing the app.

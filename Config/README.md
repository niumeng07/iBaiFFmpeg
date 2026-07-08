# FFmpeg configure flags (phase 2)

Fixed, reviewable `configure` arguments for an **LGPL v3-only** FFmpeg build tailored to [iBai](https://github.com/niumeng07/iBai) playback (`MEPlayer`).

Upstream source: `Vendor/ffmpeg` (submodule, currently **n8.1.2**).

## Layout

| File | Purpose |
|------|---------|
| `ffmpeg-lgpl-base.conf` | License, libraries, demuxers/decoders/filters/protocols shared by all Apple targets |
| `ffmpeg-lgpl-darwin.conf` | `--target-os=darwin`, VideoToolbox / AudioToolbox, VT filters |
| `ffmpeg-lgpl-ios.conf` | ARM NEON + asm (device & arm64 simulator) |
| `ffmpeg-lgpl-ios-simulator-x86.conf` | x86_64 simulator slice (`--disable-neon --disable-asm`) |
| `ffmpeg-lgpl-macos.conf` | macOS-specific options |
| `ffmpeg-lgpl-maccatalyst.conf` | Mac Catalyst overlay (no libxml2 / VideoToolbox; SDK macabi limits) |
| `ffmpeg-lgpl-tvos.conf` | tvOS-specific options |

Build scripts (phase 3) merge layers in this order:

```
base → darwin → <platform>   # maccatalyst: base → darwin → ios → maccatalyst overlay
```

Use `Scripts/load-ffmpeg-config.sh` to emit a bash array.

## Quick start

```bash
cd ~/Local/code/iBaiFFmpeg

# Print merged flags for iOS arm64
eval "$(Scripts/load-ffmpeg-config.sh ios)"
printf '%s\n' "${FFMPEG_CONFIGURE_ARGS[@]}"

# After configure (phase 3), verify compliance
Scripts/verify-lgpl-build.sh /path/to/ffbuild/config.h
```

## Design choices

- **`--disable-gpl`** — no GPL components; app can stay closed-source if other deps allow.
- **No external libs** — no libdav1d, libass, gnutls, libsmbclient, libplacebo, MoltenVK, etc. (can be opt-in later with separate compliance notes).
- **Playback-focused** — demuxers/decoders aligned with iBai `MEPlayer`.
- **GPL filters removed** — `boxblur`, `delogo`, and other `*_deps=gpl` filters are excluded from the trimmed playback set.
- **VideoToolbox** — H.264/HEVC hardware decode path preserved (`yadif_videotoolbox`, `scale_vt`, `transpose_vt`) on iOS / macOS / tvOS.
- **Mac Catalyst** — separate overlay disables libxml2 and VideoToolbox (iPhoneOS SDK macabi cannot link those the same way); iBai still uses system VideoToolbox in Swift on Catalyst.
- **Static only** — `--enable-static --disable-shared` for xcframework packaging.

## Explicitly disabled (do not re-enable without legal review)

| Flag / library | Reason |
|----------------|--------|
| `--enable-gpl` | Would GPL the combined work |
| `libx264`, `libmp3lame` | GPL / patent stack |
| `libsmbclient` | GPL v3 protocol dep in FFmpeg configure |
| `readline` | GPL companion to libsmbclient builds |
| GPL-only filters (`boxblur`, `delogo`, …) | `*_filter_deps=gpl` in upstream `configure` |

## Compliance evidence (per release)

Archive together with the iBai app version:

1. `Vendor/ffmpeg` git commit (e.g. `n8.1.2`)
2. This `Config/` directory (exact configure inputs)
3. Generated `ffbuild/config.h` — `CONFIG_GPL=0`, `CONFIG_VERSION3=1`
4. Output of `Scripts/verify-lgpl-build.sh`

## Adding a format

1. Confirm decoder/demuxer is **not** `gpl` or `nonfree` in `Vendor/ffmpeg/configure`.
2. Add `--enable-decoder=…` or `--enable-demuxer=…` to `ffmpeg-lgpl-base.conf`.
3. Re-run configure and `verify-lgpl-build.sh`.
4. Play-test in iBai.

Optional future add-ons (separate decision + attribution):

- **libdav1d** (BSD) — faster AV1 if native decoder is insufficient
- **libass** (LGPL) — `subtitles` / styled ASS rendering filter

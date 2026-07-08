#!/usr/bin/env bash
# Build one FFmpeg static-library slice for an Apple platform/architecture.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"
# shellcheck source=lib/apple.sh
source "${SCRIPT_DIR}/lib/apple.sh"

usage() {
    cat <<'EOF'
Usage: build-slice.sh <platform> <arch>

Platforms:
  iphoneos | iphonesimulator | macosx | maccatalyst | appletvos | appletvsimulator

Architectures:
  arm64 | x86_64

Example:
  Scripts/build-slice.sh iphoneos arm64
EOF
}

main() {
    local platform="${1:-}"
    local arch="${2:-}"
    if [[ -z "$platform" || -z "$arch" ]]; then
        usage
        exit 1
    fi

    if [[ "$platform" == "maccatalyst" && "$arch" == "x86_64" ]] && ! maccatalyst_x86_64_supported; then
        die "maccatalyst x86_64 is unsupported by the installed iPhoneOS SDK (no x86_64 macabi in libSystem). Skip with BUILD_MACCATALYST_X86_64=0 or build arm64 only."
    fi

    require_cmd xcrun
    require_cmd make
    require_cmd install
    [[ -x "${FFMPEG_SRC}/configure" ]] || die "run from repo with initialized Vendor/ffmpeg submodule"

    if [[ "$arch" == "x86_64" ]]; then
        require_cmd nasm
    fi

    ensure_dirs
    "${SCRIPT_DIR}/patch-videotoolbox.sh"

    local slice_id config_profile scratch prefix
    slice_id="$(apple_slice_id "$platform" "$arch")"
    config_profile="$(apple_config_profile "$platform" "$arch")"
    scratch="$(scratch_dir_for_slice "$slice_id")"
    prefix="$(thin_prefix_for_slice "$slice_id")"

    log "building slice ${slice_id} (profile=${config_profile})"

    mkdir -p "$scratch" "$prefix"
    rm -rf "$scratch"
    mkdir -p "$scratch"

    eval "$(apple_build_env "$platform" "$arch")"
    eval "$("${SCRIPT_DIR}/load-ffmpeg-config.sh" "$config_profile")"

    # Propagate Apple target triple into C/asm link lines (NEON .o must be iOS/tvOS, not macOS host).
    export AS="${CC}"
    export ASFLAGS="${CFLAGS}"

    local ffmpeg_arch
    ffmpeg_arch="$(apple_ffmpeg_arch "$arch")"

    (
        cd "$scratch"
        "${FFMPEG_SRC}/configure" \
            "${FFMPEG_CONFIGURE_ARGS[@]}" \
            --prefix="$prefix" \
            --arch="$ffmpeg_arch" \
            --cc="${CC}" \
            --cxx="${CXX}" \
            --as="${AS}" \
            --extra-cflags="${CFLAGS}" \
            --extra-cxxflags="${CXXFLAGS}" \
            --extra-ldflags="${LDFLAGS}" \
            --ar="${AR}" \
            --ranlib="${RANLIB}" \
            --strip="${STRIP}"
        make -j"$(cpu_count)"
        make install
    )

    "${SCRIPT_DIR}/verify-lgpl-build.sh" "${scratch}/config.h"

    for lib in "${FFMPEG_LIBS[@]}"; do
        [[ -f "${prefix}/lib/$(lib_archive_name "$lib")" ]] || die "missing ${prefix}/lib/$(lib_archive_name "$lib")"
    done

    cp "${scratch}/config.h" "${prefix}/include/libavutil/config.h"
    log "slice ${slice_id} installed to ${prefix}"
}

main "$@"

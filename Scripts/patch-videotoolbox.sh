#!/usr/bin/env bash
# Idempotent Metal compatibility patch for FFmpeg videotoolbox sources.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"

patch_file() {
    local path="$1"
    [[ -f "$path" ]] || return 0
    if grep -q 'kCVPixelBufferMetalCompatibilityKey' "$path" 2>/dev/null; then
        return 0
    fi
    log "patching $(basename "$path") for Metal compatibility"
    sed -i '' \
        -e 's/kCVPixelBufferOpenGLESCompatibilityKey/kCVPixelBufferMetalCompatibilityKey/g' \
        -e 's/kCVPixelBufferIOSurfaceOpenGLTextureCompatibilityKey/kCVPixelBufferMetalCompatibilityKey/g' \
        "$path"
}

main() {
    require_cmd sed
    [[ -d "$FFMPEG_SRC" ]] || die "missing FFmpeg source at $FFMPEG_SRC"
    patch_file "${FFMPEG_SRC}/libavcodec/videotoolbox.c"
    patch_file "${FFMPEG_SRC}/libavutil/internal.h"
}

main "$@"

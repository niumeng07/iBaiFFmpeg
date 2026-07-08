#!/usr/bin/env bash
# Shared helpers for iBaiFFmpeg build scripts.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
export ROOT

FFMPEG_SRC="${ROOT}/Vendor/ffmpeg"
BUILD_DIR="${ROOT}/build"
THIN_DIR="${BUILD_DIR}/thin"
SCRATCH_DIR="${BUILD_DIR}/scratch"
FRAMEWORK_DIR="${BUILD_DIR}/frameworks"
ARTIFACTS_DIR="${ROOT}/Artifacts"

FFMPEG_LIBS=(avcodec avformat avutil avfilter swresample swscale)

log() {
    printf '[iBaiFFmpeg] %s\n' "$*"
}

die() {
    printf '[iBaiFFmpeg] ERROR: %s\n' "$*" >&2
    exit 1
}

require_cmd() {
    local cmd="$1"
    command -v "$cmd" >/dev/null 2>&1 || die "missing required command: $cmd"
}

ensure_dirs() {
    mkdir -p "$THIN_DIR" "$SCRATCH_DIR" "$FRAMEWORK_DIR" "$ARTIFACTS_DIR"
}

cpu_count() {
    sysctl -n hw.ncpu 2>/dev/null || echo 4
}

framework_name_for_lib() {
    local lib="$1"
    printf 'Lib%s' "$lib"
}

lib_archive_name() {
    local lib="$1"
    printf 'lib%s.a' "$lib"
}

thin_prefix_for_slice() {
    local slice_id="$1"
    printf '%s/%s' "$THIN_DIR" "$slice_id"
}

scratch_dir_for_slice() {
    local slice_id="$1"
    printf '%s/%s' "$SCRATCH_DIR" "$slice_id"
}

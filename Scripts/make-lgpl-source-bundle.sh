#!/usr/bin/env bash
# Create an LGPL compliance source bundle matching the built iBaiFFmpeg binaries.
#
# Usage:
#   Scripts/make-lgpl-source-bundle.sh [output.tar.gz]
#
# Bundle includes: iBaiFFmpeg (configs, scripts, Package.swift), Vendor/ffmpeg at pinned commit.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"

ROOT="$ROOT"
FFMPEG_SRC="${ROOT}/Vendor/ffmpeg"
STAGING="${ROOT}/build/lgpl-source-bundle"
DATE_TAG="$(date +%Y%m%d)"
FFMPEG_TAG="$(git -C "$FFMPEG_SRC" describe --tags --always 2>/dev/null || echo unknown)"
IBAI_FFMPEG_REV="$(git -C "$ROOT" rev-parse --short HEAD 2>/dev/null || echo unknown)"
DEFAULT_OUT="${ROOT}/build/ibai-ffmpeg-lgpl-source-${FFMPEG_TAG}-${IBAI_FFMPEG_REV}-${DATE_TAG}.tar.gz"
OUT="${1:-$DEFAULT_OUT}"

require_cmd git
require_cmd tar
[[ -d "$FFMPEG_SRC" ]] || die "missing Vendor/ffmpeg submodule"

log "staging source bundle"
rm -rf "$STAGING"
mkdir -p "$STAGING/ibai-ffmpeg"

copy_tree() {
    local src="$1" dest="$2"
    mkdir -p "$(dirname "$dest")"
    rsync -a --exclude '.git' --exclude 'build' --exclude 'Artifacts' --exclude '.swiftpm' "$src/" "$dest/"
}

if command -v rsync >/dev/null 2>&1; then
    copy_tree "$ROOT/Config" "$STAGING/ibai-ffmpeg/Config"
    copy_tree "$ROOT/Scripts" "$STAGING/ibai-ffmpeg/Scripts"
    copy_tree "$ROOT/Sources" "$STAGING/ibai-ffmpeg/Sources"
    cp "$ROOT/Package.swift" "$ROOT/README.md" "$STAGING/ibai-ffmpeg/"
    mkdir -p "$STAGING/ibai-ffmpeg/Vendor"
    rsync -a "$FFMPEG_SRC/" "$STAGING/ibai-ffmpeg/Vendor/ffmpeg/"
else
    die "rsync required for source bundle"
fi

cat >"$STAGING/ibai-ffmpeg/SOURCE-BUNDLE.txt" <<EOF
iBai FFmpeg LGPL source bundle
Generated: $(date -u +%Y-%m-%dT%H:%M:%SZ)
iBaiFFmpeg: $(git -C "$ROOT" rev-parse HEAD 2>/dev/null || echo unknown)
FFmpeg: $(git -C "$FFMPEG_SRC" rev-parse HEAD 2>/dev/null || echo unknown) ($FFMPEG_TAG)

This archive satisfies LGPL v3 source-distribution obligations for the
Libav* static libraries embedded in iBai when built from this repository state.

Rebuild (example iOS arm64):
  Scripts/build-slice.sh iphoneos arm64
EOF

if [[ -f "$ROOT/build/thin/ios-arm64/include/libavutil/config.h" ]]; then
    mkdir -p "$STAGING/ibai-ffmpeg/evidence"
    cp "$ROOT/build/thin/ios-arm64/include/libavutil/config.h" "$STAGING/ibai-ffmpeg/evidence/config.h"
    "$ROOT/Scripts/verify-lgpl-build.sh" "$STAGING/ibai-ffmpeg/evidence/config.h" \
        >"$STAGING/ibai-ffmpeg/evidence/verify-lgpl-build.txt" 2>&1 || true
fi

mkdir -p "$(dirname "$OUT")"
tar -czf "$OUT" -C "$STAGING" ibai-ffmpeg
log "created $OUT"
shasum -a 256 "$OUT" | tee "${OUT}.sha256"

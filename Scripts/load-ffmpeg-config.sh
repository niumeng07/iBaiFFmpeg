#!/usr/bin/env bash
# Merge iBaiFFmpeg Config/*.conf into a single argument list for Vendor/ffmpeg/configure.
#
# Usage:
#   eval "$(Scripts/load-ffmpeg-config.sh ios)"
#   cd Vendor/ffmpeg && ./configure "${FFMPEG_CONFIGURE_ARGS[@]}" --prefix=... --arch=...
#
# Platforms: ios | ios-simulator-x86 | macos | maccatalyst | tvos | darwin (base+darwin only)

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CONFIG_DIR="${ROOT}/Config"

usage() {
    cat <<'EOF'
Usage: load-ffmpeg-config.sh <platform>

Platforms:
  ios                 iOS arm64 (device + Apple-silicon simulator)
  ios-simulator-x86   iOS x86_64 simulator slice
  macos               macOS
  maccatalyst         Mac Catalyst (ios profile + catalyst overlay)
  tvos                tvOS
  darwin              base + darwin only (no platform slice)

Prints shell snippet:
  FFMPEG_CONFIGURE_ARGS=( ... )
EOF
}

read_conf() {
    local file="$1"
    if [[ ! -f "$file" ]]; then
        echo "missing config: $file" >&2
        exit 1
    fi
    grep -v '^\s*#' "$file" | grep -v '^\s*$' || true
}

platform="${1:-}"
if [[ -z "$platform" || "$platform" == "-h" || "$platform" == "--help" ]]; then
    usage
    exit 0
fi

files=(
    "${CONFIG_DIR}/ffmpeg-lgpl-base.conf"
    "${CONFIG_DIR}/ffmpeg-lgpl-darwin.conf"
)

case "$platform" in
    ios)
        files+=("${CONFIG_DIR}/ffmpeg-lgpl-ios.conf")
        ;;
    ios-simulator-x86)
        files+=("${CONFIG_DIR}/ffmpeg-lgpl-ios.conf")
        files+=("${CONFIG_DIR}/ffmpeg-lgpl-ios-simulator-x86.conf")
        ;;
    macos)
        files+=("${CONFIG_DIR}/ffmpeg-lgpl-macos.conf")
        ;;
    maccatalyst)
        files+=("${CONFIG_DIR}/ffmpeg-lgpl-ios.conf")
        files+=("${CONFIG_DIR}/ffmpeg-lgpl-maccatalyst.conf")
        ;;
    tvos)
        files+=("${CONFIG_DIR}/ffmpeg-lgpl-tvos.conf")
        ;;
    darwin)
        ;;
    *)
        echo "unknown platform: $platform" >&2
        usage
        exit 1
        ;;
esac

args=()
for f in "${files[@]}"; do
    while IFS= read -r line; do
        args+=("$line")
    done < <(read_conf "$f")
done

# Emit a reproducible, sourceable array for build scripts.
printf 'FFMPEG_CONFIGURE_ARGS=(\n'
for arg in "${args[@]}"; do
    printf '  %q\n' "$arg"
done
printf ')\n'
printf '# Merged from: %s\n' "${files[*]#${ROOT}/}"

#!/usr/bin/env bash
# Post-configure / post-build LGPL compliance checks for iBaiFFmpeg.
#
# Usage:
#   Scripts/verify-lgpl-build.sh path/to/ffbuild/config.h
#   Scripts/verify-lgpl-build.sh path/to/build/prefix/include/libavutil/config.h

set -euo pipefail

config_h="${1:-}"
if [[ -z "$config_h" || ! -f "$config_h" ]]; then
    echo "Usage: $0 <path/to/config.h>" >&2
    exit 1
fi

fail=0

expect_zero() {
    local name="$1"
    local value
    value="$(grep -E "^#define ${name} " "$config_h" | awk '{print $3}' || true)"
    if [[ "$value" != "0" ]]; then
        echo "FAIL: expected ${name} 0, got '${value:-<missing>}'" >&2
        fail=1
    else
        echo "OK: ${name}=0"
    fi
}

expect_one() {
    local name="$1"
    local value
    value="$(grep -E "^#define ${name} " "$config_h" | awk '{print $3}' || true)"
    if [[ "$value" != "1" ]]; then
        echo "FAIL: expected ${name} 1, got '${value:-<missing>}'" >&2
        fail=1
    else
        echo "OK: ${name}=1"
    fi
}

echo "Verifying LGPL build: $config_h"

expect_zero CONFIG_GPL
expect_one CONFIG_VERSION3

if grep -q -- '--enable-gpl' "$config_h"; then
    echo "FAIL: FFMPEG_CONFIGURATION still contains --enable-gpl" >&2
    fail=1
else
    echo "OK: no --enable-gpl in FFMPEG_CONFIGURATION"
fi

for forbidden in libx264 libmp3lame libsmbclient libfdk_aac; do
    macro="CONFIG_$(echo "$forbidden" | tr '[:lower:].' '[:upper:]_')"
    if grep -qE "^#define ${macro} 1" "$config_h" 2>/dev/null; then
        echo "FAIL: ${forbidden} enabled (${macro})" >&2
        fail=1
    fi
done

if [[ "$fail" -ne 0 ]]; then
    echo "LGPL verification failed." >&2
    exit 1
fi

echo "LGPL verification passed."
license_line="$(grep -E '^#define FFMPEG_LICENSE ' "$config_h" || true)"
echo "$license_line"

#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"
# shellcheck source=lib/apple.sh
source "${SCRIPT_DIR}/lib/apple.sh"

"${SCRIPT_DIR}/build-slice.sh" maccatalyst arm64
if [[ "${BUILD_MACCATALYST_X86_64:-0}" == "1" ]] && maccatalyst_x86_64_supported; then
    "${SCRIPT_DIR}/build-slice.sh" maccatalyst x86_64
elif [[ "${BUILD_MACCATALYST_X86_64:-0}" == "1" ]]; then
    log "skipping maccatalyst-x86_64: iPhoneOS SDK has no x86_64 macabi (arm64 Catalyst is enough on Apple Silicon Macs)"
fi
"${SCRIPT_DIR}/make-xcframework.sh"

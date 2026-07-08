#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
"${SCRIPT_DIR}/build-slice.sh" appletvos arm64
"${SCRIPT_DIR}/build-slice.sh" appletvsimulator arm64
if [[ "${BUILD_TVOS_X86_SIMULATOR:-1}" == "1" ]]; then
    "${SCRIPT_DIR}/build-slice.sh" appletvsimulator x86_64
fi
"${SCRIPT_DIR}/make-xcframework.sh"

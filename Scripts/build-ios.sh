#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
"${SCRIPT_DIR}/build-slice.sh" iphoneos arm64
"${SCRIPT_DIR}/build-slice.sh" iphonesimulator arm64
if [[ "${BUILD_IOS_X86_SIMULATOR:-1}" == "1" ]]; then
    "${SCRIPT_DIR}/build-slice.sh" iphonesimulator x86_64
fi
"${SCRIPT_DIR}/make-xcframework.sh"

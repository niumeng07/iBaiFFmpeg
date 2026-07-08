#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
"${SCRIPT_DIR}/build-slice.sh" macosx arm64
if [[ "${BUILD_MACOS_X86_64:-1}" == "1" ]]; then
    "${SCRIPT_DIR}/build-slice.sh" macosx x86_64
fi
"${SCRIPT_DIR}/make-xcframework.sh"

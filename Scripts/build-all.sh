#!/usr/bin/env bash
# Build all Apple platform slices and xcframeworks.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"
# shellcheck source=lib/apple.sh
source "${SCRIPT_DIR}/lib/apple.sh"

usage() {
    cat <<'EOF'
Usage: build-all.sh [ios|macos|maccatalyst|tvos|all]

Default: all

Environment:
  IOS_MIN_VERSION=15.0
  MACOS_MIN_VERSION=12.0
  TVOS_MIN_VERSION=15.0
  BUILD_IOS_X86_SIMULATOR=1
  BUILD_MACOS_X86_64=1
  BUILD_MACCATALYST_X86_64=0
  BUILD_TVOS_X86_SIMULATOR=1

Note: BUILD_MACCATALYST_X86_64 stays 0 on Xcode 16+ (iPhoneOS SDK has no x86_64 macabi).
EOF
}

main() {
    local target="${1:-all}"
    case "$target" in
        ios)
            "${SCRIPT_DIR}/build-ios.sh"
            ;;
        macos)
            "${SCRIPT_DIR}/build-macos.sh"
            ;;
        maccatalyst)
            "${SCRIPT_DIR}/build-maccatalyst.sh"
            ;;
        tvos)
            "${SCRIPT_DIR}/build-tvos.sh"
            ;;
        all)
            "${SCRIPT_DIR}/build-slice.sh" iphoneos arm64
            "${SCRIPT_DIR}/build-slice.sh" iphonesimulator arm64
            if [[ "${BUILD_IOS_X86_SIMULATOR:-1}" == "1" ]]; then
                "${SCRIPT_DIR}/build-slice.sh" iphonesimulator x86_64
            fi
            "${SCRIPT_DIR}/build-slice.sh" macosx arm64
            if [[ "${BUILD_MACOS_X86_64:-1}" == "1" ]]; then
                "${SCRIPT_DIR}/build-slice.sh" macosx x86_64
            fi
            "${SCRIPT_DIR}/build-slice.sh" maccatalyst arm64
            if [[ "${BUILD_MACCATALYST_X86_64:-0}" == "1" ]] && maccatalyst_x86_64_supported; then
                "${SCRIPT_DIR}/build-slice.sh" maccatalyst x86_64
            elif [[ "${BUILD_MACCATALYST_X86_64:-0}" == "1" ]]; then
                log "skipping maccatalyst-x86_64: iPhoneOS SDK has no x86_64 macabi (arm64 Catalyst is enough on Apple Silicon Macs)"
            fi
            "${SCRIPT_DIR}/build-slice.sh" appletvos arm64
            "${SCRIPT_DIR}/build-slice.sh" appletvsimulator arm64
            if [[ "${BUILD_TVOS_X86_SIMULATOR:-1}" == "1" ]]; then
                "${SCRIPT_DIR}/build-slice.sh" appletvsimulator x86_64
            fi
            "${SCRIPT_DIR}/make-xcframework.sh"
            ;;
        -h | --help)
            usage
            exit 0
            ;;
        *)
            usage
            exit 1
            ;;
    esac
    log "done. xcframeworks in ${ARTIFACTS_DIR}"
}

main "$@"

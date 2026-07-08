#!/usr/bin/env bash
# Apple SDK / cross-compile helpers.

set -euo pipefail

# Deployment targets (override via env).
: "${IOS_MIN_VERSION:=15.0}"
: "${MACOS_MIN_VERSION:=12.0}"
: "${TVOS_MIN_VERSION:=15.0}"
: "${CATALYST_MIN_VERSION:=14.0}"

apple_sdk_name() {
    case "$1" in
        iphoneos) echo "iphoneos" ;;
        iphonesimulator) echo "iphonesimulator" ;;
        macosx) echo "macosx" ;;
        appletvos) echo "appletvos" ;;
        appletvsimulator) echo "appletvsimulator" ;;
        maccatalyst) echo "iphoneos" ;;
        *) die "unknown apple platform: $1" ;;
    esac
}

apple_platform_id() {
    case "$1" in
        iphoneos) echo "ios" ;;
        iphonesimulator) echo "ios-simulator" ;;
        macosx) echo "macos" ;;
        appletvos) echo "tvos" ;;
        appletvsimulator) echo "tvos-simulator" ;;
        maccatalyst) echo "maccatalyst" ;;
        *) die "unknown apple platform: $1" ;;
    esac
}

apple_config_profile() {
    local platform="$1"
    local arch="$2"
    if [[ "$platform" == "iphonesimulator" && "$arch" == "x86_64" ]]; then
        echo "ios-simulator-x86"
    elif [[ "$platform" == "appletvsimulator" && "$arch" == "x86_64" ]]; then
        echo "ios-simulator-x86"
    elif [[ "$platform" == "macosx" ]]; then
        echo "macos"
    elif [[ "$platform" == "maccatalyst" ]]; then
        echo "maccatalyst"
    elif [[ "$platform" == "appletvos" || "$platform" == "appletvsimulator" ]]; then
        echo "tvos"
    elif [[ "$platform" == "maccatalyst" ]]; then
        echo "ios"
    else
        echo "ios"
    fi
}

apple_ffmpeg_arch() {
    case "$1" in
        arm64 | arm64e) echo "aarch64" ;;
        x86_64) echo "x86_64" ;;
        *) die "unsupported arch: $1" ;;
    esac
}

apple_os_version_min_flag() {
    local platform="$1"
    case "$platform" in
        iphoneos) echo "-miphoneos-version-min=${IOS_MIN_VERSION}" ;;
        iphonesimulator) echo "-mios-simulator-version-min=${IOS_MIN_VERSION}" ;;
        macosx) echo "-mmacosx-version-min=${MACOS_MIN_VERSION}" ;;
        appletvos) echo "-mappletvos-version-min=${TVOS_MIN_VERSION}" ;;
        appletvsimulator) echo "-mappletvsimulator-version-min=${TVOS_MIN_VERSION}" ;;
        maccatalyst) echo "-miphoneos-version-min=${CATALYST_MIN_VERSION}" ;;
        *) die "unknown apple platform: $platform" ;;
    esac
}

apple_deployment_target() {
    local platform="$1"
    local arch="$2"
    case "$platform" in
        iphoneos)
            printf '%s-apple-ios%s' "$arch" "$IOS_MIN_VERSION"
            ;;
        iphonesimulator)
            printf '%s-apple-ios%s-simulator' "$arch" "$IOS_MIN_VERSION"
            ;;
        macosx)
            printf '%s-apple-macos%s' "$arch" "$MACOS_MIN_VERSION"
            ;;
        appletvos)
            printf '%s-apple-tvos%s' "$arch" "$TVOS_MIN_VERSION"
            ;;
        appletvsimulator)
            printf '%s-apple-tvos%s-simulator' "$arch" "$TVOS_MIN_VERSION"
            ;;
        maccatalyst)
            printf '%s-apple-ios%s-macabi' "$arch" "$CATALYST_MIN_VERSION"
            ;;
        *)
            die "unknown apple platform: $platform"
            ;;
    esac
}

apple_slice_id() {
    local platform="$1"
    local arch="$2"
    printf '%s-%s' "$(apple_platform_id "$platform")" "$arch"
}

maccatalyst_x86_64_supported() {
    local sysroot cc src out
    sysroot="$(apple_sdk_path maccatalyst)"
    cc="$(apple_tool maccatalyst clang)"
    src="$(mktemp)"
    out="$(mktemp)"
    printf '%s\n' 'int main(void) { return 0; }' >"${src}"
    if "${cc}" -arch x86_64 -isysroot "${sysroot}" \
        -target "x86_64-apple-ios${CATALYST_MIN_VERSION}-macabi" \
        -o "${out}" "${src}" 2>/dev/null
    then
        rm -f "${src}" "${out}"
        return 0
    fi
    rm -f "${src}" "${out}"
    return 1
}

maccatalyst_xcframework_slice_name() {
    local has_arm64=0 has_x86=0
    [[ -d "$(thin_prefix_for_slice "maccatalyst-arm64")/lib" ]] && has_arm64=1
    [[ -d "$(thin_prefix_for_slice "maccatalyst-x86_64")/lib" ]] && has_x86=1
    if [[ "$has_arm64" -eq 1 && "$has_x86" -eq 1 ]]; then
        echo "ios-arm64_x86_64-maccatalyst"
    elif [[ "$has_arm64" -eq 1 ]]; then
        echo "ios-arm64-maccatalyst"
    elif [[ "$has_x86" -eq 1 ]]; then
        echo "ios-x86_64-maccatalyst"
    else
        die "no maccatalyst slices found"
    fi
}

apple_xcframework_slice_name() {
    local group="$1"
    case "$group" in
        ios) echo "ios-arm64" ;;
        ios-simulator) echo "ios-arm64_x86_64-simulator" ;;
        macos) echo "macos-arm64_x86_64" ;;
        maccatalyst) maccatalyst_xcframework_slice_name ;;
        tvos) echo "tvos-arm64" ;;
        tvos-simulator) echo "tvos-arm64_x86_64-simulator" ;;
        *) die "unknown xcframework group: $group" ;;
    esac
}

apple_sdk_path() {
    local sdk
    sdk="$(apple_sdk_name "$1")"
    xcrun --sdk "$sdk" --show-sdk-path
}

apple_tool() {
    local platform="$1"
    shift
    local sdk
    sdk="$(apple_sdk_name "$platform")"
    xcrun --sdk "$sdk" --find "$1"
}

apple_cflags() {
    local platform="$1"
    local arch="$2"
    local sysroot target min_flag
    sysroot="$(apple_sdk_path "$platform")"
    target="$(apple_deployment_target "$platform" "$arch")"
    min_flag="$(apple_os_version_min_flag "$platform")"
    printf '%s -arch %s -isysroot %s -target %s -fno-common' \
        "$min_flag" "$arch" "$sysroot" "$target"
}

apple_build_env() {
    local platform="$1"
    local arch="$2"
    local cflags cc cxx ar ranlib strip
    cflags="$(apple_cflags "$platform" "$arch")"
    cc="$(apple_tool "$platform" clang)"
    cxx="$(apple_tool "$platform" clang++)"
    ar="$(apple_tool "$platform" ar)"
    ranlib="$(apple_tool "$platform" ranlib)"
    strip="$(apple_tool "$platform" strip)"
    cat <<EOF
export CC='${cc}'
export CXX='${cxx}'
export AR='${ar}'
export RANLIB='${ranlib}'
export STRIP='${strip}'
export CFLAGS='${cflags}'
export CXXFLAGS='${cflags}'
export LDFLAGS='${cflags}'
export PKG_CONFIG_PATH=''
export LC_CTYPE='C'
EOF
}

#!/usr/bin/env bash
# Create static Lib*.framework bundles and xcframeworks from built thin slices.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"
# shellcheck source=lib/apple.sh
source "${SCRIPT_DIR}/lib/apple.sh"

declare -a XCFW_GROUPS=()

usage() {
    cat <<'EOF'
Usage: make-xcframework.sh [group...]

Groups (default: all built):
  ios
  ios-simulator
  macos
  maccatalyst
  tvos
  tvos-simulator

Requires prior Scripts/build-*.sh runs that populate build/thin/.
EOF
}

exclude_headers_for_framework() {
    local framework="$1"
    case "$framework" in
        Libavcodec)
            printf '%s\n' xvmc vdpau qsv dxva2 d3d11va mathops videotoolbox
            ;;
        Libavutil)
            printf '%s\n' \
                hwcontext_amf hwcontext_cuda hwcontext_d3d11va hwcontext_d3d12va hwcontext_drm \
                hwcontext_dxva2 hwcontext_mediacodec hwcontext_oh hwcontext_opencl hwcontext_qsv \
                hwcontext_vaapi hwcontext_vdpau hwcontext_vulkan hwcontext_videotoolbox \
                getenv_utf8 intmath libm thread mem_internal internal attributes_internal
            ;;
        Libavformat)
            printf '%s\n' os_support
            ;;
        *)
            ;;
    esac
}

write_modulemap() {
    local framework="$1"
    local modules_dir="$2"
    {
        printf 'framework module %s [system] {\n' "$framework"
        printf '    umbrella "."\n'
        while IFS= read -r header; do
            [[ -n "$header" ]] || continue
            printf '    exclude header "%s.h"\n' "$header"
        done < <(exclude_headers_for_framework "$framework")
        printf '    export *\n'
        printf '}\n'
    } >"${modules_dir}/module.modulemap"
}

write_framework_plist() {
    local plist="$1"
    local framework="$2"
    local min_version="$3"
    local sdk_name="$4"
    cat >"$plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>${framework}</string>
    <key>CFBundleIdentifier</key>
    <string>com.ibai.ffmpeg.${framework}</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>${framework}</string>
    <key>CFBundlePackageType</key>
    <string>FMWK</string>
    <key>CFBundleShortVersionString</key>
    <string>8.1.2</string>
    <key>CFBundleVersion</key>
    <string>8.1.2</string>
    <key>MinimumOSVersion</key>
    <string>${min_version}</string>
    <key>CFBundleSupportedPlatforms</key>
    <array>
        <string>${sdk_name}</string>
    </array>
</dict>
</plist>
EOF
}

sdk_display_name_for_group() {
    case "$1" in
        ios | ios-simulator) echo "iPhoneOS" ;;
        maccatalyst) echo "iPhoneOS" ;;
        macos) echo "MacOSX" ;;
        tvos | tvos-simulator) echo "AppleTVOS" ;;
        *) die "unknown group: $1" ;;
    esac
}

min_version_for_group() {
    case "$1" in
        ios | ios-simulator) echo "$IOS_MIN_VERSION" ;;
        maccatalyst) echo "$CATALYST_MIN_VERSION" ;;
        macos) echo "$MACOS_MIN_VERSION" ;;
        tvos | tvos-simulator) echo "$TVOS_MIN_VERSION" ;;
        *) die "unknown group: $1" ;;
    esac
}

slice_ids_for_group() {
    local group="$1"
    local slice_id
    case "$group" in
        ios)
            slice_id="ios-arm64"
            [[ -d "$(thin_prefix_for_slice "$slice_id")/lib" ]] && echo "$slice_id"
            ;;
        ios-simulator)
            for slice_id in ios-simulator-arm64 ios-simulator-x86_64; do
                [[ -d "$(thin_prefix_for_slice "$slice_id")/lib" ]] && echo "$slice_id"
            done
            ;;
        macos)
            for slice_id in macos-arm64 macos-x86_64; do
                [[ -d "$(thin_prefix_for_slice "$slice_id")/lib" ]] && echo "$slice_id"
            done
            ;;
        maccatalyst)
            for slice_id in maccatalyst-arm64 maccatalyst-x86_64; do
                [[ -d "$(thin_prefix_for_slice "$slice_id")/lib" ]] && echo "$slice_id"
            done
            ;;
        tvos)
            slice_id="tvos-arm64"
            [[ -d "$(thin_prefix_for_slice "$slice_id")/lib" ]] && echo "$slice_id"
            ;;
        tvos-simulator)
            for slice_id in tvos-simulator-arm64 tvos-simulator-x86_64; do
                [[ -d "$(thin_prefix_for_slice "$slice_id")/lib" ]] && echo "$slice_id"
            done
            ;;
        *)
            die "unknown group: $group"
            ;;
    esac
}

available_slices_for_group() {
    slice_ids_for_group "$1"
}

group_is_complete() {
    local group="$1"
    local count=0
    while IFS= read -r _; do
        count=$((count + 1))
    done < <(available_slices_for_group "$group")
    [[ "$count" -gt 0 ]]
}

copy_headers_for_lib() {
    local lib="$1"
    local dest="$2"
    local src="$3"
    mkdir -p "$dest"
    cp -R "${src}/include/lib${lib}/." "$dest/"
}

create_framework_for_group_lib() {
    local group="$1"
    local lib="$2"
    local framework
    framework="$(framework_name_for_lib "$lib")"
    local slice_name fw_dir fw_binary lipo_args=()
    slice_name="$(apple_xcframework_slice_name "$group")"
    fw_dir="${FRAMEWORK_DIR}/${slice_name}/${framework}.framework"
    fw_binary="${fw_dir}/${framework}"

    rm -rf "$fw_dir"
    mkdir -p "${fw_dir}/Headers" "${fw_dir}/Modules"

    local first_headers=""
    for slice_id in $(available_slices_for_group "$group"); do
        local prefix archive
        prefix="$(thin_prefix_for_slice "$slice_id")"
        archive="${prefix}/lib/$(lib_archive_name "$lib")"
        [[ -f "$archive" ]] || die "missing archive for ${slice_id}: ${archive}"
        lipo_args+=("$archive")
        if [[ -z "$first_headers" ]]; then
            first_headers="${prefix}"
        fi
    done

    if [[ "${#lipo_args[@]}" -eq 1 ]]; then
        cp "${lipo_args[0]}" "$fw_binary"
    else
        lipo -create "${lipo_args[@]}" -output "$fw_binary"
    fi
    copy_headers_for_lib "$lib" "${fw_dir}/Headers" "$first_headers"
    write_modulemap "$framework" "${fw_dir}/Modules"
    write_framework_plist \
        "${fw_dir}/Info.plist" \
        "$framework" \
        "$(min_version_for_group "$group")" \
        "$(sdk_display_name_for_group "$group")"
}

create_xcframework_for_lib() {
    local lib="$1"
    shift
    local groups=("$@")
    local framework
    framework="$(framework_name_for_lib "$lib")"
    local output="${ARTIFACTS_DIR}/${framework}.xcframework"
    local args=(-create-xcframework)

  for group in "${groups[@]}"; do
        create_framework_for_group_lib "$group" "$lib"
        local slice_name fw_path
        slice_name="$(apple_xcframework_slice_name "$group")"
        fw_path="${FRAMEWORK_DIR}/${slice_name}/${framework}.framework"
        [[ -d "$fw_path" ]] || die "missing framework: $fw_path"
        args+=(-framework "$fw_path")
    done

    args+=(-output "$output")
    rm -rf "$output"
    xcodebuild "${args[@]}"
    log "created ${output}"
}

discover_groups() {
    local found=()
    for group in ios ios-simulator macos maccatalyst tvos tvos-simulator; do
        if group_is_complete "$group"; then
            found+=("$group")
        fi
    done
    printf '%s\n' "${found[@]}"
}

main() {
    require_cmd lipo
    require_cmd xcodebuild
    ensure_dirs

    if [[ "$#" -gt 0 ]]; then
        XCFW_GROUPS=("$@")
    else
        XCFW_GROUPS=()
        while IFS= read -r group; do
            [[ -n "$group" ]] && XCFW_GROUPS+=("$group")
        done < <(discover_groups)
    fi

    if [[ "${#XCFW_GROUPS[@]}" -eq 0 ]]; then
        die "no completed slice groups found under ${THIN_DIR}"
    fi

    log "xcframework groups: ${XCFW_GROUPS[*]}"

    for lib in "${FFMPEG_LIBS[@]}"; do
        create_xcframework_for_lib "$lib" "${XCFW_GROUPS[@]}"
    done
}

main "$@"

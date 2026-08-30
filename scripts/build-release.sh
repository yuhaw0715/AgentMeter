#!/usr/bin/env bash

set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
readonly RELEASES_DIR="${PROJECT_ROOT}/releases"
readonly APP_BUNDLE="${RELEASES_DIR}/AgentMeter.app"
readonly APP_CONTENTS="${APP_BUNDLE}/Contents"
readonly APP_EXECUTABLE="${APP_CONTENTS}/MacOS/AgentMeter"
readonly APP_RESOURCES="${APP_CONTENTS}/Resources"
readonly INFO_PLIST_SOURCE="${PROJECT_ROOT}/Resources/Info.plist"
readonly ICON_SOURCE="${PROJECT_ROOT}/Resources/AppIcon.icns"
readonly ENTITLEMENTS_SOURCE="${PROJECT_ROOT}/Resources/AgentMeter.entitlements"
readonly RESOURCE_BUNDLE_NAME="AgentMeter_AgentMeter.bundle"
readonly CODESIGN_IDENTITY="${CODESIGN_IDENTITY:--}"

log() {
  printf '[AgentMeter Release] %s\n' "$1"
}

fail() {
  printf '[AgentMeter Release] 錯誤：%s\n' "$1" >&2
  exit 1
}

require_command() {
  command -v "$1" >/dev/null 2>&1 || fail "找不到必要工具：$1"
}

for command_name in swift ditto plutil codesign shasum unzip; do
  require_command "${command_name}"
done

[[ "${APP_BUNDLE}" == "${PROJECT_ROOT}/releases/AgentMeter.app" ]] || fail "App 輸出路徑不安全"

for required_file in "${INFO_PLIST_SOURCE}" "${ICON_SOURCE}" "${ENTITLEMENTS_SOURCE}"; do
  [[ -f "${required_file}" ]] || fail "缺少必要檔案：${required_file}"
done

plutil -lint "${INFO_PLIST_SOURCE}" >/dev/null
plutil -lint "${ENTITLEMENTS_SOURCE}" >/dev/null

bundle_identifier="$(plutil -extract CFBundleIdentifier raw "${INFO_PLIST_SOURCE}")"
bundle_version="$(plutil -extract CFBundleShortVersionString raw "${INFO_PLIST_SOURCE}")"
bundle_build="$(plutil -extract CFBundleVersion raw "${INFO_PLIST_SOURCE}")"
bundle_executable="$(plutil -extract CFBundleExecutable raw "${INFO_PLIST_SOURCE}")"

[[ -n "${bundle_identifier}" ]] || fail "Info.plist 缺少 CFBundleIdentifier"
[[ -n "${bundle_version}" ]] || fail "Info.plist 缺少 CFBundleShortVersionString"
[[ -n "${bundle_build}" ]] || fail "Info.plist 缺少 CFBundleVersion"
[[ "${bundle_executable}" == "AgentMeter" ]] || fail "CFBundleExecutable 必須是 AgentMeter"

readonly ARCHIVE_PATH="${RELEASES_DIR}/AgentMeter-v${bundle_version}.zip"
[[ "${ARCHIVE_PATH}" == "${PROJECT_ROOT}/releases/AgentMeter-v${bundle_version}.zip" ]] || fail "ZIP 輸出路徑不安全"

cd "${PROJECT_ROOT}"

log "建置 AgentMeter ${bundle_version} (${bundle_build}) Release 版本"
swift build -c release
bin_path="$(swift build -c release --show-bin-path)"
source_executable="${bin_path}/AgentMeter"
source_resource_bundle="${bin_path}/${RESOURCE_BUNDLE_NAME}"

[[ -f "${source_executable}" ]] || fail "找不到 Release executable：${source_executable}"
[[ -x "${source_executable}" ]] || fail "Release executable 沒有執行權限：${source_executable}"
[[ -d "${source_resource_bundle}" ]] || fail "找不到 SwiftPM resource bundle：${source_resource_bundle}"
[[ -f "${source_resource_bundle}/Info.plist" ]] || fail "SwiftPM resource bundle 缺少 Info.plist"

log "建立標準 macOS App Bundle"
mkdir -p "${RELEASES_DIR}"
rm -rf "${APP_BUNDLE}"
rm -f "${ARCHIVE_PATH}"
mkdir -p "${APP_CONTENTS}/MacOS" "${APP_RESOURCES}"

ditto "${source_executable}" "${APP_EXECUTABLE}"
chmod 755 "${APP_EXECUTABLE}"
ditto "${INFO_PLIST_SOURCE}" "${APP_CONTENTS}/Info.plist"
ditto "${ICON_SOURCE}" "${APP_RESOURCES}/AppIcon.icns"
ditto "${source_resource_bundle}" "${APP_RESOURCES}/${RESOURCE_BUNDLE_NAME}"

plutil -lint "${APP_CONTENTS}/Info.plist" >/dev/null
[[ -f "${APP_RESOURCES}/AppIcon.icns" ]] || fail "App Bundle 缺少 AppIcon.icns"
[[ -d "${APP_RESOURCES}/${RESOURCE_BUNDLE_NAME}" ]] || fail "App Bundle 缺少 SwiftPM resource bundle"
[[ -x "${APP_EXECUTABLE}" ]] || fail "App Bundle executable 沒有執行權限"

log "使用簽署 identity『${CODESIGN_IDENTITY}』簽署 App Bundle"
codesign_args=(--force --sign "${CODESIGN_IDENTITY}")
if [[ "${CODESIGN_IDENTITY}" != "-" ]]; then
  codesign_args+=(--timestamp --options runtime)
fi

codesign "${codesign_args[@]}" "${APP_RESOURCES}/${RESOURCE_BUNDLE_NAME}"
codesign "${codesign_args[@]}" --entitlements "${ENTITLEMENTS_SOURCE}" "${APP_BUNDLE}"
codesign --verify --deep --strict --verbose=2 "${APP_BUNDLE}"

signed_identifier="$(codesign -d --verbose=4 "${APP_BUNDLE}" 2>&1 | sed -n 's/^Identifier=//p')"
[[ "${signed_identifier}" == "${bundle_identifier}" ]] || fail "簽署後 Bundle Identifier 不一致"

log "產生 Homebrew Cask 使用的 ZIP"
ditto -c -k --sequesterRsrc --keepParent "${APP_BUNDLE}" "${ARCHIVE_PATH}"

archive_entries="$(unzip -Z1 "${ARCHIVE_PATH}")"
[[ -n "${archive_entries}" ]] || fail "ZIP 是空的"
if printf '%s\n' "${archive_entries}" | grep -Ev '^(AgentMeter\.app|__MACOSX)(/|$)' >/dev/null; then
  fail "ZIP 含有 AgentMeter.app 與 macOS metadata 以外的頂層內容"
fi
for expected_entry in \
  "AgentMeter.app/Contents/Info.plist" \
  "AgentMeter.app/Contents/MacOS/AgentMeter" \
  "AgentMeter.app/Contents/Resources/AppIcon.icns"; do
  printf '%s\n' "${archive_entries}" | grep -Fx "${expected_entry}" >/dev/null || fail "ZIP 缺少：${expected_entry}"
done
printf '%s\n' "${archive_entries}" | grep -F "AgentMeter.app/Contents/Resources/${RESOURCE_BUNDLE_NAME}/" >/dev/null || fail "ZIP 缺少 SwiftPM resource bundle"

archive_sha256="$(shasum -a 256 "${ARCHIVE_PATH}" | awk '{print $1}')"
archive_size="$(du -h "${ARCHIVE_PATH}" | awk '{print $1}')"

log "發布產物建立完成"
printf 'App:     %s\n' "${APP_BUNDLE}"
printf 'ZIP:     %s (%s)\n' "${ARCHIVE_PATH}" "${archive_size}"
printf 'Version: %s (%s)\n' "${bundle_version}" "${bundle_build}"
printf 'SHA-256: %s\n' "${archive_sha256}"

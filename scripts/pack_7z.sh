#!/usr/bin/env bash
# Download the latest 7-Zip release and place the binaries for each platform
# under assets/7z/{windows,macos,linux}/ with their original names.
#
# The macOS binary is merged into a universal binary and signed with
# Developer ID (hardened runtime + secure timestamp). It is notarized together
# with the app's DMG in CI, so it is not notarized here.
#
# Requires scripts/.env.sign containing:
#   SIGN_IDENTITY="Developer ID Application: <Name> (<Team ID>)"
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
ASSETS_DIR="$SCRIPT_DIR/../assets/7z"
ENV_FILE="$SCRIPT_DIR/.env.sign"

die() {
  echo "error: $*" >&2
  exit 1
}

# --- Preflight: stop before downloading anything ---

[[ $(uname -s) == Darwin ]] || die "this script must be run on macOS"
for cmd in gh jq shasum tar codesign security xcrun; do
  command -v "$cmd" >/dev/null || die "missing command: $cmd"
done
gh auth status >/dev/null 2>&1 || die "gh is not logged in (run: gh auth login)"
xcrun --find lipo >/dev/null 2>&1 || die "missing command: lipo (install Xcode Command Line Tools)"

[[ -f $ENV_FILE ]] || die "missing $ENV_FILE"
# shellcheck source=/dev/null
source "$ENV_FILE"
[[ -n ${SIGN_IDENTITY:-} ]] || die "SIGN_IDENTITY is not set in $ENV_FILE"
security find-identity -v -p codesigning | grep -qF -- "$SIGN_IDENTITY" ||
  die "signing identity not found in keychain: $SIGN_IDENTITY"

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT
OUT="$WORK/out"
mkdir -p "$OUT/windows" "$OUT/macos" "$OUT/linux"

# --- Resolve the latest version ---

release=$(gh api repos/ip7z/7zip/releases/latest)
tag=$(jq -r '.tag_name' <<<"$release") # e.g. 26.06
ver=${tag//./}                          # e.g. 2606
[[ $ver =~ ^[0-9]+$ ]] || die "unexpected release tag: $tag"
echo "Latest 7-Zip: $tag"

# Download a release asset and verify it against the SHA-256 digest GitHub publishes for it.
fetch() {
  local expected actual
  expected=$(jq -r --arg name "$1" '.assets[] | select(.name == $name) | .digest // empty' <<<"$release")
  [[ $expected == sha256:* ]] || die "no SHA-256 digest published for $1"
  echo "Downloading $1"
  gh release download "$tag" -R ip7z/7zip -p "$1" -D "$WORK"
  actual=$(shasum -a 256 "$WORK/$1" | cut -d' ' -f1)
  [[ $actual == "${expected#sha256:}" ]] || die "checksum mismatch for $1 (expected ${expected#sha256:}, got $actual)"
}

# --- Windows (x64) ---

fetch "7z$ver-extra.7z"
mkdir "$WORK/windows"
# bsdtar (macOS tar) can read .7z archives.
tar -xf "$WORK/7z$ver-extra.7z" -C "$WORK/windows" x64/7za.exe License.txt
mv "$WORK/windows/x64/7za.exe" "$WORK/windows/License.txt" "$OUT/windows/"

# --- macOS (universal: arm64 + x86_64) ---

# shortcut: assumes upstream ships thin arm64 (-mac) and x86_64 (-mac-x64) packages, update if that changes.
fetch "7z$ver-mac.tar.xz"
fetch "7z$ver-mac-x64.tar.xz"
mkdir "$WORK/mac-arm64" "$WORK/mac-x64"
tar -xf "$WORK/7z$ver-mac.tar.xz" -C "$WORK/mac-arm64" 7zz License.txt
tar -xf "$WORK/7z$ver-mac-x64.tar.xz" -C "$WORK/mac-x64" 7zz
lipo -create "$WORK/mac-arm64/7zz" "$WORK/mac-x64/7zz" -output "$OUT/macos/7zz"
# This lipo rejects multiple archs in one -verify_arch, so check each separately.
for arch in arm64 x86_64; do
  lipo "$OUT/macos/7zz" -verify_arch "$arch" || die "universal binary is missing $arch"
done
mv "$WORK/mac-arm64/License.txt" "$OUT/macos/"

codesign --force --options runtime --timestamp --sign "$SIGN_IDENTITY" "$OUT/macos/7zz"
codesign --verify --strict "$OUT/macos/7zz"
# Notarizing the app's DMG fails without hardened runtime and a secure timestamp.
sig_info=$(codesign -dvv "$OUT/macos/7zz" 2>&1)
grep -q 'flags=.*runtime' <<<"$sig_info" || die "signature lacks hardened runtime"
grep -q '^Timestamp=' <<<"$sig_info" || die "signature lacks a secure timestamp"

# --- Linux (x64) ---

fetch "7z$ver-linux-x64.tar.xz"
tar -xf "$WORK/7z$ver-linux-x64.tar.xz" -C "$OUT/linux" 7zz License.txt

# --- Place files only after every step has succeeded ---

for platform in windows macos linux; do
  mkdir -p "$ASSETS_DIR/$platform"
  cp -p "$OUT/$platform/"* "$ASSETS_DIR/$platform/"
done

echo "Done: 7-Zip $tag placed in $(cd "$ASSETS_DIR" && pwd)"
ls -l "$ASSETS_DIR"/{windows,macos,linux}

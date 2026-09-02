#!/bin/sh
# Engineering Runtime installer.
#
#   curl -fsSL https://raw.githubusercontent.com/kishore-gutta/engineering-runtime-releases/main/install.sh | sh
#
# No GitHub account or token is required: this repository publishes the release
# artifacts publicly. The runtime *source* repository remains private — a public
# artifact is not open source.
#
# Environment:
#   VERSION=v0.8.0      install a specific tag instead of the latest
#   INSTALL_DIR=/path   install here instead of the default search
#
# Exit codes are deliberately distinct, because an automated caller branches on
# them and "unsupported platform" must not look like "checksum mismatch":
#
#   0  success
#   1  usage / unexpected internal error
#   2  unsupported platform (OS or architecture)
#   3  required tool missing (curl, tar, shasum/sha256sum)
#   4  download failed (release, asset or checksum file unreachable)
#   5  checksum verification failed — nothing is installed
#   6  no writable install directory
#
set -eu

REPO="kishore-gutta/engineering-runtime-releases"
API="https://api.github.com/repos/${REPO}"

log()  { printf '%s\n' "$*"; }
warn() { printf '%s\n' "$*" >&2; }
die()  { code=$1; shift; printf 'error: %s\n' "$*" >&2; exit "$code"; }

need() {
  command -v "$1" >/dev/null 2>&1 || die 3 "'$1' is required but not installed."
}

# --- platform -----------------------------------------------------------------
os=$(uname -s 2>/dev/null || echo unknown)
arch=$(uname -m 2>/dev/null || echo unknown)

case "$os" in
  Darwin) os=darwin ;;
  Linux)  os=linux ;;
  MINGW*|MSYS*|CYGWIN*|Windows_NT)
    die 2 "Windows is not supported by this script.
Download the .zip for your architecture from
https://github.com/${REPO}/releases/latest and add runtime.exe to your PATH." ;;
  *) die 2 "unsupported operating system: ${os}" ;;
esac

case "$arch" in
  x86_64|amd64) arch=amd64 ;;
  arm64|aarch64) arch=arm64 ;;
  *) die 2 "unsupported architecture: ${arch}
Supported: amd64, arm64." ;;
esac

need curl
need tar

# shasum (macOS) or sha256sum (most Linux) — either is fine.
if command -v shasum >/dev/null 2>&1; then
  sha_check() { shasum -a 256 -c "$1" --ignore-missing >/dev/null 2>&1; }
elif command -v sha256sum >/dev/null 2>&1; then
  sha_check() { sha256sum -c "$1" --ignore-missing >/dev/null 2>&1; }
else
  die 3 "need 'shasum' or 'sha256sum' to verify the download."
fi

# --- version ------------------------------------------------------------------
version="${VERSION:-}"
if [ -z "$version" ]; then
  version=$(curl -fsSL "${API}/releases/latest" 2>/dev/null \
    | sed -n 's/.*"tag_name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' \
    | head -n 1) || true
  [ -n "$version" ] || die 4 "could not resolve the latest release tag from ${API}.
Set VERSION=vX.Y.Z to pin a version explicitly."
fi

name="engineering-runtime-${version}-${os}-${arch}"
archive="${name}.tar.gz"
base="https://github.com/${REPO}/releases/download/${version}"

log "Engineering Runtime ${version} (${os}/${arch})"

# --- download + verify --------------------------------------------------------
tmp=$(mktemp -d 2>/dev/null || mktemp -d -t engineering-runtime)
# shellcheck disable=SC2064
trap "rm -rf '$tmp'" EXIT INT TERM

log "  downloading ${archive}"
curl -fsSL -o "${tmp}/${archive}" "${base}/${archive}" \
  || die 4 "download failed: ${base}/${archive}
Check that ${version} exists and publishes a ${os}/${arch} archive."

log "  downloading SHA256SUMS.txt"
curl -fsSL -o "${tmp}/SHA256SUMS.txt" "${base}/SHA256SUMS.txt" \
  || die 4 "could not download the checksum file: ${base}/SHA256SUMS.txt"

# SHA256SUMS.txt lists every archive in the release, so verifying one download
# needs --ignore-missing — without it the five files we did not fetch are
# reported as failures, which reads like tampering.
log "  verifying checksum"
( cd "$tmp" && sha_check SHA256SUMS.txt ) \
  || die 5 "checksum verification FAILED for ${archive}.
The download does not match the published SHA256. Nothing has been installed.
Do not use this file; retry, and if it fails again report it."

# --- extract ------------------------------------------------------------------
# The archive expands to a versioned directory containing the binary alongside
# README/LICENSE and reference material — not a bare ./runtime.
tar -xzf "${tmp}/${archive}" -C "$tmp" || die 1 "could not extract ${archive}"

bin="${tmp}/${name}/runtime"
if [ ! -f "$bin" ]; then
  bin=$(find "$tmp" -type f -name runtime -perm -u+x 2>/dev/null | head -n 1) || true
  [ -n "$bin" ] && [ -f "$bin" ] || die 1 "could not find the 'runtime' binary inside ${archive}"
fi
chmod +x "$bin" 2>/dev/null || true

# --- install ------------------------------------------------------------------
target=""
if [ -n "${INSTALL_DIR:-}" ]; then
  mkdir -p "$INSTALL_DIR" 2>/dev/null || die 6 "cannot create INSTALL_DIR: ${INSTALL_DIR}"
  [ -w "$INSTALL_DIR" ] || die 6 "INSTALL_DIR is not writable: ${INSTALL_DIR}"
  target="$INSTALL_DIR"
elif [ -w /usr/local/bin ] 2>/dev/null; then
  target=/usr/local/bin
else
  target="${HOME}/.local/bin"
  mkdir -p "$target" 2>/dev/null || die 6 "no writable install directory.
Tried /usr/local/bin and ${target}. Set INSTALL_DIR=/somewhere/on/your/PATH."
  [ -w "$target" ] || die 6 "no writable install directory (${target})."
fi

cp "$bin" "${target}/runtime" || die 6 "could not write to ${target}"
chmod +x "${target}/runtime" 2>/dev/null || true

# --- report -------------------------------------------------------------------
installed=$("${target}/runtime" version 2>/dev/null || echo "${version}")

log ""
log "Installed ${installed}"
log "  location: ${target}/runtime"

case ":${PATH}:" in
  *":${target}:"*) on_path=yes ;;
  *) on_path=no ;;
esac

if [ "$on_path" = no ]; then
  log ""
  warn "NOTE: ${target} is not on your PATH."
  warn "Add it, then re-open your shell:"
  warn "  export PATH=\"${target}:\$PATH\""
fi

log ""
log "Next:"
log "  runtime config validate  # confirm the install"
log ""
log "The Runtime Home is created by the first command you run - there is no"
log "separate setup step. Governance is deliberately not created for you:"
log "until you supply a policy document, the compiled safety profile governs."
log ""
log "Docs: https://docs.engineeringruntime.com"

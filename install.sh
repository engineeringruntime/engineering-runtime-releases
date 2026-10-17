#!/bin/sh
# Engineering Runtime installer.
#
#   curl -fsSL https://raw.githubusercontent.com/engineeringruntime/engineering-runtime-releases/main/install.sh | sh
#
# The intended contract is anonymous public release artifacts. If the repository
# is private, GitHub returns 404 and this installer fails closed; do not add a
# credential workaround here. The runtime *source* repository remains private —
# a public artifact is not open source.
#
# v0.10.0 and later use engrt archives and install only engrt; no runtime alias.
#
# Environment:
#   VERSION=vX.Y.Z      install a specific release tag instead of the latest
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

REPO="engineeringruntime/engineering-runtime-releases"
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
https://github.com/${REPO}/releases/latest and add engrt.exe to your PATH." ;;
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
  sha_tool=shasum
  sha_check_line() { printf '%s\n' "$1" | shasum -a 256 -c - >/dev/null 2>&1; }
elif command -v sha256sum >/dev/null 2>&1; then
  sha_tool=sha256sum
  sha_check_line() { printf '%s\n' "$1" | sha256sum -c - >/dev/null 2>&1; }
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

# This installer deliberately owns only the new machine namespace. Old releases
# have different archive/member/binary names; never guess a new name for them.
release_number=${version#v}
printf '%s\n' "$release_number" | awk '
  /^[0-9]+\.[0-9]+\.[0-9]+(-[0-9A-Za-z.-]+)?(\+[0-9A-Za-z.-]+)?$/ {
    split($0, parts, ".")
    split(parts[3], patch, /[-+]/)
    if (parts[1] ~ /^0[0-9]/ || parts[2] ~ /^0[0-9]/ || patch[1] ~ /^0[0-9]/) exit 1
    exit 0
  }
  { exit 1 }
' || die 1 "invalid release tag: ${version}. Expected vX.Y.Z (optional prerelease/build suffix)."
major=${release_number%%.*}
rest=${release_number#*.}
minor=${rest%%.*}
if [ "$major" = 0 ]; then
  case "$minor" in
    0|1|2|3|4|5|6|7|8|9)
      die 1 "this engrt installer supports v0.10.0 and later, not ${version}.
For an older release or rollback, use that release's checksum-verified manual installation of the runtime binary in a separate destination and Home.
Nothing has been installed." ;;
  esac
fi

name="engrt-${version}-${os}-${arch}"
archive="${name}.tar.gz"
base="https://github.com/${REPO}/releases/download/${version}"

log "Engineering Runtime ${version} (${os}/${arch})"

# --- download + verify --------------------------------------------------------
tmp=$(mktemp -d 2>/dev/null || mktemp -d -t engineering-runtime)
stage_dir=
cleanup() {
  if [ -n "$stage_dir" ]; then
    rm -f "$stage_dir/engrt"
    rmdir "$stage_dir" 2>/dev/null || true
  fi
  rm -rf "$tmp"
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

log "  downloading ${archive}"
curl -fsSL -o "${tmp}/${archive}" "${base}/${archive}" \
  || die 4 "download failed: ${base}/${archive}
Check that ${version} exists and publishes a ${os}/${arch} archive."

log "  downloading SHA256SUMS.txt"
curl -fsSL -o "${tmp}/SHA256SUMS.txt" "${base}/SHA256SUMS.txt" \
  || die 4 "could not download the checksum file: ${base}/SHA256SUMS.txt"

log "  verifying checksum"
checksum_lines=$(awk -v wanted="$archive" '
  $2 == wanted || $2 == "*" wanted { print }
' "${tmp}/SHA256SUMS.txt")
checksum_count=$(printf '%s\n' "$checksum_lines" | sed '/^$/d' | wc -l | tr -d ' ')
[ "$checksum_count" = 1 ] \
  || die 5 "checksum entry for ${archive} is missing or ambiguous.
The release checksum manifest is not safe to use. Nothing has been installed."
checksum_line=$(printf '%s\n' "$checksum_lines" | sed -n '1p')
( cd "$tmp" && sha_check_line "$checksum_line" ) \
  || die 5 "checksum verification FAILED for ${archive}.
The download does not match the published SHA256. Nothing has been installed.
Do not use this file; retry, and if it fails again report it."

# --- extract ------------------------------------------------------------------
# The archive expands to a versioned directory containing the binary alongside
# README/LICENSE and reference material — not a bare ./engrt.
members=$(tar -tzf "${tmp}/${archive}") \
  || die 1 "could not inspect ${archive}"
while IFS= read -r member; do
  case "$member" in
    "${name}/"*) ;;
    *) die 1 "archive contains an unexpected member path" ;;
  esac
  case "$member" in
    /*|../*|*/../*|*/..|*'/./'*|*/.|*'\'*) die 1 "archive contains an absolute or traversal path" ;;
  esac
done <<EOF
$members
EOF
tar -tvzf "${tmp}/${archive}" | awk '
  substr($0, 1, 1) !~ /[-d]/ { bad=1 }
  END { exit bad }
' || die 1 "archive contains an unsupported link or special member"
binary_count=$(printf '%s\n' "$members" | awk -v expected="${name}/engrt" '$0 == expected { n++ } END { print n+0 }')
[ "$binary_count" = 1 ] || die 1 "archive must contain exactly one expected runtime executable"

# Stream only the admitted member; other archive content is never extracted.
bin="${tmp}/engrt"
tar -xOzf "${tmp}/${archive}" "${name}/engrt" > "$bin" \
  || die 1 "could not extract the expected runtime executable"
[ -f "$bin" ] || die 1 "could not find the expected runtime binary inside ${archive}"
chmod +x "$bin" 2>/dev/null || true
[ -x "$bin" ] || die 1 "the runtime binary inside ${archive} is not executable"
reported_version=$("$bin" version 2>/dev/null) \
  || die 1 "the runtime binary inside ${archive} could not report its version"
expected_version="engrt ${version#v}"
[ "$reported_version" = "$expected_version" ] \
  || die 1 "the runtime binary reports '${reported_version}', not ${expected_version}"

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

stage_dir=$(mktemp -d "${target}/.engrt.install.XXXXXXXX") \
  || die 6 "could not create a private install staging directory"
staged="${stage_dir}/engrt"
cp "$bin" "$staged" || die 6 "could not stage the runtime in ${target}"
chmod 0755 "$staged" 2>/dev/null || die 6 "could not set runtime mode in ${target}"
mv -f "$staged" "${target}/engrt" \
  || die 6 "could not atomically replace runtime in ${target}"

# --- report -------------------------------------------------------------------
installed=$("${target}/engrt" version 2>/dev/null || echo "${version}")

log ""
log "Installed ${installed}"
log "  location: ${target}/engrt"

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
log "  engrt config validate  # confirm the install"
log ""
log "The Runtime Home is created by the first command you run - there is no"
log "separate setup step. Governance is deliberately not created for you:"
log "until you supply a policy document, the compiled safety profile governs."
log ""
log "Docs: https://docs.engineeringruntime.com"

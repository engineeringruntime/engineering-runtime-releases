#!/bin/sh
# Verify that published release bytes are reachable without credentials.
# This is a read-only manual gate; it never downloads or changes a release.
set -eu

version=${1:-}
os=${2:-}
arch=${3:-}
[ -n "$version" ] && [ -n "$os" ] && [ -n "$arch" ] || {
  printf 'usage: %s VERSION OS ARCH\n' "$0" >&2
  exit 2
}
case "$version" in v[0-9]*[0-9]) ;; *) echo "VERSION must look like v0.10.0" >&2; exit 2;; esac
case "$os" in darwin|linux|windows) ;; *) echo "OS must be darwin, linux or windows" >&2; exit 2;; esac
case "$arch" in amd64|arm64) ;; *) echo "ARCH must be amd64 or arm64" >&2; exit 2;; esac

repo=engineeringruntime/engineering-runtime-releases
base="https://github.com/${repo}/releases/download/${version}"
extension=tar.gz
[ "$os" != windows ] || extension=zip
archive="engrt-${version}-${os}-${arch}.${extension}"

check_url() {
  url=$1
  curl -fsSIL --retry 2 --max-time 15 "$url" >/dev/null 2>&1 || {
    echo "anonymous asset check failed: ${url}" >&2
    exit 1
  }
}

check_url "${base}/${archive}"
check_url "${base}/SHA256SUMS.txt"
echo "Anonymous release assets: PASS (${version} ${os}/${arch})"

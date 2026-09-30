#!/bin/sh
# Offline installer regression fixtures. No network, release or real install.
set -eu
repo_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
test -x "$repo_dir/install.sh"
sh -n "$repo_dir/install.sh"
tmp=$(mktemp -d "${TMPDIR:-/tmp}/er-install-test.XXXXXX")
trap 'rm -rf "$tmp"' EXIT INT TERM
fakebin="$tmp/fakebin"
mkdir -p "$fakebin" "$tmp/releases/v0.10.0/engrt-v0.10.0-darwin-arm64" "$tmp/target"
cat > "$tmp/releases/v0.10.0/engrt-v0.10.0-darwin-arm64/engrt" <<'RUNTIME'
#!/bin/sh
case "${1:-}" in version) printf 'engrt 0.10.0\n';; *) exit 0;; esac
RUNTIME
chmod 0755 "$tmp/releases/v0.10.0/engrt-v0.10.0-darwin-arm64/engrt"
tar -czf "$tmp/releases/v0.10.0/engrt-v0.10.0-darwin-arm64.tar.gz" \
  -C "$tmp/releases/v0.10.0" engrt-v0.10.0-darwin-arm64
( cd "$tmp/releases/v0.10.0" && shasum -a 256 engrt-v0.10.0-darwin-arm64.tar.gz > SHA256SUMS.txt )
cat > "$fakebin/curl" <<'CURL'
#!/bin/sh
set -eu
output=
url=
while [ "$#" -gt 0 ]; do
  case "$1" in -o) output=$2; shift 2;; *) url=$1; shift;; esac
done
case "$url" in
  */releases/download/v0.10.0/*) file=${url##*/}; cp "$ER_FIXTURE/$file" "$output";;
  *) exit 1;;
esac
CURL
chmod 0755 "$fakebin/curl"
cat > "$fakebin/uname" <<'UNAME'
#!/bin/sh
case "${1:-}" in -s) printf 'Darwin\n';; -m) printf 'arm64\n';; esac
UNAME
chmod 0755 "$fakebin/uname"
fixture="$tmp/releases/v0.10.0"
# Reject legacy pins before any download or destination creation, with guidance.
cat > "$fakebin/curl" <<'NODOWNLOAD'
#!/bin/sh
printf 'unexpected-download\n' >> "$ER_DOWNLOAD_MARKER"
exit 99
NODOWNLOAD
for old in v0.9.9 0.9.9 v0.9.10 v0.1.0; do
  status=0
  PATH="$fakebin:/usr/bin:/bin" ER_DOWNLOAD_MARKER="$tmp/download-marker" VERSION="$old" \
    INSTALL_DIR="$tmp/legacy-refusal-target" "$repo_dir/install.sh" > "$tmp/legacy-refusal.out" 2>&1 || status=$?
  test "$status" = 1
  grep -q 'supports v0.10.0 and later' "$tmp/legacy-refusal.out"
  test ! -e "$tmp/download-marker"
  test ! -e "$tmp/legacy-refusal-target"
done
# Current/future/prerelease pins reach asset download rather than legacy refusal.
for supported in v0.10.0 v0.11.0 v1.0.0 v0.10.0-rc.1+build.7; do
  status=0
  PATH="$fakebin:/usr/bin:/bin" ER_DOWNLOAD_MARKER="$tmp/download-marker" VERSION="$supported" \
    INSTALL_DIR="$tmp/legacy-refusal-target" "$repo_dir/install.sh" > "$tmp/supported-pin.out" 2>&1 || status=$?
  test "$status" = 4
  test -f "$tmp/download-marker"
  rm "$tmp/download-marker"
  test ! -e "$tmp/legacy-refusal-target"
done
cat > "$fakebin/curl" <<'CURL'
#!/bin/sh
set -eu
output=
url=
while [ "$#" -gt 0 ]; do
  case "$1" in -o) output=$2; shift 2;; *) url=$1; shift;; esac
done
case "$url" in
  */releases/download/v0.10.0/*) file=${url##*/}; cp "$ER_FIXTURE/$file" "$output";;
  *) exit 1;;
esac
CURL
chmod 0755 "$fakebin/curl"
# The namespace transition installs engrt without overwriting or aliasing runtime.
printf 'old runtime canary\n' > "$tmp/target/runtime"
cp "$tmp/target/runtime" "$tmp/legacy-runtime-canary"
PATH="$fakebin:/usr/bin:/bin" ER_FIXTURE="$fixture" VERSION=v0.10.0 \
  INSTALL_DIR="$tmp/target" "$repo_dir/install.sh" > "$tmp/success.out"
test "$("$tmp/target/engrt" version)" = 'engrt 0.10.0'
test -x "$tmp/target/engrt"
cmp "$tmp/legacy-runtime-canary" "$tmp/target/runtime"
test ! -L "$tmp/target/engrt"
PATH="$fakebin:/usr/bin:/bin" ER_FIXTURE="$fixture" VERSION=v0.10.0 \
  INSTALL_DIR="$tmp/target" "$repo_dir/install.sh" > "$tmp/concurrent-a.out" 2>&1 &
pid_a=$!
PATH="$fakebin:/usr/bin:/bin" ER_FIXTURE="$fixture" VERSION=v0.10.0 \
  INSTALL_DIR="$tmp/target" "$repo_dir/install.sh" > "$tmp/concurrent-b.out" 2>&1 &
pid_b=$!
wait "$pid_a" || exit 1
wait "$pid_b" || exit 1
test "$("$tmp/target/engrt" version)" = 'engrt 0.10.0'
cp "$tmp/target/engrt" "$tmp/old-runtime"
cat > "$tmp/target/engrt" <<'OLD'
#!/bin/sh
printf 'engrt 0.9.8\n'
OLD
chmod 0755 "$tmp/target/engrt"
PATH="$fakebin:/usr/bin:/bin" ER_FIXTURE="$fixture" VERSION=v0.10.0 \
  INSTALL_DIR="$tmp/target" "$repo_dir/install.sh" > "$tmp/upgrade.out"
test "$("$tmp/target/engrt" version)" = 'engrt 0.10.0'
test ! -f "$tmp/target/.engrt.staging.$$"
cp "$tmp/target/engrt" "$tmp/old-runtime"
# A failed destination copy must preserve the old executable AND remove its
# partial staging artifact. The wrapper affects only the explicit test target.
cat > "$fakebin/cp" <<'COPYFAIL'
#!/bin/sh
case "${2:-}" in
  "$ER_TARGET"/.engrt*) printf 'partial-copy-canary\n' > "$2"; exit 1 ;;
  *) exec /bin/cp "$@" ;;
esac
COPYFAIL
chmod 0755 "$fakebin/cp"
if PATH="$fakebin:/usr/bin:/bin" ER_FIXTURE="$fixture" ER_TARGET="$tmp/target" VERSION=v0.10.0 \
    INSTALL_DIR="$tmp/target" "$repo_dir/install.sh" > "$tmp/copy-failure.out" 2>&1; then exit 1; fi
cmp "$tmp/old-runtime" "$tmp/target/engrt"
if [ -n "$(find "$tmp/target" -mindepth 1 -name '.engrt*' -print)" ]; then
  printf 'FAIL installer left partial staging state after copy failure\n' >&2
  exit 1
fi
rm "$fakebin/cp"
cat > "$fakebin/mv" <<'MOVEFAIL'
#!/bin/sh
if [ "${ER_INTERRUPT:-}" = yes ]; then kill -TERM "$PPID"; fi
exit 1
MOVEFAIL
chmod 0755 "$fakebin/mv"
for interrupt in no yes; do
  if PATH="$fakebin:/usr/bin:/bin" ER_FIXTURE="$fixture" ER_INTERRUPT="$interrupt" VERSION=v0.10.0 \
      INSTALL_DIR="$tmp/target" "$repo_dir/install.sh" > "$tmp/rename-$interrupt.out" 2>&1; then exit 1; fi
  cmp "$tmp/old-runtime" "$tmp/target/engrt"
  test -z "$(find "$tmp/target" -mindepth 1 -name '.engrt*' -print)"
done
rm "$fakebin/mv"
printf '0000000000000000000000000000000000000000000000000000000000000000  engrt-v0.10.0-darwin-arm64.tar.gz\n' > "$fixture/SHA256SUMS.txt"
if PATH="$fakebin:/usr/bin:/bin" ER_FIXTURE="$fixture" VERSION=v0.10.0 \
    INSTALL_DIR="$tmp/target" "$repo_dir/install.sh" > "$tmp/checksum.out" 2>&1; then exit 1; fi
cmp "$tmp/old-runtime" "$tmp/target/engrt"
cp "$tmp/releases/v0.10.0/engrt-v0.10.0-darwin-arm64.tar.gz" "$tmp/good.tar.gz"
correct_line=$(cd "$fixture" && shasum -a 256 engrt-v0.10.0-darwin-arm64.tar.gz)
printf '%s\n%s\n' "$correct_line" "$correct_line" > "$fixture/SHA256SUMS.txt"
if PATH="$fakebin:/usr/bin:/bin" ER_FIXTURE="$fixture" VERSION=v0.10.0 \
    INSTALL_DIR="$tmp/target" "$repo_dir/install.sh" > "$tmp/duplicate.out" 2>&1; then exit 1; fi
cmp "$tmp/old-runtime" "$tmp/target/engrt"
printf '%s\n' 'not-a-checksum-manifest' > "$fixture/SHA256SUMS.txt"
if PATH="$fakebin:/usr/bin:/bin" ER_FIXTURE="$fixture" VERSION=v0.10.0 \
    INSTALL_DIR="$tmp/target" "$repo_dir/install.sh" > "$tmp/missing.out" 2>&1; then exit 1; fi
cmp "$tmp/old-runtime" "$tmp/target/engrt"
printf 'corrupt archive\n' > "$fixture/engrt-v0.10.0-darwin-arm64.tar.gz"
( cd "$fixture" && shasum -a 256 engrt-v0.10.0-darwin-arm64.tar.gz > SHA256SUMS.txt )
if PATH="$fakebin:/usr/bin:/bin" ER_FIXTURE="$fixture" VERSION=v0.10.0 \
    INSTALL_DIR="$tmp/target" "$repo_dir/install.sh" > "$tmp/corrupt.out" 2>&1; then exit 1; fi
cmp "$tmp/old-runtime" "$tmp/target/engrt"
mkdir -p "$tmp/bad/engrt-v0.10.0-darwin-arm64"
cat > "$tmp/bad/engrt-v0.10.0-darwin-arm64/engrt" <<'BAD'
#!/bin/sh
printf 'engrt 0.9.8\n'
BAD
chmod 0755 "$tmp/bad/engrt-v0.10.0-darwin-arm64/engrt"
tar -czf "$fixture/engrt-v0.10.0-darwin-arm64.tar.gz" \
  -C "$tmp/bad" engrt-v0.10.0-darwin-arm64
( cd "$fixture" && shasum -a 256 engrt-v0.10.0-darwin-arm64.tar.gz > SHA256SUMS.txt )
if PATH="$fakebin:/usr/bin:/bin" ER_FIXTURE="$fixture" VERSION=v0.10.0 \
    INSTALL_DIR="$tmp/target" "$repo_dir/install.sh" > "$tmp/version.out" 2>&1; then exit 1; fi
cmp "$tmp/old-runtime" "$tmp/target/engrt"
cat > "$tmp/bad/engrt-v0.10.0-darwin-arm64/engrt" <<'BADSUFFIX'
#!/bin/sh
printf 'engrt 0.10.0+tampered\n'
BADSUFFIX
chmod 0755 "$tmp/bad/engrt-v0.10.0-darwin-arm64/engrt"
tar -czf "$fixture/engrt-v0.10.0-darwin-arm64.tar.gz" \
  -C "$tmp/bad" engrt-v0.10.0-darwin-arm64
( cd "$fixture" && shasum -a 256 engrt-v0.10.0-darwin-arm64.tar.gz > SHA256SUMS.txt )
if PATH="$fakebin:/usr/bin:/bin" ER_FIXTURE="$fixture" VERSION=v0.10.0 \
    INSTALL_DIR="$tmp/target" "$repo_dir/install.sh" > "$tmp/version-suffix.out" 2>&1; then exit 1; fi
cmp "$tmp/old-runtime" "$tmp/target/engrt"
mkdir -p "$tmp/link/engrt-v0.10.0-darwin-arm64"
ln -s /tmp/should-not-extract "$tmp/link/engrt-v0.10.0-darwin-arm64/escape"
tar -czf "$fixture/engrt-v0.10.0-darwin-arm64.tar.gz" \
  -C "$tmp/link" engrt-v0.10.0-darwin-arm64
( cd "$fixture" && shasum -a 256 engrt-v0.10.0-darwin-arm64.tar.gz > SHA256SUMS.txt )
if PATH="$fakebin:/usr/bin:/bin" ER_FIXTURE="$fixture" VERSION=v0.10.0 \
    INSTALL_DIR="$tmp/target" "$repo_dir/install.sh" > "$tmp/link.out" 2>&1; then exit 1; fi
cmp "$tmp/old-runtime" "$tmp/target/engrt"
# Even a checksum-matching archive must not supply the executable twice.
tar -czf "$fixture/engrt-v0.10.0-darwin-arm64.tar.gz" \
  -C "$tmp/releases/v0.10.0" engrt-v0.10.0-darwin-arm64/engrt engrt-v0.10.0-darwin-arm64/engrt
( cd "$fixture" && shasum -a 256 engrt-v0.10.0-darwin-arm64.tar.gz > SHA256SUMS.txt )
if PATH="$fakebin:/usr/bin:/bin" ER_FIXTURE="$fixture" VERSION=v0.10.0 \
    INSTALL_DIR="$tmp/target" "$repo_dir/install.sh" > "$tmp/duplicate-binary.out" 2>&1; then exit 1; fi
cmp "$tmp/old-runtime" "$tmp/target/engrt"
printf 'Installer fixtures: PASS (legacy-version refusal without downloads/writes, checksum, manifest/archive refusal, exact version, links/duplicate binary, concurrent install, copy/rename/signal cleanup)\n'

#!/bin/sh
# Offline installer regression fixtures. No network, release or real install.
set -eu
repo_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
test -x "$repo_dir/install.sh"
sh -n "$repo_dir/install.sh"
tmp=$(mktemp -d "${TMPDIR:-/tmp}/er-install-test.XXXXXX")
trap 'rm -rf "$tmp"' EXIT INT TERM
fakebin="$tmp/fakebin"
mkdir -p "$fakebin" "$tmp/releases/v0.9.9-rc.1/engineering-runtime-v0.9.9-rc.1-darwin-arm64" "$tmp/target"
cat > "$tmp/releases/v0.9.9-rc.1/engineering-runtime-v0.9.9-rc.1-darwin-arm64/runtime" <<'RUNTIME'
#!/bin/sh
case "${1:-}" in version) printf 'runtime 0.9.9-rc.1\n';; *) exit 0;; esac
RUNTIME
chmod 0755 "$tmp/releases/v0.9.9-rc.1/engineering-runtime-v0.9.9-rc.1-darwin-arm64/runtime"
tar -czf "$tmp/releases/v0.9.9-rc.1/engineering-runtime-v0.9.9-rc.1-darwin-arm64.tar.gz" \
  -C "$tmp/releases/v0.9.9-rc.1" engineering-runtime-v0.9.9-rc.1-darwin-arm64
( cd "$tmp/releases/v0.9.9-rc.1" && shasum -a 256 engineering-runtime-v0.9.9-rc.1-darwin-arm64.tar.gz > SHA256SUMS.txt )
cat > "$fakebin/curl" <<'CURL'
#!/bin/sh
set -eu
output=
url=
while [ "$#" -gt 0 ]; do
  case "$1" in -o) output=$2; shift 2;; *) url=$1; shift;; esac
done
case "$url" in
  */releases/download/v0.9.9-rc.1/*) file=${url##*/}; cp "$ER_FIXTURE/$file" "$output";;
  *) exit 1;;
esac
CURL
chmod 0755 "$fakebin/curl"
cat > "$fakebin/uname" <<'UNAME'
#!/bin/sh
case "${1:-}" in -s) printf 'Darwin\n';; -m) printf 'arm64\n';; esac
UNAME
chmod 0755 "$fakebin/uname"
fixture="$tmp/releases/v0.9.9-rc.1"
PATH="$fakebin:/usr/bin:/bin" ER_FIXTURE="$fixture" VERSION=v0.9.9-rc.1 \
  INSTALL_DIR="$tmp/target" "$repo_dir/install.sh" > "$tmp/success.out"
test "$("$tmp/target/runtime" version)" = 'runtime 0.9.9-rc.1'
test -x "$tmp/target/runtime"
PATH="$fakebin:/usr/bin:/bin" ER_FIXTURE="$fixture" VERSION=v0.9.9-rc.1 \
  INSTALL_DIR="$tmp/target" "$repo_dir/install.sh" > "$tmp/concurrent-a.out" 2>&1 &
pid_a=$!
PATH="$fakebin:/usr/bin:/bin" ER_FIXTURE="$fixture" VERSION=v0.9.9-rc.1 \
  INSTALL_DIR="$tmp/target" "$repo_dir/install.sh" > "$tmp/concurrent-b.out" 2>&1 &
pid_b=$!
wait "$pid_a" || exit 1
wait "$pid_b" || exit 1
test "$("$tmp/target/runtime" version)" = 'runtime 0.9.9-rc.1'
cp "$tmp/target/runtime" "$tmp/old-runtime"
cat > "$tmp/target/runtime" <<'OLD'
#!/bin/sh
printf 'runtime 0.9.8\n'
OLD
chmod 0755 "$tmp/target/runtime"
PATH="$fakebin:/usr/bin:/bin" ER_FIXTURE="$fixture" VERSION=v0.9.9-rc.1 \
  INSTALL_DIR="$tmp/target" "$repo_dir/install.sh" > "$tmp/upgrade.out"
test "$("$tmp/target/runtime" version)" = 'runtime 0.9.9-rc.1'
test ! -f "$tmp/target/.runtime.staging.$$"
cp "$tmp/target/runtime" "$tmp/old-runtime"
# A failed destination copy must preserve the old executable AND remove its
# partial staging artifact. The wrapper affects only the explicit test target.
cat > "$fakebin/cp" <<'COPYFAIL'
#!/bin/sh
case "${2:-}" in
  "$ER_TARGET"/.runtime*) printf 'partial-copy-canary\n' > "$2"; exit 1 ;;
  *) exec /bin/cp "$@" ;;
esac
COPYFAIL
chmod 0755 "$fakebin/cp"
if PATH="$fakebin:/usr/bin:/bin" ER_FIXTURE="$fixture" ER_TARGET="$tmp/target" VERSION=v0.9.9-rc.1 \
    INSTALL_DIR="$tmp/target" "$repo_dir/install.sh" > "$tmp/copy-failure.out" 2>&1; then exit 1; fi
cmp "$tmp/old-runtime" "$tmp/target/runtime"
if [ -n "$(find "$tmp/target" -mindepth 1 -name '.runtime*' -print)" ]; then
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
  if PATH="$fakebin:/usr/bin:/bin" ER_FIXTURE="$fixture" ER_INTERRUPT="$interrupt" VERSION=v0.9.9-rc.1 \
      INSTALL_DIR="$tmp/target" "$repo_dir/install.sh" > "$tmp/rename-$interrupt.out" 2>&1; then exit 1; fi
  cmp "$tmp/old-runtime" "$tmp/target/runtime"
  test -z "$(find "$tmp/target" -mindepth 1 -name '.runtime*' -print)"
done
rm "$fakebin/mv"
printf '0000000000000000000000000000000000000000000000000000000000000000  engineering-runtime-v0.9.9-rc.1-darwin-arm64.tar.gz\n' > "$fixture/SHA256SUMS.txt"
if PATH="$fakebin:/usr/bin:/bin" ER_FIXTURE="$fixture" VERSION=v0.9.9-rc.1 \
    INSTALL_DIR="$tmp/target" "$repo_dir/install.sh" > "$tmp/checksum.out" 2>&1; then exit 1; fi
cmp "$tmp/old-runtime" "$tmp/target/runtime"
cp "$tmp/releases/v0.9.9-rc.1/engineering-runtime-v0.9.9-rc.1-darwin-arm64.tar.gz" "$tmp/good.tar.gz"
correct_line=$(cd "$fixture" && shasum -a 256 engineering-runtime-v0.9.9-rc.1-darwin-arm64.tar.gz)
printf '%s\n%s\n' "$correct_line" "$correct_line" > "$fixture/SHA256SUMS.txt"
if PATH="$fakebin:/usr/bin:/bin" ER_FIXTURE="$fixture" VERSION=v0.9.9-rc.1 \
    INSTALL_DIR="$tmp/target" "$repo_dir/install.sh" > "$tmp/duplicate.out" 2>&1; then exit 1; fi
cmp "$tmp/old-runtime" "$tmp/target/runtime"
printf '%s\n' 'not-a-checksum-manifest' > "$fixture/SHA256SUMS.txt"
if PATH="$fakebin:/usr/bin:/bin" ER_FIXTURE="$fixture" VERSION=v0.9.9-rc.1 \
    INSTALL_DIR="$tmp/target" "$repo_dir/install.sh" > "$tmp/missing.out" 2>&1; then exit 1; fi
cmp "$tmp/old-runtime" "$tmp/target/runtime"
printf 'corrupt archive\n' > "$fixture/engineering-runtime-v0.9.9-rc.1-darwin-arm64.tar.gz"
( cd "$fixture" && shasum -a 256 engineering-runtime-v0.9.9-rc.1-darwin-arm64.tar.gz > SHA256SUMS.txt )
if PATH="$fakebin:/usr/bin:/bin" ER_FIXTURE="$fixture" VERSION=v0.9.9-rc.1 \
    INSTALL_DIR="$tmp/target" "$repo_dir/install.sh" > "$tmp/corrupt.out" 2>&1; then exit 1; fi
cmp "$tmp/old-runtime" "$tmp/target/runtime"
mkdir -p "$tmp/bad/engineering-runtime-v0.9.9-rc.1-darwin-arm64"
cat > "$tmp/bad/engineering-runtime-v0.9.9-rc.1-darwin-arm64/runtime" <<'BAD'
#!/bin/sh
printf 'runtime 0.9.8\n'
BAD
chmod 0755 "$tmp/bad/engineering-runtime-v0.9.9-rc.1-darwin-arm64/runtime"
tar -czf "$fixture/engineering-runtime-v0.9.9-rc.1-darwin-arm64.tar.gz" \
  -C "$tmp/bad" engineering-runtime-v0.9.9-rc.1-darwin-arm64
( cd "$fixture" && shasum -a 256 engineering-runtime-v0.9.9-rc.1-darwin-arm64.tar.gz > SHA256SUMS.txt )
if PATH="$fakebin:/usr/bin:/bin" ER_FIXTURE="$fixture" VERSION=v0.9.9-rc.1 \
    INSTALL_DIR="$tmp/target" "$repo_dir/install.sh" > "$tmp/version.out" 2>&1; then exit 1; fi
cmp "$tmp/old-runtime" "$tmp/target/runtime"
cat > "$tmp/bad/engineering-runtime-v0.9.9-rc.1-darwin-arm64/runtime" <<'BADSUFFIX'
#!/bin/sh
printf 'runtime 0.9.9-rc.1+tampered\n'
BADSUFFIX
chmod 0755 "$tmp/bad/engineering-runtime-v0.9.9-rc.1-darwin-arm64/runtime"
tar -czf "$fixture/engineering-runtime-v0.9.9-rc.1-darwin-arm64.tar.gz" \
  -C "$tmp/bad" engineering-runtime-v0.9.9-rc.1-darwin-arm64
( cd "$fixture" && shasum -a 256 engineering-runtime-v0.9.9-rc.1-darwin-arm64.tar.gz > SHA256SUMS.txt )
if PATH="$fakebin:/usr/bin:/bin" ER_FIXTURE="$fixture" VERSION=v0.9.9-rc.1 \
    INSTALL_DIR="$tmp/target" "$repo_dir/install.sh" > "$tmp/version-suffix.out" 2>&1; then exit 1; fi
cmp "$tmp/old-runtime" "$tmp/target/runtime"
mkdir -p "$tmp/link/engineering-runtime-v0.9.9-rc.1-darwin-arm64"
ln -s /tmp/should-not-extract "$tmp/link/engineering-runtime-v0.9.9-rc.1-darwin-arm64/escape"
tar -czf "$fixture/engineering-runtime-v0.9.9-rc.1-darwin-arm64.tar.gz" \
  -C "$tmp/link" engineering-runtime-v0.9.9-rc.1-darwin-arm64
( cd "$fixture" && shasum -a 256 engineering-runtime-v0.9.9-rc.1-darwin-arm64.tar.gz > SHA256SUMS.txt )
if PATH="$fakebin:/usr/bin:/bin" ER_FIXTURE="$fixture" VERSION=v0.9.9-rc.1 \
    INSTALL_DIR="$tmp/target" "$repo_dir/install.sh" > "$tmp/link.out" 2>&1; then exit 1; fi
cmp "$tmp/old-runtime" "$tmp/target/runtime"
# Even a checksum-matching archive must not supply the executable twice.
tar -czf "$fixture/engineering-runtime-v0.9.9-rc.1-darwin-arm64.tar.gz" \
  -C "$tmp/releases/v0.9.9-rc.1" engineering-runtime-v0.9.9-rc.1-darwin-arm64/runtime engineering-runtime-v0.9.9-rc.1-darwin-arm64/runtime
( cd "$fixture" && shasum -a 256 engineering-runtime-v0.9.9-rc.1-darwin-arm64.tar.gz > SHA256SUMS.txt )
if PATH="$fakebin:/usr/bin:/bin" ER_FIXTURE="$fixture" VERSION=v0.9.9-rc.1 \
    INSTALL_DIR="$tmp/target" "$repo_dir/install.sh" > "$tmp/duplicate-binary.out" 2>&1; then exit 1; fi
cmp "$tmp/old-runtime" "$tmp/target/runtime"
printf 'Installer fixtures: PASS (checksum, manifest/archive refusal, exact version, links/duplicate binary, concurrent install, copy/rename/signal cleanup)\n'

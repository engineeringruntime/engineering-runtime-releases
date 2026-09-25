#!/bin/sh
# Offline installer regression fixtures. No network, release or real install.
set -eu
repo_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
test -x "$repo_dir/install.sh"
sh -n "$repo_dir/install.sh"
tmp=$(mktemp -d "${TMPDIR:-/tmp}/er-install-test.XXXXXX")
trap 'rm -rf "$tmp"' EXIT INT TERM
fakebin="$tmp/fakebin"
mkdir -p "$fakebin" "$tmp/releases/v0.10.0-rc.1/engrt-v0.10.0-rc.1-darwin-arm64" "$tmp/target"
cat > "$tmp/releases/v0.10.0-rc.1/engrt-v0.10.0-rc.1-darwin-arm64/engrt" <<'ENGRT'
#!/bin/sh
case "${1:-}" in version) printf 'engrt 0.10.0-rc.1\n';; *) exit 0;; esac
ENGRT
chmod 0755 "$tmp/releases/v0.10.0-rc.1/engrt-v0.10.0-rc.1-darwin-arm64/engrt"
tar -czf "$tmp/releases/v0.10.0-rc.1/engrt-v0.10.0-rc.1-darwin-arm64.tar.gz" \
  -C "$tmp/releases/v0.10.0-rc.1" engrt-v0.10.0-rc.1-darwin-arm64
( cd "$tmp/releases/v0.10.0-rc.1" && shasum -a 256 engrt-v0.10.0-rc.1-darwin-arm64.tar.gz > SHA256SUMS.txt )
cat > "$fakebin/curl" <<'CURL'
#!/bin/sh
set -eu
output=
url=
while [ "$#" -gt 0 ]; do
  case "$1" in -o) output=$2; shift 2;; *) url=$1; shift;; esac
done
case "$url" in
  */releases/download/v0.10.0-rc.1/*) file=${url##*/}; cp "$ER_FIXTURE/$file" "$output";;
  *) exit 1;;
esac
CURL
chmod 0755 "$fakebin/curl"
cat > "$fakebin/uname" <<'UNAME'
#!/bin/sh
case "${1:-}" in -s) printf 'Darwin\n';; -m) printf 'arm64\n';; esac
UNAME
chmod 0755 "$fakebin/uname"
fixture="$tmp/releases/v0.10.0-rc.1"
PATH="$fakebin:/usr/bin:/bin" ER_FIXTURE="$fixture" VERSION=v0.10.0-rc.1 \
  INSTALL_DIR="$tmp/target" "$repo_dir/install.sh" > "$tmp/success.out"
test "$("$tmp/target/engrt" version)" = 'engrt 0.10.0-rc.1'
test -x "$tmp/target/engrt"
PATH="$fakebin:/usr/bin:/bin" ER_FIXTURE="$fixture" VERSION=v0.10.0-rc.1 \
  INSTALL_DIR="$tmp/target" "$repo_dir/install.sh" > "$tmp/concurrent-a.out" 2>&1 &
pid_a=$!
PATH="$fakebin:/usr/bin:/bin" ER_FIXTURE="$fixture" VERSION=v0.10.0-rc.1 \
  INSTALL_DIR="$tmp/target" "$repo_dir/install.sh" > "$tmp/concurrent-b.out" 2>&1 &
pid_b=$!
wait "$pid_a" || exit 1
wait "$pid_b" || exit 1
test "$("$tmp/target/engrt" version)" = 'engrt 0.10.0-rc.1'
cp "$tmp/target/engrt" "$tmp/old-engrt"
cat > "$tmp/target/engrt" <<'OLD'
#!/bin/sh
printf 'engrt 0.10.0-rc.0\n'
OLD
chmod 0755 "$tmp/target/engrt"
PATH="$fakebin:/usr/bin:/bin" ER_FIXTURE="$fixture" VERSION=v0.10.0-rc.1 \
  INSTALL_DIR="$tmp/target" "$repo_dir/install.sh" > "$tmp/upgrade.out"
test "$("$tmp/target/engrt" version)" = 'engrt 0.10.0-rc.1'
test ! -f "$tmp/target/.engrt.staging.$$"
cp "$tmp/target/engrt" "$tmp/old-engrt"
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
if PATH="$fakebin:/usr/bin:/bin" ER_FIXTURE="$fixture" ER_TARGET="$tmp/target" VERSION=v0.10.0-rc.1 \
    INSTALL_DIR="$tmp/target" "$repo_dir/install.sh" > "$tmp/copy-failure.out" 2>&1; then exit 1; fi
cmp "$tmp/old-engrt" "$tmp/target/engrt"
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
  if PATH="$fakebin:/usr/bin:/bin" ER_FIXTURE="$fixture" ER_INTERRUPT="$interrupt" VERSION=v0.10.0-rc.1 \
      INSTALL_DIR="$tmp/target" "$repo_dir/install.sh" > "$tmp/rename-$interrupt.out" 2>&1; then exit 1; fi
  cmp "$tmp/old-engrt" "$tmp/target/engrt"
  test -z "$(find "$tmp/target" -mindepth 1 -name '.engrt*' -print)"
done
rm "$fakebin/mv"
printf '0000000000000000000000000000000000000000000000000000000000000000  engrt-v0.10.0-rc.1-darwin-arm64.tar.gz\n' > "$fixture/SHA256SUMS.txt"
if PATH="$fakebin:/usr/bin:/bin" ER_FIXTURE="$fixture" VERSION=v0.10.0-rc.1 \
    INSTALL_DIR="$tmp/target" "$repo_dir/install.sh" > "$tmp/checksum.out" 2>&1; then exit 1; fi
cmp "$tmp/old-engrt" "$tmp/target/engrt"
cp "$tmp/releases/v0.10.0-rc.1/engrt-v0.10.0-rc.1-darwin-arm64.tar.gz" "$tmp/good.tar.gz"
correct_line=$(cd "$fixture" && shasum -a 256 engrt-v0.10.0-rc.1-darwin-arm64.tar.gz)
printf '%s\n%s\n' "$correct_line" "$correct_line" > "$fixture/SHA256SUMS.txt"
if PATH="$fakebin:/usr/bin:/bin" ER_FIXTURE="$fixture" VERSION=v0.10.0-rc.1 \
    INSTALL_DIR="$tmp/target" "$repo_dir/install.sh" > "$tmp/duplicate.out" 2>&1; then exit 1; fi
cmp "$tmp/old-engrt" "$tmp/target/engrt"
printf '%s\n' 'not-a-checksum-manifest' > "$fixture/SHA256SUMS.txt"
if PATH="$fakebin:/usr/bin:/bin" ER_FIXTURE="$fixture" VERSION=v0.10.0-rc.1 \
    INSTALL_DIR="$tmp/target" "$repo_dir/install.sh" > "$tmp/missing.out" 2>&1; then exit 1; fi
cmp "$tmp/old-engrt" "$tmp/target/engrt"
printf 'corrupt archive\n' > "$fixture/engrt-v0.10.0-rc.1-darwin-arm64.tar.gz"
( cd "$fixture" && shasum -a 256 engrt-v0.10.0-rc.1-darwin-arm64.tar.gz > SHA256SUMS.txt )
if PATH="$fakebin:/usr/bin:/bin" ER_FIXTURE="$fixture" VERSION=v0.10.0-rc.1 \
    INSTALL_DIR="$tmp/target" "$repo_dir/install.sh" > "$tmp/corrupt.out" 2>&1; then exit 1; fi
cmp "$tmp/old-engrt" "$tmp/target/engrt"
mkdir -p "$tmp/bad/engrt-v0.10.0-rc.1-darwin-arm64"
cat > "$tmp/bad/engrt-v0.10.0-rc.1-darwin-arm64/engrt" <<'BAD'
#!/bin/sh
printf 'engrt 0.10.0-rc.0\n'
BAD
chmod 0755 "$tmp/bad/engrt-v0.10.0-rc.1-darwin-arm64/engrt"
tar -czf "$fixture/engrt-v0.10.0-rc.1-darwin-arm64.tar.gz" \
  -C "$tmp/bad" engrt-v0.10.0-rc.1-darwin-arm64
( cd "$fixture" && shasum -a 256 engrt-v0.10.0-rc.1-darwin-arm64.tar.gz > SHA256SUMS.txt )
if PATH="$fakebin:/usr/bin:/bin" ER_FIXTURE="$fixture" VERSION=v0.10.0-rc.1 \
    INSTALL_DIR="$tmp/target" "$repo_dir/install.sh" > "$tmp/version.out" 2>&1; then exit 1; fi
cmp "$tmp/old-engrt" "$tmp/target/engrt"
cat > "$tmp/bad/engrt-v0.10.0-rc.1-darwin-arm64/engrt" <<'BADSUFFIX'
#!/bin/sh
printf 'engrt 0.10.0-rc.1+tampered\n'
BADSUFFIX
chmod 0755 "$tmp/bad/engrt-v0.10.0-rc.1-darwin-arm64/engrt"
tar -czf "$fixture/engrt-v0.10.0-rc.1-darwin-arm64.tar.gz" \
  -C "$tmp/bad" engrt-v0.10.0-rc.1-darwin-arm64
( cd "$fixture" && shasum -a 256 engrt-v0.10.0-rc.1-darwin-arm64.tar.gz > SHA256SUMS.txt )
if PATH="$fakebin:/usr/bin:/bin" ER_FIXTURE="$fixture" VERSION=v0.10.0-rc.1 \
    INSTALL_DIR="$tmp/target" "$repo_dir/install.sh" > "$tmp/version-suffix.out" 2>&1; then exit 1; fi
cmp "$tmp/old-engrt" "$tmp/target/engrt"
mkdir -p "$tmp/link/engrt-v0.10.0-rc.1-darwin-arm64"
ln -s /tmp/should-not-extract "$tmp/link/engrt-v0.10.0-rc.1-darwin-arm64/escape"
tar -czf "$fixture/engrt-v0.10.0-rc.1-darwin-arm64.tar.gz" \
  -C "$tmp/link" engrt-v0.10.0-rc.1-darwin-arm64
( cd "$fixture" && shasum -a 256 engrt-v0.10.0-rc.1-darwin-arm64.tar.gz > SHA256SUMS.txt )
if PATH="$fakebin:/usr/bin:/bin" ER_FIXTURE="$fixture" VERSION=v0.10.0-rc.1 \
    INSTALL_DIR="$tmp/target" "$repo_dir/install.sh" > "$tmp/link.out" 2>&1; then exit 1; fi
cmp "$tmp/old-engrt" "$tmp/target/engrt"
# Even a checksum-matching archive must not supply the executable twice.
tar -czf "$fixture/engrt-v0.10.0-rc.1-darwin-arm64.tar.gz" \
  -C "$tmp/releases/v0.10.0-rc.1" engrt-v0.10.0-rc.1-darwin-arm64/engrt engrt-v0.10.0-rc.1-darwin-arm64/engrt
( cd "$fixture" && shasum -a 256 engrt-v0.10.0-rc.1-darwin-arm64.tar.gz > SHA256SUMS.txt )
if PATH="$fakebin:/usr/bin:/bin" ER_FIXTURE="$fixture" VERSION=v0.10.0-rc.1 \
    INSTALL_DIR="$tmp/target" "$repo_dir/install.sh" > "$tmp/duplicate-binary.out" 2>&1; then exit 1; fi
cmp "$tmp/old-engrt" "$tmp/target/engrt"
# Releases before v0.10.0 ship `runtime`, not `engrt`: refused before any download.
for old in v0.9.9 v0.9.9-rc.1 v0.8.0; do
  if PATH="$fakebin:/usr/bin:/bin" ER_FIXTURE="$fixture" VERSION="$old" \
      INSTALL_DIR="$tmp/target" "$repo_dir/install.sh" > "$tmp/pre-engrt.out" 2>&1; then exit 1; fi
  grep -q 'predates the engrt executable' "$tmp/pre-engrt.out"
done
cmp "$tmp/old-engrt" "$tmp/target/engrt"
# An earlier release's `runtime` is left untouched, and the install says so.
tar -czf "$fixture/engrt-v0.10.0-rc.1-darwin-arm64.tar.gz" \
  -C "$tmp/releases/v0.10.0-rc.1" engrt-v0.10.0-rc.1-darwin-arm64
( cd "$fixture" && shasum -a 256 engrt-v0.10.0-rc.1-darwin-arm64.tar.gz > SHA256SUMS.txt )
printf '#!/bin/sh\nprintf "runtime 0.9.9\\n"\n' > "$tmp/target/runtime"
chmod 0755 "$tmp/target/runtime"
cp "$tmp/target/runtime" "$tmp/legacy-runtime"
PATH="$fakebin:/usr/bin:/bin" ER_FIXTURE="$fixture" VERSION=v0.10.0-rc.1 \
  INSTALL_DIR="$tmp/target" "$repo_dir/install.sh" > "$tmp/legacy.out" 2>&1
test "$("$tmp/target/engrt" version)" = 'engrt 0.10.0-rc.1'
cmp "$tmp/legacy-runtime" "$tmp/target/runtime"
grep -q 'runtime from an earlier release is still present' "$tmp/legacy.out"
printf 'Installer fixtures: PASS (checksum, manifest/archive refusal, exact version, links/duplicate binary, pre-engrt versions, legacy runtime untouched, concurrent install, copy/rename/signal cleanup)\n'

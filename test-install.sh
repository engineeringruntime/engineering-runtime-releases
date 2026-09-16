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
cp "$tmp/target/runtime" "$tmp/old-runtime"
printf '0000000000000000000000000000000000000000000000000000000000000000  engineering-runtime-v0.9.9-rc.1-darwin-arm64.tar.gz\n' > "$fixture/SHA256SUMS.txt"
if PATH="$fakebin:/usr/bin:/bin" ER_FIXTURE="$fixture" VERSION=v0.9.9-rc.1 \
    INSTALL_DIR="$tmp/target" "$repo_dir/install.sh" > "$tmp/checksum.out" 2>&1; then exit 1; fi
cmp "$tmp/old-runtime" "$tmp/target/runtime"
cp "$tmp/releases/v0.9.9-rc.1/engineering-runtime-v0.9.9-rc.1-darwin-arm64.tar.gz" "$tmp/good.tar.gz"
printf '%s\n%s\n' "$(shasum -a 256 "$tmp/good.tar.gz")" "$(shasum -a 256 "$tmp/good.tar.gz")" > "$fixture/SHA256SUMS.txt"
if PATH="$fakebin:/usr/bin:/bin" ER_FIXTURE="$fixture" VERSION=v0.9.9-rc.1 \
    INSTALL_DIR="$tmp/target" "$repo_dir/install.sh" > "$tmp/duplicate.out" 2>&1; then exit 1; fi
cmp "$tmp/old-runtime" "$tmp/target/runtime"
printf 'Installer fixtures: PASS (exact checksum, checksum failure preservation, duplicate rejection, atomic staged install)\n'

#!/usr/bin/env python3
"""Read-only post-publication inventory gate for downstream distribution.

This verifies consistency of already-published release metadata, not the
original release qualification or exact-byte native test results. Those
remain owned by the Runtime publisher and its independent evidence.
"""

import argparse
import json
from pathlib import Path
import re


TAG = re.compile(r"^v(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$")
SHA256 = re.compile(r"^[0-9a-f]{64}$")
REVISION = re.compile(r"^[0-9a-f]{40}$")
PLATFORMS = {(os_name, arch) for os_name in ("darwin", "linux", "windows")
             for arch in ("amd64", "arm64")}


class DistributionNotReady(ValueError):
    """Release is not suitable for downstream version propagation."""


def _require(condition, message):
    if not condition:
        raise DistributionNotReady(message)


def verify_publication(release, latest, provenance, checksums, requested_tag):
    _require(bool(TAG.fullmatch(requested_tag)), "Expected an exact stable vX.Y.Z tag")
    _require(release.get("tag_name") == requested_tag, "Requested release tag differs")
    _require(latest.get("tag_name") == requested_tag,
             "Requested release is not GitHub Latest; refuse stale promotion")
    _require(not release.get("draft") and not release.get("prerelease"),
             "Drafts and prereleases are not eligible")
    _require(not latest.get("draft") and not latest.get("prerelease"),
             "GitHub Latest must be stable")
    _require(provenance.get("format") == 1, "Unknown provenance format")
    _require(provenance.get("version") == requested_tag, "Provenance version differs")
    _require(bool(REVISION.fullmatch(str(provenance.get("source_revision", "")))),
             "Missing qualified source revision in provenance")

    rows = provenance.get("archives", [])
    _require(isinstance(rows, list) and len(rows) == len(PLATFORMS),
             "Provenance must list six platform archives")
    expected = {}
    seen_platforms = set()
    for row in rows:
        os_name, arch = row.get("os"), row.get("arch")
        _require((os_name, arch) in PLATFORMS and (os_name, arch) not in seen_platforms,
                 "Unknown or duplicate platform in provenance")
        seen_platforms.add((os_name, arch))
        ext = "zip" if os_name == "windows" else "tar.gz"
        name = f"engrt-{requested_tag}-{os_name}-{arch}.{ext}"
        _require(row.get("archive") == name, "Archive name differs from release contract")
        _require(bool(SHA256.fullmatch(str(row.get("sha256", "")))),
                 "Invalid archive digest in provenance")
        _require(bool(SHA256.fullmatch(str(row.get("binary_sha256", "")))),
                 "Invalid binary digest in provenance")
        expected[name] = row["sha256"]
    _require(seen_platforms == PLATFORMS, "Incomplete native platform inventory")

    checksum_map = {}
    for line in checksums.splitlines():
        match = re.fullmatch(r"([0-9a-f]{64})  (\S+)", line)
        _require(match is not None, "Malformed SHA256SUMS line")
        digest, name = match.groups()
        _require(name not in checksum_map, "Duplicate checksum entry")
        checksum_map[name] = digest
    _require(checksum_map == expected, "Checksums do not match provenance")

    assets = release.get("assets", [])
    _require(isinstance(assets, list), "Release asset inventory is missing")
    expected_assets = set(expected) | {"PROVENANCE.json", "SHA256SUMS.txt"}
    _require(len(assets) == len(expected_assets), "Release must have eight assets")
    asset_names = {a.get("name") for a in assets}
    _require(asset_names == expected_assets, "Release assets differ from provenance")
    for asset in assets:
        _require(asset.get("state") == "uploaded" and asset.get("size", 0) > 0,
                 "Release asset was not completely uploaded")
        name = asset["name"]
        if name in expected and asset.get("digest"):
            _require(asset["digest"] == "sha256:" + expected[name],
                     "Published archive API digest differs from provenance")
    return requested_tag


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--release", type=Path, required=True)
    parser.add_argument("--latest", type=Path, required=True)
    parser.add_argument("--provenance", type=Path, required=True)
    parser.add_argument("--checksums", type=Path, required=True)
    parser.add_argument("--tag", required=True)
    args = parser.parse_args()
    try:
        verified = verify_publication(
            json.loads(args.release.read_text()),
            json.loads(args.latest.read_text()),
            json.loads(args.provenance.read_text()),
            args.checksums.read_text(),
            args.tag,
        )
    except (DistributionNotReady, OSError, ValueError, TypeError, KeyError) as error:
        parser.exit(1, f"Distribution inventory not ready: {error}\n")
    print(f"Ready for downstream distribution handoff: {verified}")


if __name__ == "__main__":
    main()

"""Offline regression checks for downstream publication-readiness verification."""

import copy
import importlib.util
from pathlib import Path
import unittest


module_path = Path(__file__).with_name("verify-distribution-release.py")
spec = importlib.util.spec_from_file_location("verify_distribution_release", module_path)
gate = importlib.util.module_from_spec(spec)
spec.loader.exec_module(gate)


def fixtures(tag="v0.13.0"):
    rows = []
    for os_name in ("darwin", "linux", "windows"):
        for arch in ("amd64", "arm64"):
            ext = "zip" if os_name == "windows" else "tar.gz"
            rows.append({
                "archive": f"engrt-{tag}-{os_name}-{arch}.{ext}",
                "os": os_name,
                "arch": arch,
                "sha256": "a" * 64,
                "binary_sha256": "b" * 64,
            })
    release = {
        "tag_name": tag, "draft": False, "prerelease": False,
        "assets": [{"name": row["archive"], "size": 42,
                    "state": "uploaded", "digest": "sha256:" + row["sha256"]}
                   for row in rows] + [
                       {"name": "SHA256SUMS.txt", "size": 50, "state": "uploaded"},
                       {"name": "PROVENANCE.json", "size": 50, "state": "uploaded"},
                   ],
    }
    latest = {"tag_name": tag, "draft": False, "prerelease": False}
    provenance = {
        "format": 1, "version": tag, "source_revision": "c" * 40,
        "archives": rows,
    }
    sums = "".join(f"{row['sha256']}  {row['archive']}\n" for row in rows)
    return [release, latest, provenance, sums, tag]


class DistributionGateTests(unittest.TestCase):
    def check(self, values):
        return gate.verify_publication(*values)

    def test_verified_inventory(self):
        self.assertEqual(self.check(fixtures()), "v0.13.0")

    def test_blocks_stale_event(self):
        values = fixtures()
        values[1]["tag_name"] = "v0.14.0"
        with self.assertRaisesRegex(gate.DistributionNotReady, "not GitHub Latest"):
            self.check(values)

    def test_blocks_draft_or_prerelease(self):
        for field in ("draft", "prerelease"):
            with self.subTest(field=field):
                values = fixtures()
                values[0][field] = True
                with self.assertRaises(gate.DistributionNotReady):
                    self.check(values)

    def test_blocks_wrong_provenance_version(self):
        values = fixtures()
        values[2]["version"] = "v0.12.0"
        with self.assertRaises(gate.DistributionNotReady):
            self.check(values)

    def test_blocks_missing_asset(self):
        values = fixtures()
        values[0]["assets"].pop()
        with self.assertRaises(gate.DistributionNotReady):
            self.check(values)

    def test_blocks_missing_platform(self):
        values = fixtures()
        values[2]["archives"].pop()
        with self.assertRaises(gate.DistributionNotReady):
            self.check(values)

    def test_blocks_checksum_disagreement(self):
        values = fixtures()
        values[3] = values[3].replace("a" * 64, "d" * 64, 1)
        with self.assertRaises(gate.DistributionNotReady):
            self.check(values)

    def test_blocks_api_digest_disagreement(self):
        values = fixtures()
        values[0]["assets"][0]["digest"] = "sha256:" + "e" * 64
        with self.assertRaises(gate.DistributionNotReady):
            self.check(values)

    def test_blocks_bad_source_revision(self):
        values = fixtures()
        values[2]["source_revision"] = "none"
        with self.assertRaises(gate.DistributionNotReady):
            self.check(values)

    def test_blocks_extra_checksums(self):
        values = fixtures()
        values[3] += "0" * 64 + "  unexpected.tar.gz\n"
        with self.assertRaises(gate.DistributionNotReady):
            self.check(values)


if __name__ == "__main__":
    unittest.main()

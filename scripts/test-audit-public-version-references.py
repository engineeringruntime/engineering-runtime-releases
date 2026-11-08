"""Offline checks for intentionally narrow public-version hygiene rules."""

import importlib.util
from pathlib import Path
import unittest


module_path = Path(__file__).with_name("audit-public-version-references.py")
spec = importlib.util.spec_from_file_location("audit_public_version_references", module_path)
hygiene = importlib.util.module_from_spec(spec)
spec.loader.exec_module(hygiene)


DOCS = 'extra:\n  runtime_release: "0.13.0"\n  runtime_release_date: "October 21, 2026"\n'
HOME = '<a class="er-pill" href="/install/"><b>Latest stable release</b></a>'
RELEASES_PAGE = 'For the currently approved release, consult Docs.\n## v0.13.0 release highlight\n'
FAQ = 'For current providers, see technical documentation.'
RELEASES_README = (
    '<!-- latest-release:start -->\n'
    '## Latest release — v0.13.0\n'
    '| engrt-v0.13.0-darwin-arm64.tar.gz |\n'
    '<!-- latest-release:end -->\n'
    'Use the latest installer without VERSION; release v0.10.0 used older binary.\n'
)
CAPABILITIES = (
    'Tested with engrt 0.13.0 (historical).\n'
    'Capabilities require engrt_version: ">=0.13.0".\n'
    'Install with the default installer.\n'
)


def scan(docs=DOCS, home=HOME, releases_page=RELEASES_PAGE, faq=FAQ,
         releases_readme=RELEASES_README, capabilities=CAPABILITIES,
         tag="v0.13.0"):
    return hygiene.find_hygiene_items(
        tag, docs, home, releases_page, faq, releases_readme, capabilities
    )


class HygieneTests(unittest.TestCase):
    def test_current_references_and_history_are_safe(self):
        self.assertEqual(scan(), [])

    def test_approved_docs_metadata_lag_is_reported(self):
        issues = scan(tag="v0.14.0")
        self.assertTrue(any("mkdocs.yaml" == issue["path"] for issue in issues))

    def test_reintroduced_hardcoded_latest_version_is_reported(self):
        home = '<a class="er-pill" href="/install/"><b>v0.13.0</b></a>'
        issues = scan(home=home)
        self.assertTrue(any(issue["path"] == "docs/index.md" for issue in issues))

    def test_pinned_generic_installs_are_reported(self):
        issues = scan(capabilities=CAPABILITIES + "\nVERSION=v0.13.0\n")
        self.assertTrue(any(issue["repository"] == "engineering-runtime-capabilities"
                            for issue in issues))

    def test_generated_latest_block_must_exist(self):
        issues = scan(releases_readme="No generated marker")
        self.assertTrue(any("Generated" in issue["reason"] for issue in issues))

    def test_stale_generated_latest_block_is_only_advisory(self):
        issues = scan(tag="v0.14.0")
        self.assertTrue(any(issue["repository"] == "engineering-runtime-releases"
                            for issue in issues))

    def test_invalid_tag_fails(self):
        with self.assertRaises(ValueError):
            scan(tag="v0.14.0-rc.1")


if __name__ == "__main__":
    unittest.main()

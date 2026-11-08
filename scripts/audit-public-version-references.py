#!/usr/bin/env python3
"""Conservative, read-only check of allowlisted public release references.

Only current-facing fields with known semantics are checked. Historical release
notes, tested output and capability minimum versions are not rewritten or
treated as stale just because a newer release exists.
"""

import argparse
import json
import os
from pathlib import Path
import re


def find_hygiene_items(tag, docs_config, website_home, website_releases,
                       website_faq, releases_readme, capabilities_readme):
    if not re.fullmatch(r"v[0-9]+\.[0-9]+\.[0-9]+", tag):
        raise ValueError("expected an exact stable release tag")
    version = tag[1:]
    findings = []

    def report(repo, path, reason):
        findings.append({"repository": repo, "path": path, "reason": reason})

    docs_version = re.search(
        r'(?m)^\s{2}runtime_release:\s*["\x27]?([0-9]+\.[0-9]+\.[0-9]+)',
        docs_config,
    )
    if not docs_version:
        report("engineering-runtime-docs", "mkdocs.yaml",
               "Approved current release metadata not found")
    elif docs_version.group(1) != version:
        report("engineering-runtime-docs", "mkdocs.yaml",
               f"Approved release metadata is {docs_version.group(1)}; review promotion to {version}")
    if not re.search(r'(?m)^\s{2}runtime_release_date:\s*\S+', docs_config):
        report("engineering-runtime-docs", "mkdocs.yaml",
               "Approved release publication date metadata not found")

    # Inspect only the hero: dated posts and snapshots may legitimately mention
    # earlier versions elsewhere in this long Markdown source.
    hero = website_home[:2500]
    if re.search(r'class="er-pill"[^>]*>[\s\S]{0,250}<b>\s*v[0-9]+\.[0-9]+\.[0-9]+',
                 hero):
        report("engineering-runtime-website", "docs/index.md",
               "Homepage hero has a hardcoded current-version badge")
    if re.search(r'Latest published stable release:\s*v[0-9]+\.[0-9]+\.[0-9]+',
                 website_releases):
        report("engineering-runtime-website", "docs/releases.md",
               "Release entry point reintroduced a pinned current-release label")
    if re.search(r'As of v[0-9]+\.[0-9]+\.[0-9]+,\s*the public documentation covers',
                 website_faq):
        report("engineering-runtime-website", "docs/references/faq.md",
               "Provider FAQ has an outdated current-version convention")

    # The Releases README latest-release block is intentionally generated at
    # publication and MUST keep its exact historical/versioned asset list.
    generated = re.search(
        r'<!-- latest-release:start -->([\s\S]*?)<!-- latest-release:end -->',
        releases_readme,
    )
    if not generated:
        report("engineering-runtime-releases", "README.md",
               "Generated latest-release block is missing")
    elif not re.search(rf'Latest release\s+[—-]\s+{re.escape(tag)}\b',
                       generated.group(1)):
        report("engineering-runtime-releases", "README.md",
               "Generated Latest block does not yet match the published tag")
    evergreen_releases = re.sub(
        r'<!-- latest-release:start -->[\s\S]*?<!-- latest-release:end -->',
        "", releases_readme,
    )
    pinned = re.compile(r'\bVERSION=v[0-9]+\.[0-9]+\.[0-9]+|'
                        r'-Version\s+v[0-9]+\.[0-9]+\.[0-9]+')
    if pinned.search(evergreen_releases):
        report("engineering-runtime-releases", "README.md",
               "General installation instructions have a hardcoded tag")
    if pinned.search(capabilities_readme):
        report("engineering-runtime-capabilities", "README.md",
               "Capabilities quick start has a hardcoded install tag")

    return findings


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--tag", required=True)
    for name in ("docs-config", "website-home", "website-releases",
                 "website-faq", "releases-readme", "capabilities-readme"):
        parser.add_argument("--" + name, required=True, type=Path)
    args = parser.parse_args()
    try:
        issues = find_hygiene_items(
            args.tag, args.docs_config.read_text(),
            args.website_home.read_text(), args.website_releases.read_text(),
            args.website_faq.read_text(), args.releases_readme.read_text(),
            args.capabilities_readme.read_text(),
        )
    except (OSError, ValueError) as exc:
        parser.exit(1, f"Unable to audit public version hygiene: {exc}\n")

    summary = ["### Public release-reference hygiene (advisory)",
               f"Latest published stable tag: **{args.tag}**.",
               "This check does not prove release qualification or review feature claims.",
               ""]
    if not issues:
        summary.append("No stale references in the allowlisted current-version fields.")
    else:
        summary.append(f"**{len(issues)} item(s) require owner/Engineering Director review:**")
        for issue in issues:
            path = issue["repository"] + "/" + issue["path"]
            summary.append(f"- \`{path}\`: {issue['reason']}")
            print(f"::warning title=Public version hygiene::{path}: {issue['reason']}")
    summary.extend([
        "",
        "Historical notes, captured test results and capability minimum versions are excluded.",
        "This is not a full-text organization-wide or rendered-page audit.",
    ])
    print(json.dumps({"tag": args.tag, "findings": issues}, indent=2))
    if os.environ.get("GITHUB_STEP_SUMMARY"):
        with open(os.environ["GITHUB_STEP_SUMMARY"], "a", encoding="utf-8") as file:
            file.write("\n".join(summary) + "\n")


if __name__ == "__main__":
    main()

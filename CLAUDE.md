# CLAUDE.md — engineering-runtime-releases

**Public release, installation, Discussions and Issues home for Runtime.**
Supportive child of the Runtime product hub.

Product hub: [`../CLAUDE.md`](../CLAUDE.md).
ER map: [`../../engineering-runtime-workspace/CLAUDE.md`](../../engineering-runtime-workspace/CLAUDE.md).

---

## What this repo is

The **artifacts live in GitHub Releases, not in git**. The tracked tree is
intentionally just `README.md` + this file — do not "fix" that by committing
binaries.

| Carried by a GitHub Release | Not in this repo |
|---|---|
| Versioned `runtime` binaries per platform | Runtime source code (→ `../engineering-runtime`) |
| `SHA256SUMS.txt` checksums | Build/staging scratch (ephemeral in the Runtime release workflow) |
| Release notes on the Release itself | Customer upgrade guides (→ `../engineering-runtime-docs`) |

The latest published non-draft, non-prerelease Release is the source of truth
for "what a user can install". The README's marked latest-release block mirrors
that release; the Runtime release workflow owns that block and no other README
content. Check with
`gh release list -R engineeringruntime/engineering-runtime-releases`.

This repository is also the source repository for organization Discussions and
the canonical public Issue tracker. Use the stable organization URL for
conversation links:

<https://github.com/orgs/engineeringruntime/discussions>

---

## Hard rules

1. **Never commit binaries, archives, or checksums into git.** They are Release
   assets. This repo stays docs-only.
2. **This repo does not decide what ships** — `../engineering-runtime` source,
   tests, version metadata and release tag do. Publishing here only distributes
   what that binary already is.
3. **Do not write release notes that claim behavior the binary lacks.** Ground
   every note in the core repo's changes for that version.
4. **Tag naming is not free-form.** Match the existing series. Note that both
   `v0.5.3` and `0.5.3` style tags exist historically, and consumers resolve the
   **latest Release** rather than a tag pattern — do not break that assumption.
5. Publishing is a deliberate act. Do not cut, retag, or delete a Release as a
   side effect of another task.
6. Do not hand-edit content between `latest-release:start` and
   `latest-release:end`; it is generated from the published GitHub Latest
   Release. Discussion titles, bodies and categories remain owner-managed and
   are not release artifacts.

---

## Who consumes this repo

| Consumer | How |
|---|---|
| `../engineering-runtime-ci` | Downloads the release archive, verifies `SHA256SUMS.txt`, puts `runtime` on `PATH` (`.github/actions/setup-runtime/`) |
| `../engineering-runtime-series` | `releases.md` reads the latest Release live from the GitHub API |
| `../engineering-runtime-docs` | Install + upgrade instructions point users here |
| End users | Public installer or direct asset download |

Because CI and the public site both read this repo live, a bad or deleted
Release breaks installs and the website's releases page at the same time.

The repository and its release assets are public. Downloads require no GitHub
token; `RUNTIME_GITHUB_TOKEN` is only for later governed GitHub operations.

---

## Same-effort updates

When a new version is published here, check in the same effort:

| Also update | Why |
|---|---|
| `../engineering-runtime-docs` release notes | Upgrade impact for existing users |
| `../engineering-runtime-series` releases landing | Public download story |
| `../engineering-runtime-ci` pinned version (if pinned) | Keep install proofs on a real asset |

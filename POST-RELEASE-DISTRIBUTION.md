# Post-release distribution handoff

The **Runtime release operator** approves and qualifies each exact source revision
and native binary set. The private Runtime publishing workflow transfers those
exact bytes to a stable public GitHub Release. This repository does not qualify,
rebuild, replace, retag, or publish Runtime binaries.

After a stable `release.published` event, the
[`post-release-distribution.yml`](.github/workflows/post-release-distribution.yml)
workflow verifies the published release's **eight-asset inventory** against
`PROVENANCE.json`, `SHA256SUMS.txt`, the exact tag, and GitHub's current
non-prerelease Latest pointer. It tolerates the asset-upload race through
bounded retries, but fails closed on missing, mismatched or stale metadata.
This is a **distribution consistency gate**, not a substitute for the
qualification evidence or downloaded-byte comparison owned by Runtime.

If the gate passes, the workflow dispatches the existing
[`homebrew-tap/update.yml`](https://github.com/engineeringruntime/homebrew-tap/blob/main/.github/workflows/update.yml)
with the exact version. The tap owns formula generation and exact checksum
pins; it explicitly dispatches its native four-platform CI after updating.
An accepted dispatch is **not** a passing Homebrew test.

## One-time setup before enabling automatic dispatch

Configure `HOMEBREW_TAP_DISPATCH_TOKEN` as an Actions secret **in
`engineering-runtime-releases`**. The current workflow expects a
**fine-grained GitHub token** restricted to `engineeringruntime/homebrew-tap`
with Actions: write, and no unnecessary repository privileges. Review its
expiration and rotation policy. Do not use a broadly scoped classic token or
print the secret. The workflow fails closed if the secret is absent.
A GitHub App is preferable longer term, but its **short-lived installation
token must be minted during each run**, not stored as a static secret.

Merge the tap-side workflow change **before** this workflow so it accepts
`release_version` and explicitly starts Homebrew CI.

## Normal and recovery flow

1. Runtime release skill qualifies and the owner approves publication.
2. Runtime publishing creates the public non-draft, non-prerelease GitHub Release.
3. Releases' publication inventory gate accepts that exact stable tag.
4. The tap updater generates and pushes the exact formula, then dispatches CI.
5. The release operator **checks all four Homebrew CI platforms**, verifies the
   formula provenance and tests the installed binary on the owner's Mac.
6. The Engineering Director maintains release notes, schema/policy/provider
   claims and Docs content. Website/README installation links stay evergreen.
   Review the Docs approved version metadata separately.

The `release.published` event may be unavailable if the release was created
using a token that does not propagate workflow events. In that case, after
ensuring the same publication gates are satisfied, recover with the manual
Actions workflow `Post-release distribution handoff` and enter the exact
published stable tag. The workflow is idempotent at the same tag; the tap
updater does not commit again when its formula already matches.

In parallel, the same Releases workflow performs a **read-only, advisory public
version hygiene audit** of allowlisted current-version fields in Docs, Website,
Releases and Capabilities. It flags stale release metadata and newly introduced
hardcoded latest-version instructions without changing historical evidence.
The report is in the workflow job summary and is not a substitute for Engineering
Director review or comprehensive rendered-page verification. Because the audit
can run before Docs promotion finishes, review the report after Docs merge and,
if needed, manually rerun the workflow with `audit_only=true` (no Homebrew
dispatch).

If the handoff fails, **do not close the release**. Investigate the action
logs, correct the missing asset or credentials, and retry without replacing
published binaries. A manual tap updater remains available as a recovery path.

## Scope boundary

This automation handles the **Homebrew handoff** plus a conservative
**read-only version-reference report**. It does not automatically edit
Docs/Website/Capabilities content or determine product changes. Engineering
Director owns that documentation, including policy/schema changes. Historical
proof, capability minimum versions and formula checksums remain unchanged.

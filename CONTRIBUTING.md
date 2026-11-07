# Contributing

This repository publishes Engineering Runtime (`engrt`): its releases, the
installers and the issue tracker for Runtime itself. The `engrt` source code is
private, so the way to change Runtime's behaviour is an issue here.

## How to get involved

1. **Not sure yet, or just an idea?** Start a [Discussion](https://github.com/orgs/engineeringruntime/discussions/categories/ideas): ask in
   [Q&A](https://github.com/orgs/engineeringruntime/discussions/categories/q-a), or share an idea in [Ideas](https://github.com/orgs/engineeringruntime/discussions/categories/ideas).
2. **It is concrete?** Open an issue: a capability problem or request in
   [engineering-runtime-capabilities](https://github.com/engineeringruntime/engineering-runtime-capabilities/issues/new/choose), a problem or request for `engrt`
   itself in [engineering-runtime-releases](https://github.com/engineeringruntime/engineering-runtime-releases/issues/new/choose).
3. **Want to build it?** Capabilities are open source: open a
   [pull request](https://github.com/engineeringruntime/engineering-runtime-capabilities/pulls) to the capabilities repository.

## Where to report what

| You found… | Report it in |
|---|---|
| `engrt` installs, runs or behaves incorrectly | [a bug report here](https://github.com/engineeringruntime/engineering-runtime-releases/issues/new/choose) |
| Something `engrt` should do but does not (a provider, an operation, auth, policy, audit, CLI, MCP) | [a feature request here](https://github.com/engineeringruntime/engineering-runtime-releases/issues/new/choose) |
| A capability fails or is wrong, or you want a new one | [engineering-runtime-capabilities issues](https://github.com/engineeringruntime/engineering-runtime-capabilities/issues/new/choose) |
| A question | [Discussions → Q&A](https://github.com/orgs/engineeringruntime/discussions/categories/q-a) |
| An idea that is not concrete yet | [Discussions → Ideas](https://github.com/orgs/engineeringruntime/discussions/categories/ideas) |
| A security vulnerability | privately, through the [contact page](https://engineeringruntime.com/contact/). Never in a public issue |

Not sure whether it is a capability or `engrt`? Run the same operation
directly (for example `engrt github api GET …`). If it fails there too, report
it here.

## A good bug report

- `engrt version`, your platform and how you installed it.
- The exact command and its output. `--output json` (placed before the
  provider name) shows the refusal or error code.
- What you expected instead.
- The relevant part of your config and policy, and `engrt config validate`.
- **No secrets:** remove tokens, credential values, private repository names,
  hostnames and personal data.

## Pull requests

Pull requests here are for this repository's own files: the README, the
installers (`install.sh`, `install.ps1`) and their tests. A maintainer reviews
and merges them.

- Never commit binaries, archives or checksum files; they are release assets.
- Do not edit the block between `latest-release:start` and
  `latest-release:end` in the README. The release workflow generates it.
- Installer changes must keep verifying `SHA256SUMS.txt` and refusing a
  mismatch, and pass `test-install.sh` (macOS and Linux) and
  `scripts/test-install.ps1` (Windows; the Windows workflow runs it on every
  pull request).

To contribute a capability, see the
[capabilities repository](https://github.com/engineeringruntime/engineering-runtime-capabilities/blob/main/CONTRIBUTING.md).

## Licence

Engineering Runtime is proprietary software under the [binary licence](LICENSE).
For anything beyond a small fix, open an issue before a pull request.

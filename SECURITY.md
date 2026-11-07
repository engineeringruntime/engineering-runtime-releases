# Security policy

## Reporting a vulnerability

**Do not open a public issue, discussion or pull request for a security
problem.** Report it privately, in one of two ways:

1. **On GitHub (preferred):** [**Report a vulnerability**](https://github.com/engineeringruntime/engineering-runtime-releases/security/advisories/new), also on
   this repository's **Security** tab. Only you and the maintainers see the
   report, and the fix, any advisory and your credit are handled in the same
   private thread.
2. **By email**, if you have no GitHub account:
   **[support@engineeringruntime.com](mailto:support@engineeringruntime.com?subject=Security%3A%20)**,
   with a subject that starts with `Security:`.

Please include:

- `engrt version`, your operating system and architecture, and how you
  installed it;
- what is affected and what an attacker could do with it;
- the smallest set of steps that reproduces it;
- whether anyone else knows about it, or it is already public.

While you investigate:

- use test or revoked credentials, never a real token, and never send one;
- touch only systems and data you own or are allowed to test;
- give us a chance to fix it before you disclose it.

## What happens next

- We aim to acknowledge your report within five business days.
- We keep you updated while we investigate and agree on when the issue
  can be disclosed.
- A fix ships in a new release and is described in its release notes. If you
  would like credit, tell us the name to use.

## Supported versions

Security fixes go into the **latest release** only. Upgrade with
`brew update && brew upgrade engineering-runtime`, or re-run the installer from
the [README](README.md#install).

## Scope

In scope:

- the `engrt` binary, on every published platform;
- `install.sh`, `install.ps1`, the release archives and `SHA256SUMS.txt`;
- the Homebrew formula in
  [homebrew-tap](https://github.com/engineeringruntime/homebrew-tap).

We especially want to hear about:

- an operation that gets past a policy denial or the compiled safety profile;
- a token, key or other credential value appearing in output, audit records or
  logs;
- audit records that can be altered without `engrt audit verify` noticing;
- an installer that installs something not matching `SHA256SUMS.txt`.

Report problems in capability files to the
[capabilities repository's security policy](https://github.com/engineeringruntime/engineering-runtime-capabilities/security/policy),
at the same address.

Not in scope:

- attacks that need another process running as the same user on the same
  machine. Runtime does not isolate itself from those, and says so;
- limitations already listed in the
  [release notes](https://docs.engineeringruntime.com/release-notes/);
- vulnerabilities in GitHub or another provider. Report those to that
  provider.

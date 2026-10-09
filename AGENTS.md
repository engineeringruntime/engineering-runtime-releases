# AGENTS.md — engineering-runtime-releases

Read this repository's [CLAUDE.md](CLAUDE.md) first. It is the canonical source-specific instruction contract for Claude, Codex, Gemini and other agents; this is a routing adapter, not a second implementation or release procedure.

**Hub:** Product Engineering. **Repository owns:** published binaries, checksums and release packaging, not source implementation.

Before changing any file, inspect the owning hub guides and Workspace rules, the actual current implementation and relevant runbooks. Verify the task's approved scope, exact revisions, child-specific checks, evidence and authorisation. In a standalone checkout, missing siblings do not create authority to bypass external approval gates.

Read broadly only where authorised; write only to approved repository paths. Record positive and refusal cases, unknowns, failed tests, source and artifact identities where applicable. Reusable regressions belong in owning source/CI repos; agent handoffs in Workspace `agents-artifacts/`; canonical release decisions and proof references in Workspace `releases/vX.Y.Z/evidence/`; private post-release records stay restricted. A lab run is not live production qualification.

For internal development agents, GitHub provider operations must use ENGRT; never silently fall back to gh, direct GitHub API/MCP or remote Git. Founder-controlled ChatGPT connector sessions are separate. Preserve every existing specialised Claude hook and runtime release skill. Do not merge, publish, deploy, spend cloud budget or activate autonomous work without explicit existing approval.

# Decision: OpenCode Receives the Harness via CLAUDE.md Only (Single Source)

**Date:** 2026-09-27
**Decision Owner:** Antonio De Marinis
**Status:** Accepted

## Context

`scripts/install.sh` run on a system with both OpenCode and Claude Code creates two harness sources for OpenCode:

1. Merges the EEA harness + rules URLs into `~/.config/opencode/opencode.json` `instructions`.
2. Symlinks `~/.claude/CLAUDE.md` to `harness/EEA-HARNESS.md`.

OpenCode loads `~/.claude/CLAUDE.md` via its Claude Code compatibility layer, so the harness was injected **twice** into the LLM context on every session (duplicated tokens, drift risk if the two sources diverge). `scripts/verify.sh` flags this as "potential duplication in LLM context".

## Decision

OpenCode's harness source is **solely** the `~/.claude/CLAUDE.md` symlink.

- `~/.config/opencode/opencode.json` must **not** contain the EEA harness or rules URLs in `instructions`.
- The installer's `harness_via_claude` branch already encodes this policy (it merges only the rules URLs when the harness is inherited via CLAUDE.md), but on a fresh install `install_opencode` runs **before** `install_claude`, so the CLAUDE.md symlink does not exist yet and the harness URL gets added anyway. The installer cannot self-heal; deduplication must be done manually (or the install order fixed upstream).

## Consequences

### Positive

- Harness loaded exactly once; no context/token duplication.
- Local symlink means no network dependency on `raw.githubusercontent.com` at OpenCode startup.

### Negative / Trade-offs

- Setting `OPENCODE_DISABLE_CLAUDE_CODE_PROMPT=1` silently removes the harness from OpenCode; the URL would need to be re-added to `opencode.json` in that case.
- The setup depends on the Claude Code compatibility path; deleting `~/.claude/CLAUDE.md` breaks it silently (detectable via `verify.sh`).
- The installer ordering bug remains; worth an upstream fix (check for an existing CLAUDE.md harness symlink before deciding what to merge into `opencode.json`).

## Related

- `scripts/install.sh` — `install_opencode`, `install_claude`, `harness_via_claude` branch
- `scripts/verify.sh` — `check_opencode` duplication warning
- `docs/decisions/installer-backup-merge.md` — installer backup/merge policy

# Decision: Safe Installer — Backup and Merge Existing Configs

**Date:** 2026-05-16
**Decision Owner:** Antonio De Marinis
**Status:** Accepted

## Context

The EEA AI Harness installer (`scripts/install.sh`) was previously unsafe for developers who already had global agent configurations (e.g., a personal `CLAUDE.md` with graphify instructions, or a team `opencode.json`). The installer would either overwrite or skip these files without preserving the existing content, leading to lost personal/team instructions.

## Decision

The installer **must** back up and merge existing agent configs instead of overwriting them.

| Agent | Strategy |
|---|---|
| **OpenCode** | Detect `opencode.json` and `opencode.jsonc`. Merge the EEA harness URL into the existing `instructions` array. |
| **Claude Code** | Back up existing `CLAUDE.md`, then append an EEA harness reference section at the end. |
| **Hermes, Pi, Gemini** | Same pattern as Claude: backup + append reference. |

### Backup Behavior

- Backups are **timestamped** (`filename.backup-YYYYMMDD-HHMMSS`) and accumulate per run.
- `--no-backup` flag available for automation (not recommended for interactive use).
- Existing symlinks that already point to the EEA harness are detected and skipped.

### JSONC Parsing

OpenCode configs may be `.jsonc` (JSON with comments). The merge logic uses a robust Python state-machine parser that:
- Strips `//` single-line comments
- Strips `/* */` multi-line comments
- Removes trailing commas
- **Does not** break URLs containing `//` (e.g., `https://example.com/path`)

## Consequences

### Positive
- Developers with existing global configs can install the EEA harness without losing personal instructions.
- Backups provide an immediate restore path if something goes wrong.
- No manual merge steps required for most users.

### Negative / Trade-offs
- `.jsonc` comments are stripped during merge (original preserved in backup).
- Backups accumulate over time; users should periodically clean old backups.
- Slightly more complex installer logic to maintain.

## Related

- `scripts/install.sh` — implementation
- `docs/BOOTSTRAP.md` — user-facing documentation
- `docs/agent-profiles/opencode.md` and `docs/agent-profiles/claudecode.md` — per-agent merge details

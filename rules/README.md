# Rules

This directory contains **organization-wide rule files** that constrain and guide AI agent behavior across all EEA projects.

## What Goes Here

- **Prohibitions** — what agents must never do (security, compliance, operational safety)
- **Mandatory behaviors** — what agents must always do (end-of-session actions, verification steps)
- **Style constraints** — coding standards that apply org-wide
- **Process rules** — workflow requirements (PR review, commit conventions, etc.)

## What Does NOT Go Here

- Project-specific rules (those belong in `{repo}/.agents/`)
- Skill-specific guidance (those belong in `src/skills/{name}/`)
- Tool-specific configuration (those belong in `agents/`)

## File Naming Convention

```
rules/{domain}.{type}.md
```

| Type | Suffix | Example |
|------|--------|---------|
| Prohibitions | `.prohibitions.md` | `eeaprohibitions.rules.md` |
| Mandatory actions | `.mandatory.md` | `eeamandatory.rules.md` |
| Style guide | `.style.md` | `python.style.md` |
| Process | `.process.md` | `pr-review.process.md` |

> **Note:** The `.rules.md` extension is kept for backward compatibility with agentget.

## Available Rule Sets

| File | Purpose |
|------|---------|
| `eeaprohibitions.rules.md` | Global prohibitions (security, operational safety, code quality) |
| `eeamandatory.rules.md` | Mandatory end-of-session and verification actions |

## Usage

Agents load rule files based on context:
- **OpenCode**: Referenced via `harness/EEA-HARNESS.md` routing rules
- **Claude Code**: Loaded from symlinked `~/.claude/CLAUDE.md`
- **Other agents**: Referenced in their respective profiles under `agents/`

Rule files are written in Markdown and should be human-readable as well as agent-actionable.

---

*Last updated: 2026-05-14*

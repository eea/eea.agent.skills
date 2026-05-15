# Agents

This directory contains **per-tool agent profiles** that explain how to wire the EEA AI Harness into specific agentic coding tools.

## What Goes Here

- Tool-specific setup instructions (OpenCode, Claude Code, Hermes, Gemini, Pi)
- Path conventions for each tool
- Known limitations or special behaviors
- Troubleshooting for common issues

## What Does NOT Go Here

- Org-wide rules (those are in `rules/`)
- Reusable skills (those are in `skills/`)
- Generic instructions (those are in `instructions/`)

## Available Profiles

| File | Tool | Status |
|------|------|--------|
| `opencode.md` | OpenCode | Ready |
| `claudecode.md` | Claude Code | Ready |
| `hermes.md` | Hermes Agent | Ready |
| `gemini.md` | Gemini (Google) | Ready |
| `pi.md` | Pi (Earendil Works) | Ready |

## Profile Format

Each profile should include:

1. **Tool overview** — what the tool is and how it loads instructions
2. **Installation** — how to install the EEA harness for this tool
3. **Path conventions** — where the tool looks for files
4. **Verification** — how to confirm the harness is loaded
5. **Troubleshooting** — common issues and fixes
6. **Limitations** — known constraints

## Adding a New Agent Profile

1. Create `{tool-name}.md` in this directory
2. Follow the format above
3. Update the table in this README
4. Update `harness/EEA-HARNESS.md` Tool-Specific Wiring section

---

*Last updated: 2026-05-14*

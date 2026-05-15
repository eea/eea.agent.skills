# EEA AI Harness — Bootstrap Guide

Quick start for EEA developers who want to use the EEA AI Harness with their coding agents.

---

## What You Get

The EEA AI Harness provides:

- **Org-wide rules** — security, compliance, and quality standards
- **Reusable skills** — expert capabilities for Docker, React, design review, etc.
- **Mandatory protocols** — required actions at session end
- **Tool-specific wiring** — setup instructions for OpenCode, Claude Code, Gemini, etc.

---

## One-Line Install (Recommended)

If you have [agentget](https://github.com/joeyism/agentget) installed:

```bash
agentget install eea/eea.agent.skills
```

This will:
1. Clone the harness to `~/.eea/agent-harness`
2. Detect your installed agents (OpenCode, Claude, etc.)
3. Create appropriate symlinks
4. Verify the setup

---

## Manual Install

### Step 1: Clone the Harness

```bash
mkdir -p ~/.eea
[ -d ~/.eea/agent-harness/.git ] || \
  git clone https://github.com/eea/eea.agent.skills.git ~/.eea/agent-harness
```

### Step 2: Wire Your Agent

#### OpenCode (Recommended Method)

Add to your project's `opencode.json`:

```json
{
  "instructions": [
    "https://raw.githubusercontent.com/eea/eea.agent.skills/main/harness/EEA-HARNESS.md"
  ]
}
```

Or add globally:
```bash
mkdir -p ~/.config/opencode
cp ~/.eea/agent-harness/docs/opencode-examples/global-opencode.json ~/.config/opencode/opencode.json
```

See [`agents/opencode.md`](../agents/opencode.md) for full details.

#### Claude Code

```bash
mkdir -p ~/.claude
ln -sf ~/.eea/agent-harness/harness/EEA-HARNESS.md ~/.claude/CLAUDE.md
```

See [`agents/claudecode.md`](../agents/claudecode.md) for full details.

#### Hermes Agent

```bash
mkdir -p ~/.hermes
ln -sf ~/.eea/agent-harness/harness/EEA-HARNESS.md ~/.hermes/HERMES.md
```

See [`agents/hermes.md`](../agents/hermes.md) for full details.

#### Gemini

Gemini requires copying instructions into your IDE or API configuration. See [`agents/gemini.md`](../agents/gemini.md) for options.

#### Pi

```bash
mkdir -p ~/.pi/agent
ln -sf ~/.eea/agent-harness/harness/EEA-HARNESS.md ~/.pi/agent/AGENTS.md
```

Pi loads `AGENTS.md` from `~/.pi/agent/` and walks up from the current directory. We recommend standardizing on `AGENTS.md` for cross-agent compatibility.

See [`agents/pi.md`](../agents/pi.md) for full details.

---

## Step 3: Verify Installation

Start your agent and ask:

```
What are the EEA global prohibitions?
```

The agent should reference rules from `EEA-HARNESS.md` (e.g., never commit secrets, never modify CI without request).

---

## Adding Project-Local Rules

Every EEA project should have local instructions that add to (not replace) the org harness.

Create `{your-project}/AGENTS.md`:

```markdown
# My Project

## Your Role

You are working on [description].

## Tech Stack

- [Stack]

## Project-Specific Rules

- [Rule 1]
- [Rule 2]

## EEA Global Harness

See: https://raw.githubusercontent.com/eea/eea.agent.skills/main/harness/EEA-HARNESS.md
```

For OpenCode projects, also create `{your-project}/opencode.json` with the instructions URL.

Template available at: [`docs/opencode-examples/project-agents.md`](opencode-examples/project-agents.md)

---

## Keeping Harness Updated

```bash
# Update harness
cd ~/.eea/agent-harness && git pull origin main

# For OpenCode with remote URL: no action needed (always loads latest)
# For symlinked agents: update is automatic (symlinks point to latest)
```

---

## Troubleshooting

### "Harness not loading"

- **OpenCode:** Check `opencode.json` is valid JSON and the URL is accessible
- **Claude Code:** Check `~/.claude/CLAUDE.md` symlink is not broken
- **Hermes:** Check `~/.hermes/HERMES.md` exists and is readable

### "Skills not found"

Install skills manually:
```bash
cp -r ~/.eea/agent-harness/skills/docker-expert ~/.config/opencode/skills/
```

Or use agentget:
```bash
agentget install eea/eea.agent.skills --skill docker-expert
```

### "Rules too restrictive"

Project-specific rules can add exceptions, but org-wide prohibitions cannot be overridden without discussion. Open an issue at `eea/eea.agent.skills` if a rule needs adjustment.

---

## Next Steps

1. **Install the harness** using one of the methods above
2. **Create project-local `AGENTS.md`** for your active projects
3. **Install skills** you need (`docker-expert`, `react-best-practices`, etc.)
4. **Verify** by asking your agent about EEA rules

---

*Last updated: 2026-05-14*

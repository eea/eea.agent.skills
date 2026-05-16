# EEA AI Harness — Bootstrap Guide

Quick start for EEA developers who want to use the EEA AI Harness with their coding agents.

---

## What You Get

The EEA AI Harness provides:

- **Org-wide rules** — security, compliance, and quality standards
- **Reusable skills** — expert capabilities for Docker, React, design review, etc.
- **Mandatory protocols** — required actions at session end
- **Tool-specific wiring** — setup instructions for OpenCode, Claude Code, Gemini, Pi, etc.

---

## Choose Your Installation Method

There are **three** ways to use the harness. Pick the one that fits your workflow.

| Method | Best For | Internet Required |
|---|---|---|
| **A. Automated Global Install** | Most users — one command, all agents | Yes (for clone) |
| **B. Manual Global Install** | Air-gapped or control-oriented users | Once, for clone |
| **C. Project-Embedded** | No global setup, harness lives in one project | Per-session (remote URL) |

---

## A. Automated Global Install (Recommended)

### Option A1: agentget

If you have [agentget](https://github.com/joeyism/agentget) installed:

```bash
agentget install eea/eea.agent.skills
```

### Option A2: curl + bash

If you don't have agentget:

```bash
curl -fsSL https://raw.githubusercontent.com/eea/eea.agent.skills/main/scripts/install.sh | bash
```

Both options will:
1. Clone the harness to `~/.eea/agent-harness`
2. Detect your installed agents (OpenCode, Claude, Hermes, Pi, Gemini)
3. Create appropriate symlinks and copy skills/rules
4. Set up global configurations

**To update:** `cd ~/.eea/agent-harness && git pull origin main`

---

## B. Manual Global Install

For users who prefer to see every step, or who work in restricted environments.

### Step 1: Clone the Harness

```bash
mkdir -p ~/.eea
[ -d ~/.eea/agent-harness/.git ] || \
  git clone https://github.com/eea/eea.agent.skills.git ~/.eea/agent-harness
```

### Step 2: Install Per Agent

#### OpenCode

```bash
mkdir -p ~/.config/opencode
cp ~/.eea/agent-harness/docs/opencode-examples/global-opencode.json ~/.config/opencode/opencode.json
```

See [`agents/opencode.md`](../agents/opencode.md) for alternatives (remote URL, submodule, local file).

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

#### Pi

```bash
mkdir -p ~/.pi/agent
ln -sf ~/.eea/agent-harness/harness/EEA-HARNESS.md ~/.pi/agent/AGENTS.md
```

Pi loads `AGENTS.md` from `~/.pi/agent/` and walks up from the current directory. We recommend standardizing on `AGENTS.md` for cross-agent compatibility.

See [`agents/pi.md`](../agents/pi.md) for full details.

#### Gemini

```bash
mkdir -p ~/.gemini
ln -sf ~/.eea/agent-harness/harness/EEA-HARNESS.md ~/.gemini/GEMINI.md
```

See [`agents/gemini.md`](../agents/gemini.md) for full details.

### Step 3: Install Skills

```bash
# Install all skill directories to all agent skill paths
for dir in ~/.config/opencode/skills ~/.claude/skills ~/.agents/skills; do
  mkdir -p "$dir"
  for skill in ~/.eea/agent-harness/skills/*/; do
    [ -d "$skill" ] && cp -r "$skill" "$dir/"
  done
done
```

### Step 4: Link Rules

```bash
for dir in ~/.claude/rules ~/.config/opencode/rules ~/.hermes/rules ~/.pi/agent/rules; do
  mkdir -p "$dir"
  for rule in ~/.eea/agent-harness/rules/*.rules.md; do
    ln -sf "$rule" "$dir/$(basename "$rule")"
  done
done
```

---

## C. Project-Embedded (No Global Install)

For projects where you don't want (or can't have) a global harness installation. The harness is referenced only within a single project.

### C1: Remote URL (Zero Install)

Add to your project's `opencode.json`:

```json
{
  "instructions": [
    "https://raw.githubusercontent.com/eea/eea.agent.skills/main/harness/EEA-HARNESS.md"
  ]
}
```

**Pros:** Always up to date, no local storage.
**Cons:** Requires internet on every session start.

### C2: Git Submodule (Pinned, Reproducible)

```bash
git submodule add https://github.com/eea/eea.agent.skills.git .harness/eea.agent.skills
```

Then reference locally in `opencode.json`:

```json
{
  "instructions": [
    "{file:.harness/eea.agent.skills/harness/EEA-HARNESS.md}"
  ]
}
```

**Pros:** Works offline, version-controlled, reproducible.
**Cons:** Must update submodule to get harness updates.

### C3: Inline Copy (Self-Contained)

Copy the full harness content into your project's `AGENTS.md`:

```bash
cat ~/.eea/agent-harness/harness/EEA-HARNESS.md >> your-project/AGENTS.md
```

**Pros:** Zero external dependencies, works with any agent.
**Cons:** Must manually re-copy to update.

See [`agents/opencode.md`](../agents/opencode.md) for full OpenCode options.

---

## Verify Installation

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

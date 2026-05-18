# OpenCode Agent Profile

**Tool:** [OpenCode](https://github.com/opencode-ai/opencode)
**Harness support:** Native remote instructions via `opencode.json`
**Priority:** Primary — recommended for all EEA developers.  
**Compliance:** Open-source, audit-able and transparent. Compliant with GDPR/EUDPR. Telemetry can be disabled.

---

## How OpenCode Loads Instructions

OpenCode combines instructions from three sources (in this order):

1. **Local `AGENTS.md`** — walks up from current directory looking for `AGENTS.md`
2. **Global `~/.config/opencode/AGENTS.md`** — per-user global instructions
3. **`opencode.json` instructions** — both local (`{repo}/opencode.json`) and global (`~/.config/opencode/opencode.json`)

All three are combined. Local rules override global rules for conflicts.

---

## Installation Options

> **See [`docs/BOOTSTRAP.md`](../BOOTSTRAP.md) for the canonical 3-method overview.**
> The options below map to **Method C (Project-Embedded)** for OpenCode-specific wiring.

### Option A: Remote URL (Recommended)

Add the EEA harness to your project's `opencode.json`:

```json
{
  "instructions": [
    "https://raw.githubusercontent.com/eea/eea.agent.skills/main/harness/EEA-HARNESS.md"
  ]
}
```

Place this file at your project root:
```
your-eea-project/
├── opencode.json          # <-- add this
├── src/
└── package.json
```

**Pros:**
- Zero installation
- Always up to date (loads latest on each session)
- No local storage needed

**Cons:**
- Requires internet access
- Cannot pin to a specific version (always gets `main` branch)

---

### Option B: Global Configuration

For consultants or personal machines, add to global config:

```bash
mkdir -p ~/.config/opencode
cat > ~/.config/opencode/opencode.json << 'EOF'
{
  "instructions": [
    "https://raw.githubusercontent.com/eea/eea.agent.skills/main/harness/EEA-HARNESS.md"
  ]
}
EOF
```

This applies the EEA harness to all OpenCode sessions on this machine.

---

### Option C: Git Submodule + File Reference

For projects that need reproducible/pinned harness versions:

```bash
# Add harness as submodule
git submodule add https://github.com/eea/eea.agent.skills.git .harness/eea.agent.skills

# Reference local file in opencode.json
cat > opencode.json << 'EOF'
{
  "instructions": [
    "{file:.harness/eea.agent.skills/harness/EEA-HARNESS.md}"
  ]
}
EOF
```

**Pros:**
- Pins to specific commit
- Works offline
- Version controlled with project

**Cons:**
- Requires submodule management
- Must update submodule to get harness updates

---

### Option D: Local Clone + File Reference

For air-gapped or highly restricted environments:

```bash
# Clone harness locally
git clone https://github.com/eea/eea.agent.skills.git ~/.eea/agent-harness

# Reference in opencode.json
cat > opencode.json << 'EOF'
{
  "instructions": [
    "{file:/home/USERNAME/.eea/agent-harness/harness/EEA-HARNESS.md}"
  ]
}
EOF
```

---

### Option E: Merge with an Existing Global Config

If you already have a global `opencode.json` or `opencode.jsonc`, the installer will **back it up and merge** the EEA harness URL into your existing `instructions` array instead of replacing the file.

**What happens:**

```bash
# Before (your existing opencode.json)
{
  "instructions": [
    "{file:~/.my-personal-rules.md}",
    "https://example.com/my-team-rules.md"
  ]
}

# After (installer merged EEA harness)
{
  "instructions": [
    "{file:~/.my-personal-rules.md}",
    "https://example.com/my-team-rules.md",
    "https://raw.githubusercontent.com/eea/eea.agent.skills/main/harness/EEA-HARNESS.md"
  ]
}
```

**Notes:**
- The installer detects both `opencode.json` and `opencode.jsonc`.
- For `.jsonc`, comments are stripped during the merge (your original is preserved in the backup).
- If `python3` is not available, the installer prints the URL and asks you to add it manually.

**Restore if needed:**

```bash
ls ~/.config/opencode/opencode.json.backup-*
cp ~/.config/opencode/opencode.json.backup-20260516-143052 ~/.config/opencode/opencode.json
```

---

### OpenCode + Claude Code: Avoiding Duplication

If you use **both** OpenCode and Claude Code, OpenCode will automatically read `~/.claude/CLAUDE.md` via its Claude Code compatibility mode. This means:

- **If `~/.claude/CLAUDE.md` is symlinked to `EEA-HARNESS.md`**, OpenCode already receives the harness without any `opencode.json` changes.
- **If you also add the EEA URL to `opencode.json`**, the harness will appear **twice** in OpenCode's LLM context.

**What the installer does:**
- Detects if `~/.claude/CLAUDE.md` is linked to the EEA harness.
- If yes, it **skips** adding the URL to `opencode.json` and logs an informational message.

**If you want to force `opencode.json`-only loading** (and ignore `~/.claude/CLAUDE.md`):

```bash
export OPENCODE_DISABLE_CLAUDE_CODE_PROMPT=1
```

Then re-run the installer. This disables Claude Code compatibility for prompts while still allowing `.claude/skills/` discovery.

---

### `AGENTS.md` vs `opencode.json`: Personal vs Org-Wide

OpenCode loads instructions from **two** global sources:

| Source | Purpose | Best For |
|---|---|---|
| `~/.config/opencode/AGENTS.md` | Personal global instructions | Your own preferences, shortcuts, habits |
| `~/.config/opencode/opencode.json` (`instructions` array) | Org-wide / team-shared rules | EEA harness, company standards, project URLs |

**Do not copy the full EEA harness into `AGENTS.md`.**

- `AGENTS.md` is for **personal** rules that follow you across projects.
- `opencode.json` is for **organizational** references that should stay current.
- Copied harness content in `AGENTS.md` will **go stale** (the file is static; it doesn't auto-update when the harness changes on GitHub).

**Correct setup:**

```json
// ~/.config/opencode/opencode.json
{
  "instructions": [
    "https://raw.githubusercontent.com/eea/eea.agent.skills/main/harness/EEA-HARNESS.md"
  ]
}
```

```markdown
<!-- ~/.config/opencode/AGENTS.md — personal stuff only -->
# My Personal Rules

- Always use `pnpm` instead of `npm`
- Prefer `async/await` over raw Promises
```

---

## Project-Local Instructions

For project-specific rules that add to (not replace) the org harness:

1. Create `{repo}/AGENTS.md` with project-specific instructions
2. OpenCode will automatically discover and load it
3. The org harness from `opencode.json` is loaded in addition

Example project `AGENTS.md`:
```markdown
# My EEA Project

## Project-Specific Rules

- Use Python 3.11+ features
- Database migrations must include rollback scripts
- All API changes require OpenAPI spec updates

## For Org-Wide Rules

See: `https://raw.githubusercontent.com/eea/eea.agent.skills/main/harness/EEA-HARNESS.md`
```

---

## Verification

To confirm the EEA harness is loaded:

1. Start OpenCode in an EEA project
2. Ask: "What are the EEA global prohibitions?"
3. The agent should reference rules from `EEA-HARNESS.md`

Or check the system prompt context for the harness URL.

---

## Skills in OpenCode

OpenCode discovers skills from standard paths:

```bash
# Global paths
~/.config/opencode/skills/<name>/SKILL.md
~/.claude/skills/<name>/SKILL.md
~/.agents/skills/<name>/SKILL.md

# Project-local paths
.opencode/skills/<name>/SKILL.md
.claude/skills/<name>/SKILL.md
.agents/skills/<name>/SKILL.md
```

Install EEA skills:

```bash
# Option 1: Copy from cloned repo
cp eea.agent.skills/skills/docker-expert/SKILL.md ~/.config/opencode/skills/docker-expert/SKILL.md

# Option 2: Use agentget
agentget install eea/eea.agent.skills
```

Invoke skills naturally:
```
Use docker-expert to review this Dockerfile
Use react-best-practices to optimize this component
```

---

## Troubleshooting

### Issue: Harness not loading

**Check:**
1. Is `opencode.json` valid JSON?
2. Is the URL accessible? (test with `curl`)
3. Is `opencode.json` in the project root or `~/.config/opencode/`?

**Fix:**
```bash
# Test URL accessibility
curl -I https://raw.githubusercontent.com/eea/eea.agent.skills/main/harness/EEA-HARNESS.md

# Should return HTTP 200
```

### Issue: Skills not discovered

**Check:**
1. Is the skill file at the correct path? (must be `SKILL.md`)
2. Is the skill directory name consistent?

**Fix:**
```bash
# Verify skill path
ls ~/.config/opencode/skills/docker-expert/SKILL.md
```

### Issue: Local rules conflicting with org harness

**Fix:** Ensure local `AGENTS.md` uses additive language, not contradictory. OpenCode combines all instruction sources.

---

## Limitations

- Remote instructions require internet access on each session start
- Cannot dynamically load skills from the harness repo; skills must be installed locally or via agentget
- `opencode.json` only supports string URLs and `{file:}` references, not complex logic

---

*Last updated: 2026-05-14*

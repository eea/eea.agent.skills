# Pi Agent Profile

**Tool:** [Pi](https://github.com/earendil-works/pi) (Earendil Works)
**Harness support:** File-based instructions via `AGENTS.md` or `CLAUDE.md`
**Priority:** Medium — loads instruction files natively

---

## How Pi Loads Instructions

Pi loads instruction files automatically at startup:

1. **Global:** `~/.pi/agent/AGENTS.md`
2. **Project-local:** Walks up from the current working directory looking for `AGENTS.md` or `CLAUDE.md`
3. **Current directory:** Loads from `./AGENTS.md` or `./CLAUDE.md`

Pi recognizes **both** `AGENTS.md` and `CLAUDE.md` filenames.

> **Cross-agent compatibility note:** We recommend standardizing on `AGENTS.md` for all EEA projects. This filename is understood by OpenCode, Pi, and other agents, making your project instructions portable across tools.

---

## Installation Options

> **See [`docs/BOOTSTRAP.md`](../docs/BOOTSTRAP.md) for the canonical 3-method overview.**
> The options below map to **Method B (Manual Global Install)** for Pi-specific wiring.

### Option A: Symlink to Global (Recommended)

```bash
# Step 1: Clone canonical harness
mkdir -p ~/.eea/agent-harness
[ -d ~/.eea/agent-harness/.git ] || \
  git clone https://github.com/eea/eea.agent.skills.git ~/.eea/agent-harness

# Step 2: Create Pi agent directory
mkdir -p ~/.pi/agent

# Step 3: Symlink harness as global instructions (standardize on AGENTS.md)
ln -sf ~/.eea/agent-harness/harness/EEA-HARNESS.md ~/.pi/agent/AGENTS.md

# Step 4: Verify
ls -la ~/.pi/agent/AGENTS.md
# Should show: ~/.pi/agent/AGENTS.md -> ~/.eea/agent-harness/harness/EEA-HARNESS.md
```

**Pros:**
- Single source of truth
- Updates with `git pull` in `~/.eea/agent-harness`
- No per-project setup needed
- Uses `AGENTS.md` — compatible with OpenCode and other agents

**Cons:**
- Affects all Pi sessions on this machine
- Requires manual update: `cd ~/.eea/agent-harness && git pull`

---

### Option B: Per-Project Setup

For project-specific harness with org-wide fallback:

```bash
cd your-eea-project

# Create project-local AGENTS.md (standardized filename)
cat > AGENTS.md << 'EOF'
# My EEA Project

## Project Context

[Project-specific instructions here]

## EEA Global Harness

This project follows the EEA AI Harness:
EOF

# Append EEA harness
cat ~/.eea/agent-harness/harness/EEA-HARNESS.md >> AGENTS.md

echo "Project-local AGENTS.md created. Commit it to git."
```

**Why `AGENTS.md` at project root?**
- Pi discovers it automatically when working in that directory
- OpenCode also discovers it (walks up looking for `AGENTS.md`)
- One file works for multiple agents

---

### Option C: Using agentget

```bash
agentget install eea/eea.agent.skills

# agentget should auto-detect Pi and create ~/.pi/agent/AGENTS.md symlink
```

---

## Project-Local Overrides

For project-specific rules that add to the org harness:

Create `{repo}/AGENTS.md` (recommended) or `{repo}/CLAUDE.md`:

```markdown
# Project Name

## Your Role

You are working on [description].

## Tech Stack

- [Technology 1]
- [Technology 2]

## Project-Specific Prohibitions

- Do not [project-specific rule]
- Always [project-specific requirement]

## EEA Global Rules

See the global harness at:
~/.eea/agent-harness/harness/EEA-HARNESS.md
```

Pi will load the local `AGENTS.md`. The org harness from the global symlink is loaded in addition.

---

## Verification

To confirm the EEA harness is loaded:

1. Start Pi in a project directory
2. Ask: "What are the EEA global prohibitions?"
3. The agent should reference rules from `EEA-HARNESS.md`

Or check the system prompt context for the harness file path.

---

## Keeping Harness Updated

### Manual Update

```bash
cd ~/.eea/agent-harness
git pull origin main
```

### Auto-Update (Optional)

Add to your shell profile:

```bash
# ~/.bashrc or ~/.zshrc
ea-harness-update() {
  if [ -d ~/.eea/agent-harness/.git ]; then
    cd ~/.eea/agent-harness && git pull origin main
    echo "EEA harness updated"
  else
    echo "EEA harness not installed. Run: git clone https://github.com/eea/eea.agent.skills.git ~/.eea/agent-harness"
  fi
}
```

---

## Troubleshooting

### Issue: Pi not loading AGENTS.md

**Check:**
1. Is the file named `AGENTS.md` (or `CLAUDE.md`)?
2. Is it in `~/.pi/agent/` (global) or the project root (local)?
3. Is the file readable?

**Fix:**
```bash
# Verify file exists and is readable
ls -la ~/.pi/agent/AGENTS.md
ls -la ./AGENTS.md

# Check file size (should not be empty)
wc -l ~/.pi/agent/AGENTS.md
```

### Issue: Symlink broken after moving directories

**Fix:**
```bash
# Re-create symlink
rm ~/.pi/agent/AGENTS.md
ln -sf ~/.eea/agent-harness/harness/EEA-HARNESS.md ~/.pi/agent/AGENTS.md
```

### Issue: Local rules conflicting with org harness

**Fix:** Ensure local `AGENTS.md` uses additive language, not contradictory. Pi combines global and local instructions.

---

## Limitations

- Pi is newer than OpenCode/Claude — documentation and ecosystem still maturing
- Verify `~/.pi/agent/` path with your specific Pi version
- Some features may differ between Pi distributions (Earendil Works vs others)

---

*Last updated: 2026-05-14*

---

*Last updated: 2026-05-14*

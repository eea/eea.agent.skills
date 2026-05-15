# Hermes Agent Profile

**Tool:** Hermes Agent
**Harness support:** File-based instructions (`HERMES.md`)
**Priority:** Medium — emerging agent platform

---

## How Hermes Loads Instructions

Hermes Agent uses a `.hermes/` directory for configuration and instructions:

1. **Global:** `~/.hermes/HERMES.md`
2. **Project-local:** `{repo}/.hermes/HERMES.md`

Hermes loads these files at session initialization and uses them as system context.

---

## Installation

### Option A: Symlink to Global (Recommended)

```bash
# Step 1: Clone canonical harness
mkdir -p ~/.eea/agent-harness
[ -d ~/.eea/agent-harness/.git ] || \
  git clone https://github.com/eea/eea.agent.skills.git ~/.eea/agent-harness

# Step 2: Create Hermes config directory
mkdir -p ~/.hermes

# Step 3: Symlink harness as global instructions
ln -sf ~/.eea/agent-harness/harness/EEA-HARNESS.md ~/.hermes/HERMES.md

# Step 4: Verify
ls -la ~/.hermes/HERMES.md
# Should show: ~/.hermes/HERMES.md -> ~/.eea/agent-harness/harness/EEA-HARNESS.md
```

---

### Option B: Per-Project Setup

```bash
cd your-eea-project
mkdir -p .hermes

# Create project-local HERMES.md with org harness
cat > .hermes/HERMES.md << 'EOF'
# My EEA Project

## Project Context

[Project-specific instructions here]

## EEA Global Harness

EOF

# Append EEA harness
cat ~/.eea/agent-harness/harness/EEA-HARNESS.md >> .hermes/HERMES.md

echo "Project-local HERMES.md created. Commit it to git."
```

---

### Option C: Using agentget

```bash
agentget install eea/eea.agent.skills

# agentget should auto-detect Hermes and create appropriate symlinks
```

---

## Project-Local Overrides

Create `{repo}/.hermes/HERMES.md` with project-specific rules.

Hermes will load the local file. To include org-wide rules, either:
1. Include harness content inline (Option B)
2. Reference the global file in instructions

---

## Verification

Start Hermes and ask:
```
What are the EEA global prohibitions?
```

The agent should reference rules from `EEA-HARNESS.md`.

---

## Keeping Harness Updated

```bash
cd ~/.eea/agent-harness
git pull origin main
```

---

## Limitations

- Hermes Agent is still emerging; documentation may be limited
- Verify `.hermes/` directory structure with your specific Hermes version
- Global vs project-local loading behavior may vary

---

*Last updated: 2026-05-14*

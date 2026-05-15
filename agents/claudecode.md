# Claude Code Agent Profile

**Tool:** [Claude Code](https://docs.anthropic.com/en/docs/agents/claude-code)
**Harness support:** File-based instructions (`CLAUDE.md`)
**Priority:** High — widely used at EEA  
**Compliance:** Closed-source commercial product with extensive telemetry and behavioural tracking. **Not recommended at EEA** due to non-compliance with GDPR/EUDPR. As mitigation, connections to Anthropic can be blocked via egress filtering.

---

## How Claude Code Loads Instructions

Claude Code reads instructions from:

1. **Project-local:** `{repo}/CLAUDE.md` or `{repo}/.claude/CLAUDE.md`
2. **Global:** `~/.claude/CLAUDE.md` (if supported by your Claude Code version)

Claude Code loads these files at session start and uses them as system context.

---

## Installation

### Option A: Symlink to Global (Recommended)

Install the EEA harness once, use everywhere:

```bash
# Step 1: Clone canonical harness
mkdir -p ~/.eea/agent-harness
[ -d ~/.eea/agent-harness/.git ] || \
  git clone https://github.com/eea/eea.agent.skills.git ~/.eea/agent-harness

# Step 2: Create Claude config directory
mkdir -p ~/.claude

# Step 3: Symlink harness as global instructions
ln -sf ~/.eea/agent-harness/harness/EEA-HARNESS.md ~/.claude/CLAUDE.md

# Step 4: Verify
ls -la ~/.claude/CLAUDE.md
# Should show: ~/.claude/CLAUDE.md -> ~/.eea/agent-harness/harness/EEA-HARNESS.md
```

**Pros:**
- Single source of truth
- Updates with `git pull` in `~/.eea/agent-harness`
- No per-project setup needed

**Cons:**
- Affects all Claude Code sessions on this machine
- Requires manual update: `cd ~/.eea/agent-harness && git pull`

---

### Option B: Per-Project Setup

For project-specific harness with org-wide fallback:

```bash
# In your project directory
cd your-eea-project

# Create .claude directory
mkdir -p .claude

# Create project-local CLAUDE.md
cat > .claude/CLAUDE.md << 'EOF'
# My EEA Project

## Project Context

This is [project name]. Tech stack: [stack].

## Project-Specific Rules

- [Rule 1]
- [Rule 2]

## EEA Global Harness

The following org-wide rules apply:

EOF

# Append the EEA harness content
cat ~/.eea/agent-harness/harness/EEA-HARNESS.md >> .claude/CLAUDE.md

echo "Project-local CLAUDE.md created. Commit it to git."
```

**Pros:**
- Project-specific rules + org-wide rules
- Version controlled with project
- Different projects can have different local rules

**Cons:**
- Must update each project when harness changes
- Larger instruction files (project + org combined)

---

### Option C: Using agentget

If agentget supports Claude Code:

```bash
# Install harness via agentget
agentget install eea/eea.agent.skills

# agentget should auto-detect Claude Code and create appropriate symlinks
```

Check agentget documentation for Claude Code support status.

---

## Project-Local Overrides

For project-specific rules that add to the org harness:

Create `{repo}/CLAUDE.md`:

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

Claude Code will load the local `CLAUDE.md`. To also load the global harness, either:
1. Include the harness content inline (Option B above)
2. Or instruct Claude to read the global file when needed

---

## Verification

To confirm the EEA harness is loaded:

1. Start Claude Code in a project
2. Ask: "What are the EEA global prohibitions?"
3. The agent should reference rules from `EEA-HARNESS.md`

Or check if the harness file is in context:
```
Please summarize the EEA AI Harness rules that apply to this session.
```

---

## Skills in Claude Code

Claude Code can load skills from:

```bash
# Global skills directory
~/.claude/skills/<name>/SKILL.md

# Project-local skills directory
.claude/skills/<name>/SKILL.md
```

Install EEA skills:

```bash
# Copy from cloned repo
cp eea.agent.skills/skills/docker-expert/SKILL.md ~/.claude/skills/docker-expert/SKILL.md

# Or use agentget
agentget install eea/eea.agent.skills
```

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

### Issue: Claude Code not loading CLAUDE.md

**Check:**
1. Is the file named exactly `CLAUDE.md`?
2. Is it in the project root or `.claude/` directory?
3. Is the file readable?

**Fix:**
```bash
# Verify file exists and is readable
ls -la CLAUDE.md
ls -la .claude/CLAUDE.md

# Check file size (should not be empty)
wc -l CLAUDE.md
```

### Issue: Symlink broken after moving directories

**Fix:**
```bash
# Re-create symlink
rm ~/.claude/CLAUDE.md
ln -sf ~/.eea/agent-harness/harness/EEA-HARNESS.md ~/.claude/CLAUDE.md
```

### Issue: Global CLAUDE.md not applied

**Note:** Some versions of Claude Code may not support global `~/.claude/CLAUDE.md`. Use per-project `.claude/CLAUDE.md` instead.

---

## Limitations

- Claude Code instruction file size may be limited; very large harness files could be truncated
- Does not support remote URLs natively; must use local files or symlinks
- Global instructions support varies by Claude Code version
- Skills loading is less structured than OpenCode's native skill tool

---

*Last updated: 2026-05-14*

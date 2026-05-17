# Gemini Agent Profile

**Tool:** Gemini (Google AI Studio / Vertex AI / Gemini CLI)
**Harness support:** System instructions via API or IDE configuration
**Priority:** Medium — growing adoption at EEA

---

## How Gemini Loads Instructions

Gemini does not have a standard global instructions file like OpenCode or Claude Code. Instructions are provided through:

1. **API system prompts** — passed with each API request
2. **IDE workspace settings** — some IDEs allow persistent system prompts
3. **Gemini CLI** — may support configuration files depending on version

---

## Installation Options

> **See [`docs/BOOTSTRAP.md`](../BOOTSTRAP.md) for the canonical 3-method overview.**
> The options below map to **Method B (Manual Global Install)** for Gemini-specific wiring.

### Option A: IDE Workspace Settings

If using an IDE with Gemini integration (VS Code with Gemini extension, JetBrains, etc.):

1. Open IDE settings
2. Find "AI Assistant" or "Gemini" settings
3. Look for "System Instructions" or "Custom Instructions"
4. Paste the content of `EEA-HARNESS.md` or reference the file

Some IDEs support file references:
```
{file:/home/USERNAME/.eea/agent-harness/harness/EEA-HARNESS.md}
```

---

### Option B: Gemini CLI

If using Gemini CLI:

```bash
# Clone canonical harness
mkdir -p ~/.eea/agent-harness
[ -d ~/.eea/agent-harness/.git ] || \
  git clone https://github.com/eea/eea.agent.skills.git ~/.eea/agent-harness

# Check if Gemini CLI supports config files
gemini --help | grep -i config

# If supported, create config file
mkdir -p ~/.config/gemini
cat > ~/.config/gemini/config.yaml << 'EOF'
system_instructions: |
  [Paste EEA-HARNESS.md content here]
EOF
```

**Note:** Gemini CLI configuration format varies. Check your specific version's documentation.

---

### Option C: Project-Level System Prompt

Create a system prompt file in your project:

```bash
cd your-eea-project

# Create system prompt
cat > GEMINI_INSTRUCTIONS.md << 'EOF'
# EEA AI Harness — System Instructions

[Paste content of EEA-HARNESS.md here]

# Project-Specific Additions

[Add project-specific rules here]
EOF
```

Reference this file when starting Gemini sessions.

---

### Option D: Using agentget

```bash
agentget install eea/eea.agent.skills

# agentget should auto-detect Gemini and configure appropriately
```

---

## Verification

Start a Gemini session and ask:
```
What are the EEA global prohibitions?
```

The agent should reference rules from `EEA-HARNESS.md`.

---

## Keeping Harness Updated

Since Gemini typically uses inline instructions or IDE settings, updates require:

1. Pull latest harness:
   ```bash
   cd ~/.eea/agent-harness && git pull origin main
   ```

2. Re-copy or re-reference the updated content in your IDE/system prompt

---

## Limitations

- No standardized global instructions file
- Must manually update instructions when harness changes
- IDE support for file references varies
- API-based usage requires passing instructions with each request
- Consider using a wrapper script or template manager for API usage

---

*Last updated: 2026-05-14*

# EEA AI Harness

> **The canonical organization-wide AI harness for all EEA coding agents.**

This repository is the single source of truth for how AI coding agents (OpenCode, Claude Code, Gemini, Copilot, etc.) behave across all European Environment Agency (EEA) projects.

It contains org-wide rules, reusable skills, mandatory protocols, shared knowledge, and tool-specific wiring instructions.

> The Initial Owner of the Original Code is [European Environment Agency (EEA)](https://www.eea.europa.eu/).

---

## Quick Start

### For Developers

Add the EEA harness to your project in 30 seconds. Pick **one** of the three methods:

**A. Automated Global Install (recommended)** — one command for all your agents:
```bash
# With agentget
agentget install eea/eea.agent.skills

# Or with curl
curl -fsSL https://raw.githubusercontent.com/eea/eea.agent.skills/main/scripts/install.sh | bash
```

**B. Manual Global Install** — clone once, symlink per agent:
```bash
git clone https://github.com/eea/eea.agent.skills.git ~/.eea/agent-harness
~/.eea/agent-harness/scripts/install.sh --local
```

**C. Project-Embedded** — no global setup, reference inside one project:
```bash
# OpenCode: remote URL in your project's opencode.json
cat > opencode.json << 'EOF'
{
  "instructions": [
    "https://raw.githubusercontent.com/eea/eea.agent.skills/main/harness/EEA-HARNESS.md"
  ]
}
EOF
```

Full bootstrap guide: [`docs/BOOTSTRAP.md`](docs/BOOTSTRAP.md)

### For Project Maintainers

Create project-local instructions that add to the org harness:

```bash
mkdir -p .agents
cp ~/.eea/agent-harness/templates/dot-agents/AGENTS.md .agents/AGENTS.md
# Edit .agents/AGENTS.md with project-specific rules
cp ~/.eea/agent-harness/templates/dot-agents/opencode.json opencode.json
```

---

## Repository Structure

```
ea.agent.skills/
├── harness/
│   └── EEA-HARNESS.md           # ORG-WIDE: canonical harness for all EEA projects
│                                  # Loaded by all agents via URL or symlink
│
├── AGENTS.md                    # REPO-LOCAL: how to work on THIS repo
│
├── skills/                      # Distributable merged skills (upstream + EEA overrides)
│   └── docker-expert/
│       └── SKILL.md
│
├── src/skills/                  # Source: upstream + EEA-OVERRIDES.md
│   ├── docker-expert/
│   │   ├── SKILL.md             # Upstream base
│   │   ├── EEA-OVERRIDES.md     # EEA-specific customizations
│   │   └── references/          # Deep reference material
│   └── <future-skills>/
│
├── rules/                       # Org-wide prohibitions & mandatory behaviors
│   ├── eeaprohibitions.rules.md # What agents must NEVER do
│   ├── eeamandatory.rules.md    # What agents MUST do
│   └── changelog.process.md     # CHANGELOG best practices
│
├── agents/                      # Per-tool agent profiles
│   ├── opencode.md              # OpenCode wiring instructions
│   ├── claudecode.md            # Claude Code wiring instructions
│   ├── hermes.md                # Hermes Agent wiring instructions
│   ├── gemini.md                # Gemini wiring instructions
│   └── pi.md                    # Pi wiring instructions
│
├── shared/                      # Cross-project knowledge base
│   ├── eea-style-guide.md       # EEA brand/tone guidance for LLM outputs
│   ├── design-foundations.md    # Design tokens, color palettes
│   ├── data-schemas.md          # Common EEA data structures/formats
│   ├── glossary.md              # EEA acronyms and terminology
│   └── architecture/            # Architecture decision records (ADRs)
│
├── instructions/                # Generic org-wide instruction templates
├── workflows/                   # Multi-skill orchestration recipes
│
├── plugins/
│   └── agentget.json            # Manifest for agentget installer
│
├── scripts/                     # Build + install automation
│   ├── build.sh                 # Merges SKILL.md + EEA-OVERRIDES.md
│   └── install.sh               # One-shot harness installer
│
├── docs/
│   ├── BOOTSTRAP.md             # Onboarding guide for EEA developers
│   ├── opencode-examples/       # opencode.json templates
│   └── SYNC-STRATEGY.md         # Upstream sync strategy
│
├── templates/                   # Templates for project-local .agents/ setup
│   └── dot-agents/
│       ├── AGENTS.md            # Project-local instructions template
│       └── opencode.json        # Project opencode.json template
│
└── catalog.yaml                 # Machine-readable skill index
```

### Key Design Decision: Two-Layer Harness

| Layer | File | Purpose |
|-------|------|---------|
| **Org-wide** | `harness/EEA-HARNESS.md` | Loaded by ALL EEA projects. Contains routing, prohibitions, mandatory actions, skill references. |
| **Repo-local** | `AGENTS.md` (root) | Only for this repo. Describes how to maintain the harness itself. |
| **Project-local** | `{repo}/AGENTS.md` | Per-project rules that add to org harness. |

This separation ensures:
- **Org rules** are version-controlled and distributed automatically
- **Repo rules** don't leak into other projects
- **Project rules** can add context without duplicating org standards

---

## The Harness

### What It Contains

The canonical org harness ([`harness/EEA-HARNESS.md`](harness/EEA-HARNESS.md)) includes:

1. **Context Routing Rules** — when to load which skills
2. **Global Prohibitions** — security, operational safety, code quality rules that apply everywhere
3. **Mandatory Actions** — required behaviors (show git status, propose commit message, ask for confirmation)
4. **Knowledge Accumulation Protocol** — how to capture decisions and gotchas
5. **Skill Library Reference** — catalog of available skills with usage instructions
6. **Tool-Specific Wiring** — how to connect OpenCode, Claude, Gemini, etc.

### Distribution Options

| Method | Best For | Command | Agents Supported |
|--------|----------|---------|------------------|
| **A. Automated Global Install** | Most users — one command, all agents | `agentget install eea/eea.agent.skills` or `curl \| bash` | OpenCode, Claude, Hermes, Pi, Gemini |
| **B. Manual Global Install** | Air-gapped or control-oriented users | `git clone ... && ./scripts/install.sh --local` | OpenCode, Claude, Hermes, Pi, Gemini |
| **C. Project-Embedded** | No global setup, harness lives in one project | Remote URL, git submodule, or inline copy in project | Any agent |

---

## Skills

### Available Skills

| Skill | Description | Category | Upstream Source |
|-------|-------------|----------|-----------------|
| `docker-expert` | Advanced Docker containerization, multi-stage builds, security hardening | devops | [sickn33/antigravity-awesome-skills](https://github.com/sickn33/antigravity-awesome-skills) |
| `react-best-practices` | React/Next.js performance optimization (70+ rules) | frontend | [vercel-labs/agent-skills](https://github.com/vercel-labs/agent-skills) |
| `composition-patterns` | React composition patterns, compound components | frontend | [vercel-labs/agent-skills](https://github.com/vercel-labs/agent-skills) |
| `web-design-guidelines` | UI review, accessibility, UX audit | design | [vercel-labs/agent-skills](https://github.com/vercel-labs/agent-skills) |
| `react-native-skills` | React Native/Expo best practices | mobile | [vercel-labs/agent-skills](https://github.com/vercel-labs/agent-skills) |
| `react-view-transitions` | View transitions, animations, shared elements | frontend | [vercel-labs/agent-skills](https://github.com/vercel-labs/agent-skills) |

### Installing Skills

**Option 1: Copy from cloned repo**
```bash
git clone https://github.com/eea/eea.agent.skills.git
cp eea.agent.skills/skills/docker-expert/SKILL.md ~/.config/opencode/skills/docker-expert/SKILL.md
```

**Option 2: agentget**
```bash
agentget install eea/eea.agent.skills
```

> **Note on GitHub Releases:** GitHub Releases distribution is **discontinued** as of 2026-05-16. Skills are now always installed from source via the install script or agentget. Previous releases have been removed. See [CHANGELOG.md](CHANGELOG.md) for details.

### Using Skills

Invoke naturally in any agent:
```
Use docker-expert to containerize this Python app
Use react-best-practices to optimize this component
Use web-design-guidelines to audit accessibility
```

---

## Sync Strategy: Two-File Overlay

Each skill follows a two-file overlay pattern:

1. **`src/skills/<name>/SKILL.md`** — Upstream base content (auto-updated from upstream source)
2. **`src/skills/<name>/EEA-OVERRIDES.md`** — EEA-specific customizations

```
┌─────────────────────────────────────────┐
│              Agent loads                 │
│         SKILL.md + EEA-OVERRIDES.md     │
└─────────────────────────────────────────┘
         ↓                    ↓
┌─────────────────┐  ┌─────────────────────┐
│   Upstream      │  │   EEA Overrides    │
│   (src/skills/) │  │   (src/skills/)    │
└─────────────────┘  └─────────────────────┘
         ↓
┌─────────────────────────────────────────┐
│   Merged output → skills/<name>/        │
│   (agentget discovers from here)        │
└─────────────────────────────────────────┘
```

**Benefits:**
- Upstream changes apply automatically (no merge conflicts in override sections)
- EEA customizations never lost during upstream updates
- Clear separation of "what's upstream" vs "what's EEA"

📄 **Full sync strategy:** [docs/SYNC-STRATEGY.md](docs/SYNC-STRATEGY.md)

---

## Adding Skills to the Harness

### Adding a New Skill

1. **Create skill directory** under `src/skills/{skill-name}/`
2. **Add upstream `SKILL.md`** (if based on upstream source)
3. **Create `EEA-OVERRIDES.md`** with EEA-specific customizations
4. **Add `metadata.json`** with skill metadata
5. **Update `catalog.yaml`** with new skill entry
6. **Build merged skill**: `./scripts/build.sh {skill-name}`
7. **Validate**: `./scripts/build.sh --validate`
8. **Commit**: `skill: add {skill-name}`

### Updating an Existing Skill

1. **Sync upstream** changes to `src/skills/{name}/SKILL.md`
2. **Update `EEA-OVERRIDES.md`** if upstream changes affect EEA customizations
3. **Rebuild**: `./scripts/build.sh {name}`
4. **Update `catalog.yaml`** version if applicable
5. **Commit**: `skill: update {name} to v{X.Y.Z}`

---

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for:
- Adding new skills
- Updating existing skills
- Updating the org harness (`harness/EEA-HARNESS.md`)
- Adding new agent profiles
- Sync workflow documentation

### Maintaining the Harness

When an agent makes a mistake the harness should have prevented, add a rule instead of rewriting the prompt.

See [`docs/harness-maintenance.md`](docs/harness-maintenance.md) for the full maintenance philosophy and process.

### Commit Convention

Use [Conventional Commits](https://www.conventionalcommits.org/):

| Type | Use For |
|------|---------|
| `skill:` | Adding or updating a skill |
| `harness:` | Changes to `harness/EEA-HARNESS.md` or org-wide rules |
| `docs:` | Documentation updates |
| `build:` | Build script or CI changes |
| `chore:` | Maintenance, dependencies, formatting |

---

## CI/CD

### Validation Workflow

`.github/workflows/validate-skills.yml` runs on every push:
- Lint `SKILL.md` files for structural conformance
- Check token count (warn if > 500 lines / 5k tokens)
- Validate `catalog.yaml` schema
- Detect upstream sync opportunities

### Harness Validation

`.github/workflows/validate-harness.yml` runs when harness files change:
- Verify `harness/EEA-HARNESS.md` exists and is valid
- Check all referenced files exist
- Scan for accidental secrets
- Validate agent profiles

### Upstream Sync Check

Runs weekly to detect upstream changes and alerts via GitHub Issues.

---

## License

MIT — See [LICENSE](LICENSE)

---

*Last updated: 2026-05-16 after harness slimming and rule extraction*

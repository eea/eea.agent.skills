# EEA Agent Skills

Centralized repository for agentic skills used across EEA's unified dev workflow with AI coding assistants.

> The Initial Owner of the Original Code is [European Environment Agency (EEA)](https://www.eea.europa.eu/).

## Overview

This repo contains reusable `SKILL.md` playbooks that extend AI coding assistants (Claude Code, Cursor, OpenCode, GitHub Copilot, etc.) with EEA-specific capabilities. Each skill is self-contained, versioned, and designed for incremental disclosure of complexity.

## Repository Structure

```
eea.agent.skills/
├── README.md                      # This file
├── CONTRIBUTING.md                # How to add/update skills
├── CHANGELOG.md                   # Version history
├── catalog.yaml                   # Machine-readable skill index
│
├── skills/                        # Source: one subdirectory per skill
│   ├── docker-expert/
│   │   ├── SKILL.md               # Upstream base
│   │   ├── EEA-OVERRIDES.md       # EEA-specific customizations
│   │   └── references/            # Deep reference material
│   └── <future-skills>/
│
├── dist/                          # Pre-built merged skills (gitignored)
│   └── skills/
│       └── docker-expert/
│           └── SKILL.md           # Merged: upstream + EEA overrides
│
├── scripts/                       # Build automation
│   └── build.sh                   # Merges SKILL.md + EEA-OVERRIDES.md
│
├── shared/                        # Cross-skill reusable fragments
│   ├── design-foundations.md      # Design tokens, color palettes
│   ├── eea-style-guide.md          # EEA brand/tone guidance for LLM outputs
│   └── data-schemas.md             # Common EEA data structures/formats
│
├── docs/                          # Documentation
│   └── SYNC-STRATEGY.md           # Upstream sync strategy
│
└── workflows/                     # Multi-skill orchestration recipes
    └── data-report.md             # chart + doc + xlsx chained workflow
```

## Quick Start

### Adding a skill to your agent

**Option 1: Clone and copy (easiest)**

The `dist/` directory contains pre-built merged skills (upstream + EEA overrides combined):

```bash
# Clone the repository
git clone https://github.com/eea/eea.agent.skills.git

# Copy merged skill to your agent's skills directory
cp eea.agent.skills/dist/skills/docker-expert/SKILL.md ~/.claude/skills/docker-expert/SKILL.md
```

**Option 2: Download from release**

Pre-built merged skills are also attached to every [GitHub Release](https://github.com/eea/eea.agent.skills/releases):

```bash
# Download latest release
curl -L -o eea-skills.zip https://github.com/eea/eea.agent.skills/releases/latest/download/eea-agent-skills.zip
unzip eea-skills.zip

# Copy merged skill
cp skills/docker-expert/SKILL.md ~/.claude/skills/docker-expert/SKILL.md
```

**Option 3: Build from source**

If you want to customize overrides or contribute:

```bash
# Clone and build
git clone https://github.com/eea/eea.agent.skills.git
cd eea.agent.skills
./scripts/build.sh docker-expert

# Copy built skill
cp dist/skills/docker-expert/SKILL.md ~/.claude/skills/docker-expert/SKILL.md
```

### Using a skill

Once installed, invoke skills naturally:

```
Use docker-expert to containerize this Python app
Use doc skill to generate technical docs for the API
```

### Using with OpenCode

For [OpenCode](https://github.com/opencode-ai/opencode) users, skills are auto-discovered from standard paths. Place them in any of these locations:

```bash
# Global paths (available across all projects)
~/.config/opencode/skills/<name>/SKILL.md
~/.claude/skills/<name>/SKILL.md
~/.agents/skills/<name>/SKILL.md

# Project-local paths (only within the project)
.opencode/skills/<name>/SKILL.md
.claude/skills/<name>/SKILL.md
.agents/skills/<name>/SKILL.md
```

**Quick install:**

```bash
# Copy the pre-built merged skill (includes upstream + EEA overrides)
mkdir -p ~/.config/opencode/skills/docker-expert
cp eea.agent.skills/dist/skills/docker-expert/SKILL.md ~/.config/opencode/skills/docker-expert/SKILL.md

# Or install via npm (if the skill supports it)
npx skills add eea/eea.agent.skills --skill docker-expert
```

**Invoke in OpenCode:**

```
Use docker-expert to review this Dockerfile
```

OpenCode loads skills on-demand via the native `skill` tool. The agent sees available skills in the `<available_skills>` section and loads the full content when needed.

## Available Skills

| Skill | Description | Upstream Source |
|-------|-------------|-----------------|
| `docker-expert` | Advanced Docker containerization, multi-stage builds, security hardening | [sickn33/antigravity-awesome-skills](https://github.com/sickn33/antigravity-awesome-skills) |

## Sync Strategy: Two-File Overlay

Each skill follows a two-file overlay pattern:

1. **`SKILL.md`** — Upstream base content (auto-updated from upstream source)
2. **`EEA-OVERRIDES.md`** — EEA-specific customizations that extend the upstream

```
┌─────────────────────────────────────────┐
│              Agent loads                 │
│         SKILL.md + EEA-OVERRIDES.md     │
└─────────────────────────────────────────┘
         ↓                    ↓
┌─────────────────┐  ┌─────────────────────┐
│   Upstream      │  │   EEA Overrides    │
│   (upstream/)   │  │   (eea/)           │
└─────────────────┘  └─────────────────────┘
```

**Benefits:**
- Upstream changes apply automatically (no merge conflicts in override sections)
- EEA customizations never lost during upstream updates
- Clear separation of "what's upstream" vs "what's EEA"

📄 **Full sync strategy documentation:** [docs/SYNC-STRATEGY.md](docs/SYNC-STRATEGY.md)

## Catalog Schema

Each skill has an entry in `catalog.yaml`:

```yaml
skills:
  - id: docker-expert
    name: Docker Expert
    description: Advanced Docker containerization for multi-stage builds, security, and orchestration
    category: devops
    upstream:
      source: sickn33/antigravity-awesome-skills
      path: skills/docker-expert
      url: https://github.com/sickn33/antigravity-awesome-skills
    triggers:
      - docker
      - container
      - dockerfile
      - docker-compose
    version: "1.0"
    eeaspecific: true
```

## CI/CD

### Validation Workflow

`.github/workflows/validate-skills.yml` runs on every push:

- Lint `SKILL.md` files for structural conformance
- Check token count (warn if > 500 lines / 5k tokens)
- Validate `catalog.yaml` schema
- Detect upstream sync opportunities

### Upstream Sync Check

```yaml
# Runs weekly to detect upstream changes
schedule:
  - cron: '0 8 * * 1'  # Monday 8am
```

Checks if upstream repo has new commits and alerts via GitHub Issues.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for:
- Adding new skills
- Updating existing skills
- Sync workflow documentation
- Override file conventions

## License

MIT — See [LICENSE](LICENSE)
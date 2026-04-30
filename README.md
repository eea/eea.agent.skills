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
├── skills/                        # One subdirectory per skill
│   ├── docker-expert/
│   │   ├── SKILL.md               # Core skill (upstream base)
│   │   ├── EEA-OVERRIDES.md       # EEA-specific customizations
│   │   └── references/            # Deep reference material
│   └── <future-skills>/
│
├── shared/                        # Cross-skill reusable fragments
│   ├── design-foundations.md      # Design tokens, color palettes
│   ├── eea-style-guide.md          # EEA brand/tone guidance for LLM outputs
│   └── data-schemas.md             # Common EEA data structures/formats
│
└── workflows/                     # Multi-skill orchestration recipes
    └── data-report.md             # chart + doc + xlsx chained workflow
```

## Quick Start

### Adding a skill to your agent

```bash
# Using npm installer (if available)
npx skills add eea/eea.agent.skills --skill docker-expert

# Or manually: copy SKILL.md into your agent's skills directory
cp skills/docker-expert/SKILL.md ~/.claude/skills/docker-expert/SKILL.md
```

### Using a skill

Once installed, invoke skills naturally:

```
Use docker-expert to containerize this Python app
Use doc skill to generate technical docs for the API
```

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
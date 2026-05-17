# Contributing to EEA Agent Skills

Welcome! This guide explains how to contribute skills, rules, agent profiles, documentation, and other parts of the EEA AI Harness.

## Adding a New Skill

### Option A: Fork from Upstream (Recommended)

When adding a skill that exists upstream:

1. **Create the skill directory:**
   ```bash
   mkdir -p src/skills/<skill-name>/references
   ```

2. **Fetch upstream content into `SKILL.md`:**
   ```bash
   # Example for docker-expert
   curl -s https://raw.githubusercontent.com/sickn33/antigravity-awesome-skills/main/skills/docker-expert/SKILL.md \
     > src/skills/docker-expert/SKILL.md
   ```

3. **Create `EEA-OVERRIDES.md`:**
   ```bash
   echo "# EEA-Specific Overrides\n\nAdd EEA customizations here." \
     > src/skills/docker-expert/EEA-OVERRIDES.md
   ```

4. **Update `catalog.yaml`:**
   Add the skill entry with upstream metadata.

5. **Open a PR** with the new skill.

### Option B: Create New (No Upstream)

When creating a skill without upstream:

```bash
mkdir -p src/skills/<new-skill>/references
```

Create `SKILL.md` following the skill template below.

---

## Updating Existing Skills

### Syncing from Upstream

When upstream has new content you want to pull:

```bash
# 1. Fetch latest upstream
curl -s https://raw.githubusercontent.com/<upstream>/main/skills/<skill>/SKILL.md \
  > src/skills/<skill>/SKILL.md

# 2. Verify EEA-OVERRIDES.md still exists and is valid
# 3. Run validation: npm run validate
# 4. Open PR with the sync
```

### Adding EEA Overrides

Edit `EEA-OVERRIDES.md` to add EEA-specific customizations:

```markdown
# EEA-Specific Overrides

## EEA-Specific Patterns

### Internal Registry Access
When building containers for internal EEA services:
- Use `registry.eea.europa.eu` as base registry
- Authenticate with EEA service accounts

### Security Compliance
EEA-specific security requirements:
- All containers must run as non-root (UID 10001+)
- Base images must be scanned weekly
- No external network calls without proxy exception
```

---

## Skill Structure Convention

Each skill directory follows this structure:

```
src/skills/<skill-name>/
├── SKILL.md              # Required: Core skill instructions
├── EEA-OVERRIDES.md       # Required (for forked skills): EEA customizations
├── references/            # Optional: Deep reference material
│   ├── topic-1.md
│   └── topic-2.md
└── upstream/              # Optional: Frozen upstream content (for sync)
    └── SKILL.md
```

### SKILL.md Requirements

- Maximum ~500 lines / 5k tokens (agent context limit)
- Clear "When invoked" section
- "Core Expertise Areas" with practical patterns
- "Code Review Checklist" section
- "Integration & Handoff Guidelines" for multi-skill workflows

### EEA-OVERRIDES.md Requirements

- Version tag: `<!-- EEA-Overrides-Version: 1.0 -->` at top of file
- Clear section headers: `## EEA-Specific Patterns`
- No duplication of upstream content
- Only additive: extend, don't modify core upstream patterns
- Version-stamped: `<!-- EEA-Overrides: v1.0 -->` at top

---

## Other Contribution Areas

Skills are the most common contribution, but the harness has many other parts:

| Area | Path | How to Contribute |
|---|---|---|
| **Rules** | `rules/` | Add or edit `.rules.md` files. Follow naming: `rules/{domain}.{type}.md`. See `rules/README.md`. |
| **Org Harness** | `harness/EEA-HARNESS.md` | Update global routing, prohibitions, or mandatory actions. See `docs/harness-maintenance.md` for the maintenance philosophy. |
| **Agent Profiles** | `docs/agent-profiles/` | Add `{tool}.md` for new tools. Follow format in `docs/agent-profiles/README.md`. |
| **Workflows** | `workflows/` | Add multi-skill recipes. See `workflows/README.md`. |
| **Shared Knowledge** | `shared/` | Update EEA-wide glossary, style guide, or design foundations when org context changes. |
| **Templates** | `templates/` | Update project-local setup templates. Keep in sync with `scripts/install.sh`. |
| **Plugins** | `plugins/` | Update `agentget.json` when new content types or paths change. |
| **Scripts** | `scripts/` | Test build or install changes locally. Ensure CI passes. |
| **Documentation** | `docs/` | Update user or maintainer docs. Add ADRs to `docs/adr/` for significant architectural decisions. |
| **Changelog** | `CHANGELOG.md` | Add entry for any user-facing change. Follow `rules/changelog.process.md`. |

Open a PR for any of the above. CI validates structure and consistency automatically.

---

## Pull Request Workflow

All changes go through a PR:

1. **Fork or branch** — Create a feature branch from `main`
2. **Make changes** — Follow the conventions in the relevant section above
3. **Validate locally** — Run `npm run validate` and `./scripts/build.sh` where applicable
4. **Open a PR** — Include a clear description and rationale
5. **CI checks** — GitHub Actions validate structure, build sync, and harness integrity
6. **Review** — A maintainer reviews and merges

**If you modified `src/skills/*/SKILL.md` or `src/skills/*/EEA-OVERRIDES.md`,** run `./scripts/build.sh` locally so the PR includes updated `skills/` output. CI will fail if `skills/` is out of sync.

---

## Catalog Update

After adding/updating a skill, update `catalog.yaml`:

```yaml
skills:
  - id: <skill-id>
    name: <Skill Name>
    description: <one-line description>
    category: <devops|frontend|backend|security|...>
    upstream:
      source: <org/repo>
      path: skills/<skill>
      url: https://github.com/<org>/<repo>
    triggers:
      - <keyword1>
      - <keyword2>
    version: "1.0"
    eeaspecific: <true|false>
```

---

## Validation

Before opening a PR, run:

```bash
# Lint SKILL.md files
npm run validate

# Check token count
npm run check-tokens
```

GitHub Actions run validation on every PR automatically.

---

## Questions?

Open an issue at https://github.com/eea/eea.agent.skills/issues
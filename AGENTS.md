# EEA Agent Skills Repository

This file governs how AI agents work when editing the `eea.agent.skills` repository itself.

> **Note:** This is the REPO-LOCAL instruction file. For the organization-wide harness that applies to all EEA projects, see [`harness/EEA-HARNESS.md`](harness/EEA-HARNESS.md).

---

## Your Role

You are maintaining the **EEA AI Harness** — the central repository for organization-wide agent rules, reusable skills, shared knowledge, and cross-project workflows.

When working in this repo, your job is to:
- Add and maintain reusable skills
- Keep EEA-specific overrides up to date
- Ensure the harness is well-documented and easy to consume
- Follow the two-file overlay pattern for upstream skills

---

## Repository Structure

```
ea.agent.skills/
├── harness/
│   └── EEA-HARNESS.md           # ORG-WIDE harness (loaded by all EEA projects)
├── AGENTS.md                    # This file — repo-local instructions
├── skills/                      # Distributable merged skills
├── src/skills/                  # Source: upstream + EEA-OVERRIDES.md
├── rules/                       # Org-wide prohibitions & mandatory behaviors
├── agents/                      # Per-tool agent profiles (OpenCode, Claude, etc.)
├── shared/                      # Cross-project knowledge base
├── instructions/                # Generic org-wide instruction templates
├── workflows/                   # Multi-skill orchestration recipes
├── plugins/                     # Tool-specific adapters (agentget manifest)
├── scripts/                     # Build + install automation
├── docs/                        # Documentation and examples
│   ├── BOOTSTRAP.md             # Onboarding guide for EEA developers
│   └── opencode-examples/       # opencode.json templates for EEA projects
├── templates/                   # Templates for project-local .agents/ setup
└── catalog.yaml                 # Machine-readable skill index
```

---

## Prohibited Actions

- **Do not edit `harness/EEA-HARNESS.md` without explicit user request** — that's org-wide policy; changes affect every EEA project
- **Do not commit unmerged upstream changes** to `src/skills/*/SKILL.md` — always run `./scripts/build.sh` first
- **Do not delete `EEA-OVERRIDES.md` files** — these contain EEA-specific customizations
- **Do not add new top-level directories** without updating this README and the harness routing rules
- **Do not commit secrets** in any file, including test fixtures and example configs

---

## Skill Development Workflow

### Adding a New Skill

1. **Create skill directory** under `src/skills/{skill-name}/`
2. **Add upstream `SKILL.md`** (if based on upstream source)
3. **Create `EEA-OVERRIDES.md`** with EEA-specific customizations
4. **Add `metadata.json`** with skill metadata
5. **Update `catalog.yaml`** with new skill entry
6. **Build merged skill**: `./scripts/build.sh {skill-name}`
7. **Verify**: check that `skills/{skill-name}/SKILL.md` was generated correctly and `git status` shows the expected changes
8. **Commit**: `skill: add {skill-name}`

### Updating an Existing Skill

1. **Sync upstream** changes to `src/skills/{name}/SKILL.md`
2. **Update `EEA-OVERRIDES.md`** if upstream changes affect EEA customizations
3. **Rebuild**: `./scripts/build.sh {name}`
4. **Update `catalog.yaml`** version if applicable
5. **Commit**: `skill: update {name} to v{X.Y.Z}`

### Updating EEA Overrides Only

1. **Edit** `src/skills/{name}/EEA-OVERRIDES.md`
2. **Rebuild**: `./scripts/build.sh {name}`
3. **Commit**: `harness: update EEA overrides for {name}`

---

## Build System

```bash
# Build a single skill (merges SKILL.md + EEA-OVERRIDES.md → skills/)
./scripts/build.sh docker-expert

# Build all skills (run with no arguments)
./scripts/build.sh
```

---

## Release Workflow

> **Note:** GitHub Releases and git tags are **discontinued** as of 2026-05-16. The harness is now distributed directly from source (main branch) via the install script or agentget.

1. Ensure all skills are built: `./scripts/build.sh`
2. Verify merged output: `git diff --stat skills/`
3. Update `CHANGELOG.md`
4. Commit and push to `main`
5. Users update via `cd ~/.eea/agent-harness && git pull origin main`

---

## Commit Convention

Use [Conventional Commits](https://www.conventionalcommits.org/):

| Type | Use For |
|------|---------|
| `skill:` | Adding or updating a skill |
| `harness:` | Changes to `harness/EEA-HARNESS.md` or org-wide rules |
| `docs:` | Documentation updates |
| `build:` | Build script or CI changes |
| `chore:` | Maintenance, dependencies, formatting |

---

## Testing Skills

Before merging a skill change:

1. Build the skill and verify the merged output
2. Check that `catalog.yaml` is valid YAML
3. Ensure no secrets or internal URLs leaked into merged output
4. Verify skill loads correctly in OpenCode: `Use {skill-name} to ...`

---

*Last updated: 2026-05-14 after harness initialization*

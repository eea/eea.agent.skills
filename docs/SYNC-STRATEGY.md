# Upstream Sync Strategy

## Two-File Overlay Pattern

```
src/skills/<skill>/
├── SKILL.md           ← Upstream base (replaced during sync)
├── EEA-OVERRIDES.md   ← EEA additions (never touched by upstream)
└── references/
```

## How Sync Works

1. Fetch latest upstream `SKILL.md` → overwrite local `src/skills/<skill>/SKILL.md`
2. `EEA-OVERRIDES.md` stays untouched — no merge conflicts
3. Run `./scripts/build.sh` to merge into `skills/<skill>/SKILL.md`
4. Users and agentget install/discover the **merged** file from `skills/`, not the source files

**Key rule:** Overrides are **additive only** — extend patterns, don't modify core upstream logic.

## Build Process

Agent frameworks expect a single `SKILL.md` per skill. To deliver both upstream + EEA content in one file, we use an automated build step. The `skills/` directory is **committed to the repository** so users can install skills immediately without running the build themselves.

```
src/skills/docker-expert/
├── SKILL.md           ← upstream base
├── EEA-OVERRIDES.md   ← EEA additions
└── references/

        ↓ ./scripts/build.sh

skills/docker-expert/
├── SKILL.md           ← merged upstream + EEA (committed)
└── references/
```

**Build command:**

```bash
# Build all skills
./scripts/build.sh

# Build specific skill
./scripts/build.sh docker-expert
```

The merged file includes:
- Original upstream `SKILL.md` content
- A `---` separator
- `EEA-OVERRIDES.md` content wrapped in `<!-- BEGIN/END EEA-OVERRIDES -->` markers

**Users install from committed `skills/`:**

```bash
git clone https://github.com/eea/eea.agent.skills.git
cp eea.agent.skills/skills/docker-expert/SKILL.md ~/.claude/skills/docker-expert/SKILL.md
```

**Agentget auto-discovery:**

```bash
agentget add eea/eea.agent.skills
```

**CI safeguards:**
- Source files parse correctly
- Build script runs without errors
- **Committed `skills/` matches what would be built from source** (fails CI if out of sync)
- Merged output is structurally valid

**⚠️ Important:** Always run `./scripts/build.sh` and commit `skills/` changes when modifying `src/skills/<skill>/SKILL.md` or `src/skills/<skill>/EEA-OVERRIDES.md`. The CI check `build-sync` will fail if `skills/` is stale.

## EEA Override Rules

### What goes in `EEA-OVERRIDES.md`
- EEA-specific configs (internal registry URLs, proxy settings)
- EEA security baselines (UID ranges, scan requirements)
- EEA-specific examples (compose files using EEA networks)
- Handoff points to other EEA skills

### What does NOT go there
- Changes to upstream's core patterns (layer caching, multi-stage logic)
- Deletions or contradictions of upstream guidance

### Consistency guards
- Version tag: `<!-- EEA-Overrides-Version: 1.0 -->` at top of file
- Clear section headers: `## EEA-Specific Patterns`
- Cross-reference upstream sections rather than duplicating them

## Cross-Skill Consistency (No Conflicts)

Three mechanisms prevent contradictions between skills:

1. **`catalog.yaml` trigger keywords** — each skill declares its activation triggers. A task matching "docker" activates `docker-expert`, not `kubernetes-expert`.

2. **`shared/` directory** — common fragments (EEA style guide, data schemas, design foundations) live in one place. Skills reference them instead of redefining.

3. **Handoff guidelines in each `EEA-OVERRIDES.md`** — explicit rules for when to stop and invoke another skill:
   - Kubernetes → kubernetes-expert (future)
   - CI/CD pipelines → github-actions-expert
   - Database persistence → database-expert

## Practical Sync Workflow

```bash
# Weekly sync check (also runs in CI)
curl -s https://raw.githubusercontent.com/<upstream>/main/skills/docker-expert/SKILL.md \
  > src/skills/docker-expert/SKILL.md

# Verify EEA-OVERRIDES.md still valid
# Open PR with sync
```

**If upstream removes a section that EEA-OVERRIDES.md references?**
- CI catches structural drift during validation
- Human reviews the PR and updates overrides if needed

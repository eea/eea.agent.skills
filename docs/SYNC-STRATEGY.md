# Upstream Sync Strategy

## Two-File Overlay Pattern

```
skills/<skill>/
├── SKILL.md           ← Upstream base (replaced during sync)
├── EEA-OVERRIDES.md   ← EEA additions (never touched by upstream)
└── references/
```

## How Sync Works

1. Fetch latest upstream `SKILL.md` → overwrite local `SKILL.md`
2. `EEA-OVERRIDES.md` stays untouched — no merge conflicts
3. Agent loads both files sequentially: base first, then overrides

**Key rule:** Overrides are **additive only** — extend patterns, don't modify core upstream logic.

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
  > skills/docker-expert/SKILL.md

# Verify EEA-OVERRIDES.md still valid
# Open PR with sync
```

**If upstream removes a section that EEA-OVERRIDES.md references?**
- CI catches structural drift during validation
- Human reviews the PR and updates overrides if needed

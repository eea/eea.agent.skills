# EEA Agent Skills Repository

This file governs how AI agents work when editing the `eea.agent.skills` repository itself.

> **Note:** This is the REPO-LOCAL instruction file. For the organization-wide harness that applies to all EEA projects, see [`harness/EEA-HARNESS.md`](harness/EEA-HARNESS.md).

---

## Prohibited Actions

- **Do not edit `harness/EEA-HARNESS.md` without explicit user request** — that's org-wide policy; changes affect every EEA project
- **Do not commit unmerged upstream changes** to `src/skills/*/SKILL.md` — always run `./scripts/build.sh` first
- **Do not delete `EEA-OVERRIDES.md` files** — these contain EEA-specific customizations
- **Do not add new top-level directories** without updating this README and the harness routing rules
- **Do not commit secrets** in any file, including test fixtures and example configs

---

## Build System

`skills/` is auto-generated. Never edit it directly.

```bash
# Build a single skill (merges SKILL.md + EEA-OVERRIDES.md → skills/)
./scripts/build.sh docker-expert

# Build all skills (run with no arguments)
./scripts/build.sh
```

**After any change to `src/skills/*/SKILL.md` or `EEA-OVERRIDES.md`, run `./scripts/build.sh` and commit the `skills/` changes.**
CI fails if `skills/` is out of sync (`git status --porcelain skills/` must be clean).

The build script also copies `references/`, `DESIGN.md`, and `assets/` if present.

---

## Validation

```bash
# Full health check: repo consistency, catalog sync, agentskills spec compliance
./scripts/verify.sh

# Validate all source and merged skills against the Agent Skills specification
./scripts/validate-skills.sh
```

- `validate-skills.sh` auto-installs `skills-ref` (PyPI) into a temp venv if `agentskills` is missing.
- CI runs both on every PR.

---

## Skill Development Workflow

### Adding a New Skill

1. Create skill directory under `src/skills/{skill-name}/`
2. Add upstream `SKILL.md` (if based on upstream source)
3. Create `EEA-OVERRIDES.md` with EEA-specific customizations
4. Add `metadata.json` with skill metadata
5. Update `catalog.yaml` with new skill entry
6. **Build merged skill**: `./scripts/build.sh {skill-name}`
7. **Verify**: check that `skills/{skill-name}/SKILL.md` was generated correctly and `git status` shows the expected changes
8. **Commit**: `skill: add {skill-name}`

### Updating an Existing Skill

1. Sync upstream changes to `src/skills/{name}/SKILL.md`
2. Update `EEA-OVERRIDES.md` if upstream changes affect EEA customizations
3. Rebuild: `./scripts/build.sh {name}`
4. Update `catalog.yaml` version if applicable
5. Commit: `skill: update {name} to v{X.Y.Z}`

### Updating EEA Overrides Only

1. Edit `src/skills/{name}/EEA-OVERRIDES.md`
2. Rebuild: `./scripts/build.sh {name}`
3. Commit: `harness: update EEA overrides for {name}`

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

## CI Enforcement

| Workflow | Trigger | What it checks |
|----------|---------|--------------|
| `validate-skills.yml` | Push/PR touching skills | `skills/` up-to-date, `catalog.yaml` valid YAML, `agentskills validate` on all skills, token count warnings |
| `validate-harness.yml` | Push/PR touching harness | `harness/EEA-HARNESS.md` exists, referenced files exist, secret scan |
| `check-changelog.yml` | All PRs | Code changes must update `CHANGELOG.md` (bypass with `skip-changelog` label) |

---

## Repo-Specific Conventions

- **Two-file overlay**: every forked skill keeps upstream in `SKILL.md` and EEA deltas in `EEA-OVERRIDES.md`. EEA-specific values must never leak into upstream base skills.
- **`agents/` is reserved** for agentget-compatible sub-agent prompts (`*.agent.md`), not for tool wiring instructions. Agent profiles live in `docs/agent-profiles/`.
- **Date-based versioning** in `CHANGELOG.md` (YYYY-MM-DD), not SemVer.
- **`graphify-out/`** exists locally; only `graphify-out/cache/` is gitignored. Do not commit cache artifacts.

---

## Verification

After running `./scripts/install.sh` (or after any manual changes), verify the installation state:

```bash
# Run the health-check script
./scripts/verify.sh

# Use a specific harness source (e.g. when testing from a local repo)
./scripts/verify.sh --harness-dir /path/to/eea.agent.skills
```

Exit codes:
- `0` — all checks passed
- `1` — failures detected
- `2` — warnings only (no failures)

> **Note on `AGENTS.md` vs `opencode.json`:**
> `~/.config/opencode/AGENTS.md` is for **personal** global instructions (individual preferences).
> `~/.config/opencode/opencode.json` (`instructions` array) is for **org-wide** rules like the EEA harness.
> Never copy the full EEA harness into `AGENTS.md` — it will go stale. Always reference the remote URL in `opencode.json`.

---

*Last updated: 2026-05-21*

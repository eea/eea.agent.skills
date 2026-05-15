<!-- refreshed: 2026-05-14 -->
# Architecture

**Analysis Date:** 2026-05-14

## System Overview

```text
┌─────────────────────────────────────────────────────────────────────────┐
│                       Consumer Agents (Claude, Cursor, OpenCode)         │
│                    Load merged SKILL.md into agent context               │
└─────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                     Distributable Layer (skills/)                        │
│     Pre-built merged artifacts — committed, installable, versioned       │
│     `skills/docker-expert/SKILL.md`  `skills/react-best-practices/...`   │
└─────────────────────────────────────────────────────────────────────────┘
                                    ▲
                                    │  ./scripts/build.sh
┌─────────────────────────────────────────────────────────────────────────┐
│                      Source Layer (src/skills/)                          │
│   ┌────────────────────────┐  ┌──────────────────────────────────────┐  │
│   │  Upstream Base         │  │  EEA Overrides                       │  │
│   │  SKILL.md              │  │  EEA-OVERRIDES.md                    │  │
│   │  (auto-synced)         │  │  (hand-maintained)                   │  │
│   └────────────────────────┘  └──────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                      Cross-Cutting Shared Layer                          │
│   shared/eea-style-guide.md   shared/design-foundations.md              │
│   shared/data-schemas.md      catalog.yaml                              │
└─────────────────────────────────────────────────────────────────────────┘
```

## Component Responsibilities

| Component | Responsibility | File |
|-----------|----------------|------|
| Catalog | Machine-readable skill index with triggers, upstream metadata, versioning | `catalog.yaml` |
| Build Script | Merges upstream `SKILL.md` + `EEA-OVERRIDES.md` into distributable | `scripts/build.sh` |
| Validate Workflow | Lints structure, checks token limits, verifies build sync | `.github/workflows/validate-skills.yml` |
| Release Workflow | Packages merged skills as zip/tar on git tag | `.github/workflows/release.yml` |
| Shared Fragments | Cross-skill reusable content (style guide, design tokens, schemas) | `shared/*.md` |
| Upstream Source | Base skill content fetched from external repositories | `src/skills/<name>/SKILL.md` |
| EEA Overrides | EEA-specific customizations that extend upstream | `src/skills/<name>/EEA-OVERRIDES.md` |

## Pattern Overview

**Overall:** Two-File Overlay Build Pipeline

**Key Characteristics:**
- Upstream content is auto-synced (replace-in-place), never hand-edited
- EEA customizations live in separate override files, immune to upstream drift
- Build-time merge produces single-file distributables committed to repository
- Catalog-driven discovery with keyword triggers for agent frameworks
- Additive-only overrides — extend upstream, never contradict core patterns

## Layers

**Source Layer:**
- Purpose: Store upstream base content and EEA customizations side-by-side
- Location: `src/skills/<skill-name>/`
- Contains: `SKILL.md`, `EEA-OVERRIDES.md`, `references/`, `rules/`, `AGENTS.md`, `metadata.json`
- Depends on: External upstream repositories (GitHub)
- Used by: Build script, CI validation, upstream sync checks

**Distributable Layer:**
- Purpose: Provide agent-ready single-file skills for direct installation
- Location: `skills/<skill-name>/`
- Contains: Merged `SKILL.md` (upstream + overrides), copied `references/`
- Depends on: Source layer via build script
- Used by: Agent frameworks (Claude Code, Cursor, OpenCode, agentget), end users

**Shared Layer:**
- Purpose: Hold cross-skill reusable fragments to avoid duplication
- Location: `shared/`
- Contains: `eea-style-guide.md`, `design-foundations.md`, `data-schemas.md`
- Depends on: Nothing
- Used by: Skill `EEA-OVERRIDES.md` files by reference

**Extension Layer:**
- Purpose: Provide hooks for agentget framework extensions
- Location: `agents/`, `plugins/`, `rules/`, `instructions/`, `workflows/`
- Contains: README placeholders defining expected file patterns
- Depends on: Nothing
- Used by: agentget auto-discovery

**Catalog Layer:**
- Purpose: Index all skills with metadata for machine discovery
- Location: `catalog.yaml`
- Contains: Skill IDs, names, descriptions, categories, upstream sources, trigger keywords, version tags, `eeaspecific` flags
- Depends on: Source layer (must stay in sync)
- Used by: CI validation, agentget, release notes generation

## Data Flow

### Primary Build Path

1. **Upstream fetch** — Latest `SKILL.md` pulled from upstream repo into `src/skills/<name>/SKILL.md` (`docs/SYNC-STRATEGY.md:14`)
2. **Override editing** — Human edits `src/skills/<name>/EEA-OVERRIDES.md` (`CONTRIBUTING.md:64`)
3. **Build merge** — `scripts/build.sh` concatenates upstream + separator + overrides into `skills/<name>/SKILL.md` (`scripts/build.sh:30-47`)
4. **Commit both** — Source and distributable layers committed together (`CONTRIBUTING.md:120`)
5. **CI verification** — `build-sync` job rebuilds and confirms `skills/` matches source (`.github/workflows/validate-skills.yml:34-52`)
6. **Release packaging** — On git tag, zip/tar of `skills/` attached to GitHub Release (`.github/workflows/release.yml:31-42`)
7. **Agent consumption** — User copies merged `SKILL.md` to agent skills directory (`README.md:58`)

### Upstream Sync Check Path

1. **Scheduled trigger** — Weekly cron runs `upstream-sync` job (`.github/workflows/validate-skills.yml:54`)
2. **SHA comparison** — Fetches upstream latest commit SHA via GitHub API
3. **Alert generation** — If changed, creates GitHub Issue (currently TODO stub)

### Skill Invocation Path (Runtime)

1. **Agent receives task** — User prompt contains trigger keyword (e.g., "docker")
2. **Agent loads skill** — Framework resolves keyword to skill path via catalog or directory scan
3. **Skill injected** — Full merged `SKILL.md` content loaded into agent context
4. **Agent follows instructions** — Skill defines detection steps, patterns, checklists, handoff rules

## Key Abstractions

**Skill:**
- Purpose: A self-contained playbook extending an AI agent with domain expertise
- Examples: `src/skills/docker-expert/`, `src/skills/react-best-practices/`
- Pattern: YAML frontmatter metadata + markdown body with code examples + checklists

**Two-File Overlay:**
- Purpose: Separate upstream content (replaceable) from EEA customizations (persistent)
- Examples: `src/skills/docker-expert/SKILL.md` + `EEA-OVERRIDES.md`
- Pattern: Build-time merge with `---` separator and `<!-- BEGIN/END EEA-OVERRIDES -->` markers

**Rule File:**
- Purpose: Granular, addressable guideline for automated or manual reference
- Examples: `src/skills/react-best-practices/rules/async-parallel.md`
- Pattern: `<category>-<rule-name>.md` containing incorrect vs correct code examples

**AGENTS.md Compiled Guide:**
- Purpose: Full expanded reference for agents/LLMs, optimized for automation
- Examples: `src/skills/react-best-practices/AGENTS.md`, `src/skills/composition-patterns/AGENTS.md`
- Pattern: Complete inline expansion of all rules with code samples and cross-references

**Reference Directory:**
- Purpose: Deep reference material beyond the main skill scope
- Examples: `src/skills/react-view-transitions/references/css-recipes.md`
- Pattern: Topic-specific markdown files referenced from main `SKILL.md`

## Entry Points

**Build System Entry Point:**
- Location: `scripts/build.sh`
- Triggers: Manual invocation, CI, release workflow
- Responsibilities: Merge upstream + overrides, copy references, emit to `skills/`

**CI Entry Point:**
- Location: `.github/workflows/validate-skills.yml`
- Triggers: Push to `main`, pull request touching skill files
- Responsibilities: Lint structure, check token counts, validate catalog.yaml, verify build sync

**Release Entry Point:**
- Location: `.github/workflows/release.yml`
- Triggers: Git tag push (`v*`)
- Responsibilities: Build all skills, package as zip/tar, create GitHub Release with artifacts

**Catalog Entry Point:**
- Location: `catalog.yaml`
- Triggers: Agent framework discovery, CI validation
- Responsibilities: Provide machine-readable skill metadata and trigger keywords

## Architectural Constraints

- **Token budget:** Each merged `SKILL.md` should stay under ~5k tokens (warned at >5500 bytes in CI). Large skills must split into `AGENTS.md` or `references/` (`CONTRIBUTING.md:100`)
- **Additive overrides only:** `EEA-OVERRIDES.md` must extend upstream, never modify or contradict core patterns (`docs/SYNC-STRATEGY.md:19`)
- **Committed distributables:** `skills/` directory is committed to git so users can install without building (`CONTRIBUTING.md:122`)
- **Build-sync CI gate:** If `skills/` is stale relative to `src/skills/`, CI fails (`.github/workflows/validate-skills.yml:45`)
- **No runtime code:** This repository contains only markdown content and shell scripts; no compiled artifacts, no package manager lockfiles, no runtime dependencies
- **Upstream immutability assumption:** Upstream `SKILL.md` files are treated as replaceable; any local edits to them are lost on next sync

## Anti-Patterns

### Editing `skills/` Directly

**What happens:** A developer edits `skills/docker-expert/SKILL.md` instead of the source files.
**Why it's wrong:** The change will be overwritten on next build and the CI `build-sync` check will fail.
**Do this instead:** Edit `src/skills/docker-expert/SKILL.md` or `EEA-OVERRIDES.md`, then run `./scripts/build.sh` and commit both layers (`CONTRIBUTING.md:124`).

### Modifying Upstream Core Patterns in Overrides

**What happens:** An override file contradicts or replaces upstream guidance instead of extending it.
**Why it's wrong:** Creates confusion for agents consuming the merged file and breaks on upstream sync.
**Do this instead:** Keep overrides additive — add EEA-specific sections, examples, and handoff rules only (`docs/SYNC-STRATEGY.md:82`).

### Missing EEA-OVERRIDES.md for Forked Skills

**What happens:** A skill copied from upstream lacks an override file.
**Why it's wrong:** CI lint job warns on this; it signals the skill hasn't been EEA-customized yet.
**Do this instead:** Create a placeholder `EEA-OVERRIDES.md` with version tag and EEA-specific patterns, even if minimal (`CONTRIBUTING.md:25`).

## Error Handling

**Strategy:** Fail-fast in CI; warn in local builds.

**Patterns:**
- Missing `SKILL.md` in source → CI exits with error (`.github/workflows/validate-skills.yml:20`)
- Missing `EEA-OVERRIDES.md` → CI prints WARNING but continues (`.github/workflows/validate-skills.yml:18`)
- Token count exceeded → CI prints WARNING (`.github/workflows/validate-skills.yml:27`)
- Build output mismatch → CI exits with error and diff (`.github/workflows/validate-skills.yml:45`)

## Cross-Cutting Concerns

**Logging:** Build script prints `✓ Built: <skill>` per skill; CI echoes validation steps.
**Validation:** YAML schema validation for `catalog.yaml`; structural checks for skill directories; token size checks.
**Authentication:** None required — this is a public repository with no secrets or API keys.

---

*Architecture analysis: 2026-05-14*

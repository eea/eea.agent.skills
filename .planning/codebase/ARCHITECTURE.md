<!-- refreshed: 2026-05-16 -->
# Architecture

**Analysis Date:** 2026-05-16

## System Overview

```text
┌─────────────────────────────────────────────────────────────────────────────┐
│                         AI Agent Tools (User Side)                           │
│   OpenCode    Claude Code    Hermes    Pi    Gemini    agentget (installer) │
└─────────────────────────────────────────────────────────────────────────────┘
                                      │
         ┌────────────────────────────┼────────────────────────────┐
         │                            │                            │
         ▼                            ▼                            ▼
┌─────────────────────┐  ┌─────────────────────┐  ┌─────────────────────┐
│  Remote URL Loader  │  │  Symlink / File Ref │  │  agentget Installer │
│  opencode.json      │  │  ~/.claude/CLAUDE.md│  │  plugins/agentget.  │
│  (harness URL)      │  │  ~/.hermes/HERMES.md│  │  json manifest      │
└─────────────────────┘  └─────────────────────┘  └─────────────────────┘
         │                            │                            │
         └────────────────────────────┼────────────────────────────┘
                                      │
                                      ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                        EEA AI Harness (This Repo)                            │
│                                                                              │
│  ┌─────────────────────────────────────────────────────────────────────────┐ │
│  │  Org-Wide Layer              `harness/EEA-HARNESS.md`                    │ │
│  │  - Safety kernel, context routing, knowledge accumulation protocol      │ │
│  └─────────────────────────────────────────────────────────────────────────┘ │
│  ┌─────────────────────────────────────────────────────────────────────────┐ │
│  │  Rules Layer                 `rules/*.rules.md`                          │ │
│  │  - eeaprohibitions, eeamandatory, changelog.process                     │ │
│  └─────────────────────────────────────────────────────────────────────────┘ │
│  ┌─────────────────────────────────────────────────────────────────────────┐ │
│  │  Skills Layer (Merged)       `skills/<name>/SKILL.md`                    │ │
│  │  - Built from upstream + EEA-OVERRIDES.md                               │ │
│  └─────────────────────────────────────────────────────────────────────────┘ │
│  ┌─────────────────────────────────────────────────────────────────────────┐ │
│  │  Shared Knowledge            `shared/`                                   │ │
│  │  - style-guide, glossary, design-foundations, data-schemas, architecture│ │
│  └─────────────────────────────────────────────────────────────────────────┘ │
│  ┌─────────────────────────────────────────────────────────────────────────┐ │
│  │  Agent Profiles              `agents/<tool>.md`                          │ │
│  │  - Per-tool wiring instructions (OpenCode, Claude, Hermes, Pi, Gemini)  │ │
│  └─────────────────────────────────────────────────────────────────────────┘ │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
                                      │
         ┌────────────────────────────┼────────────────────────────┐
         │                            │                            │
         ▼                            ▼                            ▼
┌─────────────────────┐  ┌─────────────────────┐  ┌─────────────────────┐
│  Project Local      │  │  Project Local      │  │  Project Local      │
│  `AGENTS.md`        │  │  `opencode.json`    │  │  `.claude/CLAUDE.  │
│  (additive rules)   │  │  (instructions)     │  │  md`                │
└─────────────────────┘  └─────────────────────┘  └─────────────────────┘
```

## Component Responsibilities

| Component | Responsibility | File |
|-----------|----------------|------|
| **EEA Harness** | Org-wide canonical instructions loaded by all EEA projects | `harness/EEA-HARNESS.md` |
| **Prohibitions** | Security, compliance, operational safety rules | `rules/eeaprohibitions.rules.md` |
| **Mandatory Rules** | Required agent behaviors at session end / destructive ops | `rules/eeamandatory.rules.md` |
| **Skill Merger** | Combines upstream SKILL.md + EEA-OVERRIDES.md into distributable | `scripts/build.sh` |
| **Catalog Index** | Machine-readable skill registry with triggers and versions | `catalog.yaml` |
| **Agentget Manifest** | Declarative install config for agentget installer | `plugins/agentget.json` |
| **Installer** | Auto-detects agents, clones repo, symlinks/configures | `scripts/install.sh` |
| **Shared Knowledge** | Cross-project glossary, style guide, design foundations | `shared/*.md` |
| **Agent Profiles** | Per-tool wiring docs (OpenCode, Claude, Hermes, Pi, Gemini) | `agents/*.md` |

## Pattern Overview

**Overall:** Two-Layer Harness with Two-File Overlay Build

**Key Characteristics:**
- **Separation of concerns:** Org-wide rules live in `harness/`, repo-local rules in root `AGENTS.md`, per-project rules in `{repo}/AGENTS.md`
- **Additive customization:** EEA-specific values never modify upstream skill logic; they extend via `EEA-OVERRIDES.md`
- **Build-time merge:** The `skills/` directory contains pre-built merged artifacts committed to git; consumers install from `skills/`, never from `src/skills/`
- **Trigger-based routing:** The harness maps keywords to skills/rules so agents load only relevant context
- **Multi-tool distribution:** Same harness distributed via remote URLs, symlinks, file references, or automated installer

## Layers

**Org-Wide Harness Layer:**
- Purpose: Loaded by every EEA project; defines safety kernel, routing, mandatory protocols
- Location: `harness/EEA-HARNESS.md`
- Contains: Role definition, safety kernel, skill & rule routing table, knowledge accumulation protocol
- Depends on: `rules/eeaprohibitions.rules.md`, `rules/eeamandatory.rules.md`
- Used by: All EEA projects via URL, symlink, or inline copy

**Rules Layer:**
- Purpose: Org-wide prohibitions and mandatory behaviors
- Location: `rules/`
- Contains: `eeaprohibitions.rules.md`, `eeamandatory.rules.md`, `changelog.process.md`
- Depends on: Nothing (standalone)
- Used by: Harness references them; agents load on trigger match

**Skills Source Layer:**
- Purpose: Upstream skill bases and EEA-specific overrides
- Location: `src/skills/<name>/`
- Contains: `SKILL.md` (upstream), `EEA-OVERRIDES.md` (EEA), `references/`, `metadata.json`, `AGENTS.md`, `README.md`, `rules/*.md`
- Depends on: Upstream sources (external repos)
- Used by: Build script to produce merged `skills/<name>/SKILL.md`

**Skills Distribution Layer:**
- Purpose: Pre-built merged skills ready for agent consumption
- Location: `skills/<name>/`
- Contains: `SKILL.md` (merged upstream + overrides), `references/`
- Depends on: `src/skills/<name>/SKILL.md` and `src/skills/<name>/EEA-OVERRIDES.md`
- Used by: Agents, agentget installer, manual copy

**Agent Profiles Layer:**
- Purpose: Per-tool installation and configuration instructions
- Location: `agents/`
- Contains: `opencode.md`, `claudecode.md`, `hermes.md`, `gemini.md`, `pi.md`, `README.md`
- Depends on: `harness/EEA-HARNESS.md`
- Used by: Developers setting up individual agent tools

**Shared Knowledge Layer:**
- Purpose: Cross-project reusable knowledge fragments
- Location: `shared/`
- Contains: `eea-style-guide.md`, `design-foundations.md`, `data-schemas.md`, `glossary.md`, `architecture/`
- Depends on: Nothing
- Used by: Skills reference these instead of duplicating definitions

**Workflows Layer:**
- Purpose: Multi-skill orchestration recipes
- Location: `workflows/`
- Contains: `data-report.md`, `README.md`
- Depends on: Skills (future: chart, xlsx, doc)
- Used by: Agents when user requests multi-step tasks

**Templates Layer:**
- Purpose: Starter files for project-local agent setup
- Location: `templates/dot-agents/`
- Contains: `AGENTS.md` (project-local template), `opencode.json` (project config template)
- Depends on: Nothing
- Used by: Developers bootstrapping new EEA projects

**CI/CD Layer:**
- Purpose: Validates harness integrity, skill builds, and changelog discipline
- Location: `.github/workflows/`
- Contains: `validate-harness.yml`, `validate-skills.yml`, `check-changelog.yml`
- Depends on: `scripts/build.sh`, `catalog.yaml`
- Used by: GitHub Actions on push/PR

## Data Flow

### Primary Request Path (Skill Update)

1. Developer edits upstream base (`src/skills/<name>/SKILL.md`) or overrides (`src/skills/<name>/EEA-OVERRIDES.md`)
2. Developer runs `./scripts/build.sh <name>` (`scripts/build.sh:13-55`)
3. Build script concatenates upstream + separator + overrides into `skills/<name>/SKILL.md`
4. CI `validate-skills.yml` verifies `skills/` is in sync with source (`validate-skills.yml:71-82`)
5. Agent or agentget installs merged skill from `skills/<name>/SKILL.md`
6. Agent invokes skill based on trigger-word match defined in `catalog.yaml`

### Harness Distribution Path

1. `harness/EEA-HARNESS.md` updated with new rules or routing
2. CI `validate-harness.yml` checks file existence, structure, references, and secret scan (`validate-harness.yml:24-116`)
3. Consumers receive updates via:
   - Remote URL (OpenCode loads on every session)
   - Git pull in `~/.eea/agent-harness` (symlink consumers auto-update)
   - Git submodule update (pinned consumers)

### Installer Path

1. User runs `curl ... | bash` or `agentget install eea/eea.agent.skills`
2. `scripts/install.sh` clones repo to `~/.eea/agent-harness` (`install.sh:89-114`)
3. Installer detects installed agents (`install.sh:317-341`)
4. Per-agent setup: OpenCode gets config file, Claude/Hermes/Pi/Gemini get symlinks (`install.sh:117-222`)
5. Skills copied to agent skill directories (`install.sh:225-283`)
6. Rules symlinked to agent rule directories (`install.sh:307-314`)

## Key Abstractions

**Two-File Overlay:**
- Purpose: Keep upstream content cleanly separated from EEA customizations
- Examples: `src/skills/docker-expert/SKILL.md` + `src/skills/docker-expert/EEA-OVERRIDES.md` → `skills/docker-expert/SKILL.md`
- Pattern: Upstream base is replaced during sync; overrides are additive and never touched by upstream

**Trigger-Based Routing:**
- Purpose: Load only relevant skills/rules based on user intent
- Examples: `catalog.yaml` maps `docker` → `docker-expert`; `harness/EEA-HARNESS.md` maps `security` → `eeaprohibitions`
- Pattern: Keyword lists in YAML/Markdown; agents match against user prompts

**Three-Tier Instructions:**
- Purpose: Prevent org rules from leaking into wrong scopes
- Examples: `harness/EEA-HARNESS.md` (org) → `AGENTS.md` (this repo only) → `{project}/AGENTS.md` (one project)
- Pattern: Each tier additive; local rules override global only for conflicts

## Entry Points

**Harness Entry Point:**
- Location: `harness/EEA-HARNESS.md`
- Triggers: Loaded by every EEA project agent session
- Responsibilities: Define role, safety kernel, routing, mandatory protocols, knowledge accumulation

**Build Entry Point:**
- Location: `scripts/build.sh`
- Triggers: Developer runs manually; CI runs on PR/push
- Responsibilities: Merge upstream + overrides; validate merged output exists

**Install Entry Point:**
- Location: `scripts/install.sh`
- Triggers: User runs curl/bash or agentget
- Responsibilities: Clone repo, detect agents, create symlinks/configs, copy skills, link rules

**Catalog Entry Point:**
- Location: `catalog.yaml`
- Triggers: agentget reads manifest; CI validates schema
- Responsibilities: Declare skill IDs, versions, triggers, upstream sources, EEA-specific flags

**Project Bootstrap Entry Point:**
- Location: `docs/BOOTSTRAP.md`
- Triggers: New EEA developer onboarding
- Responsibilities: Explain 3 installation methods, per-agent setup, verification steps

## Architectural Constraints

- **No runtime code:** This repository contains only Markdown, YAML, JSON, and shell scripts. No compiled artifacts, no package manager dependencies, no server runtime.
- **Single-threaded build:** `scripts/build.sh` processes skills sequentially; no parallelism implemented.
- **Git-dependent distribution:** All distribution paths assume Git is available (clone, pull, submodule).
- **Markdown-only skills:** Agent frameworks expect `SKILL.md` files; no structured formats (JSON, TOML) used for skill content.
- **Committed build artifacts:** The `skills/` directory is committed to git so consumers can install without running the build themselves. This requires CI to enforce that `skills/` stays in sync with `src/skills/`.
- **No secrets in repo:** Forbidden files policy prohibits `.env`, credentials, keys. All EEA-specific values (registry URLs, proxy addresses) live in `EEA-OVERRIDES.md` which is also public but scoped.
- **Additive overrides only:** `EEA-OVERRIDES.md` must not delete or contradict upstream guidance. Violations caught in code review.

## Anti-Patterns

### Editing `skills/` Directly

**What happens:** A developer edits `skills/docker-expert/SKILL.md` instead of source files.
**Why it's wrong:** Changes are overwritten on next `./scripts/build.sh` run. CI `build-sync` job will also fail because committed `skills/` won't match rebuilt output.
**Do this instead:** Edit `src/skills/docker-expert/SKILL.md` or `src/skills/docker-expert/EEA-OVERRIDES.md`, then run `./scripts/build.sh docker-expert`.

### Hardcoding EEA Values in Upstream Skills

**What happens:** EEA-specific registry URLs or proxy addresses are added directly to `src/skills/<name>/SKILL.md`.
**Why it's wrong:** Upstream skills may be consumed by non-EEA users or published publicly. Hardcoded values leak internal infrastructure.
**Do this instead:** Add EEA values to `src/skills/<name>/EEA-OVERRIDES.md` per `rules/eeaprohibitions.rules.md` section EEA-01.

### Skipping Build Before Commit

**What happens:** Developer commits changes to `src/skills/` but forgets to run `./scripts/build.sh`.
**Why it's wrong:** CI `validate-skills.yml` `build-sync` job checks `git status --porcelain skills/` and fails if out of sync.
**Do this instead:** Always run `./scripts/build.sh` and commit both `src/skills/` and `skills/` changes together.

## Error Handling

**Strategy:** Fail-fast in CI; warn in build script; alert in installer.

**Patterns:**
- Build script exits with code 1 if `SKILL.md` missing (`scripts/build.sh:23-26`)
- CI fails if `skills/` out of sync (`validate-skills.yml:71-82`)
- Installer warns (does not fail) if agent config already exists (`install.sh:125-130`, `install.sh:145-152`)
- Secret scan emits WARNING but does not fail CI, to avoid blocking on false positives (`validate-harness.yml:100-110`)

## Cross-Cutting Concerns

**Logging:** Build script prints success/failure per skill (`scripts/build.sh:54`). Installer uses color-coded log levels (`install.sh:41-55`).

**Validation:** Three CI workflows provide mechanical enforcement:
- `validate-harness.yml` — file existence, Markdown structure, YAML validity, secret patterns
- `validate-skills.yml` — source files present, token limits, build correctness, sync check
- `check-changelog.yml` — enforces CHANGELOG.md updates for code changes in PRs

**Authentication:** No authentication within this repo. Distribution relies on public GitHub raw URLs and public git clone. EEA-specific auth (proxies, registries) is documented in override files but no credentials are stored.

---

*Architecture analysis: 2026-05-16*

# Codebase Structure

**Analysis Date:** 2026-05-16

## Directory Layout

```
ea.agent.skills/
├── harness/                    # Org-wide canonical harness
│   └── EEA-HARNESS.md          # Loaded by all EEA projects
│
├── AGENTS.md                   # Repo-local instructions (this repo only)
│
├── skills/                     # Distributable merged skills (built artifacts)
│   ├── docker-expert/
│   │   ├── SKILL.md            # Merged upstream + EEA overrides
│   │   └── references/         # Deep reference material (copied from src)
│   ├── composition-patterns/
│   ├── react-best-practices/
│   ├── react-native-skills/
│   ├── react-view-transitions/
│   └── web-design-guidelines/
│
├── src/skills/                 # Source: upstream base + EEA overrides
│   ├── docker-expert/
│   │   ├── SKILL.md            # Upstream base (replaced during sync)
│   │   ├── EEA-OVERRIDES.md    # EEA-specific customizations
│   │   └── references/         # Reference material
│   ├── composition-patterns/
│   │   ├── SKILL.md
│   │   ├── EEA-OVERRIDES.md
│   │   ├── metadata.json       # Skill metadata
│   │   ├── AGENTS.md           # Skill-specific agent instructions
│   │   ├── README.md           # Human-readable skill overview
│   │   └── rules/              # Granular rule files for this skill
│   ├── react-best-practices/
│   ├── react-native-skills/
│   ├── react-view-transitions/
│   └── web-design-guidelines/
│
├── rules/                      # Org-wide prohibitions & mandatory behaviors
│   ├── eeaprohibitions.rules.md
│   ├── eeamandatory.rules.md
│   ├── changelog.process.md
│   └── README.md
│
├── agents/                     # Per-tool agent profiles
│   ├── opencode.md             # OpenCode wiring instructions
│   ├── claudecode.md           # Claude Code wiring instructions
│   ├── hermes.md               # Hermes Agent wiring instructions
│   ├── gemini.md               # Gemini wiring instructions
│   ├── pi.md                   # Pi wiring instructions
│   └── README.md
│
├── shared/                     # Cross-project knowledge base
│   ├── eea-style-guide.md      # EEA brand/tone for LLM outputs
│   ├── design-foundations.md   # Design tokens, color palettes
│   ├── data-schemas.md         # Common EEA data structures
│   ├── glossary.md             # EEA acronyms and terminology
│   └── architecture/           # Architecture decision records (ADRs)
│       └── README.md
│
├── instructions/               # Generic org-wide instruction templates
│
├── workflows/                  # Multi-skill orchestration recipes
│   ├── data-report.md
│   └── README.md
│
├── plugins/
│   └── agentget.json           # Manifest for agentget installer
│
├── scripts/                    # Build + install automation
│   ├── build.sh                # Merges SKILL.md + EEA-OVERRIDES.md
│   └── install.sh              # One-shot harness installer
│
├── docs/                       # Documentation and examples
│   ├── BOOTSTRAP.md            # Onboarding guide for EEA developers
│   ├── SYNC-STRATEGY.md        # Upstream sync strategy documentation
│   ├── CHANGELOG.md            # Project changelog
│   └── opencode-examples/      # opencode.json templates
│       ├── global-opencode.json
│       └── project-agents.md
│
├── templates/                  # Templates for project-local .agents/ setup
│   └── dot-agents/
│       ├── AGENTS.md           # Project-local instructions template
│       └── opencode.json       # Project opencode.json template
│
├── catalog.yaml                # Machine-readable skill index
├── README.md                   # Repository overview
├── CONTRIBUTING.md             # Contribution guidelines
├── LICENSE                     # MIT license
├── CHANGELOG.md                # Project changelog
└── .github/
    ├── CODEOWNERS              # Code ownership definitions
    └── workflows/
        ├── validate-skills.yml # CI: skill validation & build sync
        ├── validate-harness.yml# CI: harness validation
        └── check-changelog.yml # CI: enforce CHANGELOG updates
```

## Directory Purposes

**`harness/`:**
- Purpose: Org-wide canonical instructions
- Contains: Single file `EEA-HARNESS.md`
- Key files: `harness/EEA-HARNESS.md`

**`skills/`:**
- Purpose: Pre-built merged skills ready for agent consumption
- Contains: One directory per skill; each contains merged `SKILL.md` and `references/`
- Key files: `skills/docker-expert/SKILL.md`, `skills/react-best-practices/SKILL.md`
- Generated: Yes (by `scripts/build.sh`)
- Committed: Yes (so users can install without building)

**`src/skills/`:**
- Purpose: Source files for skills — upstream base + EEA overrides
- Contains: Per-skill directories with `SKILL.md`, `EEA-OVERRIDES.md`, `references/`, `metadata.json`, `AGENTS.md`, `README.md`, `rules/`
- Key files: `src/skills/docker-expert/SKILL.md`, `src/skills/docker-expert/EEA-OVERRIDES.md`

**`rules/`:**
- Purpose: Org-wide prohibitions and mandatory behaviors
- Contains: Markdown files with `.rules.md` suffix
- Key files: `rules/eeaprohibitions.rules.md`, `rules/eeamandatory.rules.md`

**`agents/`:**
- Purpose: Per-tool installation and configuration instructions
- Contains: One Markdown file per supported agent tool
- Key files: `agents/opencode.md`, `agents/claudecode.md`

**`shared/`:**
- Purpose: Cross-project reusable knowledge fragments referenced by skills
- Contains: Style guide, glossary, design foundations, data schemas, architecture ADRs
- Key files: `shared/eea-style-guide.md`, `shared/glossary.md`

**`workflows/`:**
- Purpose: Multi-skill orchestration recipes for complex tasks
- Contains: Markdown workflow definitions
- Key files: `workflows/data-report.md`

**`templates/dot-agents/`:**
- Purpose: Starter files for project-local agent setup
- Contains: `AGENTS.md` template, `opencode.json` template
- Key files: `templates/dot-agents/AGENTS.md`

**`plugins/`:**
- Purpose: Tool-specific adapter manifests
- Contains: `agentget.json` installer manifest
- Key files: `plugins/agentget.json`

**`scripts/`:**
- Purpose: Build and install automation
- Contains: Bash scripts
- Key files: `scripts/build.sh`, `scripts/install.sh`

**`docs/`:**
- Purpose: Human-facing documentation and examples
- Contains: Bootstrap guide, sync strategy, opencode examples, CHANGELOG
- Key files: `docs/BOOTSTRAP.md`, `docs/SYNC-STRATEGY.md`

**`.github/workflows/`:**
- Purpose: CI/CD automation
- Contains: GitHub Actions workflow definitions
- Key files: `.github/workflows/validate-skills.yml`, `.github/workflows/validate-harness.yml`, `.github/workflows/check-changelog.yml`

## Key File Locations

**Entry Points:**
- `harness/EEA-HARNESS.md`: Org-wide harness entry point loaded by all EEA projects
- `scripts/build.sh`: Build system entry point
- `scripts/install.sh`: Installer entry point
- `catalog.yaml`: Machine-readable skill registry entry point

**Configuration:**
- `catalog.yaml`: Skill index with triggers, versions, upstream sources
- `plugins/agentget.json`: agentget installer manifest
- `.github/CODEOWNERS`: Code ownership definitions

**Core Logic:**
- `scripts/build.sh`: Merges `SKILL.md` + `EEA-OVERRIDES.md` into `skills/`
- `scripts/install.sh`: Auto-detects agents, clones repo, creates symlinks/configs

**Testing / Validation:**
- `.github/workflows/validate-skills.yml`: CI validation for skills
- `.github/workflows/validate-harness.yml`: CI validation for harness
- `.github/workflows/check-changelog.yml`: CI enforcement of CHANGELOG updates

## Naming Conventions

**Files:**
- `SKILL.md`: Uppercase — the primary skill instruction file consumed by agents
- `EEA-OVERRIDES.md`: Uppercase with hyphen — EEA-specific customizations
- `AGENTS.md`: Uppercase — repo-local or project-local agent instructions
- `*.rules.md`: Lowercase with dot suffix — org-wide rule files
- `*.yml`: Lowercase — CI workflow definitions
- `*.sh`: Lowercase — shell scripts

**Directories:**
- `src/skills/<kebab-case-name>/`: Skill source directories use kebab-case
- `skills/<kebab-case-name>/`: Built skill directories use kebab-case
- `agents/`, `rules/`, `shared/`, `workflows/`: Plural lowercase for collections
- `harness/`: Singular lowercase for single canonical artifact

## Where to Add New Code

**New Skill:**
- Primary source: `src/skills/{skill-name}/`
  - Add `SKILL.md` (upstream base)
  - Add `EEA-OVERRIDES.md` (EEA customizations)
  - Add `metadata.json` (skill metadata)
  - Add `README.md` (human overview)
  - Optional: `references/` (deep reference material)
  - Optional: `rules/` (granular rule files)
  - Optional: `AGENTS.md` (skill-specific agent instructions)
- Update registry: `catalog.yaml`
- Build artifact: Run `./scripts/build.sh {skill-name}` → produces `skills/{skill-name}/SKILL.md`
- Commit both `src/skills/` and `skills/` changes

**New Rule:**
- Prohibitions: `rules/eeaprohibitions.rules.md`
- Mandatory actions: `rules/eeamandatory.rules.md`
- Changelog guidance: `rules/changelog.process.md`
- If adding a new rule category, create `rules/{category}.rules.md` and reference it in `harness/EEA-HARNESS.md`

**New Agent Profile:**
- Profile doc: `agents/{toolname}.md`
- Update installer: `scripts/install.sh` (add `install_{toolname}` function and detection logic)
- Update manifest: `plugins/agentget.json` (add to `agents.profiles`)
- Update bootstrap: `docs/BOOTSTRAP.md`

**New Shared Knowledge:**
- Cross-project topic: `shared/{topic}.md`
- Reference from skills via relative path or mention in `harness/EEA-HARNESS.md`

**New Workflow:**
- Recipe: `workflows/{workflow-name}.md`
- Update `workflows/README.md`

**New Project Template:**
- Template file: `templates/dot-agents/{filename}`

## Special Directories

**`skills/`:**
- Purpose: Pre-built merged skill artifacts
- Generated: Yes — output of `scripts/build.sh`
- Committed: Yes — must stay in sync with `src/skills/`; CI enforces this
- **Critical:** Never edit directly. Always edit source in `src/skills/` and rebuild.

**`src/skills/`:**
- Purpose: Source of truth for skill content
- Generated: No — hand-maintained; upstream `SKILL.md` may be copied from external repos
- Committed: Yes
- **Critical:** `EEA-OVERRIDES.md` is additive only; do not delete or contradict upstream guidance.

**`graphify-out/`:**
- Purpose: Output directory for graphify skill analysis
- Generated: Yes — by graphify skill
- Committed: No (should be in `.gitignore` or treated as ephemeral)

**`.planning/`:**
- Purpose: GSD planning artifacts (codebase maps, execution plans)
- Generated: Yes — by GSD agents
- Committed: No (ephemeral planning context)

---

*Structure analysis: 2026-05-16*

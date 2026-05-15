# Codebase Structure

**Analysis Date:** 2026-05-14

## Directory Layout

```
├── agents/                 # Agent persona definitions (*.agent.md)
├── catalog.yaml            # Machine-readable skill index
├── CHANGELOG.md            # Version history
├── CONTRIBUTING.md         # Contribution guidelines
├── docs/                   # Documentation
│   └── SYNC-STRATEGY.md    # Upstream sync strategy
├── graphify-out/           # Generated artifacts from graphify skill runs
│   ├── cache/              # Cached chunk embeddings
│   ├── graph.html          # Knowledge graph visualization
│   ├── graph.json          # Graph data
│   └── GRAPH_REPORT.md     # Graph audit report
├── instructions/           # Instruction files (*.instructions.md)
├── LICENSE                 # MIT license
├── plugins/                # Plugin directories
├── README.md               # Project overview
├── rules/                  # Rule files (*.rules.md)
├── scripts/                # Build automation
│   └── build.sh            # Merges SKILL.md + EEA-OVERRIDES.md
├── shared/                 # Cross-skill reusable fragments
│   ├── data-schemas.md     # Common EEA data structures
│   ├── design-foundations.md # Design tokens, color palettes
│   └── eea-style-guide.md  # EEA brand/tone guidance
├── skills/                 # Distributable: merged skills for agentget
│   ├── docker-expert/
│   ├── react-best-practices/
│   ├── react-native-skills/
│   ├── react-view-transitions/
│   ├── composition-patterns/
│   └── web-design-guidelines/
├── src/                    # Source code and assets
│   └── skills/             # Source: one subdirectory per skill
│       ├── docker-expert/
│       ├── react-best-practices/
│       ├── react-native-skills/
│       ├── react-view-transitions/
│       ├── composition-patterns/
│       └── web-design-guidelines/
└── workflows/              # Multi-skill orchestration recipes
    └── data-report.md      # Example chained workflow
```

## Directory Purposes

**`src/skills/`:**
- Purpose: Source of truth for all skill content
- Contains: Upstream `SKILL.md`, `EEA-OVERRIDES.md`, `references/`, `rules/`, `AGENTS.md`, `metadata.json`, `README.md`
- Key files: `src/skills/docker-expert/SKILL.md`, `src/skills/react-best-practices/rules/_template.md`

**`skills/`:>**
- Purpose: Pre-built merged distributables committed for direct installation
- Contains: Merged `SKILL.md` (upstream + EEA overrides), copied `references/`
- Key files: `skills/docker-expert/SKILL.md`, `skills/react-best-practices/SKILL.md`
- Generated: Yes (by `scripts/build.sh`)
- Committed: Yes (intentionally committed for zero-build installs)

**`shared/`:>**
- Purpose: Cross-skill reusable markdown fragments
- Contains: `eea-style-guide.md`, `design-foundations.md`, `data-schemas.md`
- Key files: `shared/eea-style-guide.md`

**`scripts/`:>**
- Purpose: Build automation
- Contains: `build.sh`
- Key files: `scripts/build.sh`

**`docs/`:>**
- Purpose: Human-readable documentation
- Contains: `SYNC-STRATEGY.md`
- Key files: `docs/SYNC-STRATEGY.md`

**`agents/`, `plugins/`, `rules/`, `instructions/`:>**
- Purpose: Extension points for agentget framework auto-discovery
- Contains: `README.md` placeholders defining expected patterns
- Key files: `agents/README.md`, `plugins/README.md`, `rules/README.md`, `instructions/README.md`

**`workflows/`:>**
- Purpose: Multi-skill orchestration recipes
- Contains: `data-report.md`
- Key files: `workflows/data-report.md`

**`.github/workflows/`:>**
- Purpose: CI/CD automation
- Contains: `validate-skills.yml`, `release.yml`
- Key files: `.github/workflows/validate-skills.yml`

**`graphify-out/`:>**
- Purpose: Generated artifacts from graphify knowledge graph runs
- Contains: `graph.html`, `graph.json`, `GRAPH_REPORT.md`, `cache/`, `manifest.json`
- Generated: Yes
- Committed: Yes (historical artifact output)

## Key File Locations

**Entry Points:**
- `scripts/build.sh`: Build system entry point
- `catalog.yaml`: Machine-readable skill catalog
- `.github/workflows/validate-skills.yml`: CI validation entry point

**Configuration:**
- `catalog.yaml`: Skill index with triggers and upstream metadata
- `.github/workflows/validate-skills.yml`: CI pipeline configuration
- `.github/workflows/release.yml`: Release automation configuration

**Core Logic:**
- `scripts/build.sh`: Merge upstream + overrides into distributable
- `src/skills/*/SKILL.md`: Upstream skill base content
- `src/skills/*/EEA-OVERRIDES.md`: EEA-specific customizations

**Testing/Validation:**
- `.github/workflows/validate-skills.yml`: Structural and build-sync validation

**Documentation:**
- `README.md`: Project overview and install instructions
- `CONTRIBUTING.md`: How to add/update skills
- `docs/SYNC-STRATEGY.md`: Upstream sync strategy documentation

## Naming Conventions

**Files:**
- `SKILL.md`: Main skill instruction file (required, exactly this name)
- `EEA-OVERRIDES.md`: EEA customization overlay (required for forked skills)
- `AGENTS.md`: Compiled full guide for LLM consumption
- `README.md`: Directory-level documentation
- `metadata.json`: Machine-readable skill metadata
- `*.rules.md`: Rule file in `rules/` directory
- `*.agent.md`: Agent persona definition
- `*.instructions.md`: Instruction fragment
- `_template.md`: Template for new rule files
- `_sections.md`: Section index for rules

**Directories:**
- `src/skills/<skill-id>/`: Source skill directory (kebab-case skill ID)
- `skills/<skill-id>/`: Distributable skill directory (mirrors source ID)
- `references/`: Deep reference material subdirectory
- `rules/`: Granular rule files subdirectory
- `cache/`: Cached embeddings/artifacts

## Where to Add New Code

**New Skill (forked from upstream):**
- Upstream base: `src/skills/<skill-id>/SKILL.md`
- EEA overrides: `src/skills/<skill-id>/EEA-OVERRIDES.md`
- References: `src/skills/<skill-id>/references/`
- Catalog entry: `catalog.yaml`
- Distributable: `skills/<skill-id>/SKILL.md` (run `./scripts/build.sh` after)

**New Skill (original, no upstream):**
- Create `src/skills/<skill-id>/SKILL.md` following template in `CONTRIBUTING.md`
- Add `EEA-OVERRIDES.md` with version tag even if minimal
- Add catalog entry in `catalog.yaml`
- Build and commit distributable

**New Rule (for skills with rules/):**
- Implementation: `src/skills/<skill-id>/rules/<category>-<rule-name>.md`
- Follow `_template.md` pattern in same rules directory
- Update `_sections.md` if category index exists
- Rebuild AGENTS.md if compiled guide is maintained

**New Reference Material:**
- Deep references: `src/skills/<skill-id>/references/<topic>.md`
- Reference from main `SKILL.md` with relative path

**New Shared Fragment:**
- Cross-skill content: `shared/<fragment-name>.md`
- Reference from `EEA-OVERRIDES.md` with relative path to `shared/`

**New Workflow:**
- Orchestration recipe: `workflows/<workflow-name>.md`

**New Agent/Plugin/Rule/Instruction:**
- Agent persona: `agents/<name>.agent.md`
- Plugin directory: `plugins/<plugin-name>/`
- Rule set: `rules/<name>.rules.md`
- Instruction: `instructions/<name>.instructions.md`

## Special Directories

**`skills/`:**
- Purpose: Pre-built merged skills for direct agent installation
- Generated: Yes (by `scripts/build.sh`)
- Committed: Yes (must stay in sync with `src/skills/`)
- Warning: Never edit directly; CI will fail if out of sync

**`graphify-out/`:**
- Purpose: Output directory for graphify knowledge graph generation
- Generated: Yes (by graphify skill/tool)
- Committed: Yes (historical artifacts)
- Contents: HTML visualization, JSON graph data, cache of chunk embeddings

**`src/skills/<skill>/references/`:**
- Purpose: Deep reference material beyond main skill scope
- Generated: No
- Committed: Yes
- Copied to `skills/<skill>/references/` during build

**`src/skills/<skill>/rules/`:**
- Purpose: Granular rule files for large skills (e.g., react-best-practices)
- Generated: No
- Committed: Yes
- Not copied to distributable by build script (referenced from SKILL.md/AGENTS.md)

---

*Structure analysis: 2026-05-14*

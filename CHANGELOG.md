# Changelog

All notable changes to this repository are documented here.

This project uses **date-based versioning** (YYYY-MM-DD) rather than semantic versioning. Entries are ordered newest-first.

---

## 2026-08-07 — Fix PR #1 Review Findings and Refocus the Testing Skill

### Fixed
- `catalog.yaml`: was committed with a literal `NNNN|` line-number prefix on every line (looked like unedited `cat -n` output); stripped, now parses as valid YAML.
- Bind-mount vs. Docker-outside-of-Docker contradiction: `testing/SKILL.md` and its `docker-test-parity.md` reference recommended `docker run -v "$PWD:/workspace" ...` for local reproduction, which silently produces an empty directory on EEA Jenkins `docker-host` agents. Both now build parity commands around source already baked into the image via `COPY . .`, so the same command genuinely works in both places instead of only looking like it does.
- `jenkins-pipeline`'s `upstream` in `metadata.json`/`catalog.yaml` claimed `aj-geddes/useful-ai-prompts` while `eeaspecific: true` and the content is fully rewritten; set to `null` and reworded the `SKILL.md` frontmatter/notes to describe it as EEA-original, consistent with `code-quality`/`quality-fixes`.
- `catalog.yaml` was missing an entry for the `testing` skill entirely; added one.
- `pom.xml` on a Java/Maven test repo never declared `org.sonarsource.scanner.maven:sonar-maven-plugin`, so `mvn sonar:sonar`'s bare-prefix resolution depended entirely on whichever Jenkins node/container ran the build having that plugin group registered in its own ambient `~/.m2/settings.xml` — confirmed via two real, otherwise-identical Jenkins builds where one succeeded and the next failed with `No plugin found for prefix 'sonar'`. `references/examples/java-maven-jenkinsfile.md` and `EEA-OVERRIDES.md` now document declaring the plugin explicitly in `pom.xml` so resolution never depends on the executing node.
- A generated Jenkinsfile pre-declared `RELEASE_IMAGE = ''` in the top-level `environment{}` block, then tried to override it with `env.RELEASE_IMAGE = "..."` inside a `script{}` step — a real Jenkins Declarative Pipeline pitfall where the pre-declared value silently wins over the later runtime assignment for every `sh` step. Confirmed via a real Jenkins run: `docker build -t '' .` failing with `invalid tag ""`. `EEA-OVERRIDES.md` now has a dedicated "Never pre-declare a dynamically-computed environment{} variable" section.

### Changed
- De-duplicated the `Dockerfile.test` artifact contract, which was stated near-verbatim in three places (`docker-expert/EEA-OVERRIDES.md`, `jenkins-pipeline/references/dockerfile-test-template.md`, `testing/SKILL.md`): `docker-expert/EEA-OVERRIDES.md` is now the single canonical source; the other two cross-reference it and keep only their own genuinely distinct content (the Jenkins-stage command mapping, respectively the parity principle).
- `code-quality/SKILL.md`'s restatement of the "same Docker image, same command strings" principle now cross-references `testing` instead of repeating it.
- Refocused the `testing` skill's mission: parity-command guidance is trimmed to a short contract (deferring detail to `docker-expert`/`jenkins-pipeline`), and two new sections — "Test quality over test presence" and "Closing a coverage gap" — make real coverage improvement (tests that exercise actual behavior, not ones that just move the number) a first-class, ongoing part of the skill rather than an afterthought. Deleted `testing/references/docker-test-parity.md`, now fully redundant.
- `references/diagnosing-failed-builds.md` now opens with a section on EEA's org-wide GitHub↔Jenkins integration: every repo's commits/PR events/tags auto-trigger the corresponding Jenkins build with no manual step, confirmed live — so a missing build shortly after a push means "not built yet," not "something is broken."
- The "Mandatory pipeline contract"'s Docker Hub release stage now has explicit guidance not to silently invent a release Dockerfile for a repository with no real deployment story (no existing Dockerfile, not a service meant to run anywhere) — ask first, the same way multi-arch and Helm/Fleet release already are.
- The `GitHubEEA` SonarQube PR-decoration binding `curl` call now checks the HTTP response and echoes a visible warning on failure (e.g. a 403 from insufficient token permissions) instead of failing silently with no trace in the build log.
- Consolidated the five separate `2026-07-29` changelog entries below into one.

### Why
Addresses every finding from the `eea/eea.agent.skills#1` PR review (one CI-blocking, several real cross-skill contradictions and metadata inconsistencies), and reframes the `testing` skill around its actual purpose going forward: Jenkins and SonarQube gate on test presence and a coverage percentage, not on whether a test is meaningful, so closing the real coverage gap (currently ~60%, target 80% on at least one active project) needs its own guidance rather than being folded into command-parity mechanics. The additional fixes came from actually re-running the modified skill against a real repo on two fresh branches with two context-isolated agents (one reusing an existing Jenkinsfile as a starting point, one forbidden from looking at any other branch) and watching the real Jenkins builds that followed — both node-dependent Maven plugin resolution and the `environment{}`/`script{}` precedence pitfall are runtime-only failure modes that no amount of local preflight or code review would have caught.

---

## 2026-07-29 — Add Jenkins Pipeline, Code Quality, Quality Fixes, and Testing Skills

### Added
- New `jenkins-pipeline` skill (`src/skills/jenkins-pipeline/`):
  - `SKILL.md` with Jenkins declarative pipeline guidance for EEA projects
  - `EEA-OVERRIDES.md` with the required EEA Jenkinsfile outer structure and stage contract
  - `references/eea-jenkinsfile-template.md` with a full stage-by-stage Jenkinsfile example
  - `references/dockerfile-test-template.md` with the expected `Dockerfile.test` artifact contract
  - `metadata.json` with skill index data
- New `code-quality` skill (`src/skills/code-quality/`):
  - `SKILL.md` with repository-first code quality guidance for AI-generated and legacy code
  - `EEA-OVERRIDES.md` with EEA policy for Jenkins-aligned auto-fix and strict verification
  - `references/jenkins-quality-gates.md` describing the recommended split between auto-fix, lint, typing, and tests
  - `metadata.json` with skill index data
- New `quality-fixes` skill (`src/skills/quality-fixes/`):
  - `SKILL.md` with diagnose → fix → rerun guidance for failing lint, typing, tests, Docker, and Jenkins gates
  - `EEA-OVERRIDES.md` with EEA routing from Jenkins/code-quality preflight failures
  - `references/fix-loop.md` describing the verification-preserving repair loop
  - `metadata.json` with skill index data
- New `testing` skill (`src/skills/testing/`):
  - `SKILL.md` with Docker-based parity guidance between developer test commands and Jenkins stages
  - `EEA-OVERRIDES.md` with EEA policy for developer-reproducible local testing
  - `references/docker-test-parity.md` describing the Docker parity model
  - `metadata.json` with skill index data
- `catalog.yaml` entries for `jenkins-pipeline`, `code-quality`, `quality-fixes`, and `testing`

### Changed
- `src/skills/docker-expert/EEA-OVERRIDES.md`:
  - added `Dockerfile.test` guidance for Jenkins-driven linting, unit tests, coverage export, and integration helpers
  - documents practical `Dockerfile.test` guidance for mixed Python + Node repositories
  - warns against copying `node` / `npm` binaries across images
  - warns to verify the real dependency source when requirements and lockfiles disagree
  - documents `--legacy-peer-deps` as a repository-specific fallback, not a universal default
- `src/skills/jenkins-pipeline/SKILL.md`:
  - requires using the `code-quality` skill mindset when designing pipeline quality stages
  - adds guidance for a dedicated `Auto-fix code style` stage
  - expands stage blueprint to separate auto-fix from strict linting
  - documents workspace propagation for container-based auto-fix steps
  - requires a preflight run of the repository's current quality/test commands before finalizing a Jenkinsfile
  - instructs the agent to surface expected failures and ask whether to repair them first using `quality-fixes`
- `src/skills/jenkins-pipeline/EEA-OVERRIDES.md`:
  - recommends an `Auto-fix code style` stage in EEA Jenkins pipelines
  - adds cross-skill routing to `code-quality` and `quality-fixes`
- `src/skills/jenkins-pipeline/references/eea-jenkinsfile-template.md`:
  - includes an `Auto-fix code style` stage ahead of strict linting
  - includes branch-build auto-commit/push behavior for safe deterministic rewrites

### Why
Provides a reusable set of EEA skills for generating Jenkinsfiles that follow the existing EEA structure, run tests inside Docker, publish JUnit and LCOV artifacts, scan with SonarQube and Trivy, and release images to Docker Hub; for generating and repairing code against those same checks; and for keeping developer-local test commands identical to what Jenkins runs, without relying on Make-only workflows or Jenkins log spelunking.

---

## 2026-05-21 — Integrate skills-ref Validation

### Added
- `scripts/validate-skills.sh` — validates all `src/skills/*` and `skills/*` against the official Agent Skills specification using `agentskills` (from `skills-ref` PyPI package)
- CI workflow step: `pip install skills-ref` + `agentskills validate` for every source and merged skill
- `verify.sh` integration: new `check_skills_agentskills()` reports per-skill spec compliance

### Changed
- `scripts/build.sh`: moved auto-generated HTML comments (`<!-- Merged Build ... -->`) to **after** the YAML frontmatter block so merged `skills/*/SKILL.md` files start with `---` and pass spec validation
- Rebuilt all 7 skills with corrected comment ordering
- `README.md`: added `eea-design-system` to skills table, documented `validate-skills.sh`, updated CI description
- `docs/BOOTSTRAP.md`: added `agentskills validate` / `skills-ref` validation section

### Why
The Agent Skills specification requires `---` as the first line of `SKILL.md`. Our merged output previously failed `agentskills validate` due to comment lines preceding frontmatter. This ensures all distributed skills are spec-compliant.

---

## 2026-05-21 — Add EEA Design System Skill

### Added
- New `eea-design-system` skill (`src/skills/eea-design-system/`):
  - `SKILL.md` with agentskills.io-compliant YAML frontmatter
  - `references/DESIGN.md` — canonical design tokens (colors, typography, spacing, components)
  - `EEA-OVERRIDES.md` — EEA logo legal rules, WIPO restrictions, corporate identity manual links
  - `metadata.json` with skill index data
  - `assets/` — 12 official logos (EEA + BISE, FISE, WISE Freshwater, WISE Marine, color + white variants)

### Changed
- `scripts/build.sh`: copy `DESIGN.md` and `assets/` to `skills/` output during build
- Normalize YAML frontmatter across all 7 skills:
  - `name` now matches directory name (fixed 4 skills with `vercel-` prefix)
  - Moved non-spec top-level keys (`category`, `risk`, `upstream`, etc.) into `metadata` block
- Updated 4 existing skills to remove "(future)" label from `eea-design-system` handoff references

### Why
Makes the EEA Design System discoverable and loadable as a reusable agent skill. Keeps DESIGN.md as a peer reference document per agentskills.io spec, rather than inlining tokens into SKILL.md.

---

## 2026-05-17 — Move Agent Profiles to docs/agent-profiles/

### Changed
- Move per-tool agent wiring docs from `agents/` to `docs/agent-profiles/`:
  - `agents/opencode.md` → `docs/agent-profiles/opencode.md`
  - `agents/claudecode.md` → `docs/agent-profiles/claudecode.md`
  - `agents/hermes.md` → `docs/agent-profiles/hermes.md`
  - `agents/gemini.md` → `docs/agent-profiles/gemini.md`
  - `agents/pi.md` → `docs/agent-profiles/pi.md`
  - `agents/README.md` → `docs/agent-profiles/README.md`
- Create new `agents/README.md` explaining the directory is reserved for agentget-compatible sub-agent prompts (`*.agent.md`)
- Update all cross-references in `README.md`, `AGENTS.md`, `docs/BOOTSTRAP.md`, `CONTRIBUTING.md`, `scripts/install.sh`, and `docs/decisions/installer-backup-merge.md`

### Why
The `agents/` directory name is semantically reserved in the [agentget](https://github.com/joeyism/agentget) framework for sub-agent system prompts (`*.agent.md`), not for tool wiring instructions. This change keeps the repository aligned with agentget conventions while preserving all documentation.

---

## 2026-05-16 — Safe Installer: Backup and Merge Existing Configs

### Changed
- `scripts/install.sh`:
  - Back up existing agent configs before modifying (`--no-backup` to skip)
  - Detect and merge into existing `opencode.json` and `opencode.jsonc` instead of overwriting
  - Use robust Python-based JSONC parser (handles comments and trailing commas without destroying `//` in URLs)
  - For Claude/Hermes/Pi/Gemini: append EEA harness reference to end of existing file instead of replacing
  - Detect if symlink already points to EEA harness and skip gracefully
  - Back up existing skills before `--force` overwrite

### Documentation
- `docs/BOOTSTRAP.md`: Add "Already Have a Global Config?" section covering backup behavior, restore commands, and why merge vs. overwrite
- `agents/opencode.md`: Add "Option E: Merge with an Existing Global Config" with before/after JSON examples and restore instructions
- `agents/claudecode.md`: Add "Option A½: Preserve an Existing CLAUDE.md" with manual steps and restore instructions

### Why
Prevents accidental loss of personal agent instructions (e.g., graphify config, team rules) when installing the EEA harness.

---

## 2026-05-16 — Harness Slimming and Rule Extraction

### Changed
- Slim down `harness/EEA-HARNESS.md`:
  - Use explicit file paths for rule references (`rules/eeaprohibitions.rules.md`, `rules/eeamandatory.rules.md`)
  - Remove verbose CHANGELOG Best Practice section from harness (keep it slim)
- Extract detailed CHANGELOG guidance into standalone `rules/changelog.process.md`
  - Remove repo-specific CI enforcement reference (not org-wide applicable)
  - Remove CalVer format mandate — agents must follow each project's existing convention
- Update `rules/eeamandatory.rules.md`:
  - MAND-09 cross-reference now points to `rules/changelog.process.md`
  - Add MAND-10: review `README.md` and other key docs before committing

### Documentation
- Update `README.md` repo structure diagram to include `changelog.process.md`
- Update `rules/README.md` to list `changelog.process.md` in Available Rule Sets

---

## 2026-05-16 — Installer Consolidation

### Changed
- Consolidate 8 installation methods into 3 canonical methods:
  - **A. Automated Global Install** — `agentget install` or `curl | bash`
  - **B. Manual Global Install** — clone + symlink per agent
  - **C. Project-Embedded** — remote URL, git submodule, or inline `AGENTS.md`
- Fix 7 mismatches between `plugins/agentget.json` and `scripts/install.sh`:
  - Add Pi harness symlink (`~/.pi/agent/AGENTS.md`)
  - Add Gemini harness symlink (`~/.gemini/GEMINI.md`)
  - Add `~/.agents/skills/` to `install_skills()`
  - Standardize agent profile name: `claudecode` → `claude`
  - Add `rules.installPaths` to `agentget.json`
  - `install_opencode()` now copies canonical template file (was hardcoded JSON)
  - Make skills/rules installation unconditional (not gated by agent detection)
- Discontinue GitHub Releases distribution. Skills are now always installed from source via the install script or agentget.

### Documentation
- Rewrite `docs/BOOTSTRAP.md` with 3-method structure and per-agent wiring
- Update `README.md` Quick Start and Distribution Options
- Add cross-reference notes to all `agents/*.md` profiles
- Add `.planning/codebase/INSTALL-CONFIG-CONCERNS-2026-05.md` detailed analysis
- Add installer alignment section to `.planning/codebase/CONCERNS.md`

---

## 2026-05-04 — v1.3.0 (Last Semver Release)

### Changed
- *(Content from original v1.3.0 release notes)*

---

## 2026-04-30 — Restructure for agentget

### Changed
- Restructure repository for [agentget](https://github.com/joeyism/agentget) compatibility
- Move source skills from `skills/` to `src/skills/`
- Move merged distributable skills from `dist/skills/` to `skills/`
- Remove `dist/` directory entirely
- Update all CI workflows, build scripts, and documentation to reflect new paths
- Add scaffolding directories for agentget content types: `agents/`, `instructions/`, `rules/`, `plugins/`

### Documentation
- Update `README.md`, `CONTRIBUTING.md`, and `docs/SYNC-STRATEGY.md` with new paths
- ~~Add `docs/RESTRUCTURE-PLAN.md` tracking the restructure~~ (removed 2026-05-17)
- Add README files to all new and renamed directories

---

## 2026-04-21 — Commit dist/ directory

### Changed
- Commit `dist/` directory to repository for immediate user access
- Simplify installation instructions — clone and copy, no build required
- Add CI safeguard `build-sync` to ensure `dist/` stays in sync with source

### Documentation
- Update `README.md` with simplified clone-and-copy instructions
- Update `docs/SYNC-STRATEGY.md` with committed `dist/` approach
- Update `CONTRIBUTING.md` with rebuild-and-commit workflow

---

## 2026-04-21 — Initial Setup

### Added
- Initial repository setup with full structure
- `docker-expert` skill with two-file overlay pattern
- `catalog.yaml` machine-readable skill index
- `shared/` directory with EEA design foundations and style guide
- `workflows/` directory with multi-skill orchestration recipes
- `.github/workflows/validate-skills.yml` CI validation
- `CONTRIBUTING.md` with sync and override conventions
- `README.md` with overview and quick start

### Documentation
- `EEA-style-guide.md` placeholder
- `design-foundations.md` placeholder
- `data-schemas.md` placeholder
- `data-report.md` workflow placeholder

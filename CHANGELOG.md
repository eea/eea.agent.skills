# Changelog

All notable changes to this repository are documented here.

This project uses **date-based versioning** (YYYY-MM-DD) rather than semantic versioning. Entries are ordered newest-first.

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
- Add `docs/RESTRUCTURE-PLAN.md` tracking the restructure
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

# Technology Stack

**Analysis Date:** 2026-05-16

## Languages

**Primary:**
- **Markdown** — Skill definitions, documentation, overrides, and rules (`src/skills/**/*.md`, `docs/*.md`, `shared/*.md`, `rules/*.md`, `harness/EEA-HARNESS.md`)
- **YAML** — Machine-readable skill index (`catalog.yaml`) and CI/CD configuration (`.github/workflows/*.yml`)
- **JSON** — Skill metadata (`src/skills/*/metadata.json`), install manifest (`plugins/agentget.json`), opencode config templates (`docs/opencode-examples/*.json`), graphify cache manifest (`graphify-out/manifest.json`)
- **Bash** — Build automation (`scripts/build.sh`) and installation orchestration (`scripts/install.sh`)

**Secondary:**
- **TOML** — Skill trigger definitions (`src/skills/docker-expert/references/triggers.toml`)
- **CSS** — Reference recipes embedded in skill content (`src/skills/react-view-transitions/references/css-recipes.md`)

## Runtime

**Environment:**
- Not applicable. This is a static content repository (skill definitions and documentation). No application server or runtime environment is required for the repository itself.
- Skills are consumed by external agent runtimes (Claude Code, OpenCode, Cursor, GitHub Copilot).

**Package Manager:**
- None. No `package.json`, `requirements.txt`, `Cargo.toml`, `go.mod`, `pyproject.toml`, or equivalent manifest exists.
- No lockfile present.

## Frameworks

**Core:**
- Not applicable. The repository contains instructional Markdown content rather than executable application code.

**Testing:**
- Not applicable. Validation is performed via shell scripts in CI.

**Build/Dev:**
- **Bash 4+** (`scripts/build.sh`) — Merges upstream `SKILL.md` with `EEA-OVERRIDES.md` into distributable `skills/<name>/SKILL.md`
- **Standard POSIX utilities** — `cat`, `cp`, `mkdir`, `wc`, `grep`, `curl`, `jq` (used in CI and build scripts)
- **Graphify** (local dev tool) — Python-based knowledge graph generator used to analyze repository content; installed via `pipx` (`graphify-out/`)

## Key Dependencies

**Critical:**
- None (static content repository)

**Infrastructure / CI-Only:**
- **Python 3** with **PyYAML** — Used in GitHub Actions to validate `catalog.yaml` schema (`.github/workflows/validate-skills.yml:43`, `.github/workflows/validate-harness.yml:79`)
- **jq** — Used in GitHub Actions to parse GitHub API JSON responses for upstream sync checks (`.github/workflows/validate-skills.yml:98`)
- **curl** — Used to fetch upstream commit SHAs from GitHub API and raw content during manual sync workflows (`docs/SYNC-STRATEGY.md:108`, `CONTRIBUTING.md:19`)

## Configuration

**Environment:**
- No environment variables or `.env` files are required for the repository build process.
- GitHub Actions workflows rely on implicit `GITHUB_TOKEN` for repository checkout and CI operations.

**Build:**
- `catalog.yaml` — Skill registry and metadata index
- `scripts/build.sh` — Build orchestration (merges upstream + EEA overrides)
- `scripts/install.sh` — One-shot harness installer for local developer machines
- `.github/workflows/validate-skills.yml` — CI validation pipeline (skill structure, token counts, catalog schema, build sync)
- `.github/workflows/validate-harness.yml` — CI harness validation pipeline (file existence, markdown structure, agent profiles, secret scan)
- `.github/workflows/check-changelog.yml` — CI changelog enforcement on PRs
- `.gitignore` — Excludes `graphify-out/cache/`, Python virtualenvs, OS files, and secrets patterns

## Platform Requirements

**Development:**
- Git
- Bash 4+
- Standard POSIX toolchain (`wc`, `grep`, `cat`, `cp`, `mkdir`)
- Optional: Python 3 + PyYAML for local `catalog.yaml` validation
- Optional: `graphify` (via `pipx`) for knowledge graph generation

**Production:**
- GitHub (hosting and distribution)
- Skills are consumed by end-user agent frameworks (OpenCode, Claude Code, Cursor, Copilot) — these frameworks load Markdown content on-demand and do not execute code from this repository.

---

*Stack analysis: 2026-05-16*

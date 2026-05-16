# Coding Conventions

**Analysis Date:** 2026-05-16

## Naming Patterns

**Files:**
- Top-level markdown files use UPPERCASE: `SKILL.md`, `EEA-OVERRIDES.md`, `README.md`, `AGENTS.md`
- Rule files follow `{section-prefix}-{rule-name}.md`: `async-api-routes.md`, `rendering-hydration-no-flicker.md`
- Metadata files: `metadata.json`
- Workflow files: `validate-skills.yml`, `validate-harness.yml`, `check-changelog.yml`
- Template files prefixed with underscore: `_template.md`
- Shell scripts: `build.sh`, `install.sh`
- Process rule files: `changelog.process.md`

**Directories:**
- Source skills: `src/skills/<skill-name>/`
- Distributable skills: `skills/<skill-name>/`
- References subdirectory: `references/`
- Rules subdirectory: `rules/`
- Scaffold directories for agentget: `agents/`, `instructions/`, `rules/`, `plugins/`, `workflows/`

**Skill IDs:**
- Use kebab-case in `catalog.yaml`: `docker-expert`, `react-best-practices`, `composition-patterns`

## Code Style

**Formatting:**
- No automated formatter detected (no `.prettierrc`, `.editorconfig`, or `biome.json`)
- Markdown prose uses line-wrapping at ~100 characters (observed in `shared/eea-style-guide.md`)
- YAML uses 2-space indentation (`catalog.yaml`, `.github/workflows/`)
- Shell scripts use 2-space indentation for `case` and nested blocks

**Linting:**
- No ESLint, Biome, or similar linter configured
- Validation is performed via GitHub Actions shell scripts (`.github/workflows/validate-skills.yml`, `.github/workflows/validate-harness.yml`)
- Token count and structural checks serve as the primary linting mechanism

## Import Organization

**Not applicable** — this repository contains no JavaScript/TypeScript/Python source code with imports. It is a documentation and skill-definition repository.

## Markdown Conventions

**Frontmatter (Rule Files):**
```yaml
---
title: Rule Title Here
impact: MEDIUM
impactDescription: Optional description of impact (e.g., "20-50% improvement")
tags: tag1, tag2
---
```

**Frontmatter (SKILL.md):**
```yaml
---
name: docker-expert
description: "..."
category: devops
risk: unknown
source: community
date_added: "2026-02-27"
upstream:
  source: sickn33/antigravity-awesome-skills
  url: https://github.com/sickn33/antigravity-awesome-skills
eea_override: EEA-OVERRIDES.md
---
```

**Rule Structure:**
- H2 heading matching the title
- `**Impact: LEVEL (description)**` immediately after heading
- `**Incorrect (description):**` followed by code block
- `**Correct (description):**` followed by code block
- `Reference: [text](url)` at end

**EEA-OVERRIDES.md Requirements:**
- Version tag at top: `<!-- EEA-Overrides-Version: 1.0 -->`
- Optional sync marker: `<!-- Last-Sync: 2026-04-21 -->`
- Section header: `## EEA-Specific Patterns`
- Only additive — never modify upstream patterns
- Version-stamped: `<!-- EEA-Overrides: v1.0 -->` at top (per `CONTRIBUTING.md`)

**Process Rule Files:**
- `rules/changelog.process.md` follows same header comment pattern as prohibition/mandatory rules
- Header comments include: `EEA-Rule-Version`, `Type`, `Scope`, `Applies to`

## Shell Script Conventions

**Build Script (`scripts/build.sh`):**
- `#!/bin/bash` shebang
- `set -euo pipefail` for strict mode
- `local` keyword for function variables
- Double-quote all variable expansions
- Error messages prefixed with `ERROR:`
- Success messages prefixed with `✓`

**Install Script (`scripts/install.sh`):**
- `#!/usr/bin/env bash` shebang
- `set -euo pipefail` for strict mode
- Color constants: `RED`, `GREEN`, `YELLOW`, `BLUE`, `NC`
- Helper functions: `log_info()`, `log_success()`, `log_warn()`, `log_error()`
- Uses `shift` and `shift 2` for argument parsing
- Creates symlinks with `ln -sf` for agent profiles
- Copies files with `cp -r` for skills installation

## Error Handling

**In Build Scripts:**
- Explicit exit codes: `exit 1` on failure
- Directory existence checks before operations
- File existence checks before reading

**In CI Workflows:**
- Step-level failure propagation via `exit 1`
- Warnings emitted to stdout for non-fatal issues
- Git status checks to detect drift (`git status --porcelain`)
- Error counters: `errors=$((errors + 1))` pattern in `validate-harness.yml`

**In Install Script:**
- Checks for existing files before overwrite (gated by `--force` flag)
- Agent detection via `command -v` and directory existence checks
- Graceful degradation when agents are not detected

## Logging / Output Conventions

**Build Output:**
- `echo "✓ Built: $skill_name -> $dist_skill_dir/SKILL.md"`
- `echo "Build complete. Merged skills available in: $DIST_DIR"`

**CI Output:**
- `echo "WARNING: ..."` for non-blocking issues
- `echo "ERROR: ..."` for blocking issues
- `echo "✓ ... passed"` for successful checks
- `echo "========================================"` for section separators

**Install Output:**
- `log_info "Installing EEA AI Harness..."`
- `log_success "EEA AI Harness installation complete!"`
- Structured next-steps block at end of script

## Comments

**Markdown Comments:**
- HTML comments for metadata: `<!-- EEA-Overrides-Version: 1.0 -->`
- HTML comments for build markers: `<!-- BEGIN EEA-OVERRIDES -->`
- HTML comments for generated warnings: `<!-- Merged Build: upstream SKILL.md + EEA-OVERRIDES.md -->`
- HTML comments for rule metadata: `<!-- EEA-Rule-Version: 1.0 -->`

**Shell Comments:**
- Function-level purpose comments
- Inline comments for non-obvious logic
- Section separators with `echo ""` for readability

## Commit Conventions

**Format:** Conventional Commits style (observed in `CHANGELOG.md` and `AGENTS.md`)
- `skill:` — Adding or updating a skill
- `harness:` — Changes to `harness/EEA-HARNESS.md` or org-wide rules
- `docs:` — Documentation updates
- `build:` — Build script or CI changes
- `chore:` — Maintenance, dependencies, formatting
- `feat:` — New feature (observed in `CONTRIBUTING.md` examples)

**Required Actions After Source Changes:**
1. Edit files in `src/skills/`
2. Run `./scripts/build.sh`
3. Stage both `src/skills/` and `skills/`
4. Commit together

**Changelog Requirements:**
- Date-based versioning: `YYYY-MM-DD — Brief description`
- Categories: `Added`, `Changed`, `Fixed`, `Removed`, `Documentation`
- PRs that change code files must update `CHANGELOG.md` (enforced by `.github/workflows/check-changelog.yml`)
- Skip allowed for docs-only, test-only, or formatting changes

## Catalog Schema Conventions

**YAML structure (`catalog.yaml`):**
```yaml
skills:
  - id: <kebab-case-id>
    name: Human Readable Name
    description: One-line description
    category: devops|frontend|backend|mobile|design|security|...
    upstream:
      source: <org/repo>
      path: skills/<skill>
      url: https://github.com/<org>/<repo>
    triggers:
      - <keyword1>
      - <keyword2>
    version: "1.0"
    eeaspecific: true|false
    added_date: "YYYY-MM-DD"
    notes: Free-form notes
```

## File Size Limits

**SKILL.md Token Budget:**
- Maximum ~500 lines / 5,000 tokens per merged skill
- CI warns if `wc -c` exceeds 5,500 bytes
- Designed for agent context window limits

## Cross-Skill Consistency

**Trigger Keywords:**
- Each skill declares activation triggers in `catalog.yaml`
- Prevents skill conflicts by domain

**Shared Resources:**
- `shared/eea-style-guide.md` — brand/tone for LLM outputs
- `shared/design-foundations.md` — design tokens
- `shared/data-schemas.md` — common data structures
- `shared/glossary.md` — EEA acronyms and terminology

**Handoff Guidelines:**
- Each `EEA-OVERRIDES.md` includes "Handoff to Other EEA Skills" section
- Explicit rules for when to invoke another skill

---

*Convention analysis: 2026-05-16*

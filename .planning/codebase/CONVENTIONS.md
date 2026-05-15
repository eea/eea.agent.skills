# Coding Conventions

**Analysis Date:** 2026-05-14

## Naming Patterns

**Files:**
- Top-level markdown files use UPPERCASE: `SKILL.md`, `EEA-OVERRIDES.md`, `README.md`, `AGENTS.md`
- Rule files follow `{section-prefix}-{rule-name}.md`: `async-api-routes.md`, `rendering-hydration-no-flicker.md`
- Metadata files: `metadata.json`
- Workflow files: `validate-skills.yml`, `release.yml`
- Template files prefixed with underscore: `_template.md`, `_sections.md`
- Shell scripts: `build.sh`

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

**Linting:**
- No ESLint, Biome, or similar linter configured
- Validation is performed via GitHub Actions shell scripts (`.github/workflows/validate-skills.yml`)
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

## Shell Script Conventions

**Build Script (`scripts/build.sh`):**
- `#!/bin/bash` shebang
- `set -euo pipefail` for strict mode
- `local` keyword for function variables
- Double-quote all variable expansions
- Error messages prefixed with `ERROR:`
- Success messages prefixed with `✓`

## Error Handling

**In Build Scripts:**
- Explicit exit codes: `exit 1` on failure
- Directory existence checks before operations
- File existence checks before reading

**In CI Workflows:**
- Step-level failure propagation via `exit 1`
- Warnings emitted to stdout for non-fatal issues
- Git status checks to detect drift (`git status --porcelain`)

## Logging / Output Conventions

**Build Output:**
- `echo "✓ Built: $skill_name -> $dist_skill_dir/SKILL.md"`
- `echo "Build complete. Merged skills available in: $DIST_DIR"`

**CI Output:**
- `echo "WARNING: ..."` for non-blocking issues
- `echo "ERROR: ..."` for blocking issues
- `echo "✓ ... passed"` for successful checks

## Comments

**Markdown Comments:**
- HTML comments for metadata: `<!-- EEA-Overrides-Version: 1.0 -->`
- HTML comments for build markers: `<!-- BEGIN EEA-OVERRIDES -->`
- HTML comments for generated warnings: `<!-- Merged Build: upstream SKILL.md + EEA-OVERRIDES.md -->`

**Shell Comments:**
- Function-level purpose comments
- Inline comments for non-obvious logic

## Commit Conventions

**Format:** Conventional Commits style (observed in `CHANGELOG.md`)
- `feat: update docker-expert with EEA proxy configuration`
- `Changed`, `Added`, `Documentation` categories in changelog

**Required Actions After Source Changes:**
1. Edit files in `src/skills/`
2. Run `./scripts/build.sh`
3. Stage both `src/skills/` and `skills/`
4. Commit together

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

**Handoff Guidelines:**
- Each `EEA-OVERRIDES.md` includes "Handoff to Other EEA Skills" section
- Explicit rules for when to invoke another skill

---

*Convention analysis: 2026-05-14*

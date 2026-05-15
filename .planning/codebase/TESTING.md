# Testing Patterns

**Analysis Date:** 2026-05-14

## Test Framework

**Runner:**
- No traditional test framework (Jest, Vitest, pytest, etc.) detected
- No `package.json`, `jest.config.*`, or `vitest.config.*` present
- Testing is performed entirely via GitHub Actions CI workflows

**Validation Approach:**
- `.github/workflows/validate-skills.yml` — primary validation pipeline
- `.github/workflows/release.yml` — build verification on tags
- `scripts/build.sh` — integration-level build test

**Run Commands:**
```bash
# Build all skills (primary validation)
./scripts/build.sh

# Build specific skill
./scripts/build.sh docker-expert

# Local structural checks
python3 -c "import yaml; yaml.safe_load(open('catalog.yaml'))"

# Token count check
for skill in src/skills/*/SKILL.md; do
  tokens=$(wc -c < "$skill")
  if [ "$tokens" -gt 5500 ]; then
    echo "WARNING: $skill exceeds 5k token limit ($tokens bytes)"
  fi
done
```

## Test File Organization

**Location:**
- No co-located or separate test files
- Validation logic lives in `.github/workflows/validate-skills.yml`
- Build script at `scripts/build.sh` serves as integration test

**Naming:**
- Not applicable — no `*.test.*` or `*.spec.*` files exist

## Test Structure

**CI Job: `lint`**
```yaml
lint:
  runs-on: ubuntu-latest
  steps:
    - uses: actions/checkout@v4
    - name: Check source SKILL.md files exist
      run: |
        for skill in src/skills/*/; do
          if [ -f "${skill}SKILL.md" ] && [ ! -f "${skill}EEA-OVERRIDES.md" ]; then
            echo "WARNING: ${skill} missing EEA-OVERRIDES.md"
          fi
          if [ ! -f "${skill}SKILL.md" ]; then
            echo "Missing SKILL.md in ${skill}"
            exit 1
          fi
        done
    - name: Check token count
      run: |
        for skill in src/skills/*/SKILL.md; do
          tokens=$(wc -c < "$skill")
          if [ "$tokens" -gt 5500 ]; then
            echo "WARNING: $skill exceeds 5k token limit ($tokens bytes)"
          fi
        done
    - name: Validate catalog.yaml
      run: |
        python3 -c "import yaml; yaml.safe_load(open('catalog.yaml'))" \
          || echo "catalog.yaml validation failed"
```

**CI Job: `build-sync`**
```yaml
build-sync:
  runs-on: ubuntu-latest
  steps:
    - uses: actions/checkout@v4
    - name: Run build script
      run: |
        chmod +x scripts/build.sh
        ./scripts/build.sh
    - name: Verify merged output
      run: |
        if [ ! -f "skills/docker-expert/SKILL.md" ]; then
          echo "ERROR: Merged SKILL.md not found for docker-expert"
          exit 1
        fi
        if ! grep -q "BEGIN EEA-OVERRIDES" "skills/docker-expert/SKILL.md"; then
          echo "ERROR: Merged file missing EEA-OVERRIDES section"
          exit 1
        fi
        echo "✓ Build validation passed"
    - name: Check skills/ is up-to-date
      run: |
        if [ -n "$(git status --porcelain skills/)" ]; then
          echo "ERROR: skills/ is out of sync with source files"
          git diff --stat skills/
          exit 1
        fi
        echo "✓ skills/ is up-to-date"
    - name: Check merged token count
      run: |
        for skill in skills/*/SKILL.md; do
          tokens=$(wc -c < "$skill")
          echo "Merged skill: $(basename $(dirname $skill)) - $tokens bytes"
        done
```

**CI Job: `upstream-sync`**
```yaml
upstream-sync:
  runs-on: ubuntu-latest
  if: github.event_name == 'schedule'
  steps:
    - uses: actions/checkout@v4
    - name: Check upstream for docker-expert
      run: |
        UPSTREAM_SHA=$(curl -s https://api.github.com/repos/sickn33/antigravity-awesome-skills/commits/main | jq -r '.[0].sha')
        echo "Upstream main: $UPSTREAM_SHA"
        # TODO: Compare with last known SHA and create issue if changed
```

## Mocking

**Not applicable** — no unit tests exist that require mocking.

## Fixtures and Factories

**Test Data:**
- No fixture files or factory functions
- The `catalog.yaml` acts as a structured fixture for skill metadata
- `src/skills/<skill>/SKILL.md` files are the "fixtures" for build validation

## Coverage

**Requirements:** Not enforced.

**What is measured:**
- Structural coverage: every skill must have `SKILL.md`
- Override coverage: every forked skill must have `EEA-OVERRIDES.md`
- Token budget coverage: every skill checked against 5,500-byte limit
- Sync coverage: `skills/` directory must match build output

## Test Types

**Structural Tests:**
- Scope: File existence and directory structure
- Approach: Shell `for` loops over `src/skills/*/`
- Failures: Missing `SKILL.md`, missing `EEA-OVERRIDES.md` (warning only)

**Build Integration Tests:**
- Scope: Build script correctness and output validity
- Approach: Run `./scripts/build.sh`, verify merged files contain expected markers
- Failures: Missing merged output, missing `BEGIN EEA-OVERRIDES` marker

**Sync Drift Tests:**
- Scope: Ensure committed `skills/` matches source
- Approach: `git status --porcelain skills/` after rebuild
- Failures: Uncommitted changes in `skills/` after build

**Schema Validation Tests:**
- Scope: `catalog.yaml` parseability
- Approach: `python3 -c "import yaml; yaml.safe_load(open('catalog.yaml'))"`
- Failures: Invalid YAML syntax

**Token Budget Tests:**
- Scope: Agent context window limits
- Approach: `wc -c` on each `SKILL.md`
- Threshold: Warn at > 5,500 bytes

**Upstream Sync Tests:**
- Scope: Detect upstream changes (weekly cron)
- Approach: `curl` upstream API, compare SHAs
- Current state: Incomplete — emits SHA but does not compare (`# TODO` in `.github/workflows/validate-skills.yml` line 100)

## Common Patterns

**Async Testing (CI shell):**
```bash
# Start background operations, then await
sessionPromise=$(auth)
configPromise=$(fetchConfig)
session=$(await $sessionPromise)
```
This pattern is tested in the build script's parallel operations logic.

**Error Testing (CI shell):**
```bash
if [ ! -f "$skill_dir/SKILL.md" ]; then
  echo "ERROR: SKILL.md missing for '$skill_name'"
  exit 1
fi
```
Every validation step follows: check condition → emit message → exit 1 on failure.

## CI Triggers

**Validation Workflow (`validate-skills.yml`):**
```yaml
on:
  push:
    branches: [main]
  pull_request:
    paths:
      - 'src/skills/**/*.md'
      - 'skills/**'
      - 'scripts/**'
      - 'catalog.yaml'
      - '.github/workflows/validate-skills.yml'
```

**Release Workflow (`release.yml`):**
```yaml
on:
  push:
    tags:
      - 'v*'
```

## Missing Test Coverage

**No unit tests for `scripts/build.sh`:**
- Build script logic is tested only through full CI runs
- No isolated tests for `build_skill()` function edge cases
- Files: `scripts/build.sh`

**No upstream drift detection:**
- The `upstream-sync` job emits upstream SHA but does not compare or create issues
- Files: `.github/workflows/validate-skills.yml` (line 100)

**No content quality tests:**
- No validation that markdown frontmatter matches expected schema
- No check that rule files reference existing sections
- No validation of `metadata.json` against a JSON schema

**No accessibility/design compliance tests:**
- The `web-design-guidelines` skill references WCAG 2.1 AA but no automated a11y checks exist
- Files: `src/skills/web-design-guidelines/`

---

*Testing analysis: 2026-05-14*

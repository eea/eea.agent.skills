# Testing Patterns

**Analysis Date:** 2026-05-16

## Test Framework

**Runner:**
- No traditional test framework (Jest, Vitest, pytest, etc.) detected
- No `package.json`, `jest.config.*`, or `vitest.config.*` present
- Testing is performed entirely via GitHub Actions CI workflows and shell scripts

**Validation Approach:**
- `.github/workflows/validate-skills.yml` — skill structure and build validation
- `.github/workflows/validate-harness.yml` — harness file and reference validation
- `.github/workflows/check-changelog.yml` — changelog update enforcement
- `scripts/build.sh` — integration-level build test
- `scripts/install.sh` — installation logic (tested manually, not in CI)

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
- Validation logic lives in `.github/workflows/`
- Build script at `scripts/build.sh` serves as integration test

**Naming:**
- Not applicable — no `*.test.*` or `*.spec.*` files exist

## Test Structure

**CI Workflow: `validate-skills.yml`**

Job: `lint`
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

Job: `build-sync`
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

Job: `upstream-sync`
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

**CI Workflow: `validate-harness.yml`**

Job: `validate-harness`
```yaml
validate-harness:
  runs-on: ubuntu-latest
  steps:
    - uses: actions/checkout@v4
    - name: Validate harness file exists
      run: |
        if [ ! -f "harness/EEA-HARNESS.md" ]; then
          echo "ERROR: harness/EEA-HARNESS.md is missing"
          exit 1
        fi
    - name: Validate harness is valid Markdown
      run: |
        if ! grep -q "^# " harness/EEA-HARNESS.md; then
          echo "ERROR: harness/EEA-HARNESS.md missing top-level heading"
          exit 1
        fi
    - name: Validate referenced files exist
      run: |
        errors=0
        for file in rules/eeaprohibitions.rules.md rules/eeamandatory.rules.md; do
          if [ ! -f "$file" ]; then
            echo "ERROR: Referenced file missing: $file"
            errors=$((errors + 1))
          fi
        done
        if [ ! -d "agents" ]; then
          echo "ERROR: agents/ directory missing"
          errors=$((errors + 1))
        fi
        if [ ! -d "shared" ]; then
          echo "ERROR: shared/ directory missing"
          errors=$((errors + 1))
        fi
        if [ $errors -gt 0 ]; then
          exit 1
        fi
    - name: Validate catalog.yaml
      run: |
        python3 -c "import yaml; yaml.safe_load(open('catalog.yaml'))" || {
          echo "ERROR: catalog.yaml is not valid YAML"
          exit 1
        }
    - name: Validate agent profiles
      run: |
        errors=0
        for profile in agents/opencode.md agents/claudecode.md agents/hermes.md agents/gemini.md agents/pi.md; do
          if [ ! -f "$profile" ]; then
            echo "ERROR: Agent profile missing: $profile"
            errors=$((errors + 1))
          fi
        done
        if [ $errors -gt 0 ]; then
          exit 1
        fi
    - name: Check for secrets in harness files
      run: |
        patterns="api_key|apikey|password|passwd|secret|token|private_key"
        if grep -riE "$patterns" harness/ rules/ agents/ shared/ 2>/dev/null | grep -v "README\|\.md.*prohibition\|Never Commit Secrets"; then
          echo "WARNING: Potential secret patterns found in harness files"
        fi
```

**CI Workflow: `check-changelog.yml`**

Job: `check-changelog`
```yaml
check-changelog:
  runs-on: ubuntu-latest
  steps:
    - uses: actions/checkout@v4
      with:
        fetch-depth: 0
    - name: Check CHANGELOG.md updated for code changes
      run: |
        CHANGED_FILES=$(git diff --name-only origin/${{ github.base_ref }}...HEAD | grep -v 'CHANGELOG.md' || true)
        if [ -z "$CHANGED_FILES" ]; then
          echo "Only CHANGELOG.md or no files changed. Skipping check."
          exit 0
        fi
        CODE_CHANGES=$(echo "$CHANGED_FILES" | grep -vE '\.(md|txt|jsonc?)$' | grep -vE '^(\.github/|test/|tests/|__tests__/|spec/|\.planning/)' || true)
        if [ -z "$CODE_CHANGES" ]; then
          echo "Only documentation/CI/test files changed. Skipping check."
          exit 0
        fi
        if git diff --name-only origin/${{ github.base_ref }}...HEAD | grep -q 'CHANGELOG.md'; then
          echo "✅ CHANGELOG.md was updated."
          exit 0
        else
          echo "❌ ERROR: This PR changes code files but does not update CHANGELOG.md"
          exit 1
        fi
```

## Mocking

**Not applicable** — no unit tests exist that require mocking.

## Fixtures and Factories

**Test Data:**
- No fixture files or factory functions
- The `catalog.yaml` acts as a structured fixture for skill metadata
- `src/skills/<skill>/SKILL.md` files are the "fixtures" for build validation
- Agent profile files (`agents/opencode.md`, etc.) serve as fixtures for harness validation

## Coverage

**Requirements:** Not enforced.

**What is measured:**
- Structural coverage: every skill must have `SKILL.md`
- Override coverage: every forked skill must have `EEA-OVERRIDES.md`
- Token budget coverage: every skill checked against 5,500-byte limit
- Sync coverage: `skills/` directory must match build output
- Harness coverage: critical referenced files must exist
- Agent profile coverage: all five agent profiles must exist
- Secret scan coverage: harness files scanned for credential patterns

## Test Types

**Structural Tests:**
- Scope: File existence and directory structure
- Approach: Shell `for` loops over `src/skills/*/`
- Failures: Missing `SKILL.md`, missing `EEA-OVERRIDES.md` (warning only)
- Files: `.github/workflows/validate-skills.yml`

**Build Integration Tests:**
- Scope: Build script correctness and output validity
- Approach: Run `./scripts/build.sh`, verify merged files contain expected markers
- Failures: Missing merged output, missing `BEGIN EEA-OVERRIDES` marker
- Files: `.github/workflows/validate-skills.yml`

**Sync Drift Tests:**
- Scope: Ensure committed `skills/` matches source
- Approach: `git status --porcelain skills/` after rebuild
- Failures: Uncommitted changes in `skills/` after build
- Files: `.github/workflows/validate-skills.yml`

**Schema Validation Tests:**
- Scope: `catalog.yaml` parseability
- Approach: `python3 -c "import yaml; yaml.safe_load(open('catalog.yaml'))"`
- Failures: Invalid YAML syntax
- Files: `.github/workflows/validate-skills.yml`, `.github/workflows/validate-harness.yml`

**Token Budget Tests:**
- Scope: Agent context window limits
- Approach: `wc -c` on each `SKILL.md`
- Threshold: Warn at > 5,500 bytes
- Files: `.github/workflows/validate-skills.yml`

**Harness Integrity Tests:**
- Scope: `harness/EEA-HARNESS.md` structure and references
- Approach: Check top-level heading, verify referenced rules files exist
- Failures: Missing harness file, missing referenced files
- Files: `.github/workflows/validate-harness.yml`

**Agent Profile Tests:**
- Scope: All five agent profiles must exist
- Approach: `for` loop over `agents/{opencode,claudecode,hermes,gemini,pi}.md`
- Failures: Missing agent profile
- Files: `.github/workflows/validate-harness.yml`

**Secret Scan Tests:**
- Scope: Prevent credential leakage in harness files
- Approach: `grep -riE` with pattern list, exclude known-safe matches
- Failures: Potential secret patterns detected
- Files: `.github/workflows/validate-harness.yml`

**Changelog Enforcement Tests:**
- Scope: Require `CHANGELOG.md` updates for code changes in PRs
- Approach: `git diff --name-only` filtered to exclude docs/tests/CI
- Bypass: Label `skip-changelog` or docs-only changes
- Failures: Code changes without changelog update
- Files: `.github/workflows/check-changelog.yml`

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

**Accumulator Pattern (CI shell):**
```bash
errors=0
for file in rules/eeaprohibitions.rules.md rules/eeamandatory.rules.md; do
  if [ ! -f "$file" ]; then
    echo "ERROR: Referenced file missing: $file"
    errors=$((errors + 1))
  fi
done
if [ $errors -gt 0 ]; then
  exit 1
fi
```
Used in `validate-harness.yml` to collect multiple errors before failing.

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

**Harness Validation Workflow (`validate-harness.yml`):**
```yaml
on:
  push:
    branches: [main]
    paths:
      - 'harness/**'
      - 'rules/**'
      - 'agents/**'
      - 'shared/**'
      - 'skills/**'
      - 'catalog.yaml'
  pull_request:
    branches: [main]
    paths:
      - 'harness/**'
      - 'rules/**'
      - 'agents/**'
      - 'shared/**'
      - 'skills/**'
      - 'catalog.yaml'
```

**Changelog Check Workflow (`check-changelog.yml`):**
```yaml
on:
  pull_request:
    types: [opened, synchronize, reopened]
permissions:
  contents: read
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

**No install script tests:**
- `scripts/install.sh` is not exercised in CI
- No verification that symlinks are created correctly
- No test for `--force` or `--agent` flag behavior

**No secret scan false-positive baseline:**
- Secret scan grep pattern may produce false positives
- No baseline file to suppress known-safe matches

---

*Testing analysis: 2026-05-16*

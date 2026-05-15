# Codebase Concerns

**Analysis Date:** 2026-05-14

## Tech Debt

### Placeholder EEA Overrides

- **Issue:** Five of six skills contain `EEA-OVERRIDES.md` files that are empty placeholders with no EEA-specific content.
- **Files:**
  - `src/skills/composition-patterns/EEA-OVERRIDES.md`
  - `src/skills/react-best-practices/EEA-OVERRIDES.md`
  - `src/skills/react-native-skills/EEA-OVERRIDES.md`
  - `src/skills/react-view-transitions/EEA-OVERRIDES.md`
- **Impact:** Agents loading these skills receive no EEA-specific guidance, defeating the purpose of the two-file overlay pattern.
- **Fix approach:** Populate each override file with EEA-specific patterns, or remove the skill from the catalog until overrides are ready.

### Merged Skills Exceed Stated Token Limits

- **Issue:** `README.md` and `CONTRIBUTING.md` state a maximum of ~500 lines / 5k tokens per skill, but merged `skills/` output far exceeds this.
- **Files:**
  - `skills/docker-expert/SKILL.md` — 17,504 bytes (~5,800+ tokens)
  - `skills/react-view-transitions/SKILL.md` — 13,355 bytes
  - `skills/react-best-practices/SKILL.md` — 8,693 bytes
- **Impact:** Agent context windows may be exceeded when these skills are loaded, causing truncated or dropped instructions.
- **Fix approach:** The CI `build-sync` job only checks source file size; add a check for merged output size and consider splitting large skills into focused sub-skills.

### CI Validation Swallows Errors

- **Issue:** The `catalog.yaml` validation step uses `|| echo` which always exits 0.
- **File:** `.github/workflows/validate-skills.yml` lines 43–44
- **Impact:** A malformed `catalog.yaml` will print a failure message but the CI job will pass silently.
- **Fix approach:** Remove the `|| echo "catalog.yaml validation failed"` fallback so the step exits non-zero on parse failure.

### Unimplemented Upstream Sync Logic

- **Issue:** The `upstream-sync` job contains a hard-coded TODO that was never completed.
- **File:** `.github/workflows/validate-skills.yml` lines 99–100
- **Impact:** The scheduled upstream sync never actually compares SHAs or opens issues; the job is essentially a no-op.
- **Fix approach:** Implement SHA comparison against a stored last-known value (e.g., in a repo file or GitHub variable) and auto-create an issue when drift is detected.

### Referenced npm Commands Without package.json

- **Issue:** `CONTRIBUTING.md` documents `npm run validate` and `npm run check-tokens`, but no `package.json` exists in the repository.
- **File:** `CONTRIBUTING.md` lines 166–172
- **Impact:** New contributors following the guide will encounter "command not found" errors.
- **Fix approach:** Add a `package.json` with the referenced scripts, or replace the npm references with the equivalent shell/CLI commands.

## Known Bugs

### Broken Reference Link in react-native-skills

- **Symptoms:** A rule contains a placeholder/example URL instead of a real reference.
- **File:** `src/skills/react-native-skills/AGENTS.md` in section 2.2 "Hoist callbacks to the root of lists"
- **Trigger:** N/A (static content error)
- **Workaround:** Replace `https://example.com` with the correct upstream documentation URL.

## Security Considerations

### No Secret Management for CI

- **Risk:** The upstream sync job fetches public GitHub API data without authentication, which is low risk but may hit rate limits.
- **File:** `.github/workflows/validate-skills.yml` line 98
- **Current mitigation:** Uses unauthenticated `curl` to `api.github.com`.
- **Recommendations:** If sync frequency increases, add a `GITHUB_TOKEN` secret to avoid rate limiting.

## Performance Bottlenecks

### Oversized AGENTS.md Files Not Included in Build

- **Problem:** `AGENTS.md` files (3,810 lines and 2,897 lines) contain extensive compiled guidance but are excluded from the merged `SKILL.md` output.
- **Files:**
  - `src/skills/react-best-practices/AGENTS.md`
  - `src/skills/react-native-skills/AGENTS.md`
- **Cause:** `scripts/build.sh` only concatenates `SKILL.md` + `EEA-OVERRIDES.md`.
- **Improvement path:** Either include `AGENTS.md` in the merged build (with size warnings) or document that agents must load `AGENTS.md` separately when the full rule set is needed.

## Fragile Areas

### catalog.yaml eeaspecific Flags Are Inconsistent

- **Files:** `catalog.yaml`
- **Why fragile:** `web-design-guidelines` has meaningful EEA-specific accessibility overrides but is marked `eeaspecific: false`, while several placeholder-only skills are also marked `eeaspecific: false`. This makes programmatic filtering unreliable.
- **Safe modification:** Update `eeaspecific` to `true` only when the `EEA-OVERRIDES.md` contains non-placeholder content.
- **Test coverage:** No automated validation exists for this flag consistency.

### Shared Directory Contains Placeholders

- **Files:**
  - `shared/design-foundations.md`
  - `shared/data-schemas.md`
  - `shared/eea-style-guide.md`
- **Why fragile:** Skills reference these files in documentation, but they contain no actionable content. Agents may generate code using undefined design tokens or schemas.
- **Safe modification:** Populate these files before referencing them in skill instructions.

## Scaling Limits

### Repository Size Growth

- **Current capacity:** ~19,000 lines of Markdown across all skills.
- **Limit:** If every upstream skill adds an `AGENTS.md` companion file, the repo could double in size without any increase in distributable skill value.
- **Scaling path:** Exclude `AGENTS.md` and `rules/` from release artifacts if they are not part of the merged build, or prune unused upstream assets.

## Dependencies at Risk

### Upstream Content is Copied, Not Referenced

- **Risk:** Vendored upstream content will diverge over time. The sync workflow is incomplete (see Unimplemented Upstream Sync Logic above).
- **Impact:** Skills may become outdated without notice.
- **Migration plan:** Complete the upstream sync automation, or switch to a Git submodule / subtree approach that makes divergence visible.

## Missing Critical Features

### No Automated Tests

- **Problem:** There are zero test files in the repository.
- **Blocks:** Safe refactoring of `scripts/build.sh`, validation logic, or catalog schema changes.
- **Priority:** Medium

### Empty Scaffolding Directories

- **Problem:** `agents/`, `instructions/`, `rules/`, and `plugins/` were added for agentget compatibility but contain no files.
- **Files:** Directories listed in `CHANGELOG.md` as added in v1.2.0
- **Risk:** Confuses users and agents looking for agent definitions or rule files.
- **Priority:** Low

## Test Coverage Gaps

### Build Script Has No Tests

- **What's not tested:** `scripts/build.sh` behavior when `EEA-OVERRIDES.md` is missing, when references/ exist, or when invalid skill names are passed.
- **Files:** `scripts/build.sh`
- **Risk:** A typo in the script could corrupt merged output for all skills.
- **Priority:** Medium

### Workflow File Parsing Not Tested

- **What's not tested:** YAML schema validation for `catalog.yaml` beyond a basic parse check.
- **Files:** `catalog.yaml`
- **Risk:** Missing required fields or invalid trigger lists could break agent discovery.
- **Priority:** Low

---

*Concerns audit: 2026-05-14*

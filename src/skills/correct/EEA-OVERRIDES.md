# EEA-Specific Overrides
<!-- EEA-Overrides-Version: 1.0 -->
<!-- Last-Sync: 2026-11-18 -->

## EEA enforcement layers

- The agent instruction file in EEA repos is the repo-local `AGENTS.md`, plus the org-wide EEA harness loaded through `opencode.json` instructions. Keep the rule/enforcement table in `AGENTS.md`.
- The top enforcement level for EEA repos is usually the Jenkins gate (ruff lint, mypy typing, Docker-based tests; see the `code-quality` and `jenkins-pipeline` skills). A rule enforced by Jenkins beats a rule enforced by prose.
- Never add rules to `harness/EEA-HARNESS.md` from this skill. That file is org-wide policy affecting every EEA project; changes to it require an explicit user request.

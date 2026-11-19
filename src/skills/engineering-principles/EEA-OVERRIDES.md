# EEA-Specific Overrides
<!-- EEA-Overrides-Version: 1.0 -->
<!-- Last-Sync: 2026-11-18 -->

## EEA mapping

- **Encode Lessons in Structure**: the rule/enforcement table lives in the repo's `AGENTS.md`; in EEA repos the enforcement level is usually the Jenkins gate (ruff, mypy, Docker-based tests) — see the `correct`, `code-quality`, and `jenkins-pipeline` skills.
- **Prove It Works**: "the real artifact" for EEA projects means the project's documented Docker test command per the `testing` skill's parity contract, not a native one-off run.
- **Guard the Context Window** and **Never Block on the Human** apply to OpenCode subagents (the `subagent` tool) and Codex subagents when delegation is enabled and allowed by applicable instructions. They do not require delegation when it is unavailable.
- Upstream ships these as 24 separate skills; this repo consolidates them into one skill with an inline index so the catalog stays small. The leaf files are the upstream rule text, unchanged.

# EEA-Specific Overrides
<!-- EEA-Overrides-Version: 1.0 -->
<!-- Last-Sync: 2026-07-29 -->

## EEA quality policy for AI-generated code

For EEA projects, AI-generated code should be created so that it already conforms to the repository checks whenever reasonably possible. The preferred workflow is:

1. inspect repository quality rules
2. generate code that already follows them
3. use auto-fix only for safe mechanical cleanup
4. verify against the same commands Jenkins will run

The goal is to avoid a workflow where a human must repeatedly run `--fix` after every AI-generated change.

## EEA Jenkins quality expectations

If the repository uses Jenkins, quality work is not complete until the code would pass these repository-specific gates where applicable:
- code linting
- type checks if present
- unit tests
- integration tests
- Docker-based test-image verification
- SonarQube inputs generated from passing tests and coverage

## EEA auto-fix policy

Do not recommend a Jenkins `Auto-fix code style` stage. EEA Jenkins is not
permitted to commit changes back to the repository, so a CI-side auto-fix
stage either discards its own rewrites when the container is removed, or
requires auto-committing from CI — the thing EEA policy avoids. Auto-fix
runs **before the commit** instead, as part of writing or repairing code:

- `ruff check --fix`
- `ruff format`
- `black`
- `isort`
- `prettier --write`

Run these using the exact same `Dockerfile.test` image and command strings
Jenkins' `Code linting` stage will use, so what gets committed is already
what Jenkins would accept. The Jenkins pipeline then only needs strict,
read-only verification stages (`--check`/no-`--fix`) that must already
pass — it never re-fixes anything itself.

## EEA warning about Ruff docstring rules

When Ruff `D` rules are enabled, do not assume `ruff --fix` will make the repository pass. Many docstring violations are not mechanically fixable. In such repos:
- generate compliant docstrings up front for new code
- use auto-fix only for fixable classes of issues
- repair remaining issues directly or adjust rollout strategy intentionally

## EEA recommendation for legacy codebases

If an existing codebase has heavy historic lint debt, split the work into:
- safe auto-fix cleanup
- targeted repair of blocking failures
- optional phased tightening of rules

Do not present a repository as “AI-friendly” if it still requires a human to manually run formatters after every generated change.

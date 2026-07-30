---
name: code-quality
description: >
  Produce and repair code so it passes repository linting, typing, tests, and
  Jenkins quality gates with the least manual intervention possible. Optimized
  for AI-generated code and legacy cleanup workflows.
license: MIT
metadata:
  author: EEA
  version: "1.0.0"
  eeaspecific: "true"
---

# Code Quality

Use this skill when code must be created correctly from the start, or when existing code must be repaired until it passes the repository's actual quality gates.

## Primary goal

Make code pass the real checks that block delivery:
- repository formatters and linters
- type checks
- unit tests
- integration tests when present
- Docker-based test-image checks
- Jenkins stages generated for the repository

The skill is optimized for AI-generated code, where the preferred outcome is: generate correct code up front so no later fix-up pass is required.

## When to use

Use this skill when you need to:
- implement new code that must pass CI on the first try
- repair code that already exists but fails lint, typing, or tests
- reduce manual `--fix` cleanup after AI generation
- align a repository with Jenkins quality gates
- decide which checks should auto-fix code and which should remain hard gates

## Operating principles

1. Treat the repository's real checks as the source of truth.
2. Prefer prevention over cleanup: generate code that already matches project conventions.
3. Separate safe auto-fixes from non-fixable policy rules.
4. Do not assume one tool can fix everything.
5. Do not declare success until the same commands used by Jenkins pass.

## Required workflow

1. Inspect the repository before changing code:
   - `pyproject.toml`, `package.json`, `Makefile`, `tox.ini`, `setup.cfg`, `.pre-commit-config.yaml`, CI files, `Jenkinsfile`, Docker test image
   - locate lint, format, type, unit-test, and integration-test commands
2. Classify the checks into three buckets:
   - `safe auto-fix`: import sorting, formatting, some lint rewrites
   - `non-auto-fix quality rules`: architecture, typing, API behavior, complex lint rules, many docstring rules
   - `tests`: unit/integration/e2e gates
3. Implement or repair code while matching the local conventions immediately.
4. Run safe auto-fixes first, if the repo uses them.
5. Run the strict lint/type/test commands that Jenkins or CI will run.
6. Iterate until all blocking checks pass.
7. If Jenkins uses Docker-based verification, validate with the same Docker image or command path.

## AI-generated code guidance

When writing new code, do not rely on a later formatter pass as the main strategy. Generate code that already respects:
- import ordering
- naming conventions
- line length
- obvious docstring expectations when the repo enforces them
- type annotations required by the repo
- existing module boundaries and patterns
- testability

For new code, the target is not “fix it later”; the target is “it passes when first checked”.

## Auto-fix strategy

Use auto-fix only for rules that are safe and mechanical.

Typical safe auto-fix tools:
- `ruff check --fix`
- `ruff format`
- `black`
- `isort`
- `prettier --write`
- ESLint auto-fix for known-safe rule sets

Do not assume these will solve:
- failing tests
- incorrect business logic
- mypy/type errors
- architectural issues
- most documentation policy debt
- many Ruff `D*` docstring violations

## Jenkins compatibility rules

If a repository uses Jenkins, the code-quality workflow must map to the Jenkins stages.

Always identify:
- which checks run in `Code linting`
- which checks run in `Unit test`
- whether integration tests are part of the quality gate
- whether Jenkins runs checks inside `Dockerfile.test`
- the exact Docker commands or wrapper commands a developer can run locally to reproduce those same checks

If Jenkins is present, local verification is incomplete until the generated code would pass those same stages.

The preferred EEA setup is:
- Jenkins and the developer use the same Docker image or same `Dockerfile.test`
- Jenkins and the developer use the same command strings
- those commands are documented in plain shell form, not hidden behind tooling the developer may not have

## Recommended quality-stage model

For CI and Jenkins design, prefer this split:

1. `Auto-fix code style`
   - safe rewrites only
   - may update imports/formatting
2. `Code linting`
   - strict lint gates after auto-fix
3. `Type checks`
   - mypy/pyright/tsc/etc.
4. `Unit test`
5. `Integration test` when needed

This split prevents teams from confusing “fixable formatting debt” with “real quality failures”.

## How to handle failing lint on existing code

If the repository already has legacy lint debt:

1. Run safe auto-fixes first.
2. Re-run lint to see what remains.
3. Separate remaining failures into:
   - issues that require code edits
   - issues that indicate the configured rules are unrealistic for immediate hard-gating
4. When needed, propose a phased rollout:
   - hard gate safe/core rules now
   - report advisory/debt-heavy rules until the codebase is cleaned
5. If the task is primarily about repairing an already-failing repository instead of generating compliant code up front, route into the `quality-fixes` skill.

## Ruff-specific guidance

If Ruff is enabled:
- inspect the `select` list in configuration
- check whether `D` docstring rules are enabled
- do not promise that `ruff --fix` will make the repo pass if `D` rules dominate failures
- if the repo wants zero manual fix-up, ensure the generated code conforms before linting
- when a repository has heavy legacy docstring debt, prefer a split strategy: auto-fix a narrow safe subset first (for example imports/formatting), then run strict lint separately instead of pretending the whole rule set is mechanically fixable

A repo with heavy docstring enforcement often needs one of these approaches:
- generate correct docstrings from the start
- narrow the hard gate to practical rules first
- treat documentation debt as a separate cleanup stream

## Repair mode for existing code

When fixing already-written code:
1. run the real failing commands
2. capture the exact failing files and rules
3. apply safe auto-fixes
4. repair non-fixable issues directly in code
5. rerun lint, typing, and tests
6. stop only when all required checks pass

Also verify that the repository's dependency installation path is real, not merely documented. If `requirements.txt`, `pyproject.toml`, lockfiles, and package-manager behavior disagree, determine which source of truth actually builds before designing CI or test-image fixes around it.

## Output requirements

When using this skill for a repository task, provide:
1. the exact commands used for verification
2. any auto-fix commands used
3. the remaining non-auto-fix issues, if any
4. whether the code now matches the Jenkins quality gates
5. the exact Docker-based commands a developer can run locally to reproduce the same checks without reading Jenkins logs

## Reference

See `references/jenkins-quality-gates.md` for an EEA-oriented model of how to split auto-fix, lint, typing, tests, and Docker/Jenkins verification.

---

<!-- BEGIN EEA-OVERRIDES -->
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

For EEA Jenkins pipelines, recommend a dedicated pre-lint stage such as `Auto-fix code style` when the repository allows automated rewrites.

That stage may run tools like:
- `ruff check --fix`
- `ruff format`
- `black`
- `isort`
- `prettier --write`

After that stage, the pipeline should run strict verification stages that must already pass without manual intervention.

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

<!-- END EEA-OVERRIDES -->

<!-- Merged Build: upstream SKILL.md + EEA-OVERRIDES.md -->
<!-- Auto-generated by scripts/build.sh - DO NOT EDIT DIRECTLY -->
<!-- Source: https://github.com/eea/eea.agent.skills -->

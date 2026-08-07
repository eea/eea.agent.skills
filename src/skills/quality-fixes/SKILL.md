---
name: quality-fixes
description: >
  Diagnose and repair failing lint, typing, test, Docker, and Jenkins quality
  gates until the repository passes the same commands CI will run.
license: MIT
metadata:
  author: EEA
  version: "1.0.0"
  eeaspecific: "true"
---

# Quality Fixes

Use this skill when a repository already fails lint, typing, tests, Docker verification, or Jenkins quality gates and you need to repair it until the real blocking commands pass.

## When to use

Use this skill when:
- a repo fails Ruff, Black, ESLint, mypy, tsc, pytest, Playwright, Cypress, or similar checks
- a Docker-based `Dockerfile.test` verification path fails
- a Jenkins pipeline already exists and the code does not pass it
- the Jenkins skill preflight finds existing failures before creating a new Jenkinsfile

## Primary goal

Repair the code and supporting configuration until the same commands used by Jenkins or CI pass, while keeping changes as small and explainable as possible.

## Required workflow

1. Run the failing commands exactly as the repository or Jenkins would run them.
2. Capture the real failures, not guessed failures.
3. Classify them into:
   - safe auto-fixable issues
   - direct code repair issues
   - environment / dependency / Docker path issues
4. Apply safe auto-fixes first.
5. Repair remaining code or config problems directly.
6. Rerun the same commands.
7. Stop only when the real blocking commands pass.

## Safe auto-fix first

Try mechanical rewrites before manual code edits when they are safe:
- `ruff check --fix`
- `ruff format`
- `black`
- `isort`
- `prettier --write`
- `eslint --fix` for safe repository-approved rules

Do not claim the repository is fixed just because auto-fix changed files. Always rerun the failing commands.

## Repair categories

### 1. Lint/config debt
Examples:
- import ordering
- formatting drift
- docstring policy failures
- unused imports
- line length issues

### 2. Type-check failures
Examples:
- missing annotations required by repo policy
- bad return types
- incorrect optional handling
- missing stubs or import configuration

### 3. Test failures
Examples:
- broken business logic
- invalid fixtures
- outdated assertions
- file path assumptions
- API behavior mismatches

### 4. Docker/CI path failures
Examples:
- broken `Dockerfile.test`
- inconsistent dependency definitions
- package manager conflicts
- missing binaries in the test image
- report paths that Jenkins expects but code does not produce

## Jenkins repair policy

If Jenkins exists, treat its command path as canonical.

Always determine:
- which commands run in `Code linting`
- which commands run in `Unit test`
- which commands run in `Integration test`
- whether the repo is verified through `Dockerfile.test`

A repair is incomplete until those same commands pass.

## AI-generated code guidance

When repairing AI-generated code:
- prefer minimal edits that preserve the intended behavior
- remove obvious mechanical drift first
- do not hide failing logic behind formatter-only cleanup
- if the underlying generated structure is poor, rewrite the smallest coherent unit instead of stacking fragile patches

## Ruff-specific guidance

If Ruff uses heavy `D` docstring rules:
- do not assume `ruff --fix` can resolve the failures
- distinguish mechanical failures from policy-heavy documentation debt
- repair new or touched code fully where practical
- consider phased hard-gating if the repo has large historical debt, but do not weaken checks silently

## Output requirements

When using this skill, provide:
1. the exact commands that were failing
2. what was auto-fixed
3. what was repaired manually
4. the final verification commands that now pass
5. any remaining risk or follow-up debt

## Reference

See `references/fix-loop.md` for the recommended diagnosis → repair → rerun loop.

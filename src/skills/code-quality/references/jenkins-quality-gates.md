# Jenkins-oriented quality gates

Use this reference when a repository must pass Jenkins without requiring a human to run formatter or fixer commands manually.

## Recommended stage split

1. Auto-fix code style
2. Code linting
3. Type checks
4. Unit test
5. Integration test

## Why this split works

- `Auto-fix code style` handles safe mechanical rewrites.
- `Code linting` confirms no strict lint failures remain.
- `Type checks` catches issues fixers cannot solve.
- tests verify behavior instead of style.

## Example command families

Python:
- `ruff check --fix <paths>`
- `ruff format <paths>` or `black <paths>`
- `mypy <paths>`
- `pytest --junitxml=... --cov=... --cov-report=xml:... --cov-report=html:...`

JavaScript/TypeScript:
- `eslint --fix <paths>` when safe
- `prettier --write <paths>`
- `tsc --noEmit`
- `npm test` / `vitest` / `jest`

## Important guardrail

Do not use the auto-fix stage as an excuse to generate sloppy code. Its job is to remove mechanical drift, not to compensate for poor generation quality.

## Auto-commit option

On branch builds, teams may choose to auto-commit safe auto-fix output. If this is used:
- restrict it to deterministic style rewrites
- never auto-commit semantic or risky changes
- rerun strict lint and tests after the commit candidate is produced

## Ruff guidance

If Ruff is configured with heavy docstring enforcement, use one of these approaches:
- write compliant docstrings at generation time
- reduce the hard gate to practical rule sets while debt is burned down
- keep docstring rules advisory until the repository is ready

## Success criteria

A repository passes code quality when:
- auto-fix stage makes no further changes, or any changes are automatically handled
- strict lint is green
- type checks are green
- required tests are green
- the same command path used by Jenkins is green

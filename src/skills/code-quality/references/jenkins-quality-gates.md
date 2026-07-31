# Jenkins-oriented quality gates

Use this reference when a repository must pass Jenkins without requiring a human to run formatter or fixer commands manually.

## Auto-fix runs before the commit, not in Jenkins

Jenkins is not permitted to commit changes back to the repository, so
there is no `Auto-fix code style` *Jenkins* stage. A CI-side auto-fix step
either discards its own rewrites when the container is removed (the fix
never reaches the repository, so the build still needs a human to apply it
and re-push) or has to auto-commit — the pattern EEA policy avoids.

Instead, run the safe fixers yourself, before committing, using the exact
same Docker image and command strings the Jenkins `Code linting` stage will
verify with `--check`/no-`--fix` flags:

- `ruff check --fix <paths>`
- `ruff format <paths>` or `black <paths>`
- `isort <paths>`
- `eslint --fix <paths>` when safe
- `prettier --write <paths>`

By the time code is committed, it should already be clean. Jenkins then
only ever needs to *verify*, never *fix*.

## Recommended Jenkins stage split

1. `Code linting` — strict, read-only (`--check`/no-`--fix`)
2. `Type checks` — `mypy`, `tsc --noEmit`, etc.
3. `Unit test`
4. `Integration test`

## Why this split works

- `Code linting` confirms no strict lint failures remain — it assumes
  pre-commit auto-fix already ran, so a failure here means either that step
  was skipped or the finding isn't mechanically fixable.
- `Type checks` catches issues fixers cannot solve.
- Tests verify behavior instead of style.

## Example command families

Python:
- pre-commit: `ruff check --fix <paths>`, `ruff format <paths>` or `black <paths>`
- Jenkins `Code linting`: `ruff check <paths>` (no `--fix`), `black --check <paths>`
- Jenkins `Type checks`: `mypy <paths>`
- Jenkins `Unit test`: `pytest --junitxml=... --cov=... --cov-report=xml:... --cov-report=html:...`

JavaScript/TypeScript:
- pre-commit: `eslint --fix <paths>` when safe, `prettier --write <paths>`
- Jenkins `Code linting`: `eslint <paths>` (no `--fix`), `prettier --check <paths>`
- Jenkins `Type checks`: `tsc --noEmit`
- Jenkins `Unit test`: `npm test` / `vitest` / `jest`

## Important guardrail

Do not use auto-fix as an excuse to generate sloppy code. Its job is to
remove mechanical drift, not to compensate for poor generation quality.

## Ruff guidance

If Ruff is configured with heavy docstring enforcement, use one of these approaches:
- write compliant docstrings at generation time
- reduce the hard gate to practical rule sets while debt is burned down
- keep docstring rules advisory until the repository is ready

## Success criteria

A repository passes code quality when:
- the pre-commit auto-fix commands make no further changes (nothing left to fix)
- strict lint is green in Jenkins
- type checks are green
- required tests are green
- the same command path used by Jenkins is green

# EEA-Specific Overrides
<!-- EEA-Overrides-Version: 1.0 -->
<!-- Last-Sync: 2026-09-18 -->

## EEA Cypress policy

### Version matrix

Cypress suites in EEA Volto add-ons must pass against every Volto version the
add-on supports (commonly 17, 18, and 19). Read the supported versions from the
project and template generation; run the suite against each unless the task is
explicitly scoped to one version.

### CI targets

EEA add-ons expose CI-oriented targets, typically:

- `make check-ci` — wait for the frontend to be ready.
- `make cypress-ci` — run headless in the CI browser.
- `make cypress-run` — run headless locally.

The EEA Jenkins pipeline publishes JUnit results from `cypress/reports/*.xml`
and coverage from `@cypress/code-coverage`. Do not change the reporter without
updating the pipeline expectation.

### Local reproduction

Run the same target Jenkins runs (`make cypress-ci` when available) so local and
CI results match. Start the backend/frontend the way the add-on does
(`make install` / `make start`, with `VOLTO_VERSION=...` for a non-default Volto).

## Handoff to other EEA skills

- General frontend work → `plone-frontend-developer`
- CI and quality gates → `jenkins-pipeline`, `code-quality`, `testing`

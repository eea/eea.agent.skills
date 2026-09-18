# EEA-Specific Overrides
<!-- EEA-Overrides-Version: 1.0 -->
<!-- Last-Sync: 2026-09-18 -->

## EEA-wide frontend policy

### Supported Volto versions

EEA frontends run Volto 17, 18, or 19 depending on the project. Do not assume a
version: read it from the project (`package.json`, `.nvmrc`, or the template
generation) and match the commands and test runner to it. New projects default
to the latest Volto supported by the EEA Cookieplone templates.

### Add-on registry

Reusable EEA frontend behavior lives in `@eeacms/*` add-ons. Prefer extending an
existing add-on over copying code into a project. Register project-local add-ons
through the project's add-on configuration (`volto.config.js`, `package.json`
`addons`, or `mrs.developer.json`).

### Release and CI

EEA frontend releases go through Jenkins and `release-it` from the `develop`
branch. Do not create release tags or Docker images manually; the pipeline
derives them from git tags. See the `jenkins-pipeline` skill for the CI contract.

## Handoff to other EEA skills

- Cypress/E2E work → `volto-cypress-writer`
- Design tokens and visual language → `eea-design-system`
- Build and quality gates → `jenkins-pipeline`, `code-quality`, `testing`

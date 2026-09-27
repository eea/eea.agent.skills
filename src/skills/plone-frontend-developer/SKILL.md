---
name: plone-frontend-developer
description: >
  Senior Plone/Volto frontend engineering for EEA projects. Use when debugging
  Volto add-ons, fixing UI bugs, adjusting blocks or components, or handling
  theme, routing, tokens, i18n, and build/test issues in any EEA Plone/Volto
  frontend, whether it is a full project or a reusable add-on.
license: MIT
metadata:
  author: EEA
  version: "1.0.0"
  eeaspecific: "true"
---

# Plone Frontend Developer

## Overview

Diagnose and fix Plone/Volto frontend issues in any EEA frontend, whether it is a
full Volto project or a reusable add-on. EEA frontends come from more than one
template generation, so their layout and commands differ. Discover the project
first instead of assuming paths or targets.

For Cypress-specific work, use the `volto-cypress-writer` skill.

## Discover the project first

Before editing, read:

- the project `AGENTS.md` for project-specific conventions and dev environment
- `Makefile` — run `make help` to see the real targets
- `package.json` — `addons`, `resolutions`, the `volto` dependency, test scripts
- `volto.config.js` — the registered add-ons
- `mrs.developer.json` — add-ons mounted in development mode

Use `references/volto-project-layouts.md` to map what you find to one of the known
EEA generations (legacy add-on, Cookieplone add-on, Cookieplone project).

## Core workflow

1. Clarify the symptom, the affected URL, and the expected behavior. Note the
   language/locale if the site is multilingual.
2. Locate the code path: `src/`, `packages/<addon>/src/`, or
   `src/addons/<addon>/src/`, depending on the generation.
3. Reproduce and isolate: make minimal changes, add short-lived logs if needed,
   and confirm the exact component/block responsible.
4. Implement the fix in the most appropriate layer (project or add-on). Favor
   design tokens and shared helpers over hard-coded values.
5. Verify with the smallest relevant check (unit test, lint, typecheck, or a
   targeted runtime check) and report what you ran.

## Common tasks

- **Add-on debugging**: find the add-on in the project's add-on registry
  (`volto.config.js`, `package.json` `addons`, or `mrs.developer.json`), then
  trace the component to its package.
- **Blocks/components**: check both the edit and the view components; cover the
  edit-time behavior and the saved output.
- **Theme/tokens**: replace hard-coded values with design tokens and update
  shared theme/config entries to keep consistency. See the `eea-design-system`
  skill.
- **i18n**: define messages in the add-on/project, then run the project's i18n
  target (`make i18n`).
- **Routing/multilingual links**: check locale-aware routing and URL generation
  before hardcoding language paths.

## Good practices

- Prefer readable, minimal diffs; avoid refactors unless they are required for
  the fix.
- Keep temporary logs out of the final patch.
- For new features, add or update Jest/Vitest coverage.
- For Cypress, follow `volto-cypress-writer` — UI-first, no API-seeded setup.
- Run the project's or add-on's lint/check target before declaring done.
- Restart the frontend server after adding new shadow customizations if the
  project requires it.

## Repo context

Use `references/volto-project-layouts.md` for the known EEA layouts, commands,
test runners, and Cypress `specPattern` differences.

## Verification

Run the smallest relevant command from the project/add-on `Makefile`, for example
`make check`, `make lint`, `make test`, or the add-on's own targets. Report the
exact command and result.

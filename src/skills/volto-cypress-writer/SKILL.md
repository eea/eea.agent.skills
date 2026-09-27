---
name: volto-cypress-writer
description: >
  Cypress E2E writing and maintenance for Plone/Volto add-ons and projects in
  EEA. Use when writing, updating, reviewing, or debugging Cypress tests,
  including UI-first setup, stable selectors, helpers, flake reduction, and
  add-on/project Cypress commands.
license: MIT
metadata:
  author: EEA
  version: "1.0.0"
  eeaspecific: "true"
---

# Volto Cypress Writer

Use this skill when writing, updating, reviewing, or debugging Cypress tests for
EEA Plone/Volto add-ons and projects.

## Discover the project first

EEA Volto codebases come from more than one template generation, and their
Cypress setup differs. Before editing, read:

- `cypress.config.js` — the `specPattern`, `baseUrl`, reporter, and setup events
- `Makefile` — run `make help` for the real Cypress targets
- `cypress/support/e2e.js` and `cypress/support/commands.js` — the helper layout
- nearby specs — the existing naming and helper style

Put new specs where the project's `specPattern` points, not in a hardcoded
directory. Common layouts are `cypress/e2e/**/*.cy.js` (legacy add-ons) and
`cypress/tests/**/*.cy.{js,jsx,ts,tsx}` (Cookieplone projects/add-ons).

Put reusable feature helpers in `cypress/support/<feature>.js` unless the project
already uses a different convention. Keep global Cypress commands minimal;
prefer imported helpers for feature-specific flows.

## UI-First Rule

New tests must set up state, navigate, edit, save, and assert through the browser UI.

- Do not add or call `cy.request()` setup helpers for new tests unless the user explicitly asks for legacy/API-seeded style.
- Existing REST helpers such as `autologin`, `createContent`, and `removeContent` may be read for context, but do not copy them into new UI-first flows.
- Use the UI for the behavior under test even when an older suite uses API shortcuts.
- If UI-only setup is impractical for a narrow reason, stop and explain the constraint before changing the approach.

## Selectors

- Prefer stable `data-cy` or `data-testid` selectors.
- If stable selectors are missing and component edits are in scope, add explicit test selectors to the component instead of relying on DOM shape.
- Use role, label, placeholder, or visible text when they describe the user's intent.
- Avoid positional selectors like `:nth-child()` and style-driven selectors like `.ui.basic.icon.button...`.
- If Volto or Semantic UI markup forces a fragile selector, hide it behind a named helper such as `openBlockChooser()` or `saveCurrentPage()`.
- Keep assertions user-visible where possible: URL, heading, block text, saved view output, modal state, toolbar state, validation message.

## Reliability

- Each spec must pass independently; do not depend on previous tests.
- Use `beforeEach` for browser state and content setup.
- Prefer Cypress retry-ability: `cy.get(...).should(...)`, `cy.contains(...).should(...)`, and URL assertions.
- Prefer `cy.intercept().as()` and `cy.wait('@alias')` for network-dependent transitions.
- Avoid arbitrary `cy.wait(ms)`. If a Volto editor limitation requires one, keep it local and add a short comment explaining why.
- Avoid per-command `{ timeout: ... }`; wait for observable UI or network state instead. If a timeout override is unavoidable, keep it local and document the reason.
- Split chains after actions before assertions:

```js
cy.get('[data-cy="toolbar-save"]').click();
cy.get('[data-cy="view-page"]').should('be.visible');
```

- Avoid `{ force: true }` unless Volto overlays or hidden controls make it unavoidable; explain the reason in a helper or nearby comment.
- Do not suppress uncaught exceptions broadly unless the test target is a known third-party integration and the user accepts that tradeoff.

## Volto Add-on Patterns

- The add-on Cypress config usually sets `baseUrl: 'http://localhost:3000'` and passes Plone API settings through `CYPRESS_API_PATH`, `RAZZLE_DEV_PROXY_API_PATH`, or `RAZZLE_INTERNAL_API_PATH`.
- Add-on tests normally live beside the add-on, not in the root project `cypress/` directory.
- Cypress tests for an add-on must pass against every Volto version the add-on supports (commonly 17, 18, and 19) unless the user explicitly scopes the task to one version. Read the versions from the project and template generation.
- For block tests, cover the edit flow and the saved view:
  - create or navigate to a page through the UI
  - add the block through the block chooser
  - configure the fields through the sidebar or inline editor
  - save
  - assert the view mode output
- For editor interactions, prefer existing Slate helpers if the add-on already has them. Add focused helpers only when they reduce repeated low-level selection/type logic.

## Commands

Run add-on Cypress commands from the add-on directory when the add-on has its own
Makefile. Start by checking the available targets:

```sh
make help
```

Common flows (names vary by generation; use what `make help` reports):

```sh
make install
make start
make cypress-run
make cypress-open
```

Non-default Volto version (legacy and Cookieplone add-ons):

```sh
VOLTO_VERSION=18-yarn make install
VOLTO_VERSION=18-yarn make start
make cypress-run
```

`VOLTO_VERSION` selects the add-on environment during install/start; it does not
change Cypress itself. Run Cypress against the Volto version that is currently
started.

Cookieplone projects expose project-level targets:

```sh
make cypress
make cypress-open
```

Run one spec:

```sh
npx cypress run --spec "<path/to/spec.cy.js>"
```

Useful debugging and CI-style targets (confirm they exist in the target
`Makefile` before using them):

```sh
make shell
make check-ci
make cypress-ci
```

Use the smallest relevant command for verification. For a Cypress-only change,
prefer the target's Cypress command in every supported Volto environment.

## Review Checklist

- The test exercises the feature like a user, not by mutating backend state.
- Selectors are stable or wrapped in named helpers.
- The test asserts both edit-time behavior and saved output when relevant.
- The suite can run test cases independently.
- The Cypress behavior works in every supported Volto version, or the version-specific limitation is clearly reported.
- Network or async transitions wait on observable conditions, not fixed sleeps.
- Per-command `{ timeout: ... }` overrides are avoided or explicitly justified.
- Helpers are local to the add-on/project unless multiple specs need them.
- The command used to verify is reported back to the user.

# EEA Volto Project Layouts

EEA Plone/Volto frontends come from more than one template generation. Identify
which one you are in before choosing paths or commands.

## Legacy Volto add-on (`volto-addon-template`)

- The add-on package lives at the repository root; its source is in `src/`.
- The dev environment is Docker Compose driven from the add-on root.
- Commands: `make` (build/install), `make start`, `make shell`,
  `make cypress-open`, `make cypress-run`, `make test`, `make lint`.
- Non-default Volto: `VOLTO_VERSION=18-yarn make start` (default is 18).
- Unit tests: Jest.
- Cypress: the default `cypress/e2e/**/*.cy.js`; support files in
  `cypress/support/`.
- Mounting into a project: `mrs.developer.json` with `"output": "packages"`.

## Cookieplone add-on (`frontend_addon`)

- The add-on package lives at `packages/<addon>/`.
- Commands: `make install`, `make start`, `make backend-start`,
  `make frontend-start`, `make cypress-run`, `make cypress-open`, `make test`,
  `make lint`, `make i18n`.
- Non-default Volto: `VOLTO_VERSION=18-yarn make install` (default is 19).
- Unit tests: Vitest on Volto 19, Jest on Volto 18.
- Cypress: `specPattern` is set explicitly, commonly
  `cypress/tests/**/*.cy.{js,jsx,ts,tsx}`. Always read `cypress.config.js`.

## Cookieplone project (`frontend_project`)

- A full frontend project; add-ons are mounted with `mrs.developer.json`.
- Commands: `make develop`, `make install`, `make start`, `make relstorage`,
  `make check`, `make typecheck`, `make lint`, `make cypress`, `make i18n`.
- Package manager: pnpm workspace; sources under `packages/`.
- Add-ons are registered in `volto.config.js`.

## How to discover

1. Run `make help` for the real targets.
2. Look for `mrs.developer.json`, `volto.config.js`, and a `packages/` directory
   to tell a Cookieplone project/add-on from a legacy add-on.
3. Read `cypress.config.js` for the `specPattern` and support-file layout.
4. Read `package.json` for the `volto` version and the test runner.

## Consulting Volto core

When you need core behavior, read the Volto version the project actually uses —
the installed package under `node_modules/@plone/volto`, or the version pinned in
`package.json`. Do not rely on a different Volto version's behavior.

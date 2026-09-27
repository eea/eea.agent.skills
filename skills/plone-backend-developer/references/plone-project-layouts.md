# EEA Plone Backend Layouts

EEA Plone backends come from more than one build generation. Identify which one
you are in before choosing paths or commands.

## Buildout development environment (`develop/`)

Common in legacy and some current EEA projects:

- Dev environment root: `develop/` (or `backend/develop/` in monorepos).
- Sources list: `sources.ini`.
- Pins: `requirements.txt` and `constraints.txt`.
- Bootstrap and install: `make` (bootstrap + install + develop).
- Start: `make start`; RelStorage: `make relstorage`.
- Refresh add-ons: `make develop`.
- Tests: `bin/zope-testrunner --test-path sources/<package>`.
- Hot reload is not available; restart after Python changes.
- Optional reload helper: `plone.reload` / `dm.plonepatches.reload` via
  `@@reload`.

## Cookieplone / container-based projects

- The backend is started from Docker (for example `make backend-start` in a
  Cookieplone frontend project, or a dedicated backend repository).
- Follow the project `Makefile` and `AGENTS.md`; do not assume a `develop/`
  directory exists.

## How to discover

1. Run `make help` for the real targets.
2. Look for `develop/`, `sources.ini`, `constraints.txt`, or `pyproject.toml`.
3. Check the project `AGENTS.md` for the documented start and test commands.

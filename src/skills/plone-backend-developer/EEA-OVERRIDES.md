# EEA-Specific Overrides
<!-- EEA-Overrides-Version: 1.0 -->
<!-- Last-Sync: 2026-09-18 -->

## EEA-wide backend policy

### Plone version

EEA projects run Plone 6.x. Read the exact version from the project's pins
(`constraints.txt`, `requirements.txt`, or `pyproject.toml`) instead of assuming.

### Persistence

Production EEA Plone deployments use RelStorage (PostgreSQL) rather than the
default ZODB file storage. When reproducing production behavior, prefer the
project's RelStorage target when it exists.

### Release and CI

Backend releases and quality gates run through Jenkins. See `jenkins-pipeline`,
`code-quality`, and `testing` for the CI contract and command parity.

## Handoff to other EEA skills

- Frontend/Volto behavior → `plone-frontend-developer`, `volto-cypress-writer`
- CI and quality gates → `jenkins-pipeline`, `code-quality`, `testing`

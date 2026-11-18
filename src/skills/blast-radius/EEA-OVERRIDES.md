# EEA-Specific Overrides
<!-- EEA-Overrides-Version: 1.0 -->
<!-- Last-Sync: 2026-11-18 -->

## EEA blast-radius hotspots

- Plone add-ons: a change in one add-on is picked up by every EEA project that depends on it. "Look where grep stops" includes checking which projects pin the add-on and at which version.
- Volto frontends: a shared block, component, or design token affects every page that renders it. Check which blocks reference the changed component before shipping.
- Build files: a changed `Dockerfile.test` or Jenkinsfile affects every quality gate in the repo (lint, tests, coverage, Trivy scan). Treat those as wide-blast-radius changes and run the full gate set.

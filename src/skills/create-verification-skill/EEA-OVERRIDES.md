# EEA-Specific Overrides
<!-- EEA-Overrides-Version: 1.0 -->
<!-- Last-Sync: 2026-11-18 -->

## Where the generated skill lives

- OpenCode has no `.cursor/skills/` directory. Generate the project-local skill at `.opencode/skills/verify-<app>/` (OpenCode's project skills directory) instead, and point the repo README there.
- For EEA Plone/Volto projects, drive the app through the same surfaces the `volto-cypress-writer` and `testing` skills already document (Cypress specs, the documented Docker test command); reuse those harnesses instead of inventing parallel ones.

## Not yet ported

- Section 5 points at `/maintain-verification-skill`, which is not in this repo. Until it is ported, note in the generated skill's README that the feature map needs a manual re-check whenever the app changes.

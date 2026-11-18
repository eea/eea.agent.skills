# EEA-Specific Overrides
<!-- EEA-Overrides-Version: 1.0 -->
<!-- Last-Sync: 2026-11-18 -->

## EEA test runners

- "The closest test already used for that codepath" means the project's documented test command, which for most EEA projects is a Docker-based command per the `testing` skill's parity contract. Add the regression test where the project's suite already lives; discover the layout per the `plone-backend-developer` / `plone-frontend-developer` skills rather than assuming paths.
- If the project's documented test command cannot run the single new test cheaply, that is a signal to use the closest executable check (upstream skill, "If a Failing Test Is Impractical" section) instead of building a second, non-Docker test path.
- Keep the failing-then-passing evidence in the PR body as command and output, per the `technical-writing` skill.

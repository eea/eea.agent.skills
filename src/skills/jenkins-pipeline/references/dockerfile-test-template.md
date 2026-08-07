# Dockerfile.test template

See `docker-expert/EEA-OVERRIDES.md`'s "Dockerfile.test for Jenkins
Pipelines" section for the canonical artifact contract (what the image must
contain, dependency-install rules, mixed-language guidance) and a worked
Node.js `Dockerfile.test` example. This file only adds the Jenkins-stage
command mapping for a Node.js-shaped repo — adapt the script names to the
repository's actual `package.json`:

- `npm run lint` → `Code linting` stage
- `npm run test:ci` → `Unit test` stage, produces `/app/junit.xml` and
  `/app/coverage/lcov.info` + `/app/coverage/lcov-report/index.html`
- `npm run start:ci` / `npm run test:integration:ci` → `Integration test`
  stage, produces optional `/app/integration-junit.xml`

This same image is what developers build and run locally to reproduce CI
exactly — see the `testing` skill's parity contract — so keep it as the
single source of truth rather than maintaining a separate local-only image,
or the two will drift.

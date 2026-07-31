---
name: jenkins-pipeline
description: >
  Build Jenkins declarative pipelines for EEA projects with Docker-based test
  execution, parallel quality gates, JUnit and coverage publishing, SonarQube,
  Trivy image scanning, semantic versioning, and Docker Hub release.
license: MIT
metadata:
  author: aj-geddes, EEA
  version: "1.0.0"
  upstream_source: aj-geddes/useful-ai-prompts
  upstream_url: https://github.com/aj-geddes/useful-ai-prompts
  eeaspecific: "true"
---

# Jenkins Pipeline

Create Jenkins declarative pipelines that match EEA's Jenkinsfile structure and operational constraints.

## When to use

Use this skill when you need to create or update:
- `Jenkinsfile`
- Docker-based CI test pipelines
- SonarQube and Trivy quality gates
- Docker Hub release automation
- reusable CI layouts for JavaScript, Python, or mixed application repositories
- developer-reproducible Docker test flows that match Jenkins exactly
- README CI/quality badges (Jenkins pipeline, SonarQube) — raised proactively once the Jenkinsfile is finalized (see the EEA-specific override for when and why), as a conversation about which badges and branch rather than a template to apply blindly

## Required workflow

This is a strict order, not a menu — do not generate the Jenkinsfile before
completing every earlier phase, and do not skip the preflight because the
repository "looks fine." The whole point of the preflight is that a
Jenkinsfile written before it is a guess about what will pass in CI; a
Jenkinsfile written after it is a fact.

### Phase 1 — Discover

1. Inspect the repository and identify:
   - package manager / build tool
   - lint / type-check commands
   - unit test commands
   - integration / e2e test commands
   - coverage output capabilities
   - Docker build context and release image details

### Phase 2 — Build the exact environment CI will run in

2. If `Dockerfile.test` does not exist, use `docker-expert` to create it
   now. Do not move on to testing without it — every command in Phase 3
   must run inside this image, not on the host, because that's what the
   Jenkinsfile will do too. A check that only ever ran on the host has not
   actually been validated against what Jenkins will execute.
3. Build it: `docker build -f Dockerfile.test -t <repo>-test:preflight .`.
   If this fails, fix the Dockerfile.test itself before doing anything
   else — nothing downstream can be trusted until the image builds.

### Phase 3 — Preflight with the exact commands the Jenkinsfile will use

4. Decide the exact lint, type-check, and unit-test command strings the
   Jenkinsfile's stages will run. Load the `code-quality` skill mindset to
   decide what belongs in auto-fix vs. a strict hard gate, and the
   `testing` skill mindset so these are the same Docker-based commands a
   developer can run locally. These commands are decided **once**, here —
   do not write an approximate or simplified version now and a "real"
   version later when authoring the Jenkinsfile. The exact string you run
   in this phase is the exact string that goes into the Jenkinsfile's
   `sh` step in Phase 4. If they ever diverge, the preflight validated
   nothing.
5. Run each command inside the image built in Phase 2 (`docker run --rm
   <repo>-test:preflight <command>`), exactly as it will run in its
   corresponding Jenkinsfile stage (lint, type-check, unit tests,
   integration tests if feasible locally).
6. If a command fails on something mechanical (formatting, import order,
   safe auto-fixable lint rules), apply the repository's auto-fixers
   inside the image, copy the changes back to the workspace, and rerun the
   command. Repeat until it's clean or the remaining failures require
   judgment (real bugs, type errors, failing tests, non-mechanical lint
   findings) — those aren't auto-fixable and shouldn't be force-fixed.
7. If failures remain after auto-fixing, stop and report exactly which
   commands and files fail, then ask the user whether to repair them now
   (route into `quality-fixes`) before generating the Jenkinsfile, or
   proceed knowing Jenkins will report the same failures on its first run.

### Phase 4 — Generate the Jenkinsfile

8. Only now generate a declarative `Jenkinsfile`, using the EEA pipeline
   shell from `references/eea-jenkinsfile-template.md`. If the repository
   doesn't fit that template's Docker-based JS/Python assumption (e.g.
   it's Java/Maven, a Python egg/Plone add-on, or a Dockerfile-only
   release repo with nothing to test), check `references/examples/` for a
   closer-matching real EEA pipeline first.
9. Embed the **exact** commands verified in Phase 3 into the matching
   stages (`Auto-fix code style`, `Code linting`, `Unit test`, `Integration
   test`) — do not restate, simplify, or "clean up" them when writing the
   Jenkinsfile. If a command needs to change, go back to Phase 3, rerun it
   there, confirm it still passes, and only then carry the new string
   into the Jenkinsfile.
10. Keep one concern per stage. Prefer more small stages instead of one
    large stage.
11. Run all code-quality and test commands inside Docker containers
    created from `Dockerfile.test` — never on the host, matching what
    Phase 3 already validated.
12. Add an `Auto-fix code style` stage before strict linting when the
    repository benefits from safe mechanical rewrites (Phase 3, step 6,
    will already have told you whether it does).
13. Ensure every non-`--rm` test container is explicitly removed with
    `docker rm -v` in `finally` / `post` cleanup logic.
14. Keep Docker images available after the job finishes; do not add
    `docker rmi` unless the repository explicitly requires it.

## Mandatory pipeline contract

Generated Jenkinsfiles must satisfy all of the following:

- Top-level shape must remain:
  - `pipeline { ... }`
  - `agent { node { label 'docker-host' } }`
  - `environment {}`
  - `stages {}`
  - `post { always { cleanWs(...) } changed { emailext(...) } }`
- Use multiple stages, with one pipeline concern per stage.
- Include an `Auto-fix code style` stage when the repository has safe mechanical rewrites worth running in CI.
- If an auto-fix stage is used, keep it separate from strict linting and limit it to safe rewrites such as import sorting, formatting, and known-safe lint fixes.
- The pipeline must expose the exact Docker-based commands a developer can run locally to reproduce each Jenkins quality/test stage.
- Include a `Code linting` stage with one or more parallel sub-stages.
- Include a `Unit test` stage that:
  - runs tests in the test image
  - saves JUnit XML
  - saves LCOV as `lcov.info`
  - saves HTML coverage report
  - publishes JUnit and HTML coverage in Jenkins
- Include an `Integration test` stage that:
  - starts the application and required dependencies in Docker
  - runs Cypress / Playwright / equivalent smoke or e2e tests
  - saves JUnit XML
  - saves LCOV as `lcov.info` when available
  - publishes the results in Jenkins
- Include a `Sonarqube test` stage that passes source path, test result paths, and LCOV paths to `sonar-scanner`.
- Include a `Trivy test` stage that scans the release Docker image.
- Include versioning and Docker Hub release stages.
- Leave no stopped test containers behind. Named containers must be removed with `docker rm -v`.

## Stage blueprint

Use this stage sequence unless the repository has a strong reason to differ:

1. `Checkout`
2. `Versioning`
3. `Build test image`
4. `Auto-fix code style`
5. `Code linting`
6. `Unit test`
7. `Build release image`
8. `Integration test`
9. `Sonarqube test`
10. `Trivy test`
11. `Release on Docker Hub`

If needed, split these into nested stages, but preserve the same responsibilities.

## Artifact conventions

Prefer these workspace paths so Jenkins publishing stays predictable:

- `xunit-reports-current/junit.xml`
- `xunit-reports-current/coverage/lcov.info`
- `xunit-reports-current/coverage/lcov-report/index.html`
- `integration-reports-current/junit.xml` or `integration-reports-current/**/*.xml`
- `integration-reports-current/coverage/lcov.info`
- `integration-reports-current/coverage/lcov-report/index.html`
- `trivy-reports/trivy-image.txt`

Publish unit test results with:

```groovy
catchError(buildResult: 'SUCCESS', stageResult: 'SUCCESS') {
  junit testResults: 'xunit-reports-current/junit.xml', allowEmptyResults: true
}
```

Publish HTML coverage with:

```groovy
publishHTML(target : [
  allowMissing: false,
  alwaysLinkToLastBuild: true,
  keepAll: true,
  reportDir: 'xunit-reports-current/coverage/lcov-report',
  reportFiles: 'index.html',
  reportName: 'UTCoverage',
  reportTitles: 'Unit Tests Code Coverage'
])
```

## Container cleanup rules

- Use deterministic container names derived from `BUILD_TAG.toLowerCase()`.
- For containers that must stay alive long enough for `docker cp`, do not use `--rm`.
- Wrap long-running test containers in `try/finally` blocks.
- If an auto-fix stage writes changes inside a container, either:
  - mount the workspace so rewrites land directly in the checked-out repository, or
  - copy the changed files back out before strict lint and tests continue.
- In cleanup, prefer:
  - `docker stop <name>` with `returnStatus: true`
  - `docker rm -v <name>` with `returnStatus: true`
- Apply cleanup to:
  - lint fix containers
  - unit test containers
  - application containers used for integration tests
  - database / queue / backend dependency containers
  - browser-test containers
- When copying a directory out of a container with `docker cp
  <container>:<src-dir> <dest-dir>`, always use a trailing `/.` on the
  source (`docker cp <container>:<src-dir>/. <dest-dir>`). Without it,
  `docker cp`'s behavior depends on whether `<dest-dir>` already exists: if
  it does (e.g. because an earlier stage already ran `mkdir -p <dest-dir>`
  to stage output directories), Docker nests the source directory *inside*
  the destination instead of copying its contents, silently producing
  `<dest-dir>/<src-dir-basename>/coverage.xml` instead of
  `<dest-dir>/coverage.xml` — invisible until something downstream (like
  Sonarqube) looks for a file at the expected flat path and finds nothing.
  The trailing `/.` always copies contents, regardless of whether the
  destination pre-exists.

## Auto-fix stage guidance

When a repository has safe mechanical rewrites, prefer a dedicated stage such as `Auto-fix code style` before strict linting.

Good candidates for this stage:
- `ruff check --fix` for a restricted, safe rule set
- `ruff format`
- `black`
- `isort`
- `prettier --write`

Prefer narrow, proven-safe rewrites over broad fixer runs. Example: if Ruff docstring (`D`) rules create a large non-fixable failure set, auto-fix only safe subsets such as imports or formatting first, then run strict lint separately.

On branch builds, do not auto-commit from Jenkins by default. Prefer making the same safe auto-fix commands available to developers locally via Docker, then fail with a clear message or export a patch artifact when rewrites would be needed.

Do not assume the auto-fix stage can solve:
- test failures
- mypy/type failures
- logic bugs
- architecture issues
- heavy docstring debt

If the repository enables Ruff docstring (`D`) rules, do not assume `ruff --fix` will make the build pass. Either generate compliant docstrings up front, or keep the hard gate focused on practical rules while the documentation debt is cleaned intentionally.

## Dockerfile.test contract

The test image must usually:
- be built from `Dockerfile.test`
- copy the full repository source into the image
- install all development and test dependencies
- provide the tools needed for linting, unit tests, integration tests, coverage, and XML reporting
- make it easy to run commands through `docker run ... --entrypoint` or standard shell commands

A good test image should produce:
- `junit.xml` for unit tests
- `coverage/lcov.info`
- `coverage/lcov-report/index.html`
- optional integration results in a separate path

Important practical findings:
- For mixed Python + Node repositories, prefer a Node base image and install Python tooling into it, rather than starting from Python and copying Node/NPM binaries across images.
- Do not blindly trust `requirements.txt` if the repository also has `pyproject.toml`, lockfiles, or another dependency source and they disagree. Inspect which dependency definition is actually coherent and buildable, then mirror that in `Dockerfile.test`.
- If `npm ci` fails on peer dependency resolution in an existing project, use `--legacy-peer-deps` only as an explicit repository-specific choice.

See `references/dockerfile-test-template.md` for the expected layout.

## SonarQube guidance

- Use `tool 'SonarQubeScanner'`.
- Use `withSonarQubeEnv('Sonarqube')`.
- Compute branch vs PR parameters from Jenkins env vars.
- Pass both unit and integration coverage paths when both exist.
- Normalize LCOV paths when the test container writes repository-prefixed absolute paths.
- Match the coverage property to the language, not just the report format:
  - JavaScript/TypeScript coverage (LCOV, e.g. from Jest/Vitest/Istanbul) goes
    to `sonar.javascript.lcov.reportPaths`.
  - Python coverage goes to `sonar.python.coverage.reportPaths`, and it
    expects **Cobertura XML**, not LCOV — generate it with `pytest-cov`'s
    `--cov-report=xml:<path>` (alongside `lcov`/`html` if those are used for
    other artifacts), never point `sonar.javascript.lcov.reportPaths` at a
    Python-generated LCOV file. Feeding Python coverage into the JS property
    is a real failure mode that silently produces 0% coverage in Sonar even
    though tests pass and coverage was actually measured.
  - Never invoke `pytest --cov=<dir1> --cov=<dir2> --cov=<dir3> ...` with
    several unrelated top-level directories when the Cobertura (`xml`)
    report is going to Sonar. `coverage.py`'s Cobertura writer groups files
    by package *relative to each `--cov` root*, so multiple disjoint roots
    collide into ambiguous bare filenames (e.g. two different files both
    reported as `filename="analyzer.py"` with no directory) that Sonar can't
    reliably map back to source files — even though the equivalent LCOV
    report for the same run stays correctly qualified
    (`SF:analysis/analyzer.py`). Use a single `--cov=.` together with a
    `[tool.coverage.run]` `source`/`omit` config (in `pyproject.toml` or
    `.coveragerc`) to keep the same measured scope while producing
    fully-qualified relative paths (`analysis/analyzer.py`,
    `pre_analysis/analyzer.py`) in every report format.
- Do not set `sonar.python.xunit.reportPath`. It looked like a path-format
  problem at first (comma-joining two `junit.xml` paths, since the property
  takes a single path/glob rather than a comma-delimited list like
  `sonar.python.coverage.reportPaths`), but switching to a single wildcard
  glob (`./*-reports-current/junit.xml`) produced the *identical* "No
  report was found" warning on a real Jenkins PR build, even though an
  `ls -la` run immediately before the scan step confirmed both `junit.xml`
  files genuinely existed at the exact configured paths. Two different
  values failing identically against files provably present means this
  specific sensor doesn't respect a custom value at all in current
  SonarQube versions — not a pattern-syntax bug to keep chasing. It's safe
  to drop: Jenkins' own `junit` step already publishes per-test pass/fail
  to the GitHub check independently of this property, and the Quality Gate
  itself is driven by coverage (`sonar.python.coverage.reportPaths`, which
  does work) and static analysis, not by this sensor. Keeping it around
  only produces a permanent, misleading warning with no functional benefit
  — same reasoning applies to `sonar.junit.reportPaths` (the Java-oriented
  generic property) on a project with no Java sensor to consume it.

## Trivy guidance

- Scan the release image, not the test image.
- Save a text report in the workspace.
- Fail the stage for high/critical findings unless the repository explicitly documents a softer policy.
- Prefer a command shape like:
  `trivy image --no-progress --format table --output trivy-reports/trivy-image.txt <image>`

## Versioning and release guidance

- Derive version from the project source of truth when possible (`package.json`, `pyproject.toml`, Git tags, etc.).
- For branch builds, append branch / build metadata if the existing release flow expects it.
- Use Jenkins credentials for Docker Hub authentication.
- Separate image build from image push into different stages.
- Push tags only from the intended protected branch or release context.

## Output requirements

When asked to generate a Jenkins pipeline, provide:
1. a preflight summary of the repository's current lint/test state and which existing commands would already fail in Jenkins
2. if failures exist, ask whether they should be repaired first using the `quality-fixes` workflow
3. `Jenkinsfile`
4. `Dockerfile.test` when missing or outdated
5. the exact Docker commands a developer can run locally to reproduce the same lint, unit-test, and integration-test stages
6. any required report directories / command notes
7. a short explanation of assumptions and repository-specific commands selected

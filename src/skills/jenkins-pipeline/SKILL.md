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
- diagnosing and fixing a failed Jenkins build — see `references/diagnosing-failed-builds.md`

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
   - whether this repo fits the Docker-based JS/Python default at all, or
     matches one of the alternate real shapes in `references/examples/`
     instead (Java/Maven via Jenkins tool installations, a Python
     egg/Plone add-on, a Dockerfile-only release repo). Decide this now —
     it changes what Phase 2 means, not just what Phase 4 generates.

### Phase 2 — Build the exact environment CI will run in

2. **If this repo fits the Docker-based default:** if `Dockerfile.test`
   does not exist, use `docker-expert` to create it now. Do not move on to
   testing without it — every command in Phase 3 must run inside this
   image, not on the host, because that's what the Jenkinsfile will do
   too. A check that only ever ran on the host has not actually been
   validated against what Jenkins will execute.
   Build it: `docker build -f Dockerfile.test -t <repo>-test:preflight .`.
   If this fails, fix the Dockerfile.test itself before doing anything
   else — nothing downstream can be trusted until the image builds.
3. **If this repo instead matches a `references/examples/` pattern that
   uses Jenkins-provided tools instead of a project-owned test image**
   (e.g. Java/Maven's `tools { maven 'maven3'; jdk 'Java17' }`) — do not
   create a `Dockerfile.test`; it would go unused by the Jenkinsfile you
   generate in Phase 4 and just adds dead weight to the repo. Preflight
   instead against a public image that matches the Jenkins tool version
   (e.g. `docker run --rm -v "$PWD":/workspace -w /workspace
   maven:<version>-eclipse-temurin-<jdk> <command>`) as a stand-in for
   what the Jenkins `tools{}` block provides.

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
   stages (`Code linting`, `Unit test`, `Integration test`) — do not
   restate, simplify, or "clean up" them when writing the Jenkinsfile. If a
   command needs to change, go back to Phase 3, rerun it there, confirm it
   still passes, and only then carry the new string into the Jenkinsfile.
10. Keep one concern per stage. Prefer more small stages instead of one
    large stage.
11. Run all code-quality and test commands inside Docker containers
    created from `Dockerfile.test` — never on the host, matching what
    Phase 3 already validated.
12. Do not add an `Auto-fix code style` stage to the Jenkinsfile — see
    "Pre-commit auto-fix, not a Jenkins stage" below for why, and make sure
    `Code linting` runs the strict, read-only form of each command
    (`--check`, no `--fix`), since Phase 3 already fixed what was fixable.
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
- Do not include an `Auto-fix code style` stage — see "Pre-commit auto-fix, not a Jenkins stage" below.
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
  - **may be omitted** when the repository genuinely has nothing to
    integration-test against — a CLI tool or library with no server/DB to
    stand up. Don't omit it just because writing the tests is more work;
    only when there's no running application for it to exercise.
- Include a `Sonarqube test` stage that passes source path, test result paths, and LCOV paths to `sonar-scanner`.
- Include a `Trivy test` stage that scans the release Docker image.
- Include versioning and Docker Hub release stages.
- Leave no stopped test containers behind. Named containers must be removed with `docker rm -v`.

## Stage blueprint

Use this stage sequence unless the repository has a strong reason to differ:

1. `Checkout`
2. `Versioning`
3. `Build test image`
4. `Code linting`
5. `Unit test`
6. `Build release image`
7. `Integration test`
8. `Sonarqube test`
9. `Trivy test`
10. `Release on Docker Hub`

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
- In cleanup, prefer:
  - `docker stop <name>` with `returnStatus: true`
  - `docker rm -v <name>` with `returnStatus: true`
- Apply cleanup to:
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

## Pre-commit auto-fix, not a Jenkins stage

Do not add an `Auto-fix code style` stage to the Jenkinsfile. Jenkins is
not permitted to commit changes back to the repository (see the
`code-quality` skill), so a CI-side auto-fix stage has no useful outcome:
either the rewrites it makes are discarded when the container is removed
(pure waste — the build still has to be re-run after a human applies the
same fix), or it tries to commit/push the fix itself, which is exactly the
auto-commit-from-CI pattern EEA does not want.

Auto-fixing belongs **before the commit**, not in CI: it's Phase 3 of the
"Required workflow" above (run the safe fixers — `ruff check --fix`,
`ruff format`, `black`, `isort`, `prettier --write` — using the exact
commands Jenkins will use, then rerun the check). By the time a Jenkinsfile
is generated, the code should already be clean; `Code linting` in Jenkins
is a **strict, read-only verification** of that (`--check` flags, no
`--fix`), not a second chance to fix things. A lint failure in Jenkins
means the pre-commit auto-fix step was skipped or a check exists that
isn't mechanically fixable — not something for the pipeline itself to
repair.

Phase 2/3 (building `Dockerfile.test` and running the commands inside it)
is mandatory the *first* time — that's what proves the commands going into
the Jenkinsfile actually work in the environment Jenkins uses. It is not
mandatory on every later commit: once that parity is established, prefer
running the same auto-fix commands natively on the host when the installed
tool versions match what `Dockerfile.test` pins — see `code-quality`'s
"Native tools vs Docker for pre-commit auto-fix". Requiring a Docker build
for every routine commit is exactly the overhead a developer shouldn't
have to pay once the Jenkinsfile already exists and Dockerfile.test hasn't
changed.

Do not assume any auto-fixer, wherever it runs, can solve:
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

- On a tag build (`env.TAG_NAME` set), the Docker image version **must be
  the git tag itself**, not independently read from `package.json`/
  `pyproject.toml` — those are two different sources that can silently
  drift apart (confirmed in practice: a repo tagged `0.1.0` while
  `pyproject.toml` still said `0.2.0` pushed a Docker image tagged
  `0.2.0`, completely ignoring the tag that supposedly triggered the
  release). Read the version file for comparison, not as the source of
  truth for the pushed tag:
  ```groovy
  if (env.TAG_NAME) {
    if (env.BASE_VERSION != env.TAG_NAME) {
      error("Git tag (${env.TAG_NAME}) does not match pyproject.toml version (${env.BASE_VERSION}) — bump pyproject.toml to match the tag before releasing.")
    }
    env.VERSION = env.TAG_NAME
  } else if (env.BRANCH_NAME == 'main') {
    env.VERSION = env.BASE_VERSION
  } else {
    env.VERSION = "${env.BASE_VERSION}-${env.SANITIZED_BRANCH}-${env.BUILD_NUMBER}-${env.GIT_SHA_SHORT}"
  }
  ```
  Failing loudly on a mismatch turns a silent mis-tagged release into an
  immediate, fixable build failure — it also catches the human error
  (forgetting to bump the version file before tagging) at the moment it
  happens rather than after a wrong image is already on Docker Hub.
- For branch builds (no tag), derive the version from the project's
  source-of-truth file (`package.json`, `pyproject.toml`, etc.), appending
  branch/build metadata if the existing release flow expects it.
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

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
   - the repository's actual default branch (`git remote show origin |
     grep 'HEAD branch'`, or `gh repo view --json defaultBranchRef`) —
     don't assume `main`; plenty of EEA repos still default to `master`,
     and getting this wrong means every "default branch" check in the
     generated Jenkinsfile (the Docker Hub release gate, the `:latest`
     tag, the untagged-`IMAGE_TAG` fallback) silently never fires
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
  the git tag itself, unconditionally** — not independently read from
  `package.json`/`pyproject.toml`, and not gated on the two agreeing. The
  git tag is the actual thing a developer asked to release; the version
  file is a secondary signal that's useful to cross-check but not
  authoritative enough to block a release over. Treat a mismatch as a
  **warning, not a hard failure** — plenty of legitimate cases produce
  one deliberately: alpha/beta/rc pre-releases, a `v`-prefixed tag
  convention (`v1.2.3` vs a version file that just says `1.2.3`), or a
  version file that's intentionally not bumped until some other
  release-automation step runs. Failing the build in those cases would
  block a perfectly intentional release:
  ```groovy
  if (env.TAG_NAME) {
    env.VERSION = env.TAG_NAME
    def normalizedTag = env.TAG_NAME.replaceFirst(/^v/, '')
    if (env.BASE_VERSION != env.TAG_NAME && env.BASE_VERSION != normalizedTag) {
      echo "WARNING: git tag (${env.TAG_NAME}) does not match pyproject.toml version (${env.BASE_VERSION}) — pushing ${env.VERSION} anyway. Bump pyproject.toml to match if this wasn't intentional."
      currentBuild.result = 'UNSTABLE'
    }
  } else if (env.BRANCH_NAME == env.DEFAULT_BRANCH) {
    env.VERSION = env.BASE_VERSION
  } else {
    env.VERSION = "${env.BASE_VERSION}-${env.SANITIZED_BRANCH}-${env.BUILD_NUMBER}-${env.GIT_SHA_SHORT}"
  }
  ```
  `env.DEFAULT_BRANCH` is a hardcoded literal set in the `environment {}`
  block from the repository's actual default branch — checked via `git
  remote show origin` or the GitHub API in Phase 1, never assumed to be
  `main` (plenty of EEA repos still default to `master`).
  `currentBuild.result = 'UNSTABLE'` still surfaces the mismatch loudly
  (yellow build, visible in GitHub Checks and email notifications)
  without blocking the release the developer explicitly asked for by
  pushing the tag — this turns a silent mis-tagged surprise into a
  visible-but-non-blocking signal instead of an outright failure.
- For branch builds (no tag), derive the version from the project's
  source-of-truth file (`package.json`, `pyproject.toml`, etc.), appending
  branch/build metadata if the existing release flow expects it — this
  value is still useful for things like `sonar.projectVersion`, just not
  for what gets pushed to Docker Hub (see below).
- **A version-numbered Docker tag must correspond to an actual release
  (a git tag), never a plain branch build.** Confirmed as a real bug in
  practice: a Jenkinsfile that unconditionally pushes
  `$DOCKERHUB_REPOSITORY:$VERSION` on every default-branch build ends up
  pushing e.g. `0.1.0` on the *first* merge that happens to carry that
  version string in `package.json`/`pyproject.toml` — well before `0.1.0`
  is actually tagged/released. Push the version tag only when
  `env.TAG_NAME` is set; push `:latest` on default-branch builds instead
  (`:latest` means "newest build of the default branch," not "newest
  release" — those can differ):
  ```groovy
  if (env.TAG_NAME) {
    docker.tag(RELEASE_IMAGE, "${DOCKERHUB_REPOSITORY}:${env.TAG_NAME}")
    // push the version tag
  }
  if (env.BRANCH_NAME == env.DEFAULT_BRANCH) {
    docker.tag(RELEASE_IMAGE, "${DOCKERHUB_REPOSITORY}:latest")
    // push :latest
  }
  ```
  The `when` clause gating the whole release stage also needs
  `buildingTag()` alongside the default-branch check — otherwise a tag
  build never reaches this stage at all and the `env.TAG_NAME` branch
  above is dead code:
  ```groovy
  when {
    anyOf {
      expression { env.BRANCH_NAME == env.DEFAULT_BRANCH }
      buildingTag()
    }
  }
  ```
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

---

<!-- BEGIN EEA-OVERRIDES -->
# EEA-Specific Overrides
<!-- EEA-Overrides-Version: 1.2 -->
<!-- Last-Sync: 2026-07-31 -->

## EEA Trivy severity gate

Gate the build on `CRITICAL` findings only, not `HIGH,CRITICAL`. A
`HIGH,CRITICAL` gate is noisy in practice — a real scan of a
`python:3.11-slim` (Debian trixie) release image turned up 33 `HIGH` findings
in base-OS packages the repository owner has no control over, on top of the
`CRITICAL` ones. `HIGH` should stay visible, not block the pipeline.

Still generate a `HIGH,CRITICAL` report and archive it as a build artifact so
`HIGH` findings stay visible, but only the `CRITICAL`-severity scan should set
the stage's exit code.

**Most repos have no `.trivyignore` yet — this is the common case.** When
there's no `.trivyignore` to get into the scan container, use a plain
`docker run --rm` for each scan:

```groovy
stage('Trivy test') {
  steps {
    sh '''
      mkdir -p trivy-reports
      docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
        "$TRIVY_IMAGE" image --no-progress --format table --severity HIGH,CRITICAL \
        "$RELEASE_IMAGE" | tee trivy-reports/trivy-image.txt
    '''
    archiveArtifacts artifacts: 'trivy-reports/*.txt', fingerprint: true, allowEmptyArchive: false

    sh '''
      docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
        "$TRIVY_IMAGE" image --no-progress --severity CRITICAL --exit-code 1 \
        "$RELEASE_IMAGE"
    '''
  }
}
```

Only reach for the more complex pattern below once the repository actually
has a `.trivyignore` (for CVEs that are accepted risk — e.g. no fixed version
published upstream yet — with a comment explaining why): pass it to *both*
scans via `--ignorefile` so accepted findings don't reappear in the report or
fail the gate. Because `.trivyignore` lives in the checked-out workspace and
the trivy container can't see it via a bind mount (see the
Docker-outside-of-Docker constraint below), get it in with `docker create` +
`docker cp` + `docker start` instead of the plain `docker run --rm` above —
the same way any other workspace file has to reach a spawned container here:

```groovy
stage('Trivy test') {
  steps {
    sh '''
      mkdir -p trivy-reports

      docker create --name "$TRIVY_CONTAINER" \
        -v /var/run/docker.sock:/var/run/docker.sock \
        "$TRIVY_IMAGE" image --no-progress --format table --severity HIGH,CRITICAL \
        --ignorefile /tmp/.trivyignore --output /tmp/trivy-image.txt "$RELEASE_IMAGE"
      docker cp .trivyignore "$TRIVY_CONTAINER":/tmp/.trivyignore
      docker start -a "$TRIVY_CONTAINER" || true
      docker cp "$TRIVY_CONTAINER":/tmp/trivy-image.txt trivy-reports/trivy-image.txt
      docker rm -v "$TRIVY_CONTAINER"
    '''
    archiveArtifacts artifacts: 'trivy-reports/*.txt', fingerprint: true, allowEmptyArchive: false

    sh '''
      docker create --name "$TRIVY_GATE_CONTAINER" \
        -v /var/run/docker.sock:/var/run/docker.sock \
        "$TRIVY_IMAGE" image --no-progress --severity CRITICAL --exit-code 1 \
        --ignorefile /tmp/.trivyignore "$RELEASE_IMAGE"
      docker cp .trivyignore "$TRIVY_GATE_CONTAINER":/tmp/.trivyignore
      docker start -a "$TRIVY_GATE_CONTAINER"
      status=$?
      docker rm -v "$TRIVY_GATE_CONTAINER"
      exit $status
    '''
  }
}
```

The first block never fails the stage (`|| true` on the scan itself) — it
only produces the full report for the archived artifact. The second block is
the actual gate and only fails on `CRITICAL`. Archive before the gating call
so the report is still available if the build fails.

Validated CVE example: a scan turned up 4 `CRITICAL` findings, all in
`perl-base` on Debian trixie (`CVE-2026-13221`, `CVE-2026-42496`,
`CVE-2026-57433`, `CVE-2026-8376`), none with a fixed version published by
Debian. Since `python:3.11-slim` was already on the latest Debian release, no
Dockerfile version bump could resolve them — the right move was documenting
them in `.trivyignore` with a reason (unfixed upstream, `perl-base` isn't
part of the app's own code path) rather than loosening the gate further or
leaving the build red waiting on an upstream patch.

## EEA plugin/step constraint

Declarative pipeline validates `options {}` entries and plugin-provided steps
against whatever is actually installed on the target Jenkins controller — an
invalid one fails at parse time, before any stage runs. Do not add any
`options {}` entry, wrapper step, or symbol unless it is a Jenkins pipeline
core step or it appears in `references/eea-available-plugins.md`.

This is a real, previously-hit failure: an earlier draft of this skill added
`options { ansiColor('xterm') }` to color console output, and the target
controller has no AnsiColor plugin installed, so the pipeline failed
immediately with `invalid option type "ansiColor"`. `ansiColor` is not in
`references/eea-available-plugins.md` — never add it. If a capability isn't
covered by core Jenkins or that reference file, leave it out and ask the user
to confirm the plugin is installed before using it, rather than guessing.

## EEA Docker-outside-of-Docker constraint

EEA `docker-host` Jenkins agents run Docker-outside-of-Docker: the agent only
has `/var/run/docker.sock` forwarded to the real dockerd, not the
filesystem. Any `sh` step in the generated Jenkinsfile that calls `docker`
is really talking to a daemon on a different filesystem than `$WORKSPACE`.

Concretely:
- `docker build .` and `docker cp <container>:<path> <host-path>` work,
  because the build context is streamed and `docker cp` operates through
  the Docker API against the container's own filesystem — neither depends
  on the *daemon* being able to see a path on the *agent's* disk.
- `docker run -v "$WORKSPACE:/somewhere"` (or any bind mount of a path under
  `$WORKSPACE`) does not work. `$WORKSPACE` is a path inside the Jenkins
  agent, not a real path on the host the dockerd lives on. Docker's fallback
  for a bind-mount source that doesn't exist on that host is to silently
  create an empty directory and mount that — so every step inside the
  spawned container that looks for a file under the mount sees an empty
  directory, not an error about the mount itself. This is exactly what
  produced `ruff check ... -> E902 No such file or directory (os error 2)`
  for every path argument in an early generated pipeline: `-v
  "$WORKSPACE:/workspace"` mounted nothing, so ruff found nothing.

Rules for anything this skill generates:
- Never bind-mount `$WORKSPACE` (or any subpath of it) into a spawned
  container with `-v`. This applies to lint, unit test, and integration
  test stages alike, whether the mount is meant to feed source in or pull
  reports/fixtures out.
- To run checks against repository source inside a container, rely on the
  copy `Dockerfile.test` already baked into the image via `COPY . .`
  (`WORKDIR /app` in the EEA `Dockerfile.test` contract) — do not try to
  re-supply source via a mount.
- To pull JUnit/coverage/report files out of a container, run it with a
  deterministic `--name` (no `--rm`), then `docker cp
  <container-name>:<path-in-image> <path-in-workspace>` after the run, then
  clean up with `docker rm -v <container-name>` in a `finally`/`post` block
  — the same pattern the Sonarqube/versioning stages already use
  successfully.
- To feed a small input file into a container that needs it (e.g. a test
  fixture), use `docker create --name <x> <image>`, then `docker cp
  <fixture> <x>:<path-that-already-exists-in-the-image>` (e.g. `/tmp/...`,
  not a path that requires creating a new directory first), then `docker
  start <x>`. Do not rely on a bind mount for this either.
- Capture exit codes with `sh(returnStatus: true, ...)` rather than letting
  a failing `docker run` throw immediately — otherwise the `docker cp`
  calls that pull out JUnit/coverage results never run when tests fail, and
  Jenkins silently reports zero test results instead of the real failures.

## EEA Jenkinsfile shape

For EEA projects, generated Jenkinsfiles should preserve this outer structure exactly unless the repository owner explicitly asks otherwise:

```groovy
pipeline {
  agent {
    node { label 'docker-host' }
  }

  environment {


  }

  stages {


  }
  post {
    always {
      cleanWs(cleanWhenAborted: true, cleanWhenFailure: true, cleanWhenNotBuilt: true, cleanWhenSuccess: true, cleanWhenUnstable: true, deleteDirs: true)
    }
    changed {
      script {
        def details = """<h1>${env.JOB_NAME} - Build #${env.BUILD_NUMBER} - ${currentBuild.currentResult}</h1>
                         <p>Check console output at <a href="${env.BUILD_URL}/display/redirect">${env.JOB_BASE_NAME} - #${env.BUILD_NUMBER}</a></p>
                      """
        emailext(
        subject: '$DEFAULT_SUBJECT',
        body: details,
        attachLog: true,
        compressLog: true,
        recipientProviders: [[$class: 'DevelopersRecipientProvider'], [$class: 'CulpritsRecipientProvider']]
        )
      }
    }
  }
}
```

## EEA stage requirements

EEA Jenkins pipeline outputs should include these stages. No `Auto-fix code
style` stage — auto-fixing (`ruff check --fix`, `ruff format`, `black`,
`isort`, `prettier --write`) happens pre-commit, using the same commands
Jenkins' `Code linting` stage verifies with `--check`/no-`--fix` flags. See
the jenkins-pipeline `SKILL.md` "Pre-commit auto-fix, not a Jenkins stage"
section for why.

1. `Code linting`
   - one or more parallel sub-stages
   - examples: ESLint, Stylelint, Prettier, Ruff, Flake8, mypy
2. `Unit test`
   - run inside the Docker test image
   - export JUnit XML
   - export `coverage/lcov.info`
   - export `coverage/lcov-report/index.html`
   - publish both JUnit and HTML coverage in Jenkins
3. `Integration test`
   - start the application plus dependent services in Docker
   - run Playwright, Cypress, or equivalent tests
   - export JUnit XML
   - export `coverage/lcov.info` when available
   - publish results in Jenkins
4. `Sonarqube test`
   - pass sources, JUnit paths, and coverage paths to the scanner
5. `Trivy test`
   - scan the release image
6. `Versioning`
   - compute tags before release
7. `Release on Docker Hub`
   - authenticate with Jenkins credentials and push the release image
   - if the repository needs `arm64` alongside `amd64`, use the multi-arch
     buildx pattern instead of a plain `docker build`/`docker push` — see
     "EEA multi-arch Docker build and release" below
   - optionally followed by a Helm chart / Rancher catalog release stage —
     see "EEA Helm chart / Rancher catalog release stage" below; safe to
     add even before the repository has a chart yet

## EEA multi-arch Docker build and release

When finalizing a Jenkinsfile, ask the developer whether the release image
needs to run on `arm64` as well as `amd64` — don't silently decide either
way, and don't assume the developer already knows what these mean.
Explain them in plain terms when asking, since not every developer works
with CPU architectures day to day:

- **`amd64`** (aka `x86_64`) is the architecture almost all cloud servers
  and most developers' Windows/Linux machines use. **This is the default**
  — if nothing is said, build `amd64` only.
- **`arm64`** (aka `aarch64`) is the architecture Apple Silicon Macs
  (M1/M2/M3/M4+) use natively, and increasingly some cloud instances
  (e.g. AWS Graviton) and lower-power/edge hosts. Building for it too means
  the same image runs natively (no emulation) on those machines as well.

Only add `arm64` when there's an actual reason to (e.g. this is a Volto
add-on, the image needs to run on ARM-based production hosts, or
developers on Apple Silicon want native-speed local runs instead of
emulated `amd64`) — most EEA repos don't need it and should keep the plain
single-arch `docker build`/`docker push` pattern from the `Release on
Docker Hub` stage above. Make clear this isn't a now-or-never decision:
multi-arch support can be added later with no cost to not having it today
— it only touches the release stage, not anything earlier in the
pipeline.

Multi-platform images cannot be produced with the classic
`docker.build(...)` / `dockerImage.push()` Jenkins Docker Pipeline plugin
DSL — that only ever handles single-arch images. Multi-arch requires
`docker buildx` directly via `sh`, the same way the plain single-arch
release stage already authenticates with raw `docker login`/`docker
push`/`docker logout` rather than the `docker.withRegistry()` DSL.

### One-time-per-build-node setup (idempotent, safe to repeat every run)

```groovy
sh '''
  ls /proc/sys/fs/binfmt_misc/qemu-aarch64 2>/dev/null || docker run --privileged --rm tonistiigi/binfmt --install arm64
  docker buildx create --name "${IMAGE_NAME}-builder" --driver docker-container 2>/dev/null || true
  docker buildx use "${IMAGE_NAME}-builder"
'''
```

`tonistiigi/binfmt` registers QEMU emulation for `arm64` on the (typically
`amd64`) build node — check for it first rather than reinstalling every
run. The `buildx` builder instance is a small persistent container; create
it idempotently (`|| true`) and reuse it across builds rather than
removing it in cleanup — recreating it every run is wasted overhead, and
unlike test containers it holds no per-build state worth cleaning up.

### Fast sanity check: does it build for every platform? (no push, no load)

```groovy
stage('Multi-platform build check') {
  steps {
    sh '''
      ls /proc/sys/fs/binfmt_misc/qemu-aarch64 2>/dev/null || docker run --privileged --rm tonistiigi/binfmt --install arm64
      docker buildx create --name "${IMAGE_NAME}-builder" --driver docker-container 2>/dev/null || true
      docker buildx use "${IMAGE_NAME}-builder"
      docker buildx build --platform linux/amd64,linux/arm64 .
    '''
  }
}
```

Deliberately has no `-t`/`--push`/`--load` — `buildx` can't `--load` a
multi-platform result into the local image store at all (only single-arch
builds can be loaded locally), so this only ever validates that the
Dockerfile builds cleanly on every target platform, catching arm64-only
breakage (a dependency with no arm64 wheel/binary, an arch-specific base
image issue) before it reaches the actual release. Decide whether to run
it on every build (safer, but QEMU-emulated arm64 steps are meaningfully
slower than native) or only right before the release stage (cheaper, but
arm64 breakage surfaces later) — there's a real cost/coverage tradeoff
here, not a single right answer.

### Actual release: multi-arch build + push

```groovy
stage('Release on Docker Hub') {
  when {
    anyOf {
      buildingTag()
      expression { env.BRANCH_NAME == env.DEFAULT_BRANCH }
    }
  }
  steps {
    node(label: 'docker-big-jobs') {
      script {
        checkout scm
        // env.DEFAULT_BRANCH is a hardcoded literal set from the
        // repository's actual default branch (checked in Phase 1, never
        // assumed to be 'main' — plenty of EEA repos still use 'master').
        tagName = env.BRANCH_NAME == env.DEFAULT_BRANCH ? 'latest' : env.BRANCH_NAME
      }
      withCredentials([usernamePassword(credentialsId: 'jekinsdockerhub', usernameVariable: 'DOCKERHUB_USERNAME', passwordVariable: 'DOCKERHUB_PASSWORD')]) {
        sh '''
          ls /proc/sys/fs/binfmt_misc/qemu-aarch64 2>/dev/null || docker run --privileged --rm tonistiigi/binfmt --install arm64
          docker buildx create --name "${IMAGE_NAME}-builder" --driver docker-container 2>/dev/null || true
          docker buildx use "${IMAGE_NAME}-builder"
          echo "$DOCKERHUB_PASSWORD" | docker login -u "$DOCKERHUB_USERNAME" --password-stdin
          docker buildx build --platform linux/amd64,linux/arm64 -t "$registry:$tagName" --push .
          docker logout
        '''
      }
    }
  }
}
```

`--push` is mandatory here (the substitute for `--load`, since a
multi-platform result can't be loaded locally) — it assembles and pushes
the multi-arch manifest list directly to the registry in one step, so
there's no separate local image to `docker tag`/`docker push` afterward
the way the single-arch pattern does it. `node(label: 'docker-big-jobs')`
reflects that multi-arch builds (especially the QEMU-emulated `arm64` leg)
are meaningfully heavier than a native single-arch build — confirm the
actual node label with enough resources exists for this repo's Jenkins
setup rather than assuming `docker-big-jobs` is universal; a smaller/busier
label may time out or starve other jobs.

## EEA Helm chart / Rancher catalog release stage

When finalizing a Jenkinsfile, ask the developer whether releases should
automatically update a Helm chart / Rancher catalog entry — don't decide
this silently either way. Make clear it can be added later with no cost to
skipping it now: the stage below is safe to add pre-emptively even before
a chart exists (see below), so there's no rush to decide up front.

```groovy
stage('Release helm chart (on tag)') {
  when {
    buildingTag()
  }
  steps {
    node(label: 'docker') {
      withCredentials([string(credentialsId: 'eea-jenkins-token', variable: 'GITHUB_TOKEN'), usernamePassword(credentialsId: 'jekinsdockerhub', usernameVariable: 'DOCKERHUB_USER', passwordVariable: 'DOCKERHUB_PASS')]) {
        sh '''docker pull eeacms/gitflow; docker run -i --rm --name="$BUILD_TAG-release" -e GIT_BRANCH="$BRANCH_NAME" -e GIT_NAME="$GIT_NAME" -e DOCKERHUB_REPO="$registry" -e GIT_TOKEN="$GITHUB_TOKEN" -e DOCKERHUB_USER="$DOCKERHUB_USER" -e DOCKERHUB_PASS="$DOCKERHUB_PASS" -e DEPENDENT_DOCKERFILE_URL="$DEPENDENT_DOCKERFILE_URL" -e RANCHER_CATALOG_PATHS="$template" -e GITFLOW_BEHAVIOR="RUN_ON_TAG" eeacms/gitflow'''
      }
    }
  }
}
```

Same `eeacms/gitflow` release tool used everywhere else in EEA pipelines
(see "EEA real-world pipeline examples" above), pointed at a Rancher
catalog template path via `RANCHER_CATALOG_PATHS` and gated to only run on
tag builds. This also updates **Rancher Fleet** files when they exist in
the repository — Fleet is Rancher's GitOps continuous-delivery mechanism
for the Rancher 2-managed Kubernetes clusters EEA runs, and `eeacms/gitflow`
keeps Fleet manifests in sync with the release the same way it keeps the
Helm/Rancher catalog entry in sync, with no separate stage or tool needed.

Safe to add **even when the repository has no Helm chart/Rancher catalog
template yet** — it's a no-op until one exists at that path, and adding
the stage preemptively means a chart can be added later with no further
Jenkinsfile changes. `jekinsdockerhub` and `eea-jenkins-token` are
confirmed real, working credential IDs — seen across multiple independent
real EEA Jenkinsfiles (`eea.docker.jenkins.master`, `eionet.xmlconv`) that
actually exercised this exact stage in production, unlike `dockerhub`,
which looked plausible but turned out not to exist as an actual credential
entry (`Could not find credentials entry with ID 'dockerhub'` the first
time a stage using it really ran — it had only ever been copied forward,
never exercised). Still confirm against the actual Jenkins instance/folder
before trusting either name blindly for a *new* org or credential scope.

### Adding a Helm chart to a repo that already has a Jenkinsfile

This can come from the other direction too: a developer might ask to add
a Helm chart (or Rancher Fleet files) to a repository, unrelated to any
Jenkinsfile work, on a repo that already has a working Jenkinsfile. Check
whether that Jenkinsfile already has a `Release helm chart` stage — if it
doesn't, proactively propose adding one now that there's an actual chart
for it to release, rather than leaving the developer to remember to come
back and wire up automation separately. This mirrors the badge-asking
pattern elsewhere in this skill: surface the option at the moment it
becomes relevant, don't wait to be asked.

## EEA Docker cleanup policy

EEA Jenkins jobs must not leave containers behind.

- After any `docker run --name ...` used for tests or services, explicitly remove the container with `docker rm -v`.
- If the container is still running, stop it first.
- Docker images do not need to be removed here because another cleanup job handles old images.
- Avoid anonymous leftover volumes by pairing named containers with `docker rm -v`.

## EEA artifact publishing snippets

Use this JUnit publication snippet:

```groovy
catchError(buildResult: 'SUCCESS', stageResult: 'SUCCESS') {
  junit testResults: 'xunit-reports-current/junit.xml', allowEmptyResults: true
}
```

Use this HTML coverage publication snippet:

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

## EEA SonarQube command pattern

Prefer the following structure and adapt only the repository-specific values:

```groovy
def scannerHome = tool 'SonarQubeScanner'
def nodeJS = tool 'NodeJS'
if (env.CHANGE_ID) {
  env.sonarParams = " -Dsonar.pullrequest.base=${env.CHANGE_TARGET} -Dsonar.pullrequest.branch=${env.CHANGE_BRANCH} -Dsonar.pullrequest.key=${env.CHANGE_ID} "
}
else {
  env.sonarParams = " -Dsonar.branch.name=${env.BRANCH_NAME}"
}
withSonarQubeEnv('Sonarqube') {
  sh '''sed -i "s#/app/src/addons/${GIT_NAME}/##g" xunit-reports-current/coverage/lcov.info'''
  sh '''sed -i "s#src/addons/${GIT_NAME}/##g" xunit-reports-current/coverage/lcov.info'''
  sh "export PATH=${scannerHome}/bin:${nodeJS}/bin:$PATH; sonar-scanner -Dsonar.javascript.lcov.reportPaths=./xunit-reports-current/coverage/lcov.info,./integration-reports-current/coverage/lcov.info -Dsonar.sources=./src -Dsonar.projectKey=$GIT_NAME -Dsonar.projectName=$GIT_NAME -Dsonar.projectVersion=\$(jq -r '.version' package.json) ${env.sonarParams}"
}
```

## EEA SonarQube PR decoration (GitHub DevOps Platform Integration)

`sonar.pullrequest.base`/`.branch`/`.key` (already in the pattern above)
only tell the *scanner* it's analyzing a PR — they do not make SonarQube
post anything back to GitHub. For the Quality Gate result to show up as a
GitHub check/status on the PR, the SonarQube *project* needs to be bound to
a GitHub DevOps Platform Integration. At EEA this integration is already
configured instance-wide under the name **`GitHubEEA`** — a project just
needs to be bound to it, once, via the `alm_settings/set_github_binding`
Web API endpoint (confirmed against SonarQube's own Java WS client source,
not guessed):

```groovy
sh '''
  curl -s -XPOST -u "${SONAR_AUTH_TOKEN}:" "${SONAR_HOST_URL}api/alm_settings/set_github_binding" \
    -d "almSetting=GitHubEEA" \
    -d "project=$GIT_NAME" \
    -d "repository=eea/$GIT_NAME" \
    -d "summaryCommentEnabled=true"
'''
```

- Required params: `almSetting` (the integration name, `GitHubEEA`),
  `project` (`sonar.projectKey`), `repository` (the GitHub repo). Optional:
  `summaryCommentEnabled`, `monorepo`.
- `repository` is expected as `owner/repo` (e.g. `eea/eea-ai-mission-aipossible`)
  by analogy with every other EEA integration that addresses a GitHub repo
  this way (Jenkins job paths, GitHub API itself) — SonarQube's own docs
  don't spell out the exact string format, so verify once against a real
  PR (does the check actually appear?) rather than trusting this blindly.
- Call it from inside `withSonarQubeEnv` (needs `$SONAR_AUTH_TOKEN` /
  `$SONAR_HOST_URL`), right alongside the `sonar-scanner` invocation. It's
  idempotent — safe to call on every build, the same way the existing
  `api/project_tags/set` calls already are in these pipelines — not a
  one-time manual step you have to remember to run separately.
- The CI token needs "Administer" permission on the SonarQube project for
  this call to succeed; if it 403s, either grant that permission to the
  token or do the binding once manually instead (Project Settings → General
  Settings → Pull Request Decoration in the SonarQube UI) — that always
  works regardless of the API detail above.
- This binding is separate from, and doesn't replace, the
  `sonar.pullrequest.*` scanner parameters — both are required together.

## EEA Quality Gate badge and recommendation

The Quality Gate pass/fail badge is a **separate endpoint** from the 6
measure badges above — it does not take a `metric=` parameter:

```markdown
[![Quality Gate](https://sonarqube.eea.europa.eu/api/project_badges/quality_gate?project=<repo>)](https://sonarqube.eea.europa.eu/dashboard?id=<repo>)
```

It also renders visually differently from every other badge here: the
Quality Gate badge is a large square icon (~94×71px), while the Jenkins
pipeline badge and all 6 measure badges are small flat single-line badges
(~20px tall). Don't interleave the Quality Gate badge into a line of flat
badges — it breaks the row's alignment and looks inconsistent. Put it on
its own line (first, since it's the headline pass/fail signal), then all
the flat badges — Pipeline plus whichever measure badges were chosen —
together on one shared line, since they're visually consistent with each
other:

```markdown
[![Quality Gate](https://sonarqube.eea.europa.eu/api/project_badges/quality_gate?project=<repo>)](https://sonarqube.eea.europa.eu/dashboard?id=<repo>)

[![Pipeline](...)](...)
[![Coverage](...)](...)
[![Duplications](...)](...)
[![Security Hotspots](...)](...)
[![Maintainability](...)](...)
[![Reliability](...)](...)
[![Security](...)](...)
```

Recommendation on Quality Gates generally: gate on **New Code** conditions
(0 new bugs, 0 new vulnerabilities, new-code coverage above a threshold,
low new-code duplication) rather than absolute/overall-code thresholds.
This is SonarQube's own "Clean as You Code" default and it's the right fit
for any EEA repo with real legacy history — it stops new debt from being
added without demanding a retroactive cleanup of everything that came
before. Once PR decoration (above) is working, make the GitHub check a
required status check in the repo's branch protection rules — a Quality
Gate that's visible but not required doesn't actually block anything.

## EEA real-world pipeline examples

`references/examples/` holds full, real Jenkinsfiles from EEA repositories,
each covering a project shape this skill's default Docker-based template
doesn't fit well. EEA archives repositories rather than deleting them, so
these stay fetchable even for old/inactive projects — but re-fetch the
source URL in each file before trusting details as current practice, since
the source repo may have evolved since these were captured.

Consult the closest-matching one when the repository being worked on isn't
a straightforward Docker-based JS/Python app with its own `Dockerfile.test`
(this skill's default assumption) — read the example's "When to reach for
this one" section first to confirm it actually fits before borrowing from
it:

- `references/examples/python-egg-plone-jenkinsfile.md` — a Python package
  released as a PyPI/internal egg (Plone add-on style), tested via
  standalone per-tool `eeacms/<tool>` images instead of a project-owned
  test image.
- `references/examples/java-maven-jenkinsfile.md` — a Java/Maven WAR
  application, using Jenkins `tools { maven; jdk }` instead of a
  Dockerfile.test, JaCoCo coverage, and `mvn sonar:sonar`.
- `references/examples/nodejs-volto-jenkinsfile.md` — a Volto (React/Plone
  frontend) add-on that must test against multiple core-framework versions
  in parallel and run a full Cypress integration suite against a real
  backend.
- `references/examples/docker-helm-release-jenkinsfile.md` — a repository
  that's just a Dockerfile plus a Rancher/Helm catalog template, with
  nothing to build or test before release — the whole pipeline is one
  tag-triggered release stage.

All four share `eeacms/gitflow` as the standard EEA release-automation
tool regardless of language/stack — reach for it whenever a project needs
version bumping, changelog generation, or tag/PR-driven release logic, the
same way `mission-aipossible`'s own Jenkinsfile does for Docker Hub
releases.

## EEA README badges (ask proactively, don't add unasked)

Once the Jenkinsfile is finalized, proactively ask whether the developer
wants README CI/quality badges — see "EEA cross-skill routing" below for
when in the workflow this happens and why (badges need a working Jenkins
job path and Sonar project key, which only exist once the pipeline is
written). Don't wait for the developer to bring it up unprompted — most
won't know this convention exists — but never add badges without an
explicit yes, and never apply a fixed template. It's a conversation.

**Check the README for existing badges first.** Before asking anything
else, look for markdown image links pointing at
`ci.eionet.europa.eu/buildStatus` or
`sonarqube.eea.europa.eu/api/project_badges` already in the README. If any
exist:
- Tell the developer what's already there (which ones, for which
  branch/job).
- Ask whether to keep them alongside whatever gets added now, replace them
  entirely, or leave the README's badges untouched — don't default to
  appending new badges next to old ones without asking; that produces
  duplicate or redundant badge rows nobody wanted.
- If the developer's request already says "regenerate", "replace", or
  "redo" the badges, treat that as the answer — remove every existing
  recognized badge first, then add the newly-chosen set. No need to ask
  the replace-vs-keep question again in that case, since they already
  answered it.

Once badges are wanted (new or replacing), ask:

1. Do they want badges in the README at all, and for which branch(es)? Ask
   this explicitly rather than assuming the current branch — and if the
   current branch is a short-lived feature/PR branch that will be merged
   and deleted, say so as part of the question: badges pinned to it will
   look frozen or broken once it's gone (see "Only ever point badges at
   the default branch" below for why), so it's usually not what they want
   unless they're only checking the badges render correctly before the
   merge. Default to just the repository's default branch unless they
   explicitly want a non-default branch too.
2. Do they want a Jenkins pipeline badge? If yes, use this confirmed
   pattern (image URL uses `%2F`-joined path segments; the link target uses
   literal `/job/<segment>/job/<segment>/...` path segments — these are two
   different URL shapes for the same job):

   ```markdown
   [![Pipeline](https://ci.eionet.europa.eu/buildStatus/icon?job=<org-folder>%2F<repo>%2F<branch>&subject=<branch>)](https://ci.eionet.europa.eu/view/Github/job/<org-folder>/job/<repo>/job/<branch>/display/redirect)
   ```

   `<org-folder>` is the Jenkins/GitHub-org folder the job lives under
   (`EEA-AI` for AI applications; other project families use other org
   folders) — confirm it from an existing working job URL for that
   repository rather than guessing. `<repo>` is the GitHub repo name and
   `<branch>` is the branch this specific job runs.

3. If they want SonarQube badges, ask **which** they want — do not add all
   of them by default, and do not silently pick a subset. Seven are
   available: 6 measure badges plus the Quality Gate badge (see "EEA
   Quality Gate badge and recommendation" above for that one — it's a
   different endpoint shape, no `metric=` param).

   | Badge | `metric` value |
   |---|---|
   | Coverage | `coverage` |
   | Duplications | `duplicated_lines_density` |
   | Security Hotspots | `security_hotspots` |
   | Maintainability | `sqale_rating` |
   | Reliability | `reliability_rating` |
   | Security | `security_rating` |

   `security_hotspots` (a hotspot **count**), not `security_hotspots_reviewed`
   (a %-reviewed metric that does not exist for this endpoint) — confirmed by
   the badge API itself: querying with `security_hotspots_reviewed` returns
   an HTTP 400 with the exact list of accepted `metric` values, and
   `security_hotspots_reviewed` is not in it. If a future check ever turns
   up a different accepted-metric list, trust that error response over this
   table — it's the actual server enforcing the value, not documentation
   that can drift.

   **All 7 must be individually choosable — never bundle or drop any of
   them to fit a tool's option limit.** A structured multi-select question
   UI commonly caps out at 4 selectable options; asking "which do you
   want" through one and stopping there silently produces exactly the
   bug this skill hit once already: 3 distinct rating badges (Reliability,
   Security, Maintainability) collapsed into a single "ratings" option,
   and Duplications and Security Hotspots dropped from the list
   entirely, without the developer ever seeing them as choices. If the
   available question tool caps out below 7 options, either:
   - split the ask into two batched multi-select questions (e.g. 4 badges
     in one, the remaining 3 in the next), so each stays individually
     selectable, or
   - enumerate the complete list of all 7 as plain text in the question
     itself (not just as option labels), so the developer sees every name
     even if only some are individually clickable, and can say "also add
     X" for whatever wasn't clickable.
   Do not silently decide that grouping several metrics under one label is
   good enough — the developer asked to see the full menu, not a
   pre-curated subset.

   Badge/link pattern for each chosen measure metric:

   ```markdown
   [![<Label>](https://sonarqube.eea.europa.eu/api/project_badges/measure?project=<repo>&metric=<metric>)](https://sonarqube.eea.europa.eu/dashboard?id=<repo>)
   ```

   `<repo>` here is `sonar.projectKey` from the Jenkinsfile's `sonar-scanner`
   invocation — often the same as the GitHub repo name, but read it from the
   actual Jenkinsfile rather than assuming.

### Only ever point badges at the default branch

A README's badges get merged into whatever branch is default. A badge
pinned to a feature branch (`&branch=some-feature`, or a Jenkins job path
for that branch) would keep showing that branch's frozen state forever once
merged — even after the branch is deleted — because the README itself
doesn't get re-templated per branch. If a developer wants a badge for a
specific non-default branch anyway (e.g. documenting a `develop` line
alongside `main` in the same README), that's their call to make explicitly —
just don't default to it or suggest it unprompted.

### Badges for a specific non-default branch (when the developer explicitly asks)

This only makes sense as a genuinely multi-branch README section — a
second row documenting a long-lived branch (`develop`, a release line)
alongside the default-branch row, the same dual-row convention seen in
older EEA READMEs (one row per branch, each with its own Jenkins job and
its own Sonar branch). It is not a substitute for the default-branch badge
on an otherwise single-branch README — see above for why that goes stale.

For that branch's row:
- SonarQube measure badge: add `&branch=<branch>` to **both** the badge
  image URL and its dashboard link:
  ```markdown
  [![<Label>](https://sonarqube.eea.europa.eu/api/project_badges/measure?project=<repo>&branch=<branch>&metric=<metric>)](https://sonarqube.eea.europa.eu/dashboard?id=<repo>&branch=<branch>)
  ```
  Same for the Quality Gate badge:
  ```markdown
  [![Quality Gate](https://sonarqube.eea.europa.eu/api/project_badges/quality_gate?project=<repo>&branch=<branch>)](https://sonarqube.eea.europa.eu/dashboard?id=<repo>&branch=<branch>)
  ```
- Jenkins pipeline badge: point at that branch's own job, using the
  existing pattern with `<branch>` filled in
  (`.../buildStatus/icon?job=<org-folder>%2F<repo>%2F<branch>&subject=<branch>`)
  — no separate pattern needed, the placeholder already supports this.
- The branch must actually have been analyzed by Jenkins with
  `sonar.branch.name=<branch>` at least once, or the badge shows "not
  found" the same way the unscoped default-branch badge does when `main`
  hasn't been analyzed yet — see below.
- Reserve this for long-lived branches, not throwaway feature/PR branches.
  A short-lived branch's Sonar data may eventually be cleaned up once the
  branch is inactive/deleted, at which point its badge would start
  showing "not found" again with no code change to explain why.

### SonarQube badges show "not found" until the default branch itself has been analyzed

An unscoped SonarQube badge URL (no `&branch=`) shows whatever the
project's designated **default branch** in Sonar has — not "the latest
analysis of any kind." If every Jenkins run so far only ever analyzed a
feature branch (`sonar.branch.name=<feature>`) or a pull request
(`sonar.pullrequest.key=...`), the default branch itself (typically `main`)
has no data yet, and the badge renders `Quality gate has not been found` /
`Measure has not been found` — confirmed directly by curling
`api/project_badges/quality_gate`/`measure` with and without `&branch=`:
without it, "not found"; with `&branch=<feature-branch-that-was-actually-analyzed>`,
real data. This is not a badge URL bug — the syntax is correct, there's
just nothing yet for the branch it's implicitly asking about.

This resolves itself the first time Jenkins runs directly on the default
branch (merging the PR that introduces the Jenkinsfile is normally what
does this). Tell the developer this explicitly when adding badges during
initial Jenkins setup: they will show "not found" until that first
default-branch build completes — that's expected, not a sign something is
broken.

## EEA cross-skill routing

Before finalizing a Jenkinsfile, cross-check every non-core step and `options {}` entry against `references/eea-available-plugins.md` (see "EEA plugin/step constraint" above).

When building or updating Jenkins pipelines with quality gates, also apply the `code-quality` skill and the `testing` skill. Use them to decide:
- which rules are safe to auto-fix
- which rules must remain hard gates
- whether a Ruff configuration contains non-fixable docstring debt that should not be treated as a mechanical cleanup problem
- what exact Docker commands developers should run locally to reproduce Jenkins

If the repository already fails its own lint, typing, or tests before the Jenkinsfile is written, route into `quality-fixes` first. The Jenkins skill should surface the expected failures, ask whether to repair them, and only then finalize the pipeline so the first push-triggered Jenkins run is less likely to fail.

Before finalizing the `Trivy test` stage, also apply `docker-expert`'s "Trivy CVE preflight for release Dockerfiles": build the release image locally, scan it for `CRITICAL` findings, fix what has a published fix, and add what doesn't to `.trivyignore` with a reason. Do this preflight the same way the lint/test preflight above works — surface what's found, fix or document it, and only then generate the Jenkinsfile's Trivy stage — so the first Jenkins run isn't the first time anyone learns the release image has an unresolved CRITICAL CVE.

Before generating the Jenkinsfile's release stages, ask whether multi-arch
(`arm64`, in addition to the `amd64` default — explain what these mean
rather than assuming the developer already knows) builds and/or a Helm
chart / Rancher Fleet release stage are wanted — see "EEA multi-arch
Docker build and release" and "EEA Helm chart / Rancher catalog release
stage" above. Make clear both can be added later with no cost to skipping
them now, so the developer doesn't feel pressured into a decision they
don't have the information for yet.

After the Jenkinsfile is finalized (Jenkins job path and `sonar.projectKey`
known), proactively ask the developer whether they want README CI/quality
badges added — don't wait for them to think to ask. A developer setting up
Jenkins for the first time generally won't know EEA has a badge convention
at all, but the badges genuinely can't be filled in with a working URL
until the pipeline exists (the Jenkins job path and Sonar project key they
need come directly from the Jenkinsfile you just wrote). See "EEA README
badges" above for the questions to ask once they say yes.

If a Jenkins build fails after the pipeline is already in place — not
during initial setup — see `references/diagnosing-failed-builds.md`: check
GitHub Check status via `gh` before asking the user to paste a console
log, then reproduce the failing stage's exact command locally rather than
guessing at a fix and waiting for the next CI run to confirm it.

<!-- END EEA-OVERRIDES -->

<!-- Merged Build: upstream SKILL.md + EEA-OVERRIDES.md -->
<!-- Auto-generated by scripts/build.sh - DO NOT EDIT DIRECTLY -->
<!-- Source: https://github.com/eea/eea.agent.skills -->

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
`ruff format`, `black`, `isort`, `prettier --write` — inside the same
`Dockerfile.test` image Jenkins will use, using the exact same commands,
then rerun the check). By the time a Jenkinsfile is generated, the code
should already be clean; `Code linting` in Jenkins is a **strict, read-only
verification** of that (`--check` flags, no `--fix`), not a second chance
to fix things. A lint failure in Jenkins means the pre-commit auto-fix step
was skipped or a check exists that isn't mechanically fixable — not
something for the pipeline itself to repair.

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
the stage's exit code. If the repository has a `.trivyignore` (for CVEs that
are accepted risk — e.g. no fixed version published upstream yet — with a
comment explaining why), pass it to *both* scans via `--ignorefile` so
accepted findings don't reappear in the report or fail the gate. Because
`.trivyignore` lives in the checked-out workspace and the trivy container
can't see it via a bind mount (see the Docker-outside-of-Docker constraint
below), get it in with `docker create` + `docker cp` + `docker start`, the
same way any other workspace file has to reach a spawned container here:

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
so the report is still available if the build fails. If the repository has
no `.trivyignore`, drop `--ignorefile` and the two `docker cp .trivyignore
...` lines and use a plain `docker run --rm` for each scan instead of
create/cp/start.

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
explicit yes, and never apply a fixed template. It's a conversation. Once
they say yes, ask:

1. Do they want badges in the README at all, and for which branch(es)?
   Default to just the repository's default branch unless they say
   otherwise — see why below.
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
   | Security Hotspots Reviewed | `security_hotspots_reviewed` |
   | Maintainability | `sqale_rating` |
   | Reliability | `reliability_rating` |
   | Security | `security_rating` |

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

## EEA cross-skill routing

Before finalizing a Jenkinsfile, cross-check every non-core step and `options {}` entry against `references/eea-available-plugins.md` (see "EEA plugin/step constraint" above).

When building or updating Jenkins pipelines with quality gates, also apply the `code-quality` skill and the `testing` skill. Use them to decide:
- which rules are safe to auto-fix
- which rules must remain hard gates
- whether a Ruff configuration contains non-fixable docstring debt that should not be treated as a mechanical cleanup problem
- what exact Docker commands developers should run locally to reproduce Jenkins

If the repository already fails its own lint, typing, or tests before the Jenkinsfile is written, route into `quality-fixes` first. The Jenkins skill should surface the expected failures, ask whether to repair them, and only then finalize the pipeline so the first push-triggered Jenkins run is less likely to fail.

Before finalizing the `Trivy test` stage, also apply `docker-expert`'s "Trivy CVE preflight for release Dockerfiles": build the release image locally, scan it for `CRITICAL` findings, fix what has a published fix, and add what doesn't to `.trivyignore` with a reason. Do this preflight the same way the lint/test preflight above works — surface what's found, fix or document it, and only then generate the Jenkinsfile's Trivy stage — so the first Jenkins run isn't the first time anyone learns the release image has an unresolved CRITICAL CVE.

After the Jenkinsfile is finalized (Jenkins job path and `sonar.projectKey`
known), proactively ask the developer whether they want README CI/quality
badges added — don't wait for them to think to ask. A developer setting up
Jenkins for the first time generally won't know EEA has a badge convention
at all, but the badges genuinely can't be filled in with a working URL
until the pipeline exists (the Jenkins job path and Sonar project key they
need come directly from the Jenkinsfile you just wrote). See "EEA README
badges" above for the questions to ask once they say yes.

<!-- END EEA-OVERRIDES -->

<!-- Merged Build: upstream SKILL.md + EEA-OVERRIDES.md -->
<!-- Auto-generated by scripts/build.sh - DO NOT EDIT DIRECTLY -->
<!-- Source: https://github.com/eea/eea.agent.skills -->

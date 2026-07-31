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

## Required workflow

1. Inspect the repository and identify:
   - package manager / build tool
   - lint commands
   - unit test commands
   - integration / e2e test commands
   - coverage output capabilities
   - Docker build context and release image details
2. If `Dockerfile.test` does not exist, use `docker-expert` to create it before writing the pipeline.
3. Load and apply the `code-quality` skill mindset when deciding which checks belong in auto-fix, strict lint, typing, unit-test, and integration-test stages.
4. Load and apply the `testing` skill mindset so Jenkins uses the same Docker-based test commands that developers can run locally.
5. Before authoring the Jenkinsfile, run the repository's current quality and test commands through the same dependency path you plan to use for CI.
6. If those checks already fail, report exactly which commands and files will fail in Jenkins.
7. Ask the user whether they want those failures repaired before the Jenkinsfile is generated. If yes, switch into the `quality-fixes` workflow and repair the repository first.
8. Only after the preflight state is understood should you generate a declarative `Jenkinsfile` using the EEA pipeline shell from `references/eea-jenkinsfile-template.md`.
9. Keep one concern per stage. Prefer more small stages instead of one large stage.
10. Run all code-quality and test commands inside Docker containers created from `Dockerfile.test`.
11. Add an `Auto-fix code style` stage before strict linting when the repository benefits from safe mechanical rewrites.
12. Ensure every non-`--rm` test container is explicitly removed with `docker rm -v` in `finally` / `post` cleanup logic.
13. Keep Docker images available after the job finishes; do not add `docker rmi` unless the repository explicitly requires it.

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

EEA Jenkins pipeline outputs should include these stages:

0. `Auto-fix code style` (recommended when the repository has safe mechanical rewrites)
   - examples: `ruff check --fix`, `ruff format`, `black`, `isort`, `prettier --write`
   - keep this separate from strict linting
   - if fixes are made inside a container, ensure they land back in the workspace before later stages run
   - prefer exposing the same Docker auto-fix command to developers locally instead of auto-committing from Jenkins
   - on pull-request or branch builds, prefer a patch artifact or explicit failure message instead of silently mutating the source branch
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

## EEA reference implementation

When choosing patterns for test container lifecycle, result publishing, or SonarQube wiring, align with the Jenkinsfile used by `eea/volto-addon-template`.

Before finalizing a Jenkinsfile, cross-check every non-core step and `options {}` entry against `references/eea-available-plugins.md` (see "EEA plugin/step constraint" above).

## EEA cross-skill routing

When building or updating Jenkins pipelines with quality gates, also apply the `code-quality` skill and the `testing` skill. Use them to decide:
- which rules are safe to auto-fix
- which rules must remain hard gates
- whether a Ruff configuration contains non-fixable docstring debt that should not be treated as a mechanical cleanup problem
- what exact Docker commands developers should run locally to reproduce Jenkins

If the repository already fails its own lint, typing, or tests before the Jenkinsfile is written, route into `quality-fixes` first. The Jenkins skill should surface the expected failures, ask whether to repair them, and only then finalize the pipeline so the first push-triggered Jenkins run is less likely to fail.

<!-- END EEA-OVERRIDES -->

<!-- Merged Build: upstream SKILL.md + EEA-OVERRIDES.md -->
<!-- Auto-generated by scripts/build.sh - DO NOT EDIT DIRECTLY -->
<!-- Source: https://github.com/eea/eea.agent.skills -->

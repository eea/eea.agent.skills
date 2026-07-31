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

## EEA README badges (opt-in, ask first)

Never add CI/quality badges to a README on your own initiative — this is
only ever done at the developer's request, and even then it's a
conversation, not a template to apply blindly. When a developer asks for
badges (or asks something like "can we add build/coverage badges"), ask:

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

3. If they want SonarQube badges, ask **which** of the following 6 they
   want — do not add all 6 by default, and do not silently pick a subset:

   | Badge | `metric` value |
   |---|---|
   | Coverage | `coverage` |
   | Duplications | `duplicated_lines_density` |
   | Security Hotspots Reviewed | `security_hotspots_reviewed` |
   | Maintainability | `sqale_rating` |
   | Reliability | `reliability_rating` |
   | Security | `security_rating` |

   Badge/link pattern for each chosen metric:

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

Before finalizing the `Trivy test` stage, also apply `docker-expert`'s "Trivy CVE preflight for release Dockerfiles": build the release image locally, scan it for `CRITICAL` findings, fix what has a published fix, and add what doesn't to `.trivyignore` with a reason. Do this preflight the same way the lint/test preflight above works — surface what's found, fix or document it, and only then generate the Jenkinsfile's Trivy stage — so the first Jenkins run isn't the first time anyone learns the release image has an unresolved CRITICAL CVE.

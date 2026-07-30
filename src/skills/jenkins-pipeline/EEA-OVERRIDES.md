# EEA-Specific Overrides
<!-- EEA-Overrides-Version: 1.1 -->
<!-- Last-Sync: 2026-07-30 -->

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

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

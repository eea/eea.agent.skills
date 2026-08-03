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
   - if the repository needs `arm64` alongside `amd64`, use the multi-arch
     buildx pattern instead of a plain `docker build`/`docker push` — see
     "EEA multi-arch Docker build and release" below
   - optionally followed by a Helm chart / Rancher catalog release stage —
     see "EEA Helm chart / Rancher catalog release stage" below; safe to
     add even before the repository has a chart yet

## EEA multi-arch Docker build and release

Only relevant when a repository's release image needs to run on `arm64`
as well as `amd64` (e.g. Volto add-ons, or images meant to run on
Apple Silicon dev machines or ARM-based production hosts) — most EEA
repos don't need this and should keep the plain single-arch
`docker build`/`docker push` pattern from the `Release on Docker Hub`
stage above.

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
      branch 'main'
    }
  }
  steps {
    node(label: 'docker-big-jobs') {
      script {
        checkout scm
        tagName = env.BRANCH_NAME == 'main' ? 'latest' : env.BRANCH_NAME
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
tag builds. Safe to add **even when the repository has no Helm
chart/Rancher catalog template yet** — it's a no-op until one exists at
that path, and adding the stage preemptively means a chart can be added
later with no further Jenkinsfile changes. `jekinsdockerhub` and
`eea-jenkins-token` are confirmed real, working credential IDs — seen
across multiple independent real EEA Jenkinsfiles
(`eea.docker.jenkins.master`, `eionet.xmlconv`) that actually exercised
this exact stage in production, unlike `dockerhub`, which looked plausible
but turned out not to exist as an actual credential entry (`Could not find
credentials entry with ID 'dockerhub'` the first time a stage using it
really ran — it had only ever been copied forward, never exercised). Still
confirm against the actual Jenkins instance/folder before trusting either
name blindly for a *new* org or credential scope.

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

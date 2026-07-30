# EEA Jenkins available plugins

Source of truth: [`eea/eea.docker.jenkins.master/plugins.txt`](https://github.com/eea/eea.docker.jenkins.master/blob/master/plugins.txt)
(refresh this file from there if the controller's plugin set changes).

Only use a pipeline step, `options {}` entry, or symbol if it is either:

1. A Jenkins pipeline **core** step (`sh`, `stage`, `steps`, `script`, `when`,
   `parallel`, `checkout scm`, `withCredentials`, `tool`, `catchError`,
   `archiveArtifacts`, `retry`, `timeout` block step, etc. — anything from
   `workflow-basic-steps` / `pipeline-model-definition` / `durable-task`), or
2. Backed by a plugin in the confirmed list below.

If it's neither, do not add it — drop it, or ask the user to confirm the
plugin is installed before using it. This is exactly how the skill's first
draft broke: it added `options { ansiColor('xterm') }` to color console
output, and the controller has no AnsiColor plugin, so the pipeline failed to
even start with `invalid option type "ansiColor"`. `ansiColor` is **not** in
the list below — do not add it.

## Confirmed available plugins (short names, from plugins.txt)

Docker / build: `docker-workflow`, `docker-plugin`, `docker-commons`, `docker-java-api`

SCM: `git`, `git-client`, `git-server`, `github`, `github-branch-source`, `github-api`, `github-checks`, `subversion`, `mercurial`, `cvs`

Pipeline core: `workflow-aggregator`, `workflow-api`, `workflow-basic-steps`, `workflow-cps`, `workflow-durable-task-step`, `workflow-job`, `workflow-multibranch`, `workflow-scm-step`, `workflow-step-api`, `workflow-support`, `pipeline-model-api`, `pipeline-model-definition`, `pipeline-model-extensions`, `pipeline-build-step`, `pipeline-github`, `pipeline-graph-analysis`, `pipeline-graph-view`, `pipeline-groovy-lib`, `pipeline-input-step`, `pipeline-milestone-step`, `pipeline-stage-step`, `pipeline-stage-tags-metadata`, `pipeline-stage-view`, `pipeline-rest-api`, `durable-task`, `branch-api`, `basic-branch-build-strategies`, `scm-api`, `structs`, `script-security`

Credentials / secrets: `credentials`, `credentials-binding`, `plain-credentials`, `ssh-credentials`, `ssh-agent`, `config-file-provider`

Notifications: `email-ext` (`emailext`), `slack`, `instant-messaging`, `jabber`

Test / coverage / quality reporting: `junit`, `htmlpublisher` (`publishHTML`), `coverage`, `warnings-ng`, `analysis-model-api`, `forensics-api`, `checks-api`, `jira`, `sonar` (`withSonarQubeEnv`, SonarQube scanner `tool`)

Workspace / build lifecycle: `ws-cleanup` (`cleanWs`), `copyartifact`, `build-timeout` (`timeout` wrapper option), `timestamper` (`timestamps()` wrapper option — this one IS available, unlike `ansiColor`), `throttle-concurrents`, `lockable-resources`, `build-history-manager`, `resource-disposer`, `disk-usage`

Auth / infra (not pipeline-facing, listed for completeness): `active-directory`, `ldap`, `role-strategy`, `matrix-auth`, `authorize-project`

Blue Ocean / UI (not pipeline-facing): `blueocean*`

Not present — do not use:
- `ansicolor` / `ansiColor` (caused the `invalid option type "ansiColor"` failure)
- Any plugin not listed above (e.g. Cobertura, Xvfb, HashiCorp Vault, Kubernetes plugin, Allure) unless the user confirms it was added to the controller after this file was last refreshed.

## When the list looks stale

If a generated Jenkinsfile needs a capability not covered here (e.g. a new
notifier, a different coverage format), ask the user to confirm it's
installed, or point them at re-fetching
`https://raw.githubusercontent.com/eea/eea.docker.jenkins.master/master/plugins.txt`
before relying on it.

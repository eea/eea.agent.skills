# EEA Docker/Helm-chart release-only pipeline example — eea.docker.jenkins.master

Source: `https://github.com/eea/eea.docker.jenkins.master/blob/master/Jenkinsfile`
(branch `master`). EEA repos are archived rather than deleted, so this
stays available even for old/inactive projects — re-fetch before treating
details as current practice, since the source repo may have moved on.

## When to reach for this one

A repository that is just a Dockerfile plus a Rancher/Helm catalog
template — no application source, no test suite, nothing to lint. The
entire pipeline is a single tag-triggered release stage. Reach for this
shape when a project genuinely has nothing to build/test before release
(e.g. an infrastructure image, a base image, a catalog template repo) —
not as a shortcut to skip quality gates on a project that does have
testable application code.

## Notable patterns worth borrowing

- No `agent` label restriction beyond `agent any` at the top and
  `node(label: 'docker')` inside the one real stage — appropriate only
  because there's nothing here that specifically needs Docker-in-Docker
  except the release step itself.
- Gated purely on `buildingTag()`, not `branch 'master'` — release happens
  only when a version tag is pushed, never on every merge to the default
  branch. Combine with the `eionet.xmlconv` Java example's identical
  `buildingTag()` gate when a project wants "release on tag" instead of
  "release on every master build."
- `eeacms/gitflow` again handles the actual release mechanics
  (`RANCHER_CATALOG_PATHS`, `GITFLOW_BEHAVIOR=RUN_ON_TAG`), consistent with
  every other EEA example pipeline — this is the standard EEA release tool
  regardless of language/stack.

## Full Jenkinsfile

```groovy
pipeline {
  environment {
    registry = "eeacms/jenkins-master"
    template = "templates/jenkins-master"
    GIT_NAME = "eea.docker.jenkins.master"
    dockerImage = ''
    tagName = ''
  }

  agent any

  stages {
    stage('Release') {
      when {
        buildingTag()
      }
      steps{
        node(label: 'docker') {
          withCredentials([string(credentialsId: 'eea-jenkins-token', variable: 'GITHUB_TOKEN'),  usernamePassword(credentialsId: 'jekinsdockerhub', usernameVariable: 'DOCKERHUB_USER', passwordVariable: 'DOCKERHUB_PASS')]) {
           sh '''docker pull eeacms/gitflow; docker run -i --rm --name="$BUILD_TAG"  -e GIT_BRANCH="$BRANCH_NAME" -e GIT_NAME="$GIT_NAME" -e DOCKERHUB_REPO="$registry" -e GIT_TOKEN="$GITHUB_TOKEN" -e DOCKERHUB_USER="$DOCKERHUB_USER" -e DOCKERHUB_PASS="$DOCKERHUB_PASS"  -e DEPENDENT_DOCKERFILE_URL="$DEPENDENT_DOCKERFILE_URL" -e RANCHER_CATALOG_PATHS="$template" -e GITFLOW_BEHAVIOR="RUN_ON_TAG" eeacms/gitflow'''
         }
        }
      }
    }

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

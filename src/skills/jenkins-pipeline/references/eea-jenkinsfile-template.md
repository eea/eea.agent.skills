# EEA Jenkinsfile template

Use this as the baseline declarative structure for EEA repositories.

```groovy
pipeline {
  agent {
    node { label 'docker-host' }
  }

  environment {
    // Hardcoded literal, not env.JOB_BASE_NAME — on a Multibranch Pipeline
    // job that resolves to the *branch* name, not the repo name (confirmed
    // against both the real eionet.xmlconv Java pipeline, which hardcodes
    // it for the same reason, and eea-ai-mission-aipossible's real working
    // Jenkinsfile, which hardcodes its image basenames outright rather
    // than deriving them from any Jenkins env var). Getting this wrong is
    // silent until a release build runs on the branch this stage is gated
    // on and pushes to e.g. "eeacms/main" instead of the real repo name.
    GIT_NAME = "your-repo-name"
    // Hardcoded literal too, checked via `git remote show origin` or the
    // GitHub API in Phase 1 — never assume 'main'; plenty of EEA repos
    // still default to 'master'.
    DEFAULT_BRANCH = "main"
    IMAGE_NAME = BUILD_TAG.toLowerCase()
    TEST_IMAGE = "${IMAGE_NAME}-test"
    RELEASE_IMAGE = "${GIT_NAME}:${env.BUILD_NUMBER}"
    DOCKERHUB_IMAGE = "yourorg/${GIT_NAME}"
  }

  stages {
    stage('Checkout') {
      steps {
        checkout scm
      }
    }

    stage('Versioning') {
      steps {
        script {
          env.APP_VERSION = sh(script: "jq -r '.version' package.json", returnStdout: true).trim()
          // On a tag build, the image tag is always the git tag itself,
          // unconditionally — never gated on matching package.json. A
          // mismatch is only a warning: alpha/beta/rc pre-releases, a
          // v-prefixed tag convention, or a version file that's
          // deliberately not bumped until later are all legitimate, and
          // hard-failing would block a release the developer explicitly
          // asked for by pushing the tag.
          if (env.TAG_NAME) {
            env.IMAGE_TAG = env.TAG_NAME
            def normalizedTag = env.TAG_NAME.replaceFirst(/^v/, '')
            if (env.APP_VERSION != env.TAG_NAME && env.APP_VERSION != normalizedTag) {
              echo "WARNING: git tag (${env.TAG_NAME}) does not match package.json version (${env.APP_VERSION}) — pushing ${env.IMAGE_TAG} anyway. Bump package.json to match if this wasn't intentional."
              currentBuild.result = 'UNSTABLE'
            }
          } else {
            env.IMAGE_TAG = "${env.APP_VERSION}-${env.BRANCH_NAME}-${env.BUILD_NUMBER}"
          }
        }
      }
    }

    stage('Build test image') {
      steps {
        sh '''docker build --pull -f Dockerfile.test -t $TEST_IMAGE .'''
      }
    }

    // No 'Auto-fix code style' stage here — auto-fixing (ruff check --fix,
    // black, etc.) happens pre-commit, using the same commands this stage
    // verifies with --check/no-fix flags. See the jenkins-pipeline SKILL.md
    // "Pre-commit auto-fix, not a Jenkins stage" section.
    stage('Code linting') {
      parallel {
        stage('ESLint') {
          steps {
            sh '''docker run --rm --name="${IMAGE_NAME}-lint-eslint" $TEST_IMAGE npm run lint'''
          }
        }
        stage('Prettier') {
          steps {
            sh '''docker run --rm --name="${IMAGE_NAME}-lint-prettier" $TEST_IMAGE npm run prettier:check'''
          }
        }
      }
    }

    stage('Unit test') {
      steps {
        script {
          try {
            sh '''rm -rf xunit-reports-current && mkdir -p xunit-reports-current'''
            sh '''docker run --name="${IMAGE_NAME}-unit" $TEST_IMAGE npm run test:ci'''
            sh '''docker cp ${IMAGE_NAME}-unit:/app/junit.xml xunit-reports-current/junit.xml'''
            sh '''docker cp ${IMAGE_NAME}-unit:/app/coverage xunit-reports-current/coverage'''
            publishHTML(target : [
              allowMissing: false,
              alwaysLinkToLastBuild: true,
              keepAll: true,
              reportDir: 'xunit-reports-current/coverage/lcov-report',
              reportFiles: 'index.html',
              reportName: 'UTCoverage',
              reportTitles: 'Unit Tests Code Coverage'
            ])
          } finally {
            catchError(buildResult: 'SUCCESS', stageResult: 'SUCCESS') {
              junit testResults: 'xunit-reports-current/junit.xml', allowEmptyResults: true
            }
            sh script: '''docker rm -v ${IMAGE_NAME}-unit''', returnStatus: true
          }
        }
      }
    }

    stage('Build release image') {
      steps {
        sh '''docker build --pull -t $RELEASE_IMAGE .'''
      }
    }

    stage('Integration test') {
      steps {
        script {
          try {
            sh '''rm -rf integration-reports-current && mkdir -p integration-reports-current'''
            sh '''docker run -d --name="${IMAGE_NAME}-db" postgres:16-alpine'''
            sh '''docker run -d --name="${IMAGE_NAME}-app" --link ${IMAGE_NAME}-db:db $TEST_IMAGE npm run start:ci'''
            sh '''docker exec ${IMAGE_NAME}-app npm run wait-for-app'''
            sh '''docker exec ${IMAGE_NAME}-app npm run test:integration:ci'''
            sh '''docker cp ${IMAGE_NAME}-app:/app/integration-junit.xml integration-reports-current/junit.xml'''
            sh script: '''docker cp ${IMAGE_NAME}-app:/app/coverage integration-reports-current/coverage''', returnStatus: true
            catchError(buildResult: 'SUCCESS', stageResult: 'SUCCESS') {
              junit testResults: 'integration-reports-current/**/*.xml', allowEmptyResults: true
            }
          } finally {
            sh script: '''docker stop ${IMAGE_NAME}-app''', returnStatus: true
            sh script: '''docker stop ${IMAGE_NAME}-db''', returnStatus: true
            sh script: '''docker rm -v ${IMAGE_NAME}-app''', returnStatus: true
            sh script: '''docker rm -v ${IMAGE_NAME}-db''', returnStatus: true
          }
        }
      }
    }

    stage('Sonarqube test') {
      steps {
        script {
          def scannerHome = tool 'SonarQubeScanner'
          def nodeJS = tool 'NodeJS'
          if (env.CHANGE_ID) {
            env.sonarParams = " -Dsonar.pullrequest.base=${env.CHANGE_TARGET} -Dsonar.pullrequest.branch=${env.CHANGE_BRANCH} -Dsonar.pullrequest.key=${env.CHANGE_ID} "
          } else {
            env.sonarParams = " -Dsonar.branch.name=${env.BRANCH_NAME}"
          }
          withSonarQubeEnv('Sonarqube') {
            sh "export PATH=${scannerHome}/bin:${nodeJS}/bin:$PATH; sonar-scanner -Dsonar.javascript.lcov.reportPaths=./xunit-reports-current/coverage/lcov.info,./integration-reports-current/coverage/lcov.info -Dsonar.sources=./src -Dsonar.testExecutionReportPaths=./xunit-reports-current/junit.xml,./integration-reports-current/junit.xml -Dsonar.projectKey=$GIT_NAME -Dsonar.projectName=$GIT_NAME -Dsonar.projectVersion=${env.APP_VERSION} ${env.sonarParams}"
          }
        }
      }
    }

    stage('Trivy test') {
      steps {
        sh '''mkdir -p trivy-reports'''
        sh '''trivy image --no-progress --format table --output trivy-reports/trivy-image.txt $RELEASE_IMAGE'''
        archiveArtifacts artifacts: 'trivy-reports/*.txt', fingerprint: true, allowEmptyArchive: false
      }
    }

    stage('Release on Docker Hub') {
      when {
        allOf {
          environment name: 'CHANGE_ID', value: ''
          anyOf {
            expression { env.BRANCH_NAME == env.DEFAULT_BRANCH }
            buildingTag()
          }
        }
      }
      steps {
        // 'jekinsdockerhub' is the credential ID confirmed across multiple
        // real EEA Jenkinsfiles (eea.docker.jenkins.master,
        // eionet.xmlconv) — not 'dockerhub', which looked plausible but
        // isn't a real credential entry and fails with "Could not find
        // credentials entry with ID 'dockerhub'" the first time a stage
        // using it actually runs. Still confirm against the actual Jenkins
        // instance/folder rather than assuming either name is universal.
        withCredentials([usernamePassword(credentialsId: 'jekinsdockerhub', usernameVariable: 'DOCKERHUB_USERNAME', passwordVariable: 'DOCKERHUB_PASSWORD')]) {
          sh '''
            echo "$DOCKERHUB_PASSWORD" | docker login -u "$DOCKERHUB_USERNAME" --password-stdin
            # A version-numbered tag must correspond to an actual release
            # (a git tag) — pushing it on every plain branch build would
            # ship e.g. "1.2.0" before that version is actually tagged.
            # :latest tracks the newest default-branch build regardless.
            if [ -n "${TAG_NAME:-}" ]; then
              docker tag "$RELEASE_IMAGE" "$DOCKERHUB_IMAGE:$IMAGE_TAG"
              docker push "$DOCKERHUB_IMAGE:$IMAGE_TAG"
            fi
            if [ "$BRANCH_NAME" = "$DEFAULT_BRANCH" ]; then
              docker tag "$RELEASE_IMAGE" "$DOCKERHUB_IMAGE:latest"
              docker push "$DOCKERHUB_IMAGE:latest"
            fi
          '''
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

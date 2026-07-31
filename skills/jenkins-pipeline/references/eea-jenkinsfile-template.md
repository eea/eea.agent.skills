# EEA Jenkinsfile template

Use this as the baseline declarative structure for EEA repositories.

```groovy
pipeline {
  agent {
    node { label 'docker-host' }
  }

  environment {
    GIT_NAME = env.JOB_BASE_NAME
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
          env.IMAGE_TAG = env.BRANCH_NAME == 'master' ? env.APP_VERSION : "${env.APP_VERSION}-${env.BRANCH_NAME}-${env.BUILD_NUMBER}"
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
          branch 'master'
        }
      }
      steps {
        withCredentials([usernamePassword(credentialsId: 'dockerhub', usernameVariable: 'DOCKERHUB_USERNAME', passwordVariable: 'DOCKERHUB_PASSWORD')]) {
          sh '''echo "$DOCKERHUB_PASSWORD" | docker login -u "$DOCKERHUB_USERNAME" --password-stdin'''
          sh '''docker tag $RELEASE_IMAGE $DOCKERHUB_IMAGE:$IMAGE_TAG'''
          sh '''docker push $DOCKERHUB_IMAGE:$IMAGE_TAG'''
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

# EEA Java/Maven pipeline example — eionet.xmlconv

Source: `https://github.com/eea/eionet.xmlconv/blob/ConverterWorkerIntegrationMain/Jenkinsfile`
(branch `ConverterWorkerIntegrationMain`). EEA repos are archived rather
than deleted, so this stays available even for old/inactive projects —
re-fetch before treating details as current practice, since the source
repo may have moved on.

## When to reach for this one

A Java/Maven web application (WAR artifact) packaged into a Docker image
and released to a Rancher catalog template, rather than a Docker-based
Node/Python test flow. Distinctive vs. the Dockerfile.test-based pattern
this skill defaults to:

- Uses declarative `tools { maven 'maven3'; jdk 'Java17' }` instead of a
  project-owned `Dockerfile.test` — the build/test/quality tooling all
  comes from Jenkins tool installations, not a container image.
- Quality gates (PMD, Checkstyle, SpotBugs) and unit/failsafe tests all run
  through a single `mvn ... verify pmd:pmd pmd:cpd spotbugs:spotbugs
  checkstyle:checkstyle` invocation rather than separate parallel stages.
- Coverage uses the Warnings-NG `recordCoverage` step reading a JaCoCo XML
  report, not `junit`/`publishHTML` — a different coverage-publishing
  mechanism than the JS/Python pattern this skill defaults to.
- SonarQube is invoked via `mvn sonar:sonar` (the Maven Sonar plugin) rather
  than the standalone `sonar-scanner` CLI, and coverage import uses
  `sonar.coverage.jacoco.xmlReportPaths` (JaCoCo XML), not Cobertura/LCOV.
- Docker build/push and the Rancher-catalog release both happen directly in
  the main pipeline (build+push on every non-PR build with the branch name
  as the tag; the `eeacms/gitflow` release stage is gated on
  `buildingTag()` rather than `branch 'master'` — i.e. release happens when
  a version tag is pushed, not on every master merge).
- Computes free ports at pipeline-environment-evaluation time via inline
  `python3` one-liners (`environment { availableport = sh(...) }`) for
  integration tests that need to bind local ports — a pattern worth
  reusing whenever a test stage needs a guaranteed-free port and can't rely
  on a fixed one.

## Full Jenkinsfile

```groovy
pipeline {
  agent {
            node { label "docker-host" }
  }

  environment {
    GIT_NAME = "eionet.xmlconv"
    SONARQUBE_TAGS = "converters.eionet.europa.eu"
    registry = "eeacms/xmlconv"
    dockerImage = ''
    tagName = ''
    convertersTemplate = "templates/converters"
    availableport = sh(script: 'echo $(python3 -c \'import socket; s=socket.socket(); s.bind(("", 0)); print(s.getsockname()[1], end = ""); s.close()\');', returnStdout: true).trim();
    availableport2 = sh(script: 'echo $(python3 -c \'import socket; s=socket.socket(); s.bind(("", 0)); print(s.getsockname()[1], end = ""); s.close()\');', returnStdout: true).trim();
    availableport3 = sh(script: 'echo $(python3 -c \'import socket; s=socket.socket(); s.bind(("", 0)); print(s.getsockname()[1], end = ""); s.close()\');', returnStdout: true).trim();

  }


  tools {
    maven 'maven3'
    jdk 'Java17'
  }

  stages {
    stage('Project Build') {
      steps {
        withCredentials([string(credentialsId: 'jenkins-maven-token', variable: 'GITHUB_TOKEN')]) {
          sh '''mkdir -p ~/.m2'''
          sh '''sed "s/TOKEN/$GITHUB_TOKEN/" m2.settings.tpl.xml > ~/.m2/settings.xml'''
          sh '''mvn clean -B -V verify -Dmaven.test.skip=true'''
        }
      }
      post {
          success {
          archiveArtifacts artifacts: 'target/*.war', fingerprint: true
                    }
      }
    }

    stage ('Unit Tests') {
      when {
        not { buildingTag() }
      }
      steps {
            sh '''mvn clean -B -V -P docker verify pmd:pmd pmd:cpd spotbugs:spotbugs checkstyle:checkstyle '''
      }
      post {
        always {
            junit 'target/failsafe-reports/*.xml'
            recordCoverage(tools: [[parser: 'JACOCO']],
               id: 'jacoco', name: 'JaCoCo Coverage',
               sourceCodeRetention: 'EVERY_BUILD',
               ignoreParsingErrors: true,
               qualityGates: [
                 [threshold: 5.0, metric: 'LINE', baseline: 'PROJECT', unstable: true],
                 [threshold: 5.0, metric: 'BRANCH', baseline: 'PROJECT', unstable: true]])
            publishHTML target:[
               allowMissing: false,
               alwaysLinkToLastBuild: false,
               keepAll: true,
               reportDir: 'target/site/jacoco',
               reportFiles: 'index.html',
               reportName: "Detailed Coverage Report"
            ]
        }
      }
    }
    stage ('Sonarqube') {
      when {
        not { buildingTag() }
      }
      tools {
             jdk 'Java17'
      }      
      steps {
                withSonarQubeEnv('Sonarqube') {
                    sh '''mvn sonar:sonar -Dsonar.java.source=11 -Dsonar.sources=src/main/java/ -Dsonar.test.exclusions=**/src/test/** -Dsonar.coverage.exclusions=**/src/test/** -Dsonar.java.checkstyle.reportPaths=target/checkstyle-result.xml -Dsonar.java.pmd.reportPaths=target/pmd.xml -Dsonar.coverage.jacoco.xmlReportPaths=target/site/jacoco/jacoco.xml -Dsonar.java.spotbugs.reportPaths=target/spotbugsXml.xml -Dsonar.host.url=${SONAR_HOST_URL} -Dsonar.token=${SONAR_AUTH_TOKEN} -Dsonar.java.binaries=target/classes -Dsonar.projectKey="${GIT_NAME}" -Dsonar.projectName="${GIT_NAME}" -Dsonar.branch.name="${GIT_BRANCH}" '''
                    sh '''try=2; while [ \$try -gt 0 ]; do curl -s -XPOST -u "${SONAR_AUTH_TOKEN}:" "${SONAR_HOST_URL}api/project_tags/set?project=${GIT_NAME}&tags=${SONARQUBE_TAGS}" > set_tags_result; if [ \$(grep -ic error set_tags_result ) -eq 0 ]; then try=0; else cat set_tags_result; echo "... Will retry"; sleep 60; try=\$(( \$try - 1 )); fi; done'''
                }
      }
    }
    stage ('Docker build and push') {
      when {
          environment name: 'CHANGE_ID', value: ''
      }
      steps {
        script{

                 if (env.BRANCH_NAME == 'master') {
                         tagName = 'latest'
                 } else {
                         tagName = "$BRANCH_NAME"
                 }
                 def date = sh(returnStdout: true, script: 'echo $(date "+%Y-%m-%dT%H%M")').trim()
                 dockerImage = docker.build("$registry:$tagName", "--no-cache .")
                 docker.withRegistry( '', 'eeajenkins' ) {
                          dockerImage.push()
                           dockerImage.push(date)
                 }
            }
      }
      post {
        always {
            sh "docker rmi $registry:$tagName | docker images $registry:$tagName"
        }
      }
    }

        stage('Release') {
          when {
            buildingTag()
          }
          steps{
            node(label: 'docker') {
              withCredentials([string(credentialsId: 'eea-jenkins-token', variable: 'GITHUB_TOKEN'),  usernamePassword(credentialsId: 'jekinsdockerhub', usernameVariable: 'DOCKERHUB_USER', passwordVariable: 'DOCKERHUB_PASS')]) {
               sh '''docker pull eeacms/gitflow; docker run -i --rm --name="$BUILD_TAG-release"  -e GIT_BRANCH="$BRANCH_NAME" -e GIT_NAME="$GIT_NAME" -e DOCKERHUB_REPO="$registry" -e GIT_TOKEN="$GITHUB_TOKEN" -e DOCKERHUB_USER="$DOCKERHUB_USER" -e DOCKERHUB_PASS="$DOCKERHUB_PASS"  -e RANCHER_CATALOG_PATHS="$convertersTemplate" -e GITFLOW_BEHAVIOR="RUN_ON_TAG" eeacms/gitflow'''
             }
            }
          }
        }
  }

post {
    always {
      cleanWs(cleanWhenAborted: true, cleanWhenFailure: true, cleanWhenNotBuilt: true, cleanWhenSuccess: true, cleanWhenUnstable: true, deleteDirs: true)

      script {
                def url = "${env.BUILD_URL}/display/redirect"
                def status = currentBuild.currentResult
                def subject = "${status}: Job '${env.JOB_NAME} [${env.BUILD_NUMBER}]'"
                def summary = "${subject} (${url})"
                def details = """<h1>${env.JOB_NAME} - Build #${env.BUILD_NUMBER} - ${status}</h1>
                                 <p>Check console output at <a href="${url}">${env.JOB_BASE_NAME} - #${env.BUILD_NUMBER}</a></p>
                              """

                def color = '#FFFF00'
                if (status == 'SUCCESS') {
                  color = '#00FF00'
                } else if (status == 'FAILURE') {
                  color = '#FF0000'
                }


                withCredentials([string(credentialsId: 'eworx-email-list', variable: 'EMAIL_LIST')]) {
                          emailext(
                          to: "$EMAIL_LIST",
                          subject: '$DEFAULT_SUBJECT',
                          body: details,
                          attachLog: true,
                          compressLog: true,
                          )
                }
      }
    }
  }

}
```

# EEA Python/Plone egg release pipeline — eea.genai.blocks

Source: `https://github.com/eea/eea.genai.blocks/blob/develop/Jenkinsfile`
(branch `develop`). EEA repos are archived rather than deleted, so this
stays available even for old/inactive projects — re-fetch before treating
details as current practice, since the source repo may have moved on.

## When to reach for this one

A Python package released as a PyPI/internal egg (Plone add-on style),
rather than a Docker-image-per-app release. Distinctive vs. the
Dockerfile.test-based pattern this skill defaults to:

- No `Dockerfile.test` at all — each tool (lint, test, i18n) runs from its
  own standalone `eeacms/<tool>` image, not a project-built test image.
- Auto-fix stages (`ruff format`, `ruff check`) commit and push straight
  back to the PR branch and then fail the build on purpose
  (`sh 'exit 1'`) to force a fresh CI run against the fixed commit, rather
  than just failing with a diagnostic.
- Release automation (versioning, changelog, PyPI + internal egg-repo
  publish) is delegated entirely to the `eeacms/gitflow` Docker image,
  driven by env vars — no manual version-bump/publish scripting in the
  Jenkinsfile itself.
- SonarQube coverage import needs a path-rewrite step
  (`sed -i 's|<source>/app</source>|<source>.</source>|g' coverage/coverage.xml`
  plus stripping the `src/<repo>/` prefix from `filename=`/`package name=`
  attributes) because the coverage.xml was generated inside a container
  where the source lived at a different path than the Sonar scan's project
  base dir — the same class of path-mismatch problem covered in the EEA
  Docker-outside-of-Docker constraint, just solved with `sed` instead of
  avoiding the mismatch.

## Notable patterns worth borrowing

- `eeacms/gitflow` for release automation when a project already follows
  git-flow (release from `master`, PRs must come from `develop`/`hotfix`).
- Splitting lint tools into their own single-purpose containers
  (`eeacms/jshint`, `eeacms/csslint`, `eeacms/jslint4java`, `eeacms/ruff`,
  `eeacms/i18ndude`) when there's no single project-owned test image to run
  them all from.
- Registering the project's SonarQube tags via the REST API
  (`api/project_tags/set`) directly from the pipeline, with a retry loop —
  useful when a project needs to appear in specific SonarQube portfolio
  tags/dashboards beyond what the scanner itself sets.

## Full Jenkinsfile

```groovy
pipeline {
  agent any

  environment {
        GIT_NAME = "eea.genai.blocks"
        SONARQUBE_TAGS = "demo-www.eea.europa.eu,www.eea.europa.eu-en,www.eea.europa.eu,biodiversity.europa.eu,industry.eea.europa.eu,forest.eea.europa.eu,demo-ied.eea.europa.eu,www.ied.eea.europa.eu-en,demo-water.devel5cph.eea.europa.eu-freshwater,water.europa.eu-freshwater"
    }

  stages {

    stage('Cosmetics') {
      steps {
        parallel(

          "JS Hint": {
            node(label: 'docker') {
              script {
                sh '''docker run -i --rm --name="$BUILD_TAG-jshint" -e GIT_SRC="https://github.com/eea/$GIT_NAME.git" -e GIT_NAME="$GIT_NAME" -e GIT_BRANCH="$BRANCH_NAME" -e GIT_CHANGE_ID="$CHANGE_ID" eeacms/jshint'''
              }
            }
          },

          "CSS Lint": {
            node(label: 'docker') {
              script {
                sh '''docker run -i --rm --name="$BUILD_TAG-csslint" -e GIT_SRC="https://github.com/eea/$GIT_NAME.git" -e GIT_NAME="$GIT_NAME" -e GIT_BRANCH="$BRANCH_NAME" -e GIT_CHANGE_ID="$CHANGE_ID" eeacms/csslint'''
              }
            }
          },

          "Ruff": {
            node(label: 'docker') {
              script {
                if (!(env.BRANCH_NAME != "master" && (env.CHANGE_ID == null || env.CHANGE_ID == ''))) {
                  return
                }
                checkout scm
                fix_result = sh(script: '''docker run --pull=always --name="$BUILD_TAG-ruff-fix" -e GIT_SRC="https://github.com/eea/$GIT_NAME.git" -e GIT_NAME="$GIT_NAME" -e GIT_BRANCH="$BRANCH_NAME" -e GIT_CHANGE_ID="$CHANGE_ID" eeacms/ruff format''', returnStatus: true)
                sh '''docker cp $BUILD_TAG-ruff-fix:/code/$GIT_NAME .'''
                sh '''cp -rf eea.genai.blocks/* .'''
                sh '''rm -rf eea.genai.blocks'''
                sh '''docker rm -v $BUILD_TAG-ruff-fix'''
                FOUND_FIX = sh(script: '''git diff --name-only '*.py' | wc -l''', returnStdout: true).trim()

                if (FOUND_FIX != '0') {
                  withCredentials([string(credentialsId: 'eea-jenkins-token', variable: 'GITHUB_TOKEN')]) {
                    sh '''sed -i "s|url = .*|url = https://eea-jenkins:$GITHUB_TOKEN@github.com/eea/$GIT_NAME.git|" .git/config'''
                  }
                  sh '''git fetch origin $GIT_BRANCH:$GIT_BRANCH'''
                  sh '''git checkout $GIT_BRANCH'''
                  sh '''git add -- '*.py' '''
                  sh '''git commit -m "style: Automated code fix" '''
                  sh '''git push --set-upstream origin $GIT_BRANCH'''
                  sh '''exit 1'''
                }
              }
            }
          }
        )
      }
    }

    stage('Code') {
      steps {
        parallel(

          "ZPT Lint": {
            node(label: 'docker') {
              sh '''docker run -i --rm --name="$BUILD_TAG-zptlint" -e GIT_BRANCH="$BRANCH_NAME" -e ADDONS="$GIT_NAME" -e DEVELOP="src/$GIT_NAME" -e GIT_CHANGE_ID="$CHANGE_ID" eeacms/plone-test:4 zptlint'''
            }
          },

          "JS Lint": {
            node(label: 'docker') {
              sh '''docker run -i --rm --name="$BUILD_TAG-jslint" -e GIT_SRC="https://github.com/eea/$GIT_NAME.git" -e GIT_NAME="$GIT_NAME" -e GIT_BRANCH="$BRANCH_NAME" -e GIT_CHANGE_ID="$CHANGE_ID" eeacms/jslint4java'''
            }
          },

          "Ruff": {
            node(label: 'docker') {
              script {
                if (!(env.BRANCH_NAME != "master" && (env.CHANGE_ID == null || env.CHANGE_ID == ''))) {
                  return
                }
                checkout scm
                fix_result = sh(script: '''docker run --pull=always --name="$BUILD_TAG-ruff-fix" -e GIT_SRC="https://github.com/eea/$GIT_NAME.git" -e GIT_NAME="$GIT_NAME" -e GIT_BRANCH="$BRANCH_NAME" -e GIT_CHANGE_ID="$CHANGE_ID" eeacms/ruff check''', returnStatus: true)
                sh '''docker cp $BUILD_TAG-ruff-fix:/code/$GIT_NAME .'''
                sh '''cp -rf eea.genai.blocks/* .'''
                sh '''rm -rf eea.genai.blocks'''
                sh '''docker rm -v $BUILD_TAG-ruff-fix'''
                FOUND_FIX = sh(script: '''git diff --name-only '*.py' | wc -l''', returnStdout: true).trim()

                if (FOUND_FIX != '0') {
                  withCredentials([string(credentialsId: 'eea-jenkins-token', variable: 'GITHUB_TOKEN')]) {
                    sh '''sed -i "s|url = .*|url = https://eea-jenkins:$GITHUB_TOKEN@github.com/eea/$GIT_NAME.git|" .git/config'''
                  }
                  sh '''git fetch origin $GIT_BRANCH:$GIT_BRANCH'''
                  sh '''git checkout $GIT_BRANCH'''
                  sh '''git add -- '*.py' '''
                  sh '''git commit -m "lint: Automated code fix" '''
                  sh '''git push --set-upstream origin $GIT_BRANCH'''
                  sh '''exit 1'''
                }
              }
            }
          },

          "i18n": {
            node(label: 'docker') {
              sh '''docker run -i --rm --name=$BUILD_TAG-i18n -e GIT_SRC="https://github.com/eea/$GIT_NAME.git" -e GIT_NAME="$GIT_NAME" -e GIT_BRANCH="$BRANCH_NAME" -e GIT_CHANGE_ID="$CHANGE_ID" eeacms/i18ndude'''
            }
          }
        )
      }
    }

    stage('Tests') {
      steps {
        parallel(
          "Plone6 & Python3": {
            node(label: 'docker') {
              sh '''docker run --pull="always" -i --name="$BUILD_TAG-tests" -e GIT_NAME="$GIT_NAME" -e GIT_BRANCH="$BRANCH_NAME" -e DEVELOP="src/$GIT_NAME" -e GIT_CHANGE_ID="$CHANGE_ID" eeacms/plone-test:6'''
              sh '''docker cp $BUILD_TAG-tests:/app/coverage ./coverage'''
              sh '''docker rm -v $BUILD_TAG-tests'''
              stash includes: 'coverage/**', name: 'coverage'
            }
          }
        )
      }
    }

    stage('Report to SonarQube') {
      when {
        allOf {
          environment name: 'CHANGE_ID', value: ''
        }
      }
      steps {
        node(label: 'swarm') {
          script {
            checkout scm
            unstash 'coverage'
            junit 'coverage/junit-results/testreports/*.xml'
            def scannerHome = tool 'SonarQubeScanner';
            def nodeJS = tool 'NodeJS11';
            sh "sed -i 's|<source>/app</source>|<source>.</source>|g' coverage/coverage.xml"
            sh "sed -i \"s|filename=\\\"src/$GIT_NAME/|filename=\\\"|g\" coverage/coverage.xml"
            sh "sed -i \"s|package name=\\\"src\\.$GIT_NAME|package name=\\\"|g\" coverage/coverage.xml"
            withSonarQubeEnv('Sonarqube') {
              sh "export PATH=$PATH:${scannerHome}/bin:${nodeJS}/bin; sonar-scanner -Dsonar.python.xunit.skipDetails=true -Dsonar.python.xunit.reportPath=coverage/junit-results/testreports/*.xml -Dsonar.python.coverage.reportPaths=coverage/coverage.xml -Dsonar.sources=./eea -Dsonar.exclusions=**/tests/**,**/setup.py  -Dsonar.projectKey=\"${GIT_NAME}\" -Dsonar.projectName=\"${GIT_NAME}\" -Dsonar.branch.name=\"${BRANCH_NAME}\""
              sh '''try=2; while [ \$try -gt 0 ]; do curl -s -XPOST -u "${SONAR_AUTH_TOKEN}:" "${SONAR_HOST_URL}api/project_tags/set?project=${GIT_NAME}&tags=${SONARQUBE_TAGS}" > set_tags_result; if [ \$(grep -ic error set_tags_result ) -eq 0 ]; then try=0; else cat set_tags_result; echo "... Will retry"; sleep 60; try=\$(( \$try - 1 )); fi; done'''
            }
          }
        }
      }
    }

    stage('Pull Request') {
      when {
        not {
          environment name: 'CHANGE_ID', value: ''
        }
        environment name: 'CHANGE_TARGET', value: 'master'
      }
      steps {
        node(label: 'docker') {
          script {
            if ( env.CHANGE_BRANCH != "develop" &&  !( env.CHANGE_BRANCH.startsWith("hotfix")) ) {
                error "Pipeline aborted due to PR not made from develop or hotfix branch"
            }
           withCredentials([string(credentialsId: 'eea-jenkins-token', variable: 'GITHUB_TOKEN')]) {
            sh '''docker run -i --rm --name="$BUILD_TAG-gitflow-pr" -e GIT_CHANGE_BRANCH="$CHANGE_BRANCH" -e GIT_CHANGE_AUTHOR="$CHANGE_AUTHOR" -e GIT_CHANGE_TITLE="$CHANGE_TITLE" -e GIT_TOKEN="$GITHUB_TOKEN" -e GIT_BRANCH="$BRANCH_NAME" -e GIT_CHANGE_ID="$CHANGE_ID" -e GIT_ORG="$GIT_ORG" -e GIT_NAME="$GIT_NAME" eeacms/gitflow'''
           }
          }
        }
      }
    }

    stage('Release') {
      when {
        allOf {
          environment name: 'CHANGE_ID', value: ''
          branch 'master'
        }
      }
      steps {
        node(label: 'docker') {
          withCredentials([[$class: 'UsernamePasswordMultiBinding', credentialsId: 'eea-jenkins', usernameVariable: 'EGGREPO_USERNAME', passwordVariable: 'EGGREPO_PASSWORD'],string(credentialsId: 'eea-jenkins-token', variable: 'GITHUB_TOKEN'),[$class: 'UsernamePasswordMultiBinding', credentialsId: 'pypi-jenkins', usernameVariable: 'PYPI_USERNAME', passwordVariable: 'PYPI_PASSWORD']]) { //betterleaks:allow
            sh '''docker run -i --rm --name="$BUILD_TAG-gitflow-master" -e GIT_BRANCH="$BRANCH_NAME" -e EGGREPO_USERNAME="$EGGREPO_USERNAME" -e EGGREPO_PASSWORD="$EGGREPO_PASSWORD" -e GIT_NAME="$GIT_NAME"  -e PYPI_USERNAME="$PYPI_USERNAME"  -e PYPI_PASSWORD="$PYPI_PASSWORD" -e GIT_ORG="$GIT_ORG" -e GIT_TOKEN="$GITHUB_TOKEN" eeacms/gitflow'''
          }
        }
      }
    }

  }

  post {
    changed {
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

        emailext (subject: '$DEFAULT_SUBJECT', to: '$DEFAULT_RECIPIENTS', body: details)
      }
    }
  }
}
```

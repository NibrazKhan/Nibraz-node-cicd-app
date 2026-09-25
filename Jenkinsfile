pipeline {

    /*
      Stages run on the Jenkins container by default, because it has
      the Docker CLI and Trivy installed.

      Node.js stages (Install Dependencies, Unit Testing, Dependency Scan)
      run inside a Node.js 16 container, as required by the assignment.
      reuseNode true keeps them in the same workspace so later stages
      see the same source code and node_modules.
    */
    agent any

    options {
        // Req 2a: keep build logs for the last 20 builds, artifacts for the last 10
        buildDiscarder(logRotator(numToKeepStr: '20', artifactNumToKeepStr: '10'))
        // Req 2c: timestamp every console line
        timestamps()
        // The explicit Checkout stage below does the checkout, so skip the hidden one
        skipDefaultCheckout(true)
    }

    triggers {
        // Req 1c: poll the repository roughly every 2 minutes
        pollSCM('H/2 * * * *')
    }

    environment {
        // DockerHub image name (must match YOUR Docker Hub account)
        IMAGE_NAME = "nibrazkhan/nibraz-node-app"
        // Image tag, defined once and reused by every stage
        IMAGE_TAG = "${BUILD_NUMBER}"
    }

    stages {

        /* Stage 1: Retrieve application source code from GitHub */
        stage('Checkout') {
            steps {
                echo '===== STAGE: CHECKOUT ====='
                checkout scm
            }
        }

        /* Stage 2: Install Node.js dependencies (Node.js 16 container) */
        stage('Install Dependencies') {
            agent {
                docker {
                    image 'node:16'
                    reuseNode true
                }
            }
            steps {
                echo '===== STAGE: BUILD - INSTALL DEPENDENCIES ====='
                sh '''
                    node --version
                    npm --version
                    npm install
                '''
            }
        }

        /* Stage 3: Run unit tests (Node.js 16 container) */
        stage('Unit Testing') {
            agent {
                docker {
                    image 'node:16'
                    reuseNode true
                }
            }
            steps {
                echo '===== STAGE: TEST ====='
                script {
                    if (fileExists('tests')) {
                        echo 'Running automated tests'
                        sh 'npm test'
                    } else {
                        echo 'No tests folder found. Skipping test execution.'
                    }
                }
            }
        }

        /*
          Stage 4: Dependency vulnerability scan with npm audit.
          Runs in the Node.js container because the Jenkins container has no npm.
          Results are shown in the console and as a Warnings NG report (Req 2d).
        */
        stage('Dependency Scan (npm audit)') {
            agent {
                docker {
                    image 'node:16'
                    reuseNode true
                }
            }
            steps {
                echo '===== STAGE: SECURITY SCAN - DEPENDENCIES (npm audit) ====='
                sh 'npm audit --json > npm-audit.json || true'
                // Human-readable summary in the console log (Req 2c)
                sh 'npm audit || true'
            }
            post {
                always {
                    recordIssues enabledForFailure: true,
                                 tools: [npmAudit(pattern: 'npm-audit.json')]
                }
            }
        }

        /* Stage 5: Build Docker image (Jenkins container, has Docker CLI) */
        stage('Build Docker Image') {
            steps {
                echo '===== STAGE: DOCKER IMAGE BUILD ====='
                sh '''
                    docker build \
                    -t ${IMAGE_NAME}:${IMAGE_TAG} .
                '''
            }
        }

        /*
          Stage 6: Scan the Docker image with Trivy.
          - table report  -> archived for review
          - JSON report   -> Warnings NG annotated report
          - gate scan     -> prints results to the console and fails the build
                             on fixable HIGH/CRITICAL findings
        */
        stage('Security Vulnerability Scan') {
            steps {
                echo '===== STAGE: SECURITY SCAN - DOCKER IMAGE (Trivy) ====='
                sh '''
                    trivy image \
                    --severity HIGH,CRITICAL \
                    --format table \
                    --output trivy-report.txt \
                    ${IMAGE_NAME}:${IMAGE_TAG}

                    trivy image \
                    --severity HIGH,CRITICAL \
                    --format json \
                    --output trivy-report.json \
                    ${IMAGE_NAME}:${IMAGE_TAG}

                    trivy image \
                    --severity HIGH,CRITICAL \
                    --exit-code 1 \
                    --ignore-unfixed \
                    ${IMAGE_NAME}:${IMAGE_TAG}
                '''
            }
            post {
                always {
                    recordIssues enabledForFailure: true,
                                 tools: [trivy(pattern: 'trivy-report.json')]
                }
            }
        }

        /* Stage 7: Push Docker image to DockerHub (credentials stored in Jenkins) */
        stage('Push Docker Image') {
            steps {
                echo '===== STAGE: DOCKER PUSH ====='
                withCredentials([
                    usernamePassword(
                        credentialsId: 'dockerhub-credentials',
                        usernameVariable: 'DOCKER_USERNAME',
                        passwordVariable: 'DOCKER_PASSWORD'
                    )
                ]) {
                    sh '''
                        echo "$DOCKER_PASSWORD" | docker login \
                        -u "$DOCKER_USERNAME" \
                        --password-stdin

                        docker push ${IMAGE_NAME}:${IMAGE_TAG}

                        docker tag ${IMAGE_NAME}:${IMAGE_TAG} ${IMAGE_NAME}:latest
                        docker push ${IMAGE_NAME}:latest
                    '''
                }
            }
        }
    }

    /* Pipeline completion status reporting */
    post {
        always {
            // Req 2b: archive reports in one place, even if the build fails
            archiveArtifacts artifacts: 'trivy-report.txt, trivy-report.json, npm-audit.json',
                             allowEmptyArchive: true,
                             fingerprint: true

            // Remove stored DockerHub login from the Jenkins container
            sh 'docker logout || true'
            echo 'Pipeline execution finished.'
        }
        success {
            echo 'CI/CD Pipeline completed successfully.'
        }
        failure {
            echo 'CI/CD Pipeline failed. Check console logs.'
        }
    }
}

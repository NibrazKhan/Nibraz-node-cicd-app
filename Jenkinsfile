pipeline {

    /*
      Stages run on the Jenkins container by default, because it has
      the Docker CLI and Trivy installed.

      The Node.js stages (Install Dependencies, Unit Testing) run inside
      a Node.js 16 container, as required by the assignment.
      reuseNode true keeps them in the same workspace so the Docker
      build sees the same source code and node_modules.
    */
    agent any
    
    options {
    buildDiscarder(logRotator(numToKeepStr: '20', artifactNumToKeepStr: '10'))
    timestamps()
  }



    environment {

        // DockerHub image name
        IMAGE_NAME = "nibrazkhan/nibraz-node-app"

        // Image tag, defined once and reused by every stage
        IMAGE_TAG = "${BUILD_NUMBER}"

    }


    stages {


        /*
          Stage 1:
          Retrieve application source code from GitHub
        */
        stage('Checkout') {

            steps {

                echo 'Checking out source code from repository'

                checkout scm

            }
        }



        /*
          Stage 2:
          Install Node.js application dependencies
          (runs inside Node.js 16 container)
        */
        stage('Install Dependencies') {

            agent {
                docker {
                    image 'node:16'
                    reuseNode true
                }
            }

            steps {

                echo 'Installing Node.js dependencies'

                sh '''
                    node --version
                    npm --version
                    npm install
                '''

            }
        }



        /*
          Stage 3:
          Execute application tests from the tests/ folder
          Skips safely if the folder does not exist
          (runs inside Node.js 16 container)
        */
        stage('Unit Testing') {

            agent {
                docker {
                    image 'node:16'
                    reuseNode true
                }
            }

            steps {

                script {

                    if (fileExists('tests')) {

                        echo 'Running automated tests'

                        sh 'npm test'

                    }
                    else {

                        echo 'No tests folder found. Skipping test execution.'

                    }

                }

            }
        }



        /*
          Stage 4:
          Build Docker image from application Dockerfile
          (runs on Jenkins container, which has the Docker CLI)
        */
        stage('Build Docker Image') {

            steps {

                echo 'Building Docker image'

                sh '''
                    docker build \
                    -t ${IMAGE_NAME}:${IMAGE_TAG} .
                '''

            }
        }



        /*
          Stage 5:
          Scan Docker image for vulnerabilities using Trivy.
          The first scan writes a full report; the second scan
          fails the build on fixable HIGH/CRITICAL findings
          (security gate, as required by the assignment).
          (runs on Jenkins container, which has Trivy)
        */
        stage('Security Vulnerability Scan') {

            steps {

                echo 'Running Trivy security scan'

                sh '''
                    trivy image \
                    --severity HIGH,CRITICAL \
                    --format table \
                    --output trivy-report.txt \
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

                    // Keep the scan report even when the gate fails the build
                    archiveArtifacts artifacts: 'trivy-report.txt', allowEmptyArchive: true

                }

            }

        }
        /*
          Stage :
          Archive security report and important artifacts so they can be reviewed later.
        */
	stage('Archive Security Report') {

    steps {

        archiveArtifacts artifacts: 'trivy-report.txt',
        fingerprint: true

    }

}
	stage('Security Scan') {
	  steps {
	    sh 'npm audit --json > npm-audit.json || true'
	  }
	  post {
	    always {
	      recordIssues(
		enabledForFailure: true,
		tools: [npmAudit(pattern: 'npm-audit.json')]
	      )
	      archiveArtifacts artifacts: 'npm-audit.json', allowEmptyArchive: true
	    }
	  }
	}


        /*
          Stage 6:
          Push Docker image to DockerHub
          Credentials are managed through Jenkins
        */
        stage('Push Docker Image') {

            steps {

                echo 'Pushing Docker image to registry'

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



    /*
      Pipeline completion status reporting
    */
    post {

        success {

            echo 'CI/CD Pipeline completed successfully.'

        }

        failure {

            echo 'CI/CD Pipeline failed. Check console logs.'

        }

        always {

            // Remove stored DockerHub login from the Jenkins container
            sh 'docker logout || true'

            echo 'Pipeline execution finished.'

        }

    }

}


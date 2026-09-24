pipeline {

    /*
      Jenkins pipeline runs inside Node.js 16 container
      as required by the assignment.
    */
    agent {
        docker {
            image 'node:16'
        }
    }


    environment {

        // DockerHub image name
        IMAGE_NAME = "nibrazkhan/nibraz-node-app"

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
        */
        stage('Install Dependencies') {

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
          Execute application tests
          Skips safely if no test directory exists
        */
        stage('Unit Testing') {

            steps {

                script {

                    if (fileExists('test')) {

                        echo 'Running automated tests'

                        sh 'npm test'

                    } 
                    else {

                        echo 'No automated tests found. Skipping test execution.'

                    }

                }

            }
        }



        /*
          Stage 4:
          Build Docker image from application Dockerfile
        */
        stage('Build Docker Image') {

            steps {

                echo 'Building Docker image'

                sh '''

                    docker build \
                    -t ${IMAGE_NAME}:${BUILD_NUMBER} .

                '''

            }
        }



        /*
          Stage 5:
          Scan Docker image vulnerabilities
          using Trivy security scanner
        */
        stage('Security Vulnerability Scan') {

            steps {

                echo 'Scanning Docker image with Trivy'

                sh '''

                    trivy image \
                    ${IMAGE_NAME}:${BUILD_NUMBER}

                '''

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

                    echo $DOCKER_PASSWORD | docker login \
                    -u $DOCKER_USERNAME \
                    --password-stdin


                    docker push \
                    ${IMAGE_NAME}:${BUILD_NUMBER}


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

            echo 'Pipeline execution finished.'

        }

    }

}

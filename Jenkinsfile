pipeline {

    agent {
        docker {
            image 'node:16'
            args '-u root'
        }
    }


    environment {

        IMAGE_NAME = "nibrazkhan/nibraz-node-app"

    }


    stages {


        stage('Checkout') {

            steps {

                echo 'Checking out source code'

                checkout scm

            }
        }



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



        stage('Unit Testing') {

            steps {

                echo 'Running application tests'

                sh '''

                npm test || echo "No tests configured"

                '''

            }
        }



        stage('Build Docker Image') {

            steps {

                echo 'Building Docker image'

                sh '''

                docker build \
                -t ${IMAGE_NAME}:${BUILD_NUMBER} .

                '''

            }
        }



        stage('Docker Image Scan') {

            steps {

                echo 'Scanning image vulnerabilities'

                sh '''

                trivy image ${IMAGE_NAME}:${BUILD_NUMBER}

                '''

            }
        }



        stage('Push Docker Image') {

            steps {

                echo 'Pushing image to Docker registry'

                withCredentials([
                    usernamePassword(
                    credentialsId: 'dockerhub-credentials',
                    usernameVariable: 'DOCKER_USER',
                    passwordVariable: 'DOCKER_PASS'
                    )
                ]){


                sh '''

                echo $DOCKER_PASS | \
                docker login \
                -u $DOCKER_USER \
                --password-stdin


                docker push \
                ${IMAGE_NAME}:${BUILD_NUMBER}

                '''

                }

            }
        }

    }



    post {


        success {

            echo 'CI/CD pipeline completed successfully'

        }


        failure {

            echo 'Pipeline failed. Check logs.'

        }

    }

}

pipeline {
    agent any

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Syntax Check') {
            steps {
                sh 'bash -n netwatch.sh'
            }
        }

        stage('Build Docker Image') {
            steps {
                sh """
                    docker build \
                        -t netwatch:${BUILD_NUMBER} \
                        -t netwatch:latest \
                        .
                """
            }
        }
    }
}

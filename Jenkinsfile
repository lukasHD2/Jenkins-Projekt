pipeline {
    agent any

    environment {
        VERSION = "1.0.${BUILD_NUMBER - 1}"
    }

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
                    docker build -t netwatch:${VERSION} .
                """
            }
        }

        stage('Create Latest Docker Image') {
            steps {
                sh """
                    docker tag \
                    netwatch:${VERSION} \
                    netwatch:latest
                """
            }
        }
    }

    post {

        success {
            echo 'Pipeline erfolgreich!'
            echo 'Docker-Image wurde erstellt.'
        }

        failure {
            echo 'Pipeline fehlgeschlagen!'
        }
    }
}

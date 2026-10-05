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

        stage('Tests') {
            steps {
                sh 'sh ./test.sh'
            }
        }

        stage('Build Docker Image') {
            steps {
                sh """
                    docker build -t netwatch:${BUILD_NUMBER} .
                """
            }
        }

        stage('Create Latest Docker Image') {
            steps {
                sh """
                    docker tag \
                    netwatch:${BUILD_NUMBER} \
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

pipeline {
    agent any

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Check files') {
            steps {
                sh 'docker build -t netwatch .'
            }
        }
    }
}

pipeline {
    agent any

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Run') {
            steps {
                sh 'sh netwatch.sh'
            }
        }
    }
}

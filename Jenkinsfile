pipeline {
    agent any

    environment {
        DOCKERHUB_CREDENTIALS_PSW = "dckr_pat_tVbAbr79-KEqsLo5C_6SBmIIGDg"
        DOCKERHUB_CREDENTIALS_USR = "ravneeth123"
        
        IMAGE_NAME = "ravneeth123/trend-react-app"
    }

    stages {
        

        stage('Build Docker Image') {
            steps {
                sh 'docker build -t $IMAGE_NAME .'
            }
        }

        stage('Push to DockerHub') {
            steps {
                sh '''
                echo $DOCKERHUB_CREDENTIALS_PSW | docker login -u $DOCKERHUB_CREDENTIALS_USR --password-stdin
                docker push $IMAGE_NAME
                '''
              }
        }

        stage('Deploy to Kubernetes') {
            steps {
                sh '''
                kubectl apply -f deployment.yaml
                kubectl apply -f service.yaml
                '''
            }
        }
    }
}

pipeline {
  agent any

  environment {
    IMAGE_NAME = "ravneeth123/trend-react-app"
    IMAGE_TAG = "v${BUILD_NUMBER}"
    AWS_REGION = "us-east-1"
    EKS_CLUSTER = "trend-apps-cluster"
  }

  stages {
    stage('Docker Build') {
      steps {
        script {
          sh 'docker build -t ${IMAGE_NAME}:${IMAGE_TAG} .'
        }
      }
    }

    stage('Docker Login & Push') {
      steps {
        withCredentials([usernamePassword(
          credentialsId: 'dockerhub-credentials',
          usernameVariable: 'DOCKER_USER',
          passwordVariable: 'DOCKER_PASS'
        )]) {
          sh '''
            echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin
            docker push ${IMAGE_NAME}:${IMAGE_TAG}
          '''
        }
      }
    }

    stage('Configure Kubeconfig') {
      steps {
        sh "aws eks --region ${AWS_REGION} update-kubeconfig --name ${EKS_CLUSTER}"
      }
    }

    stage('Kubernetes Deploy') {
      steps {
        sh '''
          sed -i "s|<IMAGE>|${IMAGE_NAME}:${IMAGE_TAG}|" k8s/deployment.yaml
          kubectl apply -f k8s/deployment.yaml
          kubectl apply -f k8s/service.yaml
        '''
      }
    }
  }

  post {
    success {
      echo '✅ Deployment complete!'
    }
    failure {
      echo '❌ Deployment failed!'
    }
  }
}

pipeline {
    agent any

    environment {
        DOCKER_IMAGE = "ravneeth123/trend-react-app:latest"
        DOCKER_CREDENTIALS_ID = 'dockerhub-credentials'
    }

    stages {
        stage('Clone Repository') {
            steps {
                git branch: 'main',
                    credentialsId: 'github-credentials',
                    url: 'https://github.com/ravneet12345/trendapp.git'
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    echo "🔧 Building Docker image..."
                    sh "docker build -t $DOCKER_IMAGE ."
                }
            }
        }

        stage('Login & Push to DockerHub') {
            steps {
                script {
                    echo "🔐 Logging into DockerHub and pushing image..."
                    docker.withRegistry('', DOCKER_CREDENTIALS_ID) {
                        sh "docker push $DOCKER_IMAGE"
                    }
                }
            }
        }

        stage('Deploy to EKS') {
            steps {
                script {
                    echo "🚀 Deploying to EKS cluster..."
                    sh '''
                        aws eks --region us-east-1 update-kubeconfig --name trend-apps-cluster
                        kubectl apply -f deployment.yaml
                        kubectl apply -f service.yaml
                        kubectl get svc
                    '''
                }
            }
        }
    }
}


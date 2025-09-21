pipeline {
    agent any
    parameters {
        choice(
            name: 'TF_OPERATION',
            choices: ['plan', 'apply', 'destroy'],
            description: 'Select Terraform operation to perform'
        )
    }
    environment {
        AWS_DEFAULT_REGION = 'us-east-1'
    }
    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }
        stage('Terraform Init') {
            steps {
                sh 'terraform init'
            }
        }
        stage('Terraform ${params.TF_OPERATION}') {
            steps {
                script {
                    if (params.TF_OPERATION == 'plan') {
                        sh 'terraform plan -out=tfplan'
                    } else if (params.TF_OPERATION == 'apply') {
                        sh 'terraform apply -auto-approve'
                    } else if (params.TF_OPERATION == 'destroy') {
                        sh 'terraform destroy -auto-approve'
                    }
                }
            }
        }
    }
    post {
        always {
            cleanWs()
        }
    }
}
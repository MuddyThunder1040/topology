pipeline {
    agent any
    
    parameters {
        choice(
            name: 'TF_OPERATION',
            choices: ['plan', 'apply', 'destroy'],
            description: 'Select Terraform operation'
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
        
        stage('Terraform ${params.TF_OPERATION}') {
            steps {
                withCredentials([
                    usernamePassword(
                        credentialsId: 'Aws-cli',
                        usernameVariable: 'AWS_ACCESS_KEY_ID',
                        passwordVariable: 'AWS_SECRET_ACCESS_KEY'
                    )
                ]) {
                    script {
                        if (params.TF_OPERATION == 'plan') {
                            sh 'terraform init'
                            sh 'terraform plan'
                        } else if (params.TF_OPERATION == 'apply') {
                            sh 'terraform init'
                            sh 'terraform apply -auto-approve'
                        } else if (params.TF_OPERATION == 'destroy') {
                            sh 'terraform init'
                            sh 'terraform destroy -auto-approve'
                        }
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
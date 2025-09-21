pipeline {
    agent any
    
    options {
        buildDiscarder(logRotator(numToKeepStr: '10'))
        timeout(time: 30, unit: 'MINUTES')
        timestamps()
        ansiColor('xterm')
        skipDefaultCheckout()
    }
    
    parameters {
        choice(
            name: 'TF_OPERATION',
            choices: ['plan', 'apply', 'destroy'],
            description: 'Select Terraform operation to perform'
        )
        choice(
            name: 'TF_WORKSPACE',
            choices: ['default', 'dev', 'staging', 'prod'],
            description: 'Select Terraform workspace'
        )
        booleanParam(
            name: 'AUTO_APPROVE',
            defaultValue: false,
            description: 'Auto-approve apply/destroy operations (use with caution)'
        )
        string(
            name: 'PLAN_FILE',
            defaultValue: 'tfplan',
            description: 'Name of the Terraform plan file'
        )
    }
    
    environment {
        AWS_DEFAULT_REGION = 'us-east-1'
        TF_IN_AUTOMATION = 'true'
        TF_INPUT = 'false'
        TF_LOG = 'INFO'
    }
    stages {
        stage('Checkout') {
            steps {
                echo "🔄 Checking out source code..."
                checkout scm
                echo "✅ Source code checked out successfully"
            }
        }
        
        stage('Terraform Validate') {
            steps {
                echo "🔍 Validating Terraform configuration..."
                sh '''
                    terraform fmt -check=true -diff=true
                    terraform validate
                '''
                echo "✅ Terraform configuration is valid"
            }
        }
        
        stage('Terraform Operations') {
            steps {
                withCredentials([
                    usernamePassword(
                        credentialsId: 'Aws-cli',
                        usernameVariable: 'AWS_ACCESS_KEY_ID',
                        passwordVariable: 'AWS_SECRET_ACCESS_KEY'
                    )
                ]) {
                    script {
                        // Terraform Init
                        echo "🚀 Initializing Terraform..."
                        sh '''
                            terraform init -input=false
                            terraform workspace select ${TF_WORKSPACE} || terraform workspace new ${TF_WORKSPACE}
                        '''
                        echo "✅ Terraform initialized successfully"
                        
                        // Terraform Operation
                        try {
                            if (params.TF_OPERATION == 'plan') {
                                echo "📋 Generating Terraform plan..."
                                sh "terraform plan -out=${params.PLAN_FILE} -input=false"
                                echo "✅ Terraform plan completed successfully"
                                
                            } else if (params.TF_OPERATION == 'apply') {
                                echo "🚀 Applying Terraform changes..."
                                if (params.AUTO_APPROVE) {
                                    sh "terraform apply -auto-approve -input=false"
                                } else {
                                    echo "⚠️  Manual approval required. Set AUTO_APPROVE to true for automatic approval."
                                    input message: 'Proceed with Terraform apply?', ok: 'Apply',
                                          submitterParameter: 'APPROVER'
                                    sh "terraform apply -auto-approve -input=false"
                                }
                                echo "✅ Terraform apply completed successfully"
                                
                            } else if (params.TF_OPERATION == 'destroy') {
                                echo "💥 Planning Terraform destroy..."
                                sh "terraform plan -destroy -out=${params.PLAN_FILE}-destroy -input=false"
                                
                                if (params.AUTO_APPROVE) {
                                    echo "⚠️  AUTO_APPROVE is enabled for DESTROY operation!"
                                    sh "terraform destroy -auto-approve -input=false"
                                } else {
                                    echo "🛑 DESTROY operation requires manual approval!"
                                    input message: 'Are you sure you want to DESTROY all resources? This action cannot be undone!', 
                                          ok: 'Yes, Destroy All Resources',
                                          submitterParameter: 'DESTROYER'
                                    sh "terraform destroy -auto-approve -input=false"
                                }
                                echo "💥 Terraform destroy completed"
                            }
                            
                        } catch (Exception e) {
                            error "❌ Terraform ${params.TF_OPERATION} failed: ${e.getMessage()}"
                        }
                    }
                }
            }
        }
        
        stage('Archive Artifacts') {
            when {
                anyOf {
                    equals expected: 'plan', actual: params.TF_OPERATION
                    equals expected: 'apply', actual: params.TF_OPERATION
                }
            }
            steps {
                script {
                    echo "📦 Archiving Terraform artifacts..."
                    try {
                        archiveArtifacts artifacts: '*.tfplan*, terraform.tfstate*, .terraform.lock.hcl', 
                                       fingerprint: true, 
                                       allowEmptyArchive: true
                        echo "✅ Artifacts archived successfully"
                    } catch (Exception e) {
                        echo "⚠️  Warning: Could not archive some artifacts: ${e.getMessage()}"
                    }
                }
            }
        }
    }
    post {
        always {
            echo "🧹 Cleaning up workspace..."
            script {
                // Display build summary
                def duration = currentBuild.durationString.replace(' and counting', '')
                echo """
                📊 Build Summary:
                ├─ Operation: ${params.TF_OPERATION}
                ├─ Workspace: ${params.TF_WORKSPACE}
                ├─ Duration: ${duration}
                ├─ Result: ${currentBuild.result ?: 'SUCCESS'}
                └─ Build: ${env.BUILD_NUMBER}
                """
            }
            cleanWs()
        }
        success {
            echo "✅ Pipeline completed successfully!"
            script {
                if (params.TF_OPERATION == 'apply') {
                    echo "🎉 Infrastructure changes have been applied successfully"
                } else if (params.TF_OPERATION == 'destroy') {
                    echo "💥 Infrastructure has been destroyed successfully"
                } else if (params.TF_OPERATION == 'plan') {
                    echo "📋 Terraform plan has been generated and is ready for review"
                }
            }
        }
        failure {
            echo "❌ Pipeline failed! Check the logs for more details."
            script {
                echo """
                🔍 Troubleshooting Tips:
                ├─ Check AWS credentials configuration
                ├─ Verify Terraform syntax and formatting
                ├─ Review the error messages above
                └─ Ensure proper permissions for the operation
                """
            }
        }
        unstable {
            echo "⚠️  Pipeline completed with warnings"
        }
        aborted {
            echo "🛑 Pipeline was aborted"
        }
    }
}
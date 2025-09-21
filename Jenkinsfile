pipeline {
    agent any
    stages {
        stage('Show IP Address') {
            steps {
                script {
                    if (isUnix()) {
                        sh 'hostname -I || ip addr show'
                    } else {
                        bat 'ipconfig'
                    }
                }
            }
        }
        stage('Show System Info') {
            steps {
                script {
                    if (isUnix()) {
                        sh 'uname -a && lsb_release -a || cat /etc/os-release'
                    } else {
                        bat 'systeminfo'
                    }
                }
            }
        }
    }
}
pipeline {
    agent any
    stages {
        stage('Show System Info') {
            steps {
                echo 'Operating System:'
                sh 'uname -a'
                echo 'CPU Info:'
                sh 'lscpu || cat /proc/cpuinfo'
                echo 'Memory Info:'
                sh 'free -h || cat /proc/meminfo'
                echo 'Disk Usage:'
                sh 'df -h'
            }
        }
        stage('Verify GitHub Access') {
            steps {
                echo 'Checking GitHub access...'
                sh 'git ls-remote https://github.com/github/git.git HEAD'
            }
        }
        stage('Verify AWS Access') {
            steps {
                echo 'Checking AWS access...'
                sh 'aws sts get-caller-identity'
            }
        }
    }
}
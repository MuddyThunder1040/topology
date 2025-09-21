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
    }
}
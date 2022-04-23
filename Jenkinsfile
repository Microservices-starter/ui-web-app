def getVersion(){
    def commitHash =  sh returnStdout: true, script: 'git rev-parse --short HEAD'
    return commitHash
}

pipeline{
    agent any

    options{
        buildDiscarder(logRotator(numToKeepStr: '30', artifactNumToKeepStr: '30'))
    }

    environment{
        GIT_COMMIT_HASH = getVersion()
        projectKey = "$project-ui"
        scannerHome = "${JENKINS_HOME}"

    }

    stages{
        stage("Code checkout"){
            steps{
                echo "[INFO] Checking out latest code from git"
                git branch: 'main', credentialsId: 'github', url: 'https://github.com/Microservices-starter/ui-web-app.git'  
            }
        }

        stage("Sonar analysis"){
            steps{
                echo "[INFO] Performing analysis with Sonarqube"
                script{
                    withSonarQubeEnv(credentialsId: 'sonartoken'){
                        sh "sudo ${scannerHome}/sonar-scanner/bin/sonar-scanner -Dsonar.projectKey=$project-ui"
                    }
                }
            }

        }

        stage("Quality Gates"){
            steps{
                echo "[INFO] Verifying Quality gates"
                timeout(time: 1, unit: 'HOURS') {
                    waitForQualityGate abortPipeline: true
                }
            }
        }

        stage("Docker build"){
            steps{
                echo "[INFO] Building Docker images"
                sh 'docker build -t rajputmarch2020/ui-webapp:$GIT_COMMIT_HASH .'
            }
        }

        stage("Trivy Scan"){
            steps{
                echo "[INFO] Scanning image with Trivy"
                sh 'trivy image rajputmarch2020/ui-webapp:$GIT_COMMIT_HASH'
            }
        }

        stage("Docker push"){
            steps{
                echo "[INFO] Pushing Docker images to Dockerhub"
                withCredentials([string(credentialsId: 'dockerhub', variable: 'password')]){
                    sh 'docker login -u rajputmarch2020 -p ${password} '
                }
                    sh 'docker push rajputmarch2020/wishlist:$GIT_COMMIT_HASH'
            }
        }

        stage("Teardown"){
            steps{
                echo "[INFO] Deleting Docker images after pushed to Dockerhub"
                sh ''' 
                  docker rmi rajputmarch2020/wishlist:$GIT_COMMIT_HASH
                  docker image prune -f
                '''
            }
        }
    }

    post{
        always{
            echo "========always========"
        }
        success{
            echo "========pipeline executed successfully ========"
        }
        failure{
            echo "========pipeline execution failed========"
        }
        changed{
            echo "========build has changed from last run========"
        }
    }
}
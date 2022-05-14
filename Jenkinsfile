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
        projectKey = "${projectKey}"
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
                        sh "sudo ${scannerHome}/sonar-scanner/bin/sonar-scanner -Dsonar.projectKey=$projectKey"
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
                    sh 'docker push rajputmarch2020/ui-webapp:$GIT_COMMIT_HASH'
            }
        }

        stage("Teardown"){
            steps{
                echo "[INFO] Deleting Docker images after pushed to Dockerhub"
                sh ''' 
                  docker rmi rajputmarch2020/ui-webapp:$GIT_COMMIT_HASH
                  docker image prune -f
                '''
            }
        }

        stage("Helm charts Config check"){
            steps{
                echo "[INFO] Checking Helm chart config"
                script{
                    dir('helm-charts'){
                        withEnv(['DATREE_TOKEN=ao1RpL3G3LMRL6eucy37hv']){
                            sh 'helm datree test ui-webapp/'
                        }
                    }
                }
            }
        }

        stage("Approval"){
            steps{
                script{
                    timeout(10) {
                        mail bcc: '', body: "<br>Project: ${env.JOB_NAME} <br>Build Number: ${env.BUILD_NUMBER} <br> Go to build url and approve the deployment request <br> URL de build: ${env.BUILD_URL}", cc: '', charset: 'UTF-8', from: '', mimeType: 'text/html', replyTo: '', subject: "${currentBuild.result} CI: Project name -> ${env.JOB_NAME}", to: "ravisinghrajput005@gmail.com";  
                        input(id: "Deploy Gate", message: "Deploy ${params.project_name}?", ok: 'Deploy')
                    }
                }
            }
        }

        stage("BlueGreen Deploy to Kubernetes cluster"){
            steps{
                script{
                    withCredentials([kubeconfigFile(credentialsId: 'kubernetes-config', variable: 'KUBECONFIG')]){
                        dir("helm-charts/ui-webapp"){
                            sh '''
                            currentDeploy=$(helm list | cut -f1 | grep ui)
                            echo ${currentDeploy}
                            if [ $? -eq 0 ]; then
                               echo "Helm chart exists, proceeding with Blue Green deployment"
                               bash blue-green.sh $GIT_COMMIT_HASH
                            else
                               echo "Helm chart is not installed, instaling.."
                               bash blue.sh blue $GIT_COMMIT_HASH
                            fi
                            '''
                        }
                    }
                }
            }
        }
    }

    post{
        always{
            mail bcc: '', body: "<br>Project: ${env.JOB_NAME} <br>Build Number: ${env.BUILD_NUMBER} <br> URL de build: ${env.BUILD_URL}", cc: '', charset: 'UTF-8', from: '', mimeType: 'text/html', replyTo: '', subject: "${currentBuild.result} CI: Project name -> ${env.JOB_NAME}", to: "ravisinghrajput005@gmail.com";  
        }
        success{
            echo "[SUCCESS] Pipeline executed successfully"
            slackSend color: "good", message: "Status: Pipeline executed successfully  | Job: ${env.JOB_NAME} | Build number ${env.BUILD_NUMBER} "
        }
        failure{
            echo "[FAILED] pipeline execution failed"
            slackSend color: "danger", message: "Status: pipeline execution failed | Job: ${env.JOB_NAME} | Build number ${env.BUILD_NUMBER} 
        }
        changed{
            echo "[UNSTABLE] Build is Changed"
            slackSend color: "yellow", message: "Status: Build is changed from the previous.  | Job: ${env.JOB_NAME} | Build number ${env.BUILD_NUMBER} "
        }
        unstable{
            echo "[UNSTABLE] Build is unstable"
            slackSend color: "yellow", message: "Status: Build is unstable  | Job: ${env.JOB_NAME} | Build number ${env.BUILD_NUMBER} "
        }
        aborted{
            echo "[ABORTED] Build was aborted"
            slackSend color: "yellow", message: "Status: Build was aborted  | Job: ${env.JOB_NAME} | Build number ${env.BUILD_NUMBER} "
        }
    }
}
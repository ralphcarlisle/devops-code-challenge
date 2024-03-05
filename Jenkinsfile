pipeline {
 agent any
 environment {
 AWS_ACCOUNT_ID="654654538073"
 AWS_DEFAULT_REGION="us-east-2"
 ECR_REPO="lightfeather"
 GITHUB_REPO="https://github.com/ralphcarlisle/devops-code-challenge.git"
 IMAGE_TAG="latest"
 REPO_URI = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_DEFAULT_REGION}.amazonaws.com/${ECR_REPO}"
 }
 
 stages {
 stage('Authenticating into AWS ECR') {
 steps {
 script {
 sh "aws ecr-public get-login-password --region us-east-1 | docker login --username AWS --password-stdin public.ecr.aws/l8r2w7p9"
 }
 }
 }
 
 //stage('Cloning Git') {
 //steps {
 //checkout([$class: 'GitSCM', branches: [[name: '*/master']], doGenerateSubmoduleConfigurations: false, extensions: [], submoduleCfg: [], userRemoteConfigs: [[credentialsId: '', url: 'https://github.com/ralphcarlisle/devops-code-challenge.git']]]) 
 //}
 //}
 
 // Building Docker images
 stage('Building lightfeather container image') {
 steps{
 script {
 sh "docker build --file=lightfeather.dockerfile -t lightfeather:latest"
 }
 }
 }
 
 // Uploading Docker images into AWS ECR
 stage('Tagging and pushing lightfeather image to ECR') {
 steps{ 
 script {
 sh "docker tag lightfeather:latest public.ecr.aws/l8r2w7p9/lightfeather:latest"
 sh "docker push public.ecr.aws/l8r2w7p9/lightfeather:latest"
 }
 }
 }

 // run terraform
 stage('Applying terraform scripts to the aws environment') {
 steps{ 
 script {
 sh "terraform init"
 sh "terraform apply -auto-approve"
 }
 }
 }

 }
}
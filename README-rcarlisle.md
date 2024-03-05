# Overview
This skill assessment involved the creation of a docker container, a jenkins server and pipeline deploy job, and terraform scripts to create the infrastructure within AWS.

A fork of the lightfeather devop-code-challenge repository was created (after some initial difficulties in accessing it), and the necessary dockerfile, jenkinsfile, and terraform scripts were created and pushed to it.

Overall, I believe I have met the majority of the requirements for this skill assessment, although I am unfamiliar with AWS ECS and probably made some rookie mistakes with some of the configuration of the Fargate service and tasks that the terraform scripts define.

# Setup of Docker
I manually created the lightfeather.dockerfile (instructions stated there were templates that could be used but I did not find any).  I did experience quite a few vexing issues with building the docker image on my Win 10 personal computer; directories and files were getting copied repeatedly and recursively, although the commands I used should not have caused that.  I spent a good chunk of time in a rabbit hole attempting to figure out what the cause was before deciding to mitigate it by some shell commands to delete the extraneous files and directories after the image is created.  Notably, I had no problems with the docker build command on the linux jenkins server.
The Jenkins build pipeline is configured to perform a docker build using the lightfeather.dockerfile, and then to authenticate and tag and push the image to the ECR public repository I manually created, named "lightfeather".


# Setup of Jenkins
Installation and configuration of the Jenkins server was via steps detailed in the jenkins_install.sh script, originally on a t2.micro AWS EC2 instance with a public elastic IP address of 18.189.246.211 attached to it.  The jenkins_install.sh script installs and configures the necessary tools for building the devops-code-challenge software, including:  yum-utils, java11, nginx, terraform, git, and docker.  It ensures that the necessary services are enabled and started, and that the necessary users and user groups exist.

The jenkins instance has an IAM role and policy attached to it, granting the necessary AWS permissions for the public ECR, ECS, the lightfeather S3 bucket (used to store the terraform.tfstate files), and STS.  No other IAM permissions are required or assigned to the role.

The Jenkins security_group is configured to allow all outbound connections, necessary to allow software installation onto the instance, but only allows inbound conections from my personal IP address on ports 443, 22, and 80; this should be tightened down and restricted to a VPN range, which I would do if this was not a personal example.  It is also configured to allow all inbound connections on port 80, which is a necessary for the lightfeather team to connect to the server; it would be better though if the lightfeather team had a specific source IP address that I could use to map the security to allow instead of it being open to the public internet.

There were some AWS instabilities in the us-east-2 region on 2024-march-05, and the t2.micro instance was struggling with some of the terraform steps, so I resized the instance to a t3.medium.

The Jenkins server is set to perform builds using itself; there are no slaves attached to the server due to cost consideration and simplicity of the skill assessment requirements.

The Jenkins server has a single job defined - devops-code-challenge, a build pipeline job that uses the Jenkinsfile in the devops-code-challenge forked repository.

My personal github credentials are securely stored in Jenkins to allow the server to perform the git cloning of the devops-code-challenge repository as part of the buildpipeline job.

## Jenkins Plugins
The following Jenkins plugins were either part of the default configuration that Jenkins installs as, or manually installed on the server:
- Amazon ECR plugin
- Amazon Web Services SDK::EC2
- Amazon Web Services SDK::ECR
- Amazon Web Services SDK::Minimal
- Ant Plugin
- Apache HttpComponentsClient 4.x API Plugin
- Apache HttpComponentsClient 5.x API Plugin
- Authentication Tokens API Plugin
- AWS Credentials Plugin
- Bootstrap 5 API Plugin
- bouncycastle API Plugin
- Branch API Plugin
- Build Timeout
- Caffeine API Plugin
- Checks API plugin
- Cloud Statistics Plugin
- CloudBees Docker Build and Publish plugin
- Cloudbees Docker Hub/Registry Notification Plugin
- Command Agent Launcher Plugin
- commons-lang3 v3.x Jenkins API Plugin
- common-text API Plugin
- Config File Provider Plugin
- Credentials Binding Plugin
- Credentials Plugin
- Dark Theme
- Dashboard View
- Display URL API
- Docker API Plugin
- Docker Commons Plugin
- Durable Task Plugin
- ECharts API Plugin
- Email Extension
- Folders Plugin
- Font Awesome API Plugin
- Git client plugin
- Git Parameter Plug-In
- Git plugin
- GitHub API Plugin
- GitHub Branch Source Plugin
- GitHub plugin
- Gradle Plugin
- Gson API Plugin
- Instance Identity
- Ionicons API
- Jackson 2 API Plugin
- Jakarta Activation API
- Jakarta Mail API
- Java JSON Web Token Plugin
- JavaBeans Activation Framework API
- Javadoc Plugin
- JavaMail API
- JAXB plugin
- Joda Time API Plugin
- JQuery3 API Plugin
- JSch dependency plugin
- JSON Path API Plugin
- JUnit Plugin
- LDAP Plugin
- Mailer
- Matrix Authorization Strategy Plugin
- Matrix Project Plugin
- Maven Integration plugin
- Mina SSHD API::Common
- Mina SSHD API::Core
- NodeJS Plugin
- OkHttp Plugin
- Oracle Java SE Development Kit Installer Plugin
- OWASP Markup Formatter Plugin
- PAM Authentication plugin
- Pipeline
- Pipeline Graph Analysis Plugin
- Pipeline:API
- Pipeline:Basic Steps
- Pipeline:Build Step
- Pipeline:Declarative
- Pipeline:Declarative Extension Points API
- Pipeline:GitHub Groovy Libraries
- Pipeline:Groovy
- Pipeline:Groovy Libraries
- Pipeline:Input Step
- Pipeline:Job
- Pipeline:Milestone Step
- Pipeline:Model API
- Pipeline:Multibranch
- Pipeline:Nodes and Processes
- Pipeline:REST API Plugin
- Pipeline:SCM Step
- Pipeline:Stage Step
- Pipeline:Stage Tags Metadata
- Pipeline:Stage View Plugin
- Pipeline:Step API
- Pipeline:Supporting APIs
- Plain Credentials
- Plugin Utilities API Plugin
- Resource Disposer Plugin
- Role-based Authorization Strategy
- SCM API Plugin
- Script Security Plugin
- SnakeYAML API Plugin
- SSH Build Agents plugin
- SSH Credentials
- SSH server
- Structs Plugin
- Terraform Plugin
- Theme Manager
- Timestamper
- Token Macro Plugin
- Trilead API Plugin
- Variant Plugin
- Workspace Cleanup Plugin

## Jenkins Users
Two users are defined in Jenkins; my own user account, which has the admin role and permissions assigned to it, and the lightfeather user, which has the read-only role and permissions assigned to it.  No other users are present, and no users are allowed to sign themselves up onto the server.

## Setup of Jenkins Build Pipeline
A Jenkinsfile is present in the forked github repository that contains the build pipeline for the Jenkins build job.  This performs a cloning of the forked github repository, an authentication to AWS ECR, a docker build using the lightfeather.dockerfile, tags the built image and pushes it to the AWS public ECR, and then calls terraform init, terraform plan, and terraform apply -auto-approve.  The current AWS infrastructure was deployed to using this job.


## Jenkins Access
To access the Jenkins server created for this skill assessment:
URL:       http://18.189.246.211
username:  lightfeather
password:  +mGwv17+p3erJvN1u-5q


# Setup of AWS ECR
A Public ECR registry was manually created, named "lightfeather", which stores the lightfeather docker image.


# Setup of Terraform
The forked repository has a directory within it named "terraform"; this contains the terraform code for this skill demonstration, consisting of a main.tf, config.tf, provider.tf, and variables.tf.  Main.tf will create all infrastructure required for this skill demonstration, including the IAM policy and role, the AWS Cloudwatch log group, the AWS ECS task definition, and the AWS ECS cluster inside of Fargate; the ECR repository was manually created, as above, and its data is retrieved from the account via terraform data calls.  The config.tf stores configuration/variable information regarding the infrastructure such as the amount of cpu and memory to assign to the ECS task.  Provider.tf defines the terraform versions and AWS Tags to be auto-applied.  Variable.tf could probably be deleted as it is not really used.

AWS Tags are applied to all infrastructure created via the definition in the provider.tf script, and includes tags named created_by, repository, support_level, and terraform_version.  Terraform version 1.7.4 was used for this skill demonstration.


## AWS ECS Terraform Notes
The lightfeather container is deployed to the AWS ECS stack as a Fargate service/task definition.  This was my first time working with this technology and I will admit that I probably made some mistakes with this.  Overall, the AWS ECS was an interesting experience, striking me as a combination of features from AWS EKS and Lambda.
The container images for the ECS service are stored in a public AWS ECR repository created by the terraform scripts named "lightfeather".  These images are built by the Jenkins pipeline job using docker, and tagged and pushed to the repository by Jenkins as part of that same job.
The AWS ECS terraform scripts use this repository to create the service and task.

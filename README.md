# Jenkins on AWS EC2

## Prerequisites
Before running terraform do the following requirements below.

### .ssh folder
Terraform will generate key pair and will save the private key as jenkins_key.pem

You can manually create ssh private and public keys. with `ssh-keygen -t rsa -b 2048` then add key to AWS console. This is optional.

### .credentials folder
Create `credentials` file with the same layout as below:

```
[default]
aws_access_key_id=AKIAIOSFODNN7EXAMPLE
aws_secret_access_key=wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY

[user1]
aws_access_key_id=AKIAIOSFODNN7EXAMPLE
aws_secret_access_key=wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
```

### Install Terraform Collection for Ansible
`ansible-galaxy collection install cloud.terraform`

## Run Terraform
`terraform init`
`terraform plan`
`terraform apply`

## Print Terraform Inventory
`ansible-inventory -i ./ansible/inventory.yaml --graph --vars`

## Run Ansible Playbook
`ansible-playbook -i ./ansible/inventory.yaml ./ansible/playbook.yaml`

## Jenkins Plugins
- Docker Plugin
- Docker Pipeline

### Test Docker Plugin
1. Dashboard - Manage Jenkins - Clouds - + New Cloud
2. Docker Host URI = unix:///var/run/docker.sock
3. Create test pipeline using docker_agent/Jenkinsfile content in Pipeline Script


### Test Docker Pipeline Plugin
https://github.com/angelopaolosantos/jenkins-test

## Docker inbound agents images
https://github.com/jenkinsci/docker-inbound-agents

### Cleanup
`terraform destroy`
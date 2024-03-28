# Jenkins on AWS EC2

## .ssh folder
1. Manually create ssh private and public keys.
`ssh-keygen -t rsa -b 2048` 

2. add key to AWS console

Or

1. Allow terraform to generate key pair. Terraform will save private key as jenkins_key.pem

## Install Terraform Collection for Ansible
ansible-galaxy collection install cloud.terraform

## Print Terraform Inventory
ansible-inventory -i ./ansible/inventory.yaml --graph --vars

## Run Ansible Playbook
ansible-playbook -i ./ansible/inventory.yaml ./ansible/playbook.yaml

## Jenkins Plugins
Docker Plugin
Docker Pipeline

### Test Docker Pipeline Plugin
https://github.com/angelopaolosantos/jenkins-test

## Docker inbound agents images
https://github.com/jenkinsci/docker-inbound-agents
#!/bin/bash
sudo yum update -y

wget https://releases.hashicorp.com/terraform/1.8.1/terraform_1.8.1_linux_amd64.zip -P ~/
unzip ~/terraform_1.8.1_linux_amd64.zip -d ~/.
sudo mv ~/terraform /usr/local/bin

pip install -r requirements.txt

echo "alias python='python3'
alias tf='terraform'
alias c='clear'" >> ~/.bashrc

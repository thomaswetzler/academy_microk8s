#!/bin/sh
#
# File:   install_microk8s.sh
# Author: Thomas Wetzler
#
# Created on 10.10.2018, 10:28:38
#

# Update /etc/hosts
sudo bash -c "echo $(/sbin/ifconfig eth0 | grep 'inet' | cut -d: -f2 | awk '{ print $2}') ' '  $(hostname -f ) ' ' $(hostname -s) >> /etc/hosts"
sudo bash -c "echo ' ' >> /etc/hosts"

# Allow sshd Port and TCP Forwarding
sudo bash -c "sed -i 's/AllowTcpForwarding no/AllowTcpForwarding yes/g' /etc/ssh/sshd_config"
sudo bash -c "sed -i 's/GatewayPorts no/GatewayPorts yes/g' /etc/ssh/sshd_config"
sudo systemctl restart sshd

# Uninstall docker
sudo yum -y remove docker

# Install kubectl Bash-compleation
echo "source <(kubectl completion bash)" >> ~/.bashrc

# Install SNAP
# https://computingforgeeks.com/install-snapd-snap-applications-centos-7/
sudo yum -y copr enable ngompa/snapcore-el7
sudo systemctl enable --now snapd.socket
sudo ln -s /var/lib/snapd/snap /snap

# Wait somehow - otherwise this happens:
# error: too early for operation, device not yet seeded or device model not acknowledged
sleep 60
#read -n1 -r -p "Press any key to continue..." key
sudo snap install hello-world

# Install microk8s
# https://microk8s.io/
sudo snap install microk8s --classic --channel=1.12/stable

# List all installed snaps
sudo snap list

# Alias kubectl
#snap alias microk8s.kubectl kubectl

# Set Path Variable
export PATH=$PATH:/var/lib/snapd/snap/bin/

# Change .bashrc
cd
cat >> ~/.bashrc <<- EOF

unalias ls 2>/dev/null
#alias docker='/var/lib/snapd/snap/bin/microk8s.docker'
alias docker='sudo /usr/bin/docker -H unix:///var/snap/microk8s/current/docker.sock'

export PATH=$PATH:/var/lib/snapd/snap/bin/

EOF

# Write Config File for Kubectrl
mkdir $HOME/.kube
/var/lib/snapd/snap/bin/microk8s.kubectl config view --raw > $HOME/.kube/config

sleep 60

# Services enablen
/var/lib/snapd/snap/bin/microk8s.enable dashboard dns registry metrics-server ingress storage

# Config
alias kubectl=microk8s.kubectl
alias docker=microk8s.docker

cat >> .bashrc <<- EOF
# Microk8s aliases
alias kubectl=microk8s.kubectl
alias docker=microk8s.docker
EOF


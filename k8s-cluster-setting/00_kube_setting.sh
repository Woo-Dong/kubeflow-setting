#!/bin/bash

# basic update
sudo apt-get update -y && sudo apt upgrade -y

# install docker
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu bionic stable"
sudo apt update -y
apt-cache policy docker-ce
sudo apt install -y docker-ce
sudo usermod -aG docker $USER


# error handling related docker(cgroup)
echo '{ "exec-opts": ["native.cgroupdriver=systemd"], "log-driver": "json-file", "log-opts": { "max-size": "100m" }, "storage-driver": "overlay2" }' | sudo tee /etc/docker/daemon.json > /dev/null

sudo systemctl enable docker
sudo systemctl daemon-reload
sudo systemctl restart docker
sudo rm /etc/containerd/config.toml
sudo systemctl restart containerd

# swap off
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab
sudo swapoff -a

# install kubectl
curl -LO https://dl.k8s.io/release/v1.24.9/bin/linux/amd64/kubectl
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
sudo modprobe br_netfilter
echo  "br_netfilter" | sudo tee /etc/modules-load.d/k8s.conf
echo  "net.bridge.bridge-nf-call-ip6tables = 1" | sudo tee /etc/sysctl.d/k8s.conf
echo  "net.bridge.bridge-nf-call-iptables = 1" | sudo tee /etc/sysctl.d/k8s.conf
sudo sysctl --system


# install kubelet, kubeadm
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl &&
sudo curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg &&
echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list &&
sudo apt-get update
sudo apt-get install -y kubelet=1.24.9-00 kubeadm=1.24.9-00 &&
sudo apt-mark hold kubelet kubeadm kubectl

# install nfs-client
sudo apt-get install -y nfs-common
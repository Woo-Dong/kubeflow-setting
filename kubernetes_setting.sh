#!/bin/bash

# update packages
sudo apt-get update -y && sudo apt upgrade -y

# export environment variables
source $(pwd)/.env

# hostname setting
sudo hostnamectl set-hostname $HOST_NAME

# swap off
sudo swapoff -a && sudo sed -i '/swap/d' /etc/fstab

# install kubelet kubeadm kubectl
sudo apt-get install -y apt-transport-https ca-certificates curl
sudo curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg
echo  "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update -y
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl

# install docker
sudo apt update -y software-properties-common

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu bionic stable"
sudo apt update -y
apt-cache policy docker-ce
sudo apt install -y docker-ce
sudo usermod -aG docker $USER

# install docker-compose
sudo curl -L "https://github.com/docker/compose/releases/download/1.24.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# error handling related docker(cgroup)
echo '{ "exec-opts": ["native.cgroupdriver=systemd"], "log-driver": "json-file", "log-opts": { "max-size": "100m" }, "storage-driver": "overlay2" }' | sudo tee /etc/docker/daemon.json > /dev/null

sudo systemctl enable docker
sudo systemctl daemon-reload
sudo systemctl restart docker
sudo rm /etc/containerd/config.toml
sudo systemctl restart containerd


if [ $ROLE == "WORKER" ]; then
    echo 'WORKER MODE'
    sudo kubeadm join $CONTROL_PLAIN_IP:6443 --token $TOKEN --discovery-token-ca-cert-hash sha256:$HASH
else
    echo 'MASTER MODE'
    sudo kubeadm init \
        --apiserver-advertise-address=$CONTROL_PLAIN_IP \
        --pod-network-cidr=$NETWORK_CIDR \
        --v=10

    mkdir -p $HOME/.kube
    sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
    sudo chown $(id -u):$(id -g) $HOME/.kube/config
    kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml # install Flannel add-on for networking pods

fi
echo 'DONE!!!!!'
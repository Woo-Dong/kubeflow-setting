#!/bin/bash
sudo kubeadm config images pull

sudo kubeadm init \
  --pod-network-cidr=10.244.0.0/16 \
  --kubernetes-version=v1.24.9

mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config


# CNI - flannel
kubectl apply -f https://raw.githubusercontent.com/flannel-io/flannel/master/Documentation/kube-flannel.yml

# kustomize
wget https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize%2Fv3.10.0/kustomize_v3.10.0_linux_amd64.tar.gz
tar -zxvf kustomize_v3.10.0_linux_amd64.tar.gz
sudo mv kustomize /usr/local/bin/kustomize

# CSI - nfs-storage
sudo apt-get install -y nfs-common nfs-kernel-server rpcbind portmap
sudo mkdir /mnt/shared
sudo chmod 777 /mnt/shared
echo "/mnt/shared *(rw,sync,no_subtree_check)" | sudo tee -a /etc/exports
sudo exportfs -a
sudo systemctl restart nfs-kernel-server

# PV, PVC, PV-pod setting
kubectl apply -f https://raw.githubusercontent.com/Woo-Dong/kubeflow-setting/master/k8s-cluster-setting/persistent-volume/pv-volume.yaml
kubectl apply -f https://raw.githubusercontent.com/Woo-Dong/kubeflow-setting/master/k8s-cluster-setting/persistent-volume/pv-claim.yaml

# Nvidia-device-plugin (optional)
# kubectl create -f https://raw.githubusercontent.com/NVIDIA/k8s-device-plugin/v0.10.0/nvidia-device-plugin.yml

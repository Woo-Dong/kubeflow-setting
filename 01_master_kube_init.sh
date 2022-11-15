#!/bin/bash
sudo kubeadm config images pull

sudo kubeadm init \
  --pod-network-cidr=10.244.0.0/16 \
  --kubernetes-version=v1.22.15

mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config


# CNI - flannel
kubectl apply -f https://raw.githubusercontent.com/flannel-io/flannel/master/Documentation/kube-flannel.yml

# kustomize
wget https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize%2Fv3.10.0/kustomize_v3.10.0_linux_amd64.tar.gz
tar -zxvf kustomize_v3.10.0_linux_amd64.tar.gz
sudo mv kustomize /usr/local/bin/kustomize

# CSI - LocalPath provisioner
kubectl apply -f https://raw.githubusercontent.com/rancher/local-path-provisioner/v0.0.20/deploy/local-path-storage.yaml
kubectl patch storageclass local-path  -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'

# git clone repository
# git clone https://github.com/Woo-Dong/kubeflow-setting.git
# cd kubeflow-setting

# PV, PVC, PV-pod setting
sudo mkdir /mnt/data
kubectl apply -f https://raw.githubusercontent.com/Woo-Dong/kubeflow-setting/master/pv/pv-volume.yaml
kubectl apply -f https://raw.githubusercontent.com/Woo-Dong/kubeflow-setting/master/pv/pv-claim.yaml
sleep 10
kubectl apply -f https://raw.githubusercontent.com/Woo-Dong/kubeflow-setting/master/pv/pv-pod.yaml

# Nvidia-device-plugin (optional)
# kubectl create -f https://raw.githubusercontent.com/NVIDIA/k8s-device-plugin/v0.10.0/nvidia-device-plugin.yml

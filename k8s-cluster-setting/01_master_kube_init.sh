#!/bin/bash
sudo kubeadm config images pull

sudo kubeadm init \
  --pod-network-cidr=10.244.0.0/16 \
  --kubernetes-version=v1.24.9

mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

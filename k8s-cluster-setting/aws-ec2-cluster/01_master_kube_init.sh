#!/bin/bash
sudo kubeadm config images pull

sudo kubeadm init \
  --control-plane-endpoint=<YOUR_ELB_SUB_DOMAIN>.elb.ap-northeast-2.amazonaws.com:6443 \
  --pod-network-cidr=10.244.0.0/16 \
  --kubernetes-version=v1.24.9

mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

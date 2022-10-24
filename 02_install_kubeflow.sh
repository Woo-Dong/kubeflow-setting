#!/bin/bash

# kubectl label node {HOST_NAME} node-role.kubernetes.io/worker=worker
kubectl label node kube-worker-1 node-role.kubernetes.io/worker=worker
# kubectl label node kube-worker-2 node-role.kubernetes.io/worker=worker

git clone -b v1.6.1 https://github.com/kubeflow/manifests.git
cd manifests

while ! kustomize build example | kubectl apply -f -; do echo "Retrying to apply resources"; sleep 10; done

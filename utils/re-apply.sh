#!/bin/bash

kustomize build kubeflow_install | kubectl apply -f -

# Restart Dex Application after updating account settings(config-map.yaml)
kubectl rollout restart deployment dex -n auth
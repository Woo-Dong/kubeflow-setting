#!/bin/bash

while ! kustomize build kubeflow_install | kubectl apply -f -; do echo "Retrying to apply resources"; sleep 10; done

# sudo -E kubectl port-forward --address 0.0.0.0 svc/istio-ingressgateway -n istio-system 80:80 &

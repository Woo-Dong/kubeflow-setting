#!/bin/bash
while ! kustomize build kubeflow_install | kubectl apply -f -; do echo "Retrying to apply resources"; sleep 10; done

# Port forwarding services: kubeflow main dashboard, minio, kfp-api server
# kubectl port-forward --address 0.0.0.0 svc/istio-ingressgateway -n istio-system 8080:80 &
# kubectl port-forward --address 0.0.0.0 -n kubeflow svc/ml-pipeline 8888:8888 &
# kubectl port-forward --address 0.0.0.0 -n kubeflow svc/minio-service 9000:9000 &

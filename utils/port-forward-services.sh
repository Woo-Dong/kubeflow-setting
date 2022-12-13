kubectl port-forward --address 0.0.0.0 -n istio-system svc/istio-ingressgateway 8080:80 &
kubectl port-forward --address 0.0.0.0 -n kubeflow svc/minio-service 9000:9000 &

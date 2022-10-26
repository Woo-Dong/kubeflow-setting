# Third-party

## Seldon-Core
```sh
helm repo add datawire https://www.getambassador.io
helm repo update

helm install ambassador datawire/ambassador \
  --namespace seldon-system \
  --create-namespace \
  --set image.repository=quay.io/datawire/ambassador \
  --set enableAES=false \
  --set crds.keep=false \
  --version 6.9.3
kubectl get pod -n seldon-system # check

helm install seldon-core seldon-core-operator \
    --repo https://storage.googleapis.com/seldon-charts \
    --namespace seldon-system \
    --set usageMetrics.enabled=true \
    --set ambassador.enabled=true \
    --version 1.11.2
kubectl get pod -n seldon-system | grep seldon-controller # check
```


## Prometheus & Grafana
```sh
helm repo add seldonio https://storage.googleapis.com/seldon-charts
helm repo update

helm install seldon-core-analytics seldonio/seldon-core-analytics \
  --namespace seldon-system \
  --version 1.12.0
kubectl get pod -n seldon-system | grep seldon-core-analytics # check
kubectl port-forward --address 0.0.0.0 svc/seldon-core-analytics-grafana -n seldon-system 8090:80
```

---

### truble shooting
* pod restart command
  ```sh
  kubectl get pod <pod_name> -n <namespace> -o yaml | kubectl replace --force -f -
  ```
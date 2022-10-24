# kubeflow-setting

## Getting started

### 1. Install Docker & Kubernetes tools
```sh
$ chmod +x 00_kube_setting.sh
$ ./00_kube_setting.sh
```

### 2. Kubernetes Cluster Initialization
```sh
$ chmod +x 01_kube_setting.sh
$ ./01_kube_setting.sh
```

### 2-1. Label Worker Node's Role (on Control-plane Node)
```sh
kubectl label node {HOST_NAME} node-role.kubernetes.io/worker=worker
```

### 2-2. Client Setup (on Worker Node)
```sh
mkdir -p $HOME/.kube
scp -p {CLUSTER_USER_ID}@{CLUSTER_IP}:~/.kube/config ~/.kube/config
```

### 2-3. (Optional) Single Cluster Mode
```sh
kubectl taint nodes --all node-role.kubernetes.io/master-
```

### 3. Install Kubeflow & Deployment
```sh
$ chmod +x 02_install_kubeflow.sh
$ ./02_install_kubeflow.sh
```

## Enjoy Kubeflow dashboard
```sh
# Port Forwarding Kubeflow Central Dashboard Web browser 
sudo -E kubectl port-forward --address 0.0.0.0 svc/istio-ingressgateway -n istio-system 80:80
```


---


# Third-party


## Helm
```sh
wget https://get.helm.sh/helm-v3.7.1-linux-amd64.tar.gz
tar -zxvf helm-v3.7.1-linux-amd64.tar.gz
sudo mv linux-amd64/helm /usr/local/bin/helm
```

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
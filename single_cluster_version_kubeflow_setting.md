# Single Cluster Mode

## docker
```sh
sudo apt-get update
sudo apt-get install -y socat
sudo apt-get update && sudo apt-get install -y ca-certificates curl gnupg lsb-release
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update && apt-cache madison docker-ce
sudo apt-get install -y containerd.io docker-ce=5:20.10.11~3-0~ubuntu-focal docker-ce-cli=5:20.10.11~3-0~ubuntu-focal
sudo groupadd docker
sudo usermod -aG docker $USER
newgrp docker
```

## hostname
```ssh
# hostname setting
sudo hostnamectl set-hostname kube-master # kube-worker-1
```

## swap off
```sh
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab
sudo swapoff -a
```

## kubectl
```sh
curl -LO https://dl.k8s.io/release/v1.21.7/bin/linux/amd64/kubectl
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
sudo modprobe br_netfilter

echo  "br_netfilter" | sudo tee /etc/modules-load.d/k8s.conf
echo  "net.bridge.bridge-nf-call-ip6tables = 1" | sudo tee /etc/sysctl.d/k8s.conf
echo  "net.bridge.bridge-nf-call-iptables = 1" | sudo tee /etc/sysctl.d/k8s.conf
sudo sysctl --system
```

## install kubelet, kubeadm
```sh
sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl &&
sudo curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg &&
echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list &&
sudo apt-get update

sudo apt-get install -y kubelet=1.21.7-00 kubeadm=1.21.7-00 kubectl=1.21.7-00 &&
sudo apt-mark hold kubelet kubeadm kubectl
```

## init kubernetes cluster
```sh
kubeadm config images list
kubeadm config images pull

sudo kubeadm init \
  --pod-network-cidr=10.244.0.0/16
#  --apiserver-advertise-address=$CONTROL_PLAIN_IP

mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

## Single Cluster Mode
```sh
kubectl taint nodes --all node-role.kubernetes.io/master-
```
## client setup (on wokrer node)
```sh
mkdir -p $HOME/.kube
scp -p {CLUSTER_USER_ID}@{CLUSTER_IP}:~/.kube/config ~/.kube/config
```

## client setup - role (on control-plane node)
```sh
kubectl label node {HOST_NAME} node-role.kubernetes.io/worker=worker
```

## Flannel
```sh
kubectl apply -f https://raw.githubusercontent.com/flannel-io/flannel/v0.13.0/Documentation/kube-flannel.yml
```

## Helm
```sh
wget https://get.helm.sh/helm-v3.7.1-linux-amd64.tar.gz
tar -zxvf helm-v3.7.1-linux-amd64.tar.gz
sudo mv linux-amd64/helm /usr/local/bin/helm
```

## Kustomize
```sh
wget https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize%2Fv3.10.0/kustomize_v3.10.0_linux_amd64.tar.gz
tar -zxvf kustomize_v3.10.0_linux_amd64.tar.gz
sudo mv kustomize /usr/local/bin/kustomize
```

## CSI - LocalPath provisioner
```sh
kubectl apply -f https://raw.githubusercontent.com/rancher/local-path-provisioner/v0.0.20/deploy/local-path-storage.yaml
kubectl patch storageclass local-path  -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
```

### PV, PVC Setting
```sh
sudo mkdir /mnt/data
kubectl apply -f https://k8s.io/examples/pods/storage/pv-volume.yaml
kubectl apply -f https://k8s.io/examples/pods/storage/pv-claim.yaml
kubectl apply -f https://k8s.io/examples/pods/storage/pv-pod.yaml
```

## INSTALL KUBEFLOW 
```sh
git clone -b v1.4.0 https://github.com/kubeflow/manifests.git
cd manifests

kustomize build common/cert-manager/cert-manager/base | kubectl apply -f -
kubectl get pod -n cert-manager # check

kustomize build common/cert-manager/kubeflow-issuer/base | kubectl apply -f -

kustomize build common/istio-1-9/istio-crds/base | kubectl apply -f -
kustomize build common/istio-1-9/istio-namespace/base | kubectl apply -f -
kustomize build common/istio-1-9/istio-install/base | kubectl apply -f -
kubectl get po -n istio-system # check

kustomize build common/dex/overlays/istio | kubectl apply -f -

kustomize build common/oidc-authservice/base | kubectl apply -f -


# kubeflow-namespace
kustomize build common/kubeflow-namespace/base | kubectl apply -f -
kubectl get ns kubeflow # check

# kubeflow-roles
kustomize build common/kubeflow-roles/base | kubectl apply -f -
kubectl get clusterrole | grep kubeflow # check 

kustomize build common/istio-1-9/kubeflow-istio-resources/base | kubectl apply -f -
kubectl get clusterrole | grep kubeflow-istio # check

# kfp
kustomize build apps/pipeline/upstream/env/platform-agnostic-multi-user | kubectl apply -f - # if error exists, try this command after 10 sec
kubectl port-forward --address 0.0.0.0 svc/ml-pipeline-ui -n kubeflow 8888:80 # check

# katib
kustomize build apps/katib/upstream/installs/katib-with-kubeflow | kubectl apply -f -
kubectl port-forward --address 0.0.0.0 svc/katib-ui -n kubeflow 8888:80 # check

kustomize build apps/centraldashboard/upstream/overlays/istio | kubectl apply -f -

kubectl get po -n kubeflow | grep centraldashboard
kubectl port-forward --address 0.0.0.0 svc/centraldashboard -n kubeflow 8888:80 # check

kustomize build apps/admission-webhook/upstream/overlays/cert-manager | kubectl apply -f -

kustomize build apps/jupyter/notebook-controller/upstream/overlays/kubeflow | kubectl apply -f -
kubectl get po -n kubeflow | grep notebook-controller # check

kustomize build apps/jupyter/jupyter-web-app/upstream/overlays/istio | kubectl apply -f -
kubectl get po -n kubeflow | grep jupyter-web-app # check

kustomize build apps/profiles/upstream/overlays/kubeflow | kubectl apply -f -
kubectl get po -n kubeflow | grep profiles-deployment # check

kustomize build apps/volumes-web-app/upstream/overlays/istio | kubectl apply -f -
kubectl get po -n kubeflow | grep volumes-web-app # check

kustomize build apps/tensorboard/tensorboards-web-app/upstream/overlays/istio | kubectl apply -f -
kubectl get po -n kubeflow | grep tensorboards-web-app # check

kustomize build apps/tensorboard/tensorboard-controller/upstream/overlays/kubeflow | kubectl apply -f -
kubectl get po -n kubeflow | grep tensorboard-controller # chcek

kustomize build apps/training-operator/upstream/overlays/kubeflow | kubectl apply -f -
kubectl get po -n kubeflow | grep training-operator # check

kustomize build common/user-namespace/base | kubectl apply -f -
kubectl get profile # check
```

## Port Forwarding Kubeflow Central Dashboard Web browser 
```sh
sudo -E kubectl port-forward --address 0.0.0.0 svc/istio-ingressgateway -n istio-system 80:80
```
  

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
# 1. Environment Settings

## 1-1. Install Docker
* nano or vi docker_install.sh
```bash
#!/bin/bash
sudo apt update -y \
    apt-transport-https \
    ca-certificates \
    curl \
    software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu bionic stable"
sudo apt update
apt-cache policy docker-ce
sudo apt install -y docker-ce
sudo usermod -aG docker $USER

# install docker-compose
sudo curl -L "https://github.com/docker/compose/releases/download/1.24.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
```

* Run shell script
```bash
$ sudo apt-get update
$ chmod +x docker_install.sh
$ ./docker_install.sh
```

## 1-2. Run Linux Container for setting aws configuration and managing eksctl
* Pull Ubuntu image and run container with port forwarding
  - 80:80
  - 8080:8080
```bash
$ mkdir workspace
$ docker image pull ubuntu:20.04
$ docker run -d -p 80:80 -p 8080:8080 -v $(pwd)/workspace:/workspace --name awsconf-container -t ubuntu:20.04
$ docker exec -it awsconf-conatiner bash # get inside a ubuntu docker container shell
```

## 1-3. Setting AWS configuration -> inside the ubuntu docker container
* Install awscli and set configuration
  - ACCESS_KEY_ID
  - SECRET_ACCESS_KEY
  - REGION

```bash
$ apt-get install awscli
$ aws configure
```




# 2. Setting EKS Cluster

## 2-1. Install eksctl, kubectl, kustomize
```bash
$ curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
$ mv /tmp/eksctl /usr/local/bin
$ curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
$ curl -LO "https://dl.k8s.io/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl.sha256"
$ echo "$(cat kubectl.sha256)  kubectl" | sha256sum --check
$ sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
$ install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
$ chmod +x kubectl
$ mkdir -p ~/.local/bin
$ mv ./kubectl ~/.local/bin/kubectl
$ curl -s "https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh"  | bash
$ mv ./kustomize /usr/local/bin
```

## 2-2. Create EKS Cluster using command eksctl
```bash
$ export CLUSTER_NAME=dev-kubeflow-eks
$ export CLUSTER_REGION=ap-northeast-2

$ eksctl create cluster \
	--name ${CLUSTER_NAME} \
	--version 1.21 \
	--region ${CLUSTER_REGION} \
	--nodegroup-name linux-nodes \
	--node-type m6i.xlarge \
	--nodes 4 \
	--nodes-min 4 \
	--nodes-max 8 \
	--managed \
	--with-oidc

```

# 3. Setting Kubeflow

## 3-1. Deployment kubeflow-manifests including major tools with single command at once
  * cert-manger
  * Istio-system
  * auth
  * knative-eventing
  * knative-serving
  * kubeflow
  * kubeflow-user-example-com (kubeflow dashboard)
  * KServe 

```bash
$ export KUBEFLOW_RELEASE_VERSION=v1.5.1
$ export AWS_RELEASE_VERSION=v1.5.1-aws-b1.0.1
$ git clone https://github.com/awslabs/kubeflow-manifests.git && cd kubeflow-manifests

$ while ! kustomize build deployments/vanilla | kubectl apply -f -; do echo "Retrying to apply resources"; sleep 30; done
```

## 3-2. Check each pod if they are running
```bash
$ kubectl get pods -n cert-manager
$ kubectl get pods -n istio-system
$ kubectl get pods -n auth
$ kubectl get pods -n knative-eventing
$ kubectl get pods -n knative-serving
$ kubectl get pods -n kubeflow
$ kubectl get pods -n kubeflow-user-example-com
$ kubectl get pods -n kserve
```

## 3-3. port forwarding kubeflow dashboard web site

* For temporary command
```bash
$ kubectl port-forward svc/istio-ingressgateway -n istio-system 80:80 --address='0.0.0.0'
```
* Or permenently in bacakground
```bash
$ nohup kubectl port-forward svc/istio-ingressgateway -n istio-system 80:80 --address='0.0.0.0' &
```

## 3-4. If this dashboard open at public, you shoud add an envrionment variable in the deployment spec at each services.

* Update an envrionment variable named APP_SECURE_COOKIES
  - APP_SECURE_COOKIES="false"
  
```bash
$ [nano or vi] kubeflow-manifests/upstream/apps/jupyter/jupyter-web-app/upstream/base/deployment.yaml
```
* update like below...
```yaml
...
spec:
    spec:
        ...
        containers:
            ...
            env:
                ...
                - name: APP_SECURE_COOKIES # add this envrionment variable
                    value: "false"
```

* And Re-Apply!
```bash
$ kustomize build kubeflow-manifests/upstream/apps/jupyter/jupyter-web-app/upstream/overlay/istio | kubectl apply -f -
$ kustomize build kubeflow-manifests/upstream/apps/jupyter/notebook-controller/upstream/overlays/kubeflow | kubectl apply -f -
$ kustomize build kubeflow-manifests/awsconfigs/apps/jupyter-web-app | kubectl apply -f -
```






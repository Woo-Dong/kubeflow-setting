# kubeflow-setting

## Main Folder Directory Structure
    ├── jupyter-image  
    │   ├── Makefile                # make All Jupyter Images build & push on the ECR Repositories  
    │   └── ecr-secret-helper.yaml  # kubectl apply CronJob each namespace  
    ├── k8s-cluster-setting  
    │   ├── aws-ec2-cluster         # IaC(aws-cli)  
    │   ├── haproxy  
    │   └── persistent-volume       # CSI Driver - NFS Server, kubectl create storage, dynamic PVC
    ├── k8s-dashboard               # kubectl apply k8s-dashboard  
    ├── kubeflow-setting  
    │   ├── apps                    # kubeflow apps
    │   ├── aws                     # kustomize build & kubectl apply deployment with AWS S3 and RDS  
    │   ├── common                  # dex, ...
    │   ├── contrib                 # KServer, ...
    │   └── kustomization.yaml      # kustomize build & kubectl apply kubeflow apps  
    ├── utils                       # etc  
    └── README.md  


# TODO & Release Info

### 20230109 - v0.5.0
* TODO
    - [ ] Set Katib MySQL binding with AWS RDS  
    - [ ] Permute ClusterIP to NordPort (Grafana and Prometheus on KFP)
    - [ ] Port-forward Grafana at HAProxy
    - [ ] KServe Concept Test & Debugging
    - [ ] KServe API Test
    - [ ] And More..

* UPDATED
    + K8S version updated: v1.22.15 -> v1.24.9
    + local-path storage with static PV, PVC -> nfs server with dynamic PVC
    + updated Setting GPU Worker Node: 
        - kernel version 5.15.0-1019-aws -> 5.15.0-1026-aws
        - nvidia driver autoinstall -> nvidia 515 driver install (manual)
---


# Getting started

## 1. Setting Kubernetes Cluster
* See more README info in the `k8s-cluster-setting` directory.


## 2. Install Kubeflow
* Version Info
    - Kubeflow version: v1.6.1
    - Kubernetes version: v1.24.9
    - Kustomize version: v3.2.0  

* Install Kubeflow
     - on Master Node
        ```sh
        # kustomize
        wget https://github.com/kubernetes-sigs/kustomize/releases/download/v3.2.0/kustomize_3.2.0_linux_amd64
        chmod +x kustomize_3.2.0_linux_amd64
        sudo mv kustomize_3.2.0_linux_amd64 /usr/local/bin/kustomize

        # Deploy Kubeflow
        while ! kustomize build kubeflow-setting | kubectl apply -f -; do echo "Retrying to apply resources"; sleep 10; done
        ```

* Enjoy Kubeflow dashboard
    - on Master Node
        ```sh
        # Port Forwarding Kubeflow Central Dashboard Web browser 
        # If you want port-forward to 80 port..
        # $ sudo -E kubectl port-forward --address 0.0.0.0 svc/istio-ingressgateway -n istio-system 80:80 &
        kubectl port-forward --address 0.0.0.0 svc/istio-ingressgateway -n istio-system 8080:80 &
        kubectl port-forward --address 0.0.0.0 -n kubeflow svc/ml-pipeline 8888:8888 &
        kubectl port-forward --address 0.0.0.0 -n kubeflow svc/minio-service 9000:9000 &
        ```

    * If you want to deploy with AWS S3 and RDS, see more README info at the directory `kubeflow-setting/aws`.

## 3. Setting Custom Jupyter / Docker Image for pulling them at Notebook/KFP 
* See more README info at the directory `jupyter-image`.


## 4. Third-Party

### K8s-dashboard
* Pre-requisite: SSL Certificate (https required)
* on Master Node
    ```sh
    kubectl apply -f https://raw.githubusercontent.com/Woo-Dong/kubeflow-setting/master/k8s-dashboard/k8s-dashboard.yaml
    kubectl apply -f https://raw.githubusercontent.com/Woo-Dong/kubeflow-setting/master/k8s-dashboard/metrics-server.yaml
    kubectl apply -f https://raw.githubusercontent.com/Woo-Dong/kubeflow-setting/master/k8s-dashboard/rbac.yaml
    ```

* Then, get a Login Token
    ```sh
    kubectl -n kubernetes-dashboard create token admin-user
    ```

* And visit https://{external-dns}:8443/ 

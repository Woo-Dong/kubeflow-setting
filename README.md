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
    │   ├── contrib                 # KServe, ...
    │   └── kustomization.yaml      # kustomize build & kubectl apply kubeflow apps  
    ├── utils                       # etc  
    └── README.md  


# TODO & Release Info

### 20230613 - v1.0.0

* UPDATED
    + Kubeflow version updated -> v1.7.0
    + nfs server with dynamic PVC -> Amazon EFS Provisioner
    + Amazon RDS, S3 deleted -> Amazon EFS - PVC


# Getting started

## 1. Setting Kubernetes Cluster
* See more README info in the `k8s-cluster-setting` directory.


## 2. Install Kubeflow
* Version Info
    - Kubeflow version: v1.7.0
    - Kubernetes version: v1.24.9
    - Kustomize version: v5.0.3

* Install Kubeflow
     - on Master Node
        ```sh
        # kustomize
        wget https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize%2Fv5.0.3/kustomize_v5.0.3_linux_amd64.tar.gz
        tar -zxvf kustomize_v5.0.3_linux_amd64.tar.gz
        chmod +x kustomize
        sudo mv kustomize /usr/local/bin/kustomize

        # Deploy Kubeflow
        while ! kustomize build kubeflow-setting | awk '!/well-defined/' | kubectl apply -f -; do echo "Retrying to apply resources"; sleep 10; done
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

* And visit https://{external-dns}:30522/


### KServe
* ServiceAccount Management
* Fill your AWS_ACCESS_KEY and AWS_SECRET_ACCESS_KEY value and `kubectl apply -f kserve-sa.yaml`
* kserve-sa.yaml
    ```yaml
    apiVersion: v1
    kind: Secret
    metadata:
    name: s3creds
    namespace: {YOUR_NAMESPACE}
    annotations:
        serving.kserve.io/s3-endpoint: s3.amazonaws.com # replace with your s3 endpoint e.g minio-service.kubeflow:9000
        serving.kserve.io/s3-usehttps: "1" # by default 1, if testing with minio you can set to 0
        serving.kserve.io/s3-region: "ap-northeast-2"
        serving.kserve.io/s3-useanoncredential: "false" # omitting this is the same as false, if true will ignore provided credential and use anonymous credentials
    type: Opaque
    stringData: # use `stringData` for raw credential string or `data` for base64 encoded string
    AWS_ACCESS_KEY_ID: {YOUR_AWS_ACCESS_KEY_ID}
    AWS_SECRET_ACCESS_KEY: {YOUR_AWS_SECRET_ACCESS_KEY}
    ---
    apiVersion: v1
    kind: ServiceAccount
    metadata:
    name: kserve-sa
    namespace: {YOUR_NAMESPACE}
    secrets:
    - name: s3creds
    ```
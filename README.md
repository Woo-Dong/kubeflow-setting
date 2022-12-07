# kubeflow-setting

## Main Folder Directory Structure
├── jupyter-image  
│   ├── Makefile                # `make` All Jupyter Images build & push on the ECR Repositories  
│   └── ecr-secret-helper.yaml  # `kubectl apply` CronJob each namespace  
├── k8s-cluster-setting  
│   ├── aws-ec2-cluster         # IaC(aws-cli)  
│   ├── haproxy  
│   └── persistent-volume       # `kubectl apply` pv, pvc, pv-pod resources  
├── k8s-dashboard               # `kubectl apply` k8s-dashboard  
├── kubeflow-setting  
│   ├── apps   
│   ├── aws                     # `kustomize build` & `kubectl apply` deployment with AWS S3 and RDS  
│   ├── common  
│   ├── contrib  
│   └── kustomization.yaml      # `kustomize build` & `kubectl apply` kubeflow apps  
├── utils                       # etc  
└── README.md  



# Getting started

## 1. Setting Kubernetes Cluster
* See more README info in the `k8s-cluster-setting` directory.


## 2. Install Kubeflow & Deployment
* on Master Node
    ```sh
    while ! kustomize build kubeflow-setting | kubectl apply -f -; do echo "Retrying to apply resources"; sleep 10; done
    ```

* Enjoy Kubeflow dashboard
  - on Master Node
    ```sh
    # Port Forwarding Kubeflow Central Dashboard Web browser 
    kubectl port-forward --address 0.0.0.0 svc/istio-ingressgateway -n istio-system 8080:80 &
    # If you want port-forward to 80 port..
    # $ sudo -E kubectl port-forward --address 0.0.0.0 svc/istio-ingressgateway -n istio-system 80:80 &
    ```

* If you want deploy with AWS S3 and RDS, see more README info in the `kubeflow-setting/aws` directory..

## 3. Setting Custom Jupyter / Docker Image for pulling them at Notebook/KFP 
* See more README info in the `jupyter-image` directory.



## 4. Third-Party

### K8s-dashboard
* on Master Node
    ```sh
    kubectl apply -f k8s-dashboard/k8s-dashboard.yaml
    kubectl apply -f k8s-dashboard/metrics-server.yaml
    kubectl apply -f k8s-dashboard/rbac.yaml
    ```

* Then, get a Login Token
    ```sh
    kubectl -n kubernetes-dashboard get secret $(kubectl -n kubernetes-dashboard get sa/admin-user -o jsonpath="{.secrets[0].name}") -o go-template="{{.data.token | base64decode}}"
    ```

* And visit https://{external-dns}:8443/ 


### Seldon-Core
* deployment with helm
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


### Prometheus & Grafana
* deployment with helm
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

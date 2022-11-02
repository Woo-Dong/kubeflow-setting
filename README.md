# kubeflow-setting

## Getting started
### concept
  * 1 Control-plane Node
  * 3 Worker Node

### 0. Install Docker & Kubernetes tools
   - on Master & Worker Node
      ```sh
      $ chmod +x 00_kube_setting.sh
      $ ./00_kube_setting.sh
      ```

### 1. Initialize Kubernetes Cluster
  - on Master Node
    ```sh
    $ sudo hostnamectl set-hostname kube-master
    $ chmod +x 01_master_kube_init.sh
    $ ./01_master_kube_init.sh
    ```

### 2. Join Worker Node with the Cluster
  - on Worker Node
    ```sh
    $ sudo hostnamectl set-hostname {WORKER_HOST_NAME}
    $ sudo kubeadm join {MASTER_NODE_IP_ADDRESS}:6443 \
      --token xxxxxxxxxxx \
      --discovery-token-ca-cert-hash sha256:xxxxxxxxxxxxxxxxxx
    ```

    #### 2-1. Label Worker Node's Role
      - on Master Node
        ```sh
        $ kubectl label node {WORKER_HOST_NAME} node-role.kubernetes.io/worker=worker
        ```

    #### 2-2. (Optional) Client Setup
      - on Worker Node
        ```sh
        $ mkdir -p $HOME/.kube
        $ scp -p {MASTER_NODE_USER_ID}@{MASTER_NODE_IP_ADDRESS}:~/.kube/config ~/.kube/config
        ```

### 3. Install Kubeflow & Deployment
  - on Master Node
    ```sh
    $ while ! kustomize build kubeflow_install | kubectl apply -f -; do echo "Retrying to apply resources"; sleep 10; done
    ```

### 4. (Optional) Install Nvidia Driver, nvidia-docker2 on GPU Worker Node

  - on Master Node
    ```sh
    $ kubectl create -f https://raw.githubusercontent.com/NVIDIA/k8s-device-plugin/v0.10.0/nvidia-device-plugin.yml
    ```

  - on Worker Node
    ```sh
    $ sudo add-apt-repository -y ppa:graphics-drivers/ppa # type ENTER
    $ sudo apt update && sudo apt install -y ubuntu-drivers-common
    $ sudo ubuntu-drivers autoinstall
    $ sudo reboot # It will be disconnected and takes serveral times to reboot itself.
    ```

  - Re-connect to the worker node and,
    ```sh
    $ chmod +x 03_worker_gpu_nvidia_docker.sh
    $ ./03_worker_gpu_nvidia_docker.sh
    ```
  
  - Check GPU available
    ```sh
    $ kubectl get nodes "-o=custom-columns=NAME:.metadata.name,GPU:.status.allocatable.nvidia\.com/gpu"
    ```
    ---


## Enjoy Kubeflow dashboard
  - on Master Node
    ```sh
    # Port Forwarding Kubeflow Central Dashboard Web browser 
    $ kubectl port-forward --address 0.0.0.0 svc/istio-ingressgateway -n istio-system 8080:80 &
    # If you want port-forward to 80 port..
    # $ sudo -E kubectl port-forward --address 0.0.0.0 svc/istio-ingressgateway -n istio-system 80:80 &
    ```
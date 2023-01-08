# Kubernetes-Cluster Setting

## Getting started

## 1. Setting AWS EC2 Cluster
* `aws-ec2-cluster`/`create_ec2_instance.sh`
 - Shell Script for creating AWS EC2 instances
 - .env file needed
 - see more README info in the `aws-ec2-cluster` diretory.

## 2. Kuberenetes Cluster (Vanilla)
* Concept: 1 Master Node + 3 Worker Nodes

### 0. Install Docker & Kubernetes tools
   - on Master & Worker Node
      ```sh
      chmod +x 00_kube_setting.sh
      ./00_kube_setting.sh
      ```

### 1. Initialize Kubernetes Cluster
  - on Master Node
    ```sh
    sudo hostnamectl set-hostname kube-master
    chmod +x 01_master_kube_init.sh
    ./01_master_kube_init.sh
    ```

### 2. Join Worker Node with the Cluster
  - on Worker Node
    ```sh
    sudo hostnamectl set-hostname {WORKER_HOST_NAME}
    sudo kubeadm join {MASTER_NODE_IP_ADDRESS}:6443 \
      --token xxxxxxxxxxx \
      --discovery-token-ca-cert-hash sha256:xxxxxxxxxxxxxxxxxx
    ```

    #### 2-1. Label Worker Node's Role
      - on Master Node
        ```sh
        kubectl label node {WORKER_HOST_NAME} node-role.kubernetes.io/worker=worker
        ```

    #### 2-2. (Optional) Client Setup
      - on Worker Node
        ```sh
        mkdir -p $HOME/.kube
        scp -p {MASTER_NODE_USER_ID}@{MASTER_NODE_IP_ADDRESS}:~/.kube/config ~/.kube/config
        ```

### 3. (Optional) Install Nvidia Driver, nvidia-docker2 on GPU Worker Node

  - on Master Node
    ```sh
    kubectl create -f https://raw.githubusercontent.com/NVIDIA/k8s-device-plugin/v0.13.0/nvidia-device-plugin.yml
    ```

  - on Worker Node
    ```sh
    sudo apt install nvidia-driver-515 -y
    sudo reboot # It will be disconnected and takes serveral times to reboot itself.
    ```

  - Re-connect to the worker node and,
    ```sh
    chmod +x 03_worker_gpu_nvidia_docker.sh
    ./03_worker_gpu_nvidia_docker.sh # type Y
    ```
  
  - make a config file on `/etc/containerd/config.toml`
    ```toml
    version = 2
    [plugins]
      [plugins."io.containerd.grpc.v1.cri"]
        [plugins."io.containerd.grpc.v1.cri".containerd]
          default_runtime_name = "nvidia"

          [plugins."io.containerd.grpc.v1.cri".containerd.runtimes]
            [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.nvidia]
              privileged_without_host_devices = false
              runtime_engine = ""
              runtime_root = ""
              runtime_type = "io.containerd.runc.v2"
              [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.nvidia.options]
                BinaryName = "/usr/bin/nvidia-container-runtime"
    ```
    and
    ```sh
    sudo systemctl restart containerd
    sudo reboot
    ```

  - Check GPU available
    ```sh
    kubectl get nodes "-o=custom-columns=NAME:.metadata.name,GPU:.status.allocatable.nvidia\.com/gpu"
    ```

## 3. Kubernetes Cluster with HA(High Availability)proxy
* Concept: 1 LoadBalancer + 3 Master Nodes + 6 Worker Nodes
 - See more README info in the `haproxy` directory.
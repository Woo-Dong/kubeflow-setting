# Kubernetes-Cluster Setting

## Getting started

## 1. Setting AWS EC2 Cluster
* `aws-ec2-cluster`/`create_ec2_instance.sh`
 - Shell Script for creating AWS EC2 instances
 - .env file needed
 - see more README info at the directory, `aws-ec2-cluster`.

## 2. Kuberenetes Cluster (Vanilla)
* Concept: 1 Master Node + 3 Worker Nodes

### 2-0. Install Docker & Kubernetes tools
   - on Master & Worker Node
      ```sh
      chmod +x 00_kube_setting.sh # including nfs-client tool
      ./00_kube_setting.sh
      ```

### 2-1. Initialize Kubernetes Cluster
  - on Master Node
    ```sh
    sudo hostnamectl set-hostname {MASTER_HOST_NAME}

    sudo kubeadm init \
      --pod-network-cidr=10.244.0.0/16 \
      --kubernetes-version=v1.24.9

    mkdir -p $HOME/.kube
    sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
    sudo chown $(id -u):$(id -g) $HOME/.kube/config
    ```

### 2-2. Join Worker Node with the Cluster
  
  - on Worker Node
    #### 2-2-1. Join 
    ```sh
    sudo hostnamectl set-hostname {WORKER_HOST_NAME}
    sudo kubeadm join {MASTER_NODE_IP_ADDRESS}:6443 \
      --token xxxxxxxxxxx \
      --discovery-token-ca-cert-hash sha256:xxxxxxxxxxxxxxxxxx
    ```

    #### 2-2-2. Label Worker Node's Role
      - on Master Node
        ```sh
        kubectl label node {WORKER_HOST_NAME} node-role.kubernetes.io/worker=worker
        ```
    
### 2-3. (Optional) GPU Worker Node - Install Nvidia Driver, nvidia-docker2

  - on Master Node
    #### 2-3-1. Deploy nvidia device plugin daemonset at each node
      ```sh
      kubectl create -f https://raw.githubusercontent.com/NVIDIA/k8s-device-plugin/v0.13.0/nvidia-device-plugin.yml
      ```

  - on Worker Node
    #### 2-3-2. Install Nvidia Driver
      ```sh
      sudo apt install nvidia-driver-515 -y
      sudo reboot # It will be disconnected and takes serveral times to reboot itself.
      ```
      - Check nvidia driver is successfully installed
        ```sh
        nvidia-smi
        ```

    #### 2-3-3. Install nvidia-docker2 and set default runtime as nvidia-container-runtime
      ```sh
      chmod +x 03_worker_gpu_nvidia_docker.sh
      ./03_worker_gpu_nvidia_docker.sh # type Y
      ```

    #### 2-3-4. Set containerd config and reboot
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
    - restart containerd service and reboot
      ```sh
      sudo systemctl restart containerd
      sudo reboot
      ```

    #### 2-3-5. Check GPU avilable on k8s cluster
    - on Master Node
      ```sh
      kubectl get nodes "-o=custom-columns=NAME:.metadata.name,GPU:.status.allocatable.nvidia\.com/gpu"
      ```

## 3. Kubernetes Cluster with HA(High Availability) proxy
- Concept: 1 LoadBalancer + 3 Master Nodes + N Worker Nodes
- Pre-requisite: SSL Certificate
- See more README info at directory, `haproxy`.

## 4. CNI Driver - Flannel
  * on Master Node
    ```sh
    kubectl apply -f https://raw.githubusercontent.com/flannel-io/flannel/master/Documentation/kube-flannel.yml
    ```

## 5. CSI Driver - NFS Server
  * on NFS Server Node (You can use any lb/master/worker node or EBS Volume on AWS)
    ```sh
    # Install nfs server
    sudo apt-get install -y nfs-kernel-server rpcbind portmap

    # Set nfs volume
    sudo mkdir /nfs-vol
    sudo chmod 777 -R /nfs-vol

    # wild card - $ echo "/nfs-vol *(rw,sync,no_subtree_check,no_root_squash)" | sudo tee -a /etc/exports
    echo "/nfs-vol 10.1.1.0/24(rw,sync,no_subtree_check,no_root_squash)" | sudo tee -a /etc/exports
    sudo exportfs -a

    sudo systemctl restart nfs-kernel-server
    sudo systemctl enable nfs-kernel-server
    ```

  * on Master Node
    ```sh
    # CSI Driver Setting - rbac, driverino, controller, nfs node
    kubectl apply -f https://raw.githubusercontent.com/Woo-Dong/kubeflow-setting/master/k8s-cluster-setting/persistent-volume/nfs/csi-nfs-rbac.yaml
    kubectl apply -f https://raw.githubusercontent.com/Woo-Dong/kubeflow-setting/master/k8s-cluster-setting/persistent-volume/nfs/csi-nfs-driverinfo.yaml
    kubectl apply -f https://raw.githubusercontent.com/Woo-Dong/kubeflow-setting/master/k8s-cluster-setting/persistent-volume/nfs/csi-nfs-controller.yaml
    kubectl apply -f https://raw.githubusercontent.com/Woo-Dong/kubeflow-setting/master/k8s-cluster-setting/persistent-volume/nfs/csi-nfs-node.yaml

    
    # Set StorageClass and Dynamic-PVC
    # Modify NFS Server IP on your own server
    kubectl apply -f https://raw.githubusercontent.com/Woo-Dong/kubeflow-setting/master/k8s-cluster-setting/persistent-volume/storageclass.yaml
    kubectl apply -f https://raw.githubusercontent.com/Woo-Dong/kubeflow-setting/master/k8s-cluster-setting/persistent-volume/dynamic-pvc.yaml

    # Set nfs-csi as default storage class
    kubectl patch storageclass nfs-csi -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
    ```

  * on every Nodes, already set in the code `00_kube_setting.sh` file.
    ```sh
    # Install nfs client
    sudo apt-get install nfs-common -y
    ```
  


# Kubernetes-Cluster Setting

## Getting started

## 1. Setting AWS EC2 Cluster
* `aws-ec2-cluster`/`create_ec2_instance.sh`
 - Shell Script for creating AWS EC2 instances
 - .env file needed
 - see more README info at the directory, `aws-ec2-cluster`.

## 2. Kuberenetes Cluster (High Availability)
* Concept: 3 Master Node + N Worker Nodes

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

    # Vanilla Cluster ( 1 Master Node + N Worker Node )
    # sudo kubeadm init \
    #  --pod-network-cidr=10.244.0.0/16 \
    #   --kubernetes-version=v1.24.9

    sudo kubeadm init \
      --control-plane-endpoint={YOUR_ELB_SUB_DOMAIN}.elb.ap-northeast-2.amazonaws.com \
      --upload-certs \
      --pod-network-cidr=10.244.0.0/16 \
      --kubernetes-version=v1.24.9

    mkdir -p $HOME/.kube
    sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
    sudo chown $(id -u):$(id -g) $HOME/.kube/config
    ```
  
  - on the other Master Nodes for joinng the cluster
  ```sh
  sudo kubeadm join --control-plane-endpoint={YOUR_ELB_SUB_DOMAIN}.elb.ap-northeast-2.amazonaws.com \
    --token xxxx.xxxxxx \
    --discovery-token-ca-cert-hash sha256:xxxxxxxx \
    --control-plane \
    --certificate-key xxxxxxxx
  ```

### 2-2. Join Worker Node with the Cluster
  
  - on Worker Node
    #### 2-2-1. Join 
    ```sh
    sudo hostnamectl set-hostname {WORKER_HOST_NAME}
    
    sudo kubeadm join {YOUR_ELB_SUB_DOMAIN}.elb.ap-northeast-2.amazonaws.com:6443 \
      --token xxxx.xxxxxxxx \
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
- Concept: AWS Elastic Load Balancer + 3 Master Nodes + N Worker Nodes

## 4. CNI Driver - Flannel
  * on Master Node
    ```sh
    kubectl apply -f https://raw.githubusercontent.com/flannel-io/flannel/master/Documentation/kube-flannel.yml
    ```

## 5. PV, PVC, Provisioner using Amazon EFS(Elastic File System)

  - IAM Policy for accessing Amazon EFS
    ```json
    {
      "Version": "2012-10-17",
      "Statement": [
        {
          "Effect": "Allow",
          "Action": [
            "elasticfilesystem:DescribeAccessPoints",
            "elasticfilesystem:DescribeFileSystems",
            "elasticfilesystem:DescribeMountTargets",
            "ec2:DescribeAvailabilityZones"
          ],
          "Resource": "*"
        },
        {
          "Effect": "Allow",
          "Action": [
            "elasticfilesystem:CreateAccessPoint"
          ],
          "Resource": "*",
          "Condition": {
            "StringLike": {
              "aws:RequestTag/efs.csi.aws.com/cluster": "true"
            }
          }
        },
        {
          "Effect": "Allow",
          "Action": [
            "elasticfilesystem:TagResource"
          ],
          "Resource": "*",
          "Condition": {
            "StringLike": {
              "aws:ResourceTag/efs.csi.aws.com/cluster": "true"
            }
          }
        },
        {
          "Effect": "Allow",
          "Action": "elasticfilesystem:DeleteAccessPoint",
          "Resource": "*",
          "Condition": {
            "StringEquals": {
              "aws:ResourceTag/efs.csi.aws.com/cluster": "true"
            }
          }
        }
      ]
    }
    ```

  - rbac, sc, deployment, etc
    * on Master Node
      ```sh
      kubectl apply -f efs-provisioner.yaml # included setting default storageclass
      ```

  - (optional) mounting Amazon EFS on Amazon EC2 at the path, `/mnt/efs`.
    * on Master Node
      ```sh
      # pre-requisites: setting aws-cli configure
      sudo apt-get -y install binutils
      git clone https://github.com/aws/efs-utils
      cd ./efs-utils
      ./build-deb.sh
      sudo apt-get -y install ./build/amazon-efs-utils*deb
      sudo mkdir -p /mnt/efs
      sudo mount -t efs -o tls,iam fs-xxxxxx.efs.ap-northeast-2.amazonaws.com /mnt/efs/
      ```

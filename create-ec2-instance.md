
# Getting Started

## 0. Prerequisites
* Install AWS-cli (v2)
* aws configuration
* Setting VPC, Subnet group, and Security Group

## 1. configure dot-env
* .env format
    ```sh
    export IMAGE_ID="ami-07d16c043aa8e5153" # Ubuntu Server 20.04 LTS
    export KEY_NAME="xxxxxxxxx"

    export SECURITY_GROUP_ID_CONTROLPLANE="sg-xxxxxxxxx" # control-plane security group
    export SECURITY_GROUP_ID_WORKER="sg-xxxxxxxxx" # worker security group

    export SUBNET_ID_PUBLIC_1="subnet-xxxxxxxxx" # ap-northeast-2a-public 10.1.1.0/28
    export SUBNET_ID_PRIVATE_1="subnet-xxxxxxxxx" # ap-northeast-2a-private 10.1.1.128/28
    export SUBNET_ID_PRIVATE_2="subnet-xxxxxxxxx" # ap-northeast-2b-private 10.1.1.144/28
    export SUBNET_ID_PRIVATE_3="subnet-xxxxxxxxx" # ap-northeast-2c-private 10.1.1.160/28

    export KUBE_LB_ADDRESS="10.1.1.5"
    export KUBE_MASTER_1_ADDRESS="10.1.1.133"
    export KUBE_MASTER_2_ADDRESS="10.1.1.149"
    export KUBE_MASTER_3_ADDRESS="10.1.1.165"
    export KUBE_WORKER_1_ADDRESS="10.1.1.134"
    export KUBE_WORKER_2_ADDRESS="10.1.1.150"
    export KUBE_WORKER_3_ADDRESS="10.1.1.166"
    ```


## 2. Run "create_ec2_instance.sh"
* bash commands
    ```sh
    chmod +x 400 create_ec2_instance.sh
    ./create_ec2_instance.sh
    ```
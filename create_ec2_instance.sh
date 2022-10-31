#!/bin/bash

# .env format
# =================================
# export IMAGE_ID="ami-07d16c043aa8e5153" # Ubuntu Server 20.04 LTS
# export KEY_NAME="xxxxxxxxx"

# export SECURITY_GROUP_ID_CONTROLPLANE="sg-xxxxxxxxx" # control-plane security group
# export SECURITY_GROUP_ID_WORKER="sg-xxxxxxxxx" # worker security group

# export SUBNET_ID_PUBLIC_1="subnet-xxxxxxxxx" # ap-northeast-2a-public 10.1.1.0/28
# export SUBNET_ID_PRIVATE_1="subnet-xxxxxxxxx" # ap-northeast-2a-private 10.1.1.128/28
# export SUBNET_ID_PRIVATE_2="subnet-xxxxxxxxx" # ap-northeast-2b-private 10.1.1.144/28
# export SUBNET_ID_PRIVATE_3="subnet-xxxxxxxxx" # ap-northeast-2c-private 10.1.1.160/28

# export KUBE_LB_ADDRESS="10.1.1.5"
# export KUBE_MASTER_1_ADDRESS="10.1.1.133"
# export KUBE_MASTER_2_ADDRESS="10.1.1.149"
# export KUBE_MASTER_3_ADDRESS="10.1.1.165"
# export KUBE_WORKER_1_ADDRESS="10.1.1.134"
# export KUBE_WORKER_2_ADDRESS="10.1.1.150"
# export KUBE_WORKER_3_ADDRESS="10.1.1.166"
# =================================
source .env


declare -A INSTANCES

# kube-lb
INSTANCES["lb","TAG_NAME"]='kube-cluster-ha-lb'
INSTANCES["lb","IP"]=${KUBE_LB_ADDRESS}
INSTANCES["lb","INSTANCE_TYPE"]='t2.micro'
INSTANCES["lb","SUBNET_ID"]=${SUBNET_ID_PUBLIC_1}
INSTANCES["lb","SECURITY_GROUP_ID"]=${SECURITY_GROUP_ID_CONTROLPLANE}
INSTANCES["lb","ASSOCIATE_PUBLIC_IP"]=true

# kube-master-1
INSTANCES["master-1","TAG_NAME"]='kube-cluster-ha-master-1'
INSTANCES["master-1","IP"]=${KUBE_MASTER_1_ADDRESS}
INSTANCES["master-1","INSTANCE_TYPE"]='t3.medium'
INSTANCES["master-1","SUBNET_ID"]=${SUBNET_ID_PRIVATE_1}
INSTANCES["master-1","SECURITY_GROUP_ID"]=${SECURITY_GROUP_ID_CONTROLPLANE}
INSTANCES["master-1","ASSOCIATE_PUBLIC_IP"]=false
# kube-master-2
INSTANCES["master-2","TAG_NAME"]='kube-cluster-ha-master-2'
INSTANCES["master-2","IP"]=${KUBE_MASTER_2_ADDRESS}
INSTANCES["master-2","INSTANCE_TYPE"]='t3.medium'
INSTANCES["master-2","SUBNET_ID"]=${SUBNET_ID_PRIVATE_2}
INSTANCES["master-2","SECURITY_GROUP_ID"]=${SECURITY_GROUP_ID_CONTROLPLANE}
INSTANCES["master-2","ASSOCIATE_PUBLIC_IP"]=false
# kube-master-3
INSTANCES["master-3","TAG_NAME"]='kube-cluster-ha-master-3'
INSTANCES["master-3","IP"]=${KUBE_MASTER_3_ADDRESS}
INSTANCES["master-3","INSTANCE_TYPE"]='t3.medium'
INSTANCES["master-3","SUBNET_ID"]=${SUBNET_ID_PRIVATE_3}
INSTANCES["master-3","SECURITY_GROUP_ID"]=${SECURITY_GROUP_ID_CONTROLPLANE}
INSTANCES["master-3","ASSOCIATE_PUBLIC_IP"]=false

# kube-worker-1
INSTANCES["worker-1","TAG_NAME"]='kube-cluster-ha-worker-1'
INSTANCES["worker-1","IP"]=${KUBE_WORKER_1_ADDRESS}
INSTANCES["worker-1","INSTANCE_TYPE"]='t3.medium'
INSTANCES["worker-1","SUBNET_ID"]=${SUBNET_ID_PRIVATE_1}
INSTANCES["worker-1","SECURITY_GROUP_ID"]=${SECURITY_GROUP_ID_WORKER}
INSTANCES["worker-1","ASSOCIATE_PUBLIC_IP"]=false
# kube-worker-2
INSTANCES["worker-2","TAG_NAME"]='kube-cluster-ha-worker-2'
INSTANCES["worker-2","IP"]=${KUBE_WORKER_2_ADDRESS}
INSTANCES["worker-2","INSTANCE_TYPE"]='t3.medium'
INSTANCES["worker-2","SUBNET_ID"]=${SUBNET_ID_PRIVATE_2}
INSTANCES["worker-2","SECURITY_GROUP_ID"]=${SECURITY_GROUP_ID_WORKER}
INSTANCES["worker-2","ASSOCIATE_PUBLIC_IP"]=false
# kube-worker-3
INSTANCES["worker-3","TAG_NAME"]='kube-cluster-ha-worker-3'
INSTANCES["worker-3","IP"]=${KUBE_WORKER_3_ADDRESS}
INSTANCES["worker-3","INSTANCE_TYPE"]='t3.medium'
INSTANCES["worker-3","SUBNET_ID"]=${SUBNET_ID_PRIVATE_3}
INSTANCES["worker-3","SECURITY_GROUP_ID"]=${SECURITY_GROUP_ID_WORKER}
INSTANCES["worker-3","ASSOCIATE_PUBLIC_IP"]=false

Red='\033[0;31m'
Green='\033[0;32m'
Cyan='\033[0;36m'
NC='\033[0m'

# iterator creating ec2 instances
var=( lb master-1 master-2 master-3 worker-1 worker-2 worker-3 )
for instance in "${var[@]}"
do
    echo -e "${Green}${instance} creating...${NC}"

    tag_name=${INSTANCES[${instance},'TAG_NAME']}
    tag_specifications="ResourceType=instance,Tags=[{Key=Name,Value=${tag_name}}]"
    declare -A instance_id

    if ${INSTANCES[${instance},'ASSOCIATE_PUBLIC_IP']}
    then # HA Load Balancer Instance
        instance_id=$(aws ec2 run-instances \
            --associate-public-ip-address \
            --image-id ${IMAGE_ID} \
            --count 1 \
            --key-name ${KEY_NAME} \
            --security-group-ids ${INSTANCES[${instance},'SECURITY_GROUP_ID']} \
            --instance-type ${INSTANCES[${instance},'INSTANCE_TYPE']} \
            --subnet-id ${INSTANCES[${instance},'SUBNET_ID']} \
            --tag-specifications ${tag_specifications} \
            --private-ip-address ${INSTANCES[${instance},'IP']} \
            --output text --query 'Instances[].InstanceId')
    else # Control-plane & Worker Node Instance
        script_file_path="file://$(pwd)/00_kube_install.sh"
        instance_id=$(aws ec2 run-instances \
            --no-associate-public-ip-address \
            --image-id ${IMAGE_ID} \
            --count 1 \
            --key-name ${KEY_NAME} \
            --security-group-ids ${INSTANCES[${instance},'SECURITY_GROUP_ID']} \
            --instance-type ${INSTANCES[${instance},'INSTANCE_TYPE']} \
            --subnet-id ${INSTANCES[${instance},'SUBNET_ID']} \
            --tag-specifications ${tag_specifications} \
            --private-ip-address ${INSTANCES[${instance},'IP']} \
            --block-device-mappings '[{"DeviceName":"/dev/sda1","Ebs":{"VolumeSize":64}}]' \
            --user-data ${script_file_path} \
            --output text --query 'Instances[].InstanceId')
    fi

    if [ ${instance_id} ]
    then
        echo -e "${Cyan}instance ${instance} created ==> ${instance_id}${NC}"
    else
        echo -e "${Red}instance ${instance} didn't create.. Look above errors${NC}"
    fi

done

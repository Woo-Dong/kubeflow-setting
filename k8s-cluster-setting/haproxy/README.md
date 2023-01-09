
# Getting Started

## 0. edit host configuration
* on lb, master, worker nodes
    ```sh
    sudo nano /etc/hosts
    ```
* /etc/hosts
    ```txt
    ...
    10.1.1.5 kube-lb
    10.1.1.133 kube-master-1
    10.1.1.165 kube-master-2
    10.1.1.166 kube-master-3
    10.1.1.135 kube-worker-cpu-1
    10.1.1.168 kube-worker-cpu-2
    10.1.1.138 kube-worker-gpu-1
    10.1.1.170 kube-worker-gpu-2
    10.1.1.139 kube-worker-gpu-3
    10.1.1.171 kube-worker-gpu-4
    ```

## 1. Install haproxy
* on lb node
    ```sh
    sudo apt install -y haproxy
    sudo cp /etc/haproxy/haproxy.cfg /etc/haproxy/haproxy.cfg-org
    ```

## 2. Add CA SSL certificate
* on lb node
    ```sh
    sudo mkdir -p /etc/haproxy/certs
    sudo nano /etc/haproxy/certs/unified_ssl_dl-service.chunjae-dl.com.pem
    ```
* /etc/haproxy/certs/unified_ssl_kubeflow.chunjae-dl.com.pem
    ```sh
    -----BEGIN PRIVATE KEY-----
    ...(YOUR PRIVATE KEY)...
    -----END PRIVATE KEY-----
    -----BEGIN CERTIFICATE-----
    ...(YOUR FULL CHAIN CERTIFICATE)...
    -----END CERTIFICATE-----
    -----BEGIN CERTIFICATE-----
    ...(YOUR FULL CHAIN CERTIFICATE)...
    -----END CERTIFICATE-----
    -----BEGIN CERTIFICATE-----
    ...(YOUR FULL CHAIN CERTIFICATE)...
    -----END CERTIFICATE-----
    ```

## 2. Edit haproxy configuration
* on lb node
    ```sh
    sudo nano /etc/haproxy/haproxy.cfg
    ```
* /etc/haproxy/haproxy.cfg
    ```txt
    ...

    frontend kubernetes-master-lb
        bind *:6443
        option tcplog 
        mode tcp
        default_backend kubernetes-master-nodes

    backend kubernetes-master-nodes
        mode tcp
        balance roundrobin
        option tcp-check
        option tcplog
        server kube-master-1 10.1.1.133:6443 check
        server kube-master-2 10.1.1.149:6443 check
        server kube-master-3 10.1.1.165:6443 check

    frontend http-in
        bind *:443 ssl crt /etc/haproxy/certs/unified_ssl_dl-service.chunjae-dl.com.pem
        reqadd X-Forwarded-Proto:\ https
        mode http
        default_backend http-servers

    backend http-servers
        mode http
        server kube-master-1 10.1.1.133:8080 maxconn 32
        server kube-master-2 10.1.1.149:8080 maxconn 32
        server kube-master-3 10.1.1.165:8080 maxconn 32


    frontend dashboard-in
        bind *:8443 ssl crt /etc/haproxy/certs/unified_ssl_dl-service.chunjae-dl.com.pem
        reqadd X-Forwarded-Proto:\ https
        mode http
        default_backend dashboard-servers

    backend dashboard-servers
        mode http
        server kube-master-1 10.1.1.133:30522 maxconn 32
    ```


## 3. restart haproxy
* on lb node
    ```sh
    sudo systemctl restart haproxy
    sudo systemctl enable haproxy
    ```


## 4. Init Kubernetes
* on master-1 node
    ```sh
    sudo kubeadm config images pull
    sudo kubeadm init \
        --control-plane-endpoint=kube-lb:6443 \
        --pod-network-cidr=10.244.0.0/16 \
        --upload-certs \
        --kubernetes-version=v1.24.9 
        # --ignore-preflight-errors=NumCPU

    mkdir -p $HOME/.kube
    sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
    sudo chown $(id -u):$(id -g) $HOME/.kube/config
    ```


## 5. Join the cluster as a Control-plane node
* on master-2, master-3 nodes
    ```sh
    sudo kubeadm join kube-lb:6443 \
        --token xxxxxx.xxxxxxxxxxx \
        --discovery-token-ca-cert-hash sha256:xxxxxxxxxxx \
        --control-plane --certificate-key xxxxxxxxxxx
        
    mkdir -p $HOME/.kube
    sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
    sudo chown $(id -u):$(id -g) $HOME/.kube/config
    ```


## 6. Join the cluster as a Worker node
* on worker-1, worker-2, worker-3 nodes
    ```sh
    sudo kubeadm join kube-lb:6443 \
        --token xxxxxx.xxxxxxxxxxx \
        --discovery-token-ca-cert-hash sha256:xxxxxxxxxxx
    ```


## 7. Label Worker Node's Role
* on master-1 node
    ```sh
    kubectl label node kube-worker-cpu-1 node-role.kubernetes.io/worker=worker
    kubectl label node kube-worker-cpu-2 node-role.kubernetes.io/worker=worker
    ```
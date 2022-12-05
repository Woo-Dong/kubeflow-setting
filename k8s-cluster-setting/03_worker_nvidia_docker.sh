curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | sudo apt-key add -
distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | sudo tee /etc/apt/sources.list.d/nvidia-docker.list
sudo apt-get update &&
sudo apt-get install -y nvidia-docker2 &&
sudo systemctl restart docker

echo '{ "default-runtime": "nvidia", "runtimes": { "nvidia": { "path": "nvidia-container-runtime", "runtimeArgs": [] } } }' | sudo tee /etc/docker/daemon.json > /dev/null
sudo systemctl daemon-reload && sudo systemctl restart docker

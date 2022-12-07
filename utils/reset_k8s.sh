#!/bin/bash

sudo kubeadm reset # Enter "yes"

sudo systemctl restart kubelet

sudo reboot
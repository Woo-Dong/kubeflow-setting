#!/bin/bash

sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
curl -LO https://dl.k8s.io/release/v1.24.9/bin/linux/amd64/kubectl
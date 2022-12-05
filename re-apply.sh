#!/bin/bash

kustomize build kubeflow_install | kubectl apply -f -
#!/bin/bash

helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm install prometheus prometheus-community/kube-prometheus-stack --namespace monitoring
helm -n monitoring upgrade --install prometheus-pushgateway prometheus-community/prometheus-pushgateway
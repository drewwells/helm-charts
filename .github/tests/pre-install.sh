#!/usr/bin/env bash

set -xe

SCRIPT="$(readlink -f "$0")"
SCRIPTPATH="$(dirname "${SCRIPT}")"
DEPS="${SCRIPTPATH}/dependencies"

# Set repo and version env variables
REPOS=$(jq -r '.[] | "export " + ("HELM_REPO_" + .name | ascii_upcase | gsub("-";"_")) + "=" + .repo' "${SCRIPTPATH}/charts.json")
VERSIONS=$(jq -r '.[] | "export " + ("VERSION_" + .name | ascii_upcase | gsub("-";"_")) + "=" + .version' "${SCRIPTPATH}/charts.json")
eval "$REPOS"
eval "$VERSIONS"

helm_install=(helm upgrade --install --create-namespace)

# namespace override
kubectl create namespace spire-system
kubectl create namespace spire-server

# nginx ingress
"${helm_install[@]}" ingress-nginx ingress-nginx --version "${VERSION_INGRESS_NGINX}" --repo "${HELM_REPO_INGRESS_NGINX}" \
  --namespace ingress-nginx \
  --set controller.extraArgs.enable-ssl-passthrough='' \
  --wait
kubectl wait --namespace ingress-nginx --for=condition=ready pod --selector=app.kubernetes.io/component=controller

# prometheus
"${helm_install[@]}" kube-prometheus-stack kube-prometheus-stack \
  --namespace prometheus \
  --version "${VERSION_KUBE_PROMETHEUS_STACK}" \
  --repo "${HELM_REPO_KUBE_PROMETHEUS_STACK}" \
  --wait

# cert-manager
"${helm_install[@]}" cert-manager cert-manager --version "$VERSION_CERT_MANAGER" --repo "$HELM_REPO_CERT_MANAGER" \
  --namespace cert-manager \
  --set installCRDs=true \
  --wait

kubectl apply -f "${DEPS}/cert-manager-ca.yaml"

# external database

# mysql
"${helm_install[@]}" mysql mysql --version "$VERSION_MYSQL" --repo "$HELM_REPO_MYSQL" \
  --namespace mysql \
  --values "${DEPS}/mysql.yaml" \
  --wait

# postgres
"${helm_install[@]}" postgresql postgresql --version "$VERSION_POSTGRESQL" --repo "$HELM_REPO_POSTGRESQL" \
  --namespace postgresql \
  --values "${DEPS}/postgresql.yaml" \
  --wait

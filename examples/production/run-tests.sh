#!/usr/bin/env bash

set -xe

SCRIPT="$(readlink -f "$0")"
SCRIPTPATH="$(dirname "${SCRIPT}")"

helm_install=(helm upgrade --install --create-namespace)
ns=spire-server

teardown() {
  kubectl delete --namespace "${ns}" deployment spire-spiffe-oidc-discovery-provider --wait || true
  helm uninstall --namespace "${ns}" spire 2>/dev/null || true
  kubectl delete ns "${ns}" 2>/dev/null || true
  kubectl delete ns spire-system 2>/dev/null || true
}

trap 'trap - SIGTERM && teardown' SIGINT SIGTERM EXIT

kubectl create namespace spire-system 2>/dev/null || true
kubectl label namespace spire-system pod-security.kubernetes.io/enforce=privileged || true
kubectl create namespace "${ns}" 2>/dev/null || true
kubectl label namespace "${ns}" pod-security.kubernetes.io/enforce=restricted || true

"${helm_install[@]}" --namespace "${ns}" --values "${SCRIPTPATH}/values.yaml" --wait spire charts/spire
helm test --namespace "${ns}" spire

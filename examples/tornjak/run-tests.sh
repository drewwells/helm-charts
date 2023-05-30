#!/usr/bin/env bash

set -xe

SCRIPT="$(readlink -f "$0")"
SCRIPTPATH="$(dirname "${SCRIPT}")"

helm_install=(helm upgrade --install --create-namespace)
ns=spire-system

teardown() {
  helm uninstall --namespace "${ns}" spire 2>/dev/null || true
  kubectl delete ns "${ns}" 2>/dev/null || true
}

trap 'trap - SIGTERM && teardown' SIGINT SIGTERM EXIT

"${helm_install[@]}" --namespace "${ns}" --values "${SCRIPTPATH}/values.yaml" --wait spire charts/spire
helm test --namespace "${ns}" spire

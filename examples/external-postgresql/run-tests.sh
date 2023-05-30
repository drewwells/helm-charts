#!/usr/bin/env bash

set -xe

SCRIPT="$(readlink -f "$0")"
SCRIPTPATH="$(dirname "${SCRIPT}")"
TESTDIR=${SCRIPTPATH}/../../.github/tests
DEPS="${TESTDIR}/dependencies"

REPOS=$(jq -r '.[] | "export " + ("HELM_REPO_" + .name | ascii_upcase | gsub("-";"_")) + "=" + .repo' "${TESTDIR}/charts.json")
VERSIONS=$(jq -r '.[] | "export " + ("VERSION_" + .name | ascii_upcase | gsub("-";"_")) + "=" + .version' "${TESTDIR}/charts.json")
eval "$REPOS"
eval "$VERSIONS"

helm_install=(helm upgrade --install --create-namespace)
ns=spire-system

teardown() {
  helm uninstall --namespace "${ns}" spire 2>/dev/null || true
  kubectl delete ns "${ns}" 2>/dev/null || true

  helm uninstall --namespace postgresql postgresql 2>/dev/null || true
  kubectl delete ns postgresql 2>/dev/null || true
}

trap 'trap - SIGTERM && teardown' SIGINT SIGTERM EXIT

"${helm_install[@]}" postgresql postgresql --version "$VERSION_POSTGRESQL" --repo "$HELM_REPO_POSTGRESQL" \
  --namespace postgresql \
  --values "${DEPS}/postgresql.yaml" \
  --wait

"${helm_install[@]}" --namespace "${ns}" --values "${SCRIPTPATH}/values.yaml" --wait spire charts/spire
helm test --namespace "${ns}" spire

#!/usr/bin/env bash

set -xe

SCRIPT="$(readlink -f "$0")"
SCRIPTPATH="$(dirname "${SCRIPT}")"

helm install \
  --namespace spire-server \
  --values "${SCRIPTPATH}/../../../examples/production/values.yaml" \
  --values "${SCRIPTPATH}/values.yaml" \
  spire charts/spire --wait

helm test spire --namespace spire-server

set +e
if helm get manifest -n spire-server spire | grep -i example; then
  echo Global settings did not work. Please fix.
  exit 1
fi

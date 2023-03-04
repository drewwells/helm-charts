#!/usr/bin/env bash

set -x

SCRIPT=$(readlink -f "$0")
SCRIPTPATH=$(dirname "$SCRIPT")
NS="${SCRIPTPATH##*/}"

# shellcheck source=/dev/null
source "${SCRIPTPATH}/../common.sh"

k_wait=(kubectl wait --for condition=available --timeout 30s --namespace)
k_rollout_status=(kubectl rollout status --watch --timeout 30s --namespace)

cat <<EOF >>"$GITHUB_STEP_SUMMARY"
### cert-manager

| workload | Status |
| -------- | ------ |
| cert-manager | $("${k_wait[@]}" cert-manager deployments.apps cert-manager) |
| cert-manager-cainjector | $("${k_wait[@]}" cert-manager deployments.apps cert-manager-cainjector) |
| cert-manager-webhook | $("${k_wait[@]}" cert-manager deployments.apps cert-manager-webhook) |
EOF

cat <<EOF >>"$GITHUB_STEP_SUMMARY"
### spire

| workload | Status |
| -------- | ------ |
| spire-server | $("${k_rollout_status[@]}" "${NS}" statefulset spire-server) |
| spire-spiffe-csi-driver | $("${k_rollout_status[@]}"  "${NS}" daemonset spire-spiffe-csi-driver) |
| spire-agent | $("${k_rollout_status[@]}" "${NS}" daemonset spire-agent) |
EOF

if [ $1 -ne 0 ]; then
  get_namespace_details "${NS}"
fi

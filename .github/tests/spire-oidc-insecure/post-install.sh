#!/usr/bin/env bash

set -x

SCRIPT=$(readlink -f "$0")
SCRIPTPATH=$(dirname "$SCRIPT")
NS="${SCRIPTPATH##*/}"

k_wait=(kubectl wait --for condition=available --timeout 30s --namespace)
k_rollout_status=(kubectl rollout status --watch --timeout 30s --namespace)

cat <<EOF >>"$GITHUB_STEP_SUMMARY"
### spire

| workload | Status |
| -------- | ------ |
| spire-server | $("${k_rollout_status[@]}" "$NS" statefulset spire-server) |
| spire-spiffe-csi-driver | $("${k_rollout_status[@]}" "$NS" daemonset spire-spiffe-csi-driver) |
| spire-agent | $("${k_rollout_status[@]}" "$NS" daemonset spire-agent) |
| spire-spiffe-oidc-discovery-provider | $("${k_wait[@]}" "$NS" deployments.apps spire-spiffe-oidc-discovery-provider) |
EOF

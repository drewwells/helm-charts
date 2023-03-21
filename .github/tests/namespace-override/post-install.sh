#!/usr/bin/env bash

set -x

SCRIPT=$(readlink -f "$0")
SCRIPTPATH=$(dirname "$SCRIPT")

k_wait () {
  kubectl wait --for condition=available --timeout 30s --namespace "$1" "$2" "$3" | tail -n 1
}

k_rollout_status () {
  kubectl rollout status --watch --timeout 30s --namespace "$1" "$2" "$3" | tail -n 1
}

RELEASE=$(helm ls --no-headers -n "${scenario}" | awk '{print $1}' | grep 'spire-[^-]*$')

cat <<EOF >>"$GITHUB_STEP_SUMMARY"
### release
| release |
| ------- |
| $RELEASE |

### spire
| workload | Status |
| -------- | ------ |
| spire-server | <pre>$(k_rollout_status spire-server statefulset "${RELEASE}-server")</pre> |
| spire-spiffe-csi-driver | <pre>$(k_rollout_status spire-system daemonset "${RELEASE}-spiffe-csi-driver")</pre> |
| spire-agent | <pre>$(k_rollout_status spire-system daemonset "${RELEASE}-agent")</pre> |
| spire-spiffe-oidc-discovery-provider | <pre>$(k_wait spire-server deployments.apps "${RELEASE}-spiffe-oidc-discovery-provider")</pre> |
EOF

if [ $1 -ne 0 ]; then
  get_namespace_details spire-server
  get_namespace_details spire-systen
fi


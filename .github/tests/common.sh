#!/usr/bin/env bash

function get_namespace_details {
cat <<EOF >>"$GITHUB_STEP_SUMMARY"
### Namespace $1

#### Events

\`\`\`shell
$(kubectl --request-timeout=30s get events --output wide --namespace "$1")
\`\`\`

#### Pods

\`\`\`shell
$(kubectl --request-timeout=30s describe pods --namespace "$1")
\`\`\`

#### Logs

\`\`\`shell
$(kubectl get pods -o name -n "$1" | while read -r line; do echo logs for "${line}"; kubectl logs -n "$1" "${line}" --all-containers=true --ignore-errors=true; done)
\`\`\`

EOF
}

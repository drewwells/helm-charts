#!/usr/bin/env bash

set -x

SCRIPT="$(readlink -f "$0")"
SCRIPTPATH="$(dirname "${SCRIPT}")"
scenario="${scenario:-$(basename "${SCRIPTPATH}")}"

# shellcheck source=/dev/null
source "${SCRIPTPATH}/../common.sh"

print_helm_releases
print_spire_workload_status spire-server spire-system

if [[ "$1" -ne 0 ]]; then
  get_namespace_details spire-server
  get_namespace_details spire-system
fi

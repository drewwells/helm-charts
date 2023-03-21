#!/usr/bin/env bash

set -x

SCRIPT=$(readlink -f "$0")
SCRIPTPATH=$(dirname "$SCRIPT")
NS="${SCRIPTPATH##*/}"

# shellcheck source=/dev/null
source "${SCRIPTPATH}/../common.sh"

if [ $1 -ne 0 ]; then
  get_namespace_details "${NS}"
fi

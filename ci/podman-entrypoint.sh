#!/usr/bin/env bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=ci/uid-setup.sh
source "${SCRIPT_DIR}/uid-setup.sh" 2>/dev/null \
  || source /uid-setup.sh 2>/dev/null \
  || true

exec "$@"

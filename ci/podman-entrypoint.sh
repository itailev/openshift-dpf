#!/usr/bin/env bash
# Entrypoint for rootless podman in OpenShift CI pods.
# Delegates passwd/subuid setup to uid-setup.sh (also used via BASH_ENV
# when Prow overrides the ENTRYPOINT), then configures podman storage.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=ci/uid-setup.sh
source "${SCRIPT_DIR}/uid-setup.sh" 2>/dev/null \
  || source /uid-setup.sh 2>/dev/null \
  || true

# Podman storage and registry configuration
if [ ! -d "${HOME}/.config/containers" ]; then
  mkdir -p "${HOME}/.config/containers"
  if [ -c "/dev/fuse" ] && [ -f "/usr/bin/fuse-overlayfs" ]; then
    cat > "${HOME}/.config/containers/storage.conf" <<'EOF'
[storage]
driver = "overlay"
graphroot = "/tmp/graphroot"
[storage.options.overlay]
mount_program = "/usr/bin/fuse-overlayfs"
EOF
  else
    cat > "${HOME}/.config/containers/storage.conf" <<'EOF'
[storage]
driver = "vfs"
EOF
  fi
fi

exec "$@"

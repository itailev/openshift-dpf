#!/usr/bin/env bash
# Sourced via BASH_ENV for OpenShift CI pods where Prow overrides the
# container ENTRYPOINT. Creates /etc/passwd and subuid/subgid entries for
# the arbitrary UID that OpenShift assigns (runs once, guarded by envvar).

[ -n "${_UID_SETUP_DONE:-}" ] && return 0
export _UID_SETUP_DONE=1

if [ ! -d "${HOME}" ]; then
  mkdir -p "${HOME}" 2>/dev/null || true
fi

# Create passwd/group entry for the arbitrary UID if missing
if ! getent passwd "$(id -u)" &>/dev/null; then
  if [ -w /etc/passwd ]; then
    echo "${USER_NAME:-user}:x:$(id -u):0:${USER_NAME:-user} user:${HOME}:/bin/bash" >> /etc/passwd
  fi
  if [ -w /etc/group ]; then
    echo "${USER_NAME:-user}:x:$(id -u):" >> /etc/group
  fi
fi

# Create subuid/subgid ranges for rootless podman.
# Start just above the running UID to avoid overlap (the third field is the
# count, not an end ID). Works for any UID, including OpenShift's arbitrary
# high UIDs like 1000650000.
if [ -w /etc/subuid ]; then
  _UID_SETUP_USER=$(id -un 2>/dev/null || echo "$(id -u)")
  _UID_SETUP_START=$(( $(id -u) + 1 ))
  echo "${_UID_SETUP_USER}:${_UID_SETUP_START}:65536" > /etc/subuid
  echo "${_UID_SETUP_USER}:${_UID_SETUP_START}:65536" > /etc/subgid
  unset _UID_SETUP_USER _UID_SETUP_START
fi

#!/usr/bin/env bash
# Sourced via BASH_ENV for OpenShift CI pods where Prow overrides the
# container ENTRYPOINT. Creates /etc/passwd and subuid/subgid entries for
# the arbitrary UID that OpenShift assigns (runs once, guarded by envvar).

[ -n "${_UID_SETUP_DONE:-}" ] && return 0
export _UID_SETUP_DONE=1

_UID_CUR="$(id -u)"
_UID_DESIRED_NAME="${USER_NAME:-user}"

if [ ! -d "${HOME}" ]; then
  mkdir -p "${HOME}" 2>/dev/null || true
fi

# Create passwd/group entry for the arbitrary UID if missing.
# If the container runtime already created one with a numeric username
# (e.g. "1003960000"), rename it: podman's subuid lookup matches both
# username and UID-as-string, so a numeric name causes the same range
# to be counted twice, producing overlapping uid_map mappings (EINVAL).
# Note: sed -i can't be used here because it creates a temp file in
# /etc which is not writable by non-root. We write directly instead.
if ! getent passwd "${_UID_CUR}" &>/dev/null; then
  if [ -w /etc/passwd ]; then
    echo "${_UID_DESIRED_NAME}:x:${_UID_CUR}:0:${_UID_DESIRED_NAME} user:${HOME}:/bin/bash" >> /etc/passwd
  fi
  if [ -w /etc/group ]; then
    echo "${_UID_DESIRED_NAME}:x:${_UID_CUR}:" >> /etc/group
  fi
elif [ -w /etc/passwd ]; then
  _UID_CUR_NAME="$(id -un 2>/dev/null || echo "${_UID_CUR}")"
  case "${_UID_CUR_NAME}" in
    *[!0-9]*) ;;  # already non-numeric, leave it
    *)
      _UID_TMP=$(sed "s/^${_UID_CUR_NAME}:/${_UID_DESIRED_NAME}:/" /etc/passwd)
      printf '%s\n' "${_UID_TMP}" > /etc/passwd
      unset _UID_TMP
      ;;
  esac
fi

# Create subuid/subgid ranges for rootless podman.
# Use the effective username (may differ from _UID_DESIRED_NAME if the
# account already existed with a non-numeric name we chose to keep).
if [ -w /etc/subuid ]; then
  _UID_EFFECTIVE_NAME="$(id -un 2>/dev/null || echo "${_UID_DESIRED_NAME}")"
  _UID_SETUP_START=$(( _UID_CUR + 1 ))
  echo "${_UID_EFFECTIVE_NAME}:${_UID_SETUP_START}:65536" > /etc/subuid
  echo "${_UID_EFFECTIVE_NAME}:${_UID_SETUP_START}:65536" > /etc/subgid
  unset _UID_SETUP_START _UID_EFFECTIVE_NAME
fi

unset _UID_CUR _UID_DESIRED_NAME _UID_CUR_NAME

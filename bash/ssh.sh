#!/bin/bash

########################################################################
# Generate a RSA ssh key from the given number of bits.
# The filename of the key respects this format: "~/.ssh/yyyy-mm-dd.id_rsa"
# Arguments:
#  The number of bits in the key to create by default 4096.
# Outputs:
#  ssh-keygen outputs.
########################################################################
function ssh-keygen-rsa () {
  local -l c
  >&2 printf "%s\n" \
    "Prefer ed25519 key" \
    "Continue to generate rsa one?"
  read -p "[Y/n] " c
  if [ "${c}" = "n" ]; then
    ssh-keygen-ed25519
    return
  fi
  ssh-keygen -t rsa -b "${1:-4096}" -f "${HOME}/.ssh/$(date -I).id_${1}"
}

########################################################################
# Generate an ed25519 ssh key.
# The filename of the key respects this format: "~/.ssh/yyyy-mm-dd.id_ecdsa"
# Outputs:
#  ssh-keygen outputs.
########################################################################
function ssh-keygen-ed25519 () {
  ssh-keygen -t ed25519 -f "${HOME}/.ssh/$(date -I).id_ed25519"
}

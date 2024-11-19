#!/bin/bash

########################################################################
# Generate a ssh key from the given type and the number of bits.
# The filename of the key respects this format: "~/.ssh/yyyy-mm-dd.id_{type}"
# Arguments:
#  The type of the key to create.
#  The number of bits in the key to create.
# Outputs:
#  ssh-keygen outputs.
########################################################################
# ALG BITS 
function ssh::keygen () {
  ssh-keygen -t "${1}" -b "${2}" -f "${HOME}/.ssh/$(date -I).id_${1}"
}

########################################################################
# Generate a RSA ssh key from the given number of bits.
# The filename of the key respects this format: "~/.ssh/yyyy-mm-dd.id_rsa"
# Arguments:
#  The number of bits in the key to create by default 3072.
# Outputs:
#  ssh-keygen outputs.
########################################################################
function ssh-keygen-rsa () {
  ssh::keygen rsa "${1:-3072}"
}

########################################################################
# Generate an ECDSA ssh key from the given number of bits.
# The filename of the key respects this format: "~/.ssh/yyyy-mm-dd.id_ecdsa"
# Arguments:
#  The number of bits in the key to create by default 256.
# Outputs:
#  ssh-keygen outputs.
########################################################################
function ssh-keygen-ecdsa () {
  ssh::keygen ecdsa "${1:-256}"
}

#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

declare -r BASH_ALIASES="${HOME}/.bash_aliases" OUTILS_DIR="${1:-${PWD}}"
declare fonction="${OUTILS_DIR}/bash/fonction.sh"

if [ ! -s "${fonction}" ]; then
  echo "ERROR: File doesn't exist or is empty." >&2
  echo "${fonction}" >&2
  exit 1
fi

tee -a "${BASH_ALIASES}" <<EOF 
source "${fonction}"
EOF
echo "Written in: ${BASH_ALIASES}"

echo "Copy dotfiles"
cp -v "${OUTILS_DIR}"/dotfile/.* "${HOME}"

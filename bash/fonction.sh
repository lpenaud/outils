#!/bin/bash
#
# Utility multi-os Bash functions.
# Fonctions means functions in french.
# Any question?
# Ask me at lpenaud@zaclys.net
#

declare -r FONCTION_ROOT="$(dirname "$(realpath "${BASH_SOURCE}")")"
declare -r SSH_AGENT="${HOME}/.ssh-agent"

########################################################################
# Run a fonction Bash script according to OSTYPE.
# Globals:
#   FONCTION_ROOT
#   OSTYPE
# Arguments:
#   Scripts fonction
########################################################################
function fonction::os_script () {
  local -a scripts=("${FONCTION_ROOT}/${1}/${OSTYPE}.sh" "${FONCTION_ROOT}/${1}/${1}.sh")
  local script
  for script in "${scripts[@]}"; do
    if [ -f "${script}" ]; then
      source "${script}"
      return
    fi
  done
  echo "Cannot find theses scripts:" >&2
  printf "  - %s\n" ${scripts[@]} >&2
  return 1
}

########################################################################
# Print a warning message to STDERR.
# Arguments:
#   Warning message
#   ...Stack
########################################################################
function fonction::warning () {
  printf "WARNING: %s\n" "${1}" >&2
  shift
  if [ $# -ne 0 ]; then
    printf "  %s\n" "$@" >&2
  fi
}

########################################################################
# Test if all required functions are implemented.
# Arguments:
#  ...Function to tests
# Returns:
#  1 If a fonction is missing otherwise 0.
########################################################################
function fonction::test_impl () {
  local -a missings
  while [ $# -ne 0 ]; do
    if ! type -p "${1}" &> /dev/null; then
      missings+=("${1}")
    fi
    shift
  done
  if [ "${#missings}" -eq 0 ]; then
    return 0
  fi
  fonction::warning "Missing implementations:" "${missings[@]}"
  return 1
}

########################################################################
# Add a directory to the PATH.
# Test if the given directory.
# Arguments:
#   Directory to add.
########################################################################
function add2path () {
  if [ ! -d "${1}" ]; then
    printf "Path directory not found: '%s'\n" "${1}" >&2
    return 1
  fi
  export PATH="${1}:${PATH}"
}

########################################################################
# Set JAVA_HOME and print it.
# If Java major version is not given, just print the current JAVA_HOME.
# Arguments:
#   Java major version to set.
########################################################################
function java_home () {
  if [ -n "${1}" ]; then
    java::home "${1}"
  fi
  echo "${JAVA_HOME}"
}

########################################################################
# Print well formatted xml content from user graphical clipboard.
########################################################################
function xmlout () {
  clipout | xmllint --format --output "${1:--}" -
}

########################################################################
# Set JAVA_HOME and CATALINA_HOME from the sourceCompatibility on a Gradle build file.
# Arguments:
#   Gradle build file path (by default 'build.gradle')
# Globals:
#   JAVA_HOME
#   CATALINA_HOME
# Returns:
#   1 If the asked Java version it's doesn't exist on opt directory.
#   2 If the asked Tomcat version it's doesn't exist on opt directory.
#   3 If sourceCompatibility is not readable from the Gradle build file.
########################################################################
function java_gradle () {
  java::gradle "${1}" && java_home
}

########################################################################
# Open Git repository on Website IHM.
# Returns:
#  1 If it's impossible to get 'origin' repository url.
########################################################################
function g. () {
  local -r url="$("${FUNCTIONS_ROOT}/scripts/git.ts" "get-url" $@)"
  if [ -z "${url}" ]; then
    return 1
  fi
  echo "${url}"
  open "${url}"
}

########################################################################
# Open the current directory on Codium.
# See: https://vscodium.com/
########################################################################
function c. () {
  codium .
}

########################################################################
# Open the current directory on Vim.
# See: https://www.vim.org/
########################################################################
function v. () {
  vim .
}

########################################################################
# Generate base64 from a file.
# Arguments:
#  File to convert into 64.
# Returns:
#  1 If the file is not given or doesn't exist otherwise 0.
########################################################################
function clip64 () {
  local -r infile="${1}"
  if [ -z "${infile}" ]; then
    printf "Usage: %s INFILE\n" \
      "${FUNCNAME}" \
      >&2
    return 1
  fi
  if [ ! -f "${infile}" ]; then
    printf "The file '%s' doesn't exists\n" \
      "${infile}" \
      >&2
    return 1
  fi
  base64 -w 0 "${infile}" | clipin
}

########################################################################
# Generate PDF from a base64 string stored into graphical user clipboard.
# Arguments:
#  Output file (by default generate a temporary file)
# Outputs:
#  Show PDF path 
########################################################################
function pdf64 () {
  local -r outfile="${1:-"$(mktemp --suffix=.pdf)"}"
  clipout | base64 -d > "${outfile}" \
    && open "${outfile}"
  echo "${outfile}"
}

########################################################################
# Transform text to upper case.
# Arguments:
#  Text to tranform
# Outputs:
#  Text transformed to upper case
########################################################################
function uppercase () {
  while [ $# -ne 0 ]; do
    echo "${1^^}"
    shift
  done
}

########################################################################
# Transform text to lower case.
# Arguments:
#  Text to transform
# Outputs:
#  Text transformed to lower case
########################################################################
function lowercase () {
  while [ $# -ne 0 ]; do
    echo "${1,,}"
    shift
  done
}

########################################################################
# Get string length.
# Arguments:
#  Input string
# Outputs:
#  Input string length
########################################################################
function length () {
  while [ $# -ne 0 ]; do
    echo "${#1}"
    shift
  done
}

########################################################################
# Show a calculation result.
# Arguments:
#  Calcul
# Outputs:
#  Calcul result
########################################################################
function calc () {
  echo "$(( ${1} ))"
}

########################################################################
# Extract Node major version from package.json
# Arguments:
#  Path of package.json (by default 'package.json')
# Returns:
#  1 if Node version cannot be read.
########################################################################
function nvmuse () {
  # Get the version string
  local -r version="$(jq --raw-output .engines.node "${1:-package.json}")"
  # Get the major version
  if [[ ! "${version}" =~ ^([0-9]+) ]]; then
    echo "Cannot find node version" >&2
    return 1
  fi
  # Use nvm to use
  nvm use "${BASH_REMATCH[1]}"
}

########################################################################
# Ask boolean choice to a user (by default is true).
# Arguments:
#  Optionnally a message to a user before the read prompt
# Returns:
#  0 if yes, 1 if no, otherwise 2.
########################################################################
function confirm () {
  local -l bool
  if [ -n "${1}" ]; then
    # Read prompt write on stderr
    echo "${1}" >&2
  fi
  read -r -p "[Y/n] " bool
  if [ -z "${bool}" ] || [ "${bool}" = "y" ]; then
    return 0
  fi
  if [ "${bool}" = "n" ]; then
    return 1
  fi
  return 2
}

########################################################################
# Use existing SSH Agent or create one.
# Create a file in the user home with the ssh-agent output.
# Outputs:
#   SSH agent variables.
########################################################################
function sshagent () {
  if [ -s "${SSH_AGENT}" ]; then
    cat "${SSH_AGENT}"
    if ! confirm "Launch this script?"; then
      ssh-agent > "${SSH_AGENT}"
    fi
  else 
    ssh-agent > "${SSH_AGENT}"
  fi
  source "${SSH_AGENT}" &> /dev/null
  if ! ps -p "${SSH_AGENT_PID}" > /dev/null; then
    ssh-agent > "${SSH_AGENT}"
    source "${SSH_AGENT}"
  fi
  printf "%s=%s\n" "SSH_AGENT" "${SSH_AGENT}" \
    "SSH_AUTH_SOCK" "${SSH_AUTH_SOCK}" \
    "SSH_AGENT_PID" "${SSH_AGENT_PID}"
}

# Vim are the best editor I known
# Fly Emacs and Nano (especially Nano)
export EDITOR=vim

fonction::os_script fonction
fonction::os_script java

if [ -s "${FONCTION_ROOT}/git-prompt/gitprompt.sh" ]; then
   GIT_PROMPT_ONLY_IN_REPO=1
   sshagent
   source "${FONCTION_ROOT}/git-prompt/gitprompt.sh" 
fi

java::home 17

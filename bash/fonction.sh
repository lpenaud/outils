#!/bin/bash
#
# Utility multi-os Bash functions.
# Fonctions means functions in french.
# Any question?
# Ask me at lpenaud@zaclys.net
#

declare -r FONCTION_ROOT="$(dirname "$(realpath "${BASH_SOURCE}")")"

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
    if ! type -p "${1}" 2> /dev/null; then
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

fonction::os_script fonction

fonction::os_script java

java::home 17

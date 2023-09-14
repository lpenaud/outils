#
# Utility functions.
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
# Add a directory to the PATH.
# Test if the given directory.
# Arguments:
#   Directory to add.
########################################################################
function add2path () {
  if [ -d "${1}" ]; then
    export PATH="${1}:${PATH}"
  fi
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

##########################################################
# Open Git repository on Website IHM.
# Returns:
#  1 If it's impossible to get 'origin' repository url.
##########################################################
function g. () {
  local -r url="$("${FUNCTIONS_ROOT}/scripts/git.ts" "gitlab-url" $@)"
  if [ -z "${url}" ]; then
    return 1
  fi
  echo "${url}"
  open "${url}"
}

fonction::os_script fonction
fonction::os_script java

java::home 17

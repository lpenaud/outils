
declare -r FONCTION_ROOT="$(dirname "$(realpath "${BASH_SOURCE}")")"

function fonction::os_script () {
  local -r script="${FONCTION_ROOT}/${1}/${OSTYPE}.sh"
  if [ ! -f "${script}" ]; then
    echo "Unknown OSTYPE: ${OSTYPE} to '${1}'" >&2
    return 1
  fi
  source "${script}"
}

function add2path () {
  if [ -d "${1}" ]; then
    export PATH="${1}:${PATH}"
  fi
}

function java_home () {
  if [ -n "${1}" ]; then
    java::home "${1}"
  fi
  echo "${JAVA_HOME}"
}

fonction::os_script "fonction"
source "${FONCTION_ROOT}/java/java.sh"

java_home 17

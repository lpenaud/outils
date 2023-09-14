########################################################################
# Return Java Developer Kit (JDK) absolute path from the major version number.
# Outputs:
#   The JDK absolute path according to the given version.
# Returns:
#   1 If the asked JDK doesn't exist on the current system.
########################################################################
function java::jdk () {
  local -r jdk="/opt/java${1}"
  if [ ! -d "${jdk}" ]; then
    echo "Unknow jdk: '${jdk}'" >&2
    return 1
  fi
  echo "${jdk}"
}

########################################################################
# Return Tomcat absolute path from the major version number.
# Outputs:
#   The Tomcat absolute path according to the given version.
# Returns:
#   1 If the asked Tomcat doesn't exist on the current system.
########################################################################
function java::tomcat () {
  local -r tomcat="/opt/tomcat${1}"
  if [ ! -d "${tomcat}" ]; then
    echo "Unknow tomcat: '${tomcat}'" >&2
    return 1
  fi
  echo "${tomcat}"
}

########################################################################
# Return Tomcat absolute path from the Java major version number.
# Outputs:
#   The Tomcat absolute path according to the given Java major version.
# Returns:
#   1 If the asked Tomcat doesn't exist on opt directory.
########################################################################
function java::jdk_tomcat () {
  local -i version="${1}"
  if [ "${1}" -gt 8 ]; then
    version=9
  fi
  java::tomcat "${version}"
}

########################################################################
# Set JAVA_HOME and CATALINA_HOME from a Java version.
# Globals:
#   JAVA_HOME
#   CATALINA_HOME
# Returns:
#   1 If the asked Java version it's doesn't exist on opt directory.
#   2 If the asked Tomcat version it's doesn't exist on opt directory.
########################################################################
function java::home () {
  local -r jdk="$(java::jdk "${1}")"
  local -r tomcat="$(java::jdk_tomcat "${1}")"
  if [ -z "${jdk}" ]; then
    return 1
  fi
  export JAVA_HOME="${jdk}"
  add2path "${jdk}/bin"
  if [ -z "${tomcat}" ]; then
    return 2
  fi
  export CATALINA_HOME="${tomcat}"
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
function java::gradle () {
  local -r buildfile="${1:-build.gradle}"
  if [[ "$(grep -m 1 'sourceCompatibility' "${buildfile}")" =~ [0-9]+$ ]]; then
    java::home "${BASH_REMATCH[0]}"
    return
  fi
  printf "Cannot extract java version from:\n%s\n" \
    "${buildfile}" >&2
  return 3
}

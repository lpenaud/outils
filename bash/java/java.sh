function java::jdk () {
  local -r jdk="/opt/java${1}"
  if [ ! -d "${jdk}" ]; then
    echo "Unknow jdk: '${jdk}'" >&2
    return 1
  fi
  echo "${jdk}"
}

function java::tomcat () {
  local -r tomcat="/opt/tomcat${1}"
  if [ ! -d "${tomcat}" ]; then
    echo "Unknow tomcat: '${tomcat}'" >&2
    return 1
  fi
  echo "${tomcat}"
}

function java::jdk_tomcat () {
  local -i version="${1}"
  if [ "${1}" -gt 8 ]; then
    version=9
  fi
  java::tomcat "${version}"
}

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

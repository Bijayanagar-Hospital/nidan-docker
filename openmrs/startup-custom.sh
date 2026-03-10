#!/bin/bash -aeu
#       Custom startup script for Nidan to inject Hibernate Dialect

source /openmrs/startup-init.sh

echo "Waiting for database to initialize..."

/openmrs/wait-for-it.sh -t 3600 -h "${OMRS_DB_HOSTNAME}" -p "${OMRS_DB_PORT}"

wait_for_es()
{
        IFS=',' read -a es_uris <<< "${OMRS_SEARCH_ES_URIS}"
    
    EXIT_STATUS=1  
    while [ $EXIT_STATUS -ne 0 ]
    do
                for es_uri in "${es_uris[@]}"; do
                        echo "Waiting for ES node ${es_uri} to initialize..."
                        ELASTIC_SEARCH_HOST_PORT=(${es_uri//// })
                        /openmrs/wait-for-it.sh -t 15 "${ELASTIC_SEARCH_HOST_PORT[1]}" 
                        EXIT_STATUS=$?
                        if [ $EXIT_STATUS -eq 0 ]; then
                break 
            fi
            
                done
    done
    
    return 0
}

if [ "${OMRS_SEARCH}" = "elasticsearch" ]; then
        set +e
        echo "Waiting for ElasticSearch ${OMRS_SEARCH_ES_URIS} to initialize..."
        wait_for_es
        set -e
fi

TOMCAT_DIR="/usr/local/tomcat"
TOMCAT_WEBAPPS_DIR="$TOMCAT_DIR/webapps"
TOMCAT_WORK_DIR="$TOMCAT_DIR/work"
TOMCAT_TEMP_DIR="$TOMCAT_DIR/temp"
TOMCAT_SETENV_FILE="$TOMCAT_DIR/bin/setenv.sh"

echo "Clearing out Tomcat directories"

rm -fR "${TOMCAT_WEBAPPS_DIR:?}"/*
rm -fR "${TOMCAT_WORK_DIR:?}"/*
rm -fR "${TOMCAT_TEMP_DIR:?}"/*

echo "Extracting and Injecting Nidan PostgreSQL Dialect..."
cp "${OMRS_DISTRO_CORE}/openmrs.war" "${TOMCAT_WEBAPPS_DIR}/openmrs.war"
mkdir -p "${TOMCAT_WEBAPPS_DIR}/openmrs"
cd "${TOMCAT_WEBAPPS_DIR}/openmrs"
jar xf ../openmrs.war
mkdir -p WEB-INF/lib
cp /tmp/nidan-dialect.jar WEB-INF/lib/
rm ../openmrs.war

 if [ -f "${OMRS_RUNTIME_PROPERTIES_FILE}" ]; then
  echo "Force updating ${OMRS_RUNTIME_PROPERTIES_FILE} with Nidan specific settings"
  # Replace dialect, even if it has different casing or formatting
  sed -i 's/^hibernate\.dialect=.*/hibernate\.dialect=org\.openmrs\.hibernate\.dialect\.NidanPostgreSQLDialect/' "${OMRS_RUNTIME_PROPERTIES_FILE}"
  
  # Update connection.url and remove potential backslash escapes
  # We'll use a more direct approach to make sure the URL is correct
  # Some OpenMRS images write escaped values (jdbc\:postgresql\://...) and we have
  # seen cases where the URL is split across lines, leaving a stray "/openmrs?..." line.
  # This breaks properties parsing and can also lead to CLOB handling issues.
  if grep -q '^/openmrs\?' "${OMRS_RUNTIME_PROPERTIES_FILE}"; then
    sed -i '/^\/openmrs\?/d' "${OMRS_RUNTIME_PROPERTIES_FILE}"
  fi

  if [ -n "${OMRS_DB_URL-}" ]; then
    # Force a clean, unescaped JDBC URL from the container environment.
    # Keep it single-line and always include stringtype=unspecified.
    url="${OMRS_DB_URL}"
    if [[ ! "$url" =~ "stringtype=unspecified" ]]; then
      if [[ "$url" == *"?"* ]]; then
        url="${url}&stringtype=unspecified"
      else
        url="${url}?stringtype=unspecified"
      fi
    fi
    if grep -q '^connection\.url=' "${OMRS_RUNTIME_PROPERTIES_FILE}"; then
      sed -i "s|^connection\.url=.*|connection.url=${url}|" "${OMRS_RUNTIME_PROPERTIES_FILE}"
    else
      echo "connection.url=${url}" >> "${OMRS_RUNTIME_PROPERTIES_FILE}"
    fi
  fi
  cat "${OMRS_RUNTIME_PROPERTIES_FILE}"
fi

echo "Writing out $TOMCAT_SETENV_FILE file"

JAVA_OPTS="$OMRS_JAVA_SERVER_OPTS"
CATALINA_OPTS="${OMRS_JAVA_MEMORY_OPTS} -DOPENMRS_INSTALLATION_SCRIPT=${OMRS_SERVER_PROPERTIES_FILE} -DOPENMRS_APPLICATION_DATA_DIRECTORY=${OMRS_DATA_DIR}/"

if [ -n "${OMRS_DEV_DEBUG_PORT-}" ]; then
  echo "Enabling debugging on port ${OMRS_DEV_DEBUG_PORT}"
  
  JAVA_VERSION=$(java -version 2>&1 | awk -F '"' '/version/ {print $2}' | awk -F '.' '/.*/ {print $1}')
  
  if [[ "$JAVA_VERSION" -gt "8" ]]; then
        CATALINA_OPTS="$CATALINA_OPTS -agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=*:${OMRS_DEV_DEBUG_PORT}"
  else
        CATALINA_OPTS="$CATALINA_OPTS -agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=${OMRS_DEV_DEBUG_PORT}"
  fi
fi

cat > $TOMCAT_SETENV_FILE << EOF
export JAVA_OPTS="$JAVA_OPTS"
export CATALINA_OPTS="$CATALINA_OPTS"
EOF

echo "Starting up OpenMRS..."

/usr/local/tomcat/bin/catalina.sh run &

# Trigger first filter to start data import
sleep 15
curl -sL "http://localhost:8080/${OMRS_WEBAPP_NAME}/" > /dev/null || true
sleep 15

# Bring tomcat process to foreground again
wait ${!}

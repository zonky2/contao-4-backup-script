#!/bin/bash

# Variablen bereinigen

# Slash am Ende entfernen (falls vorhanden -- ansonsten no-op)

CONTAO_DIR=${CONTAO_DIR%/}
TARGET_DIR=${TARGET_DIR%/}
SCRIPT_DIR=${SCRIPT_DIR%/}


# Slashes durch - ersetzen
# (und führendes - und - am Ende entfernen)

DUMP_NAME=$(echo ${DUMP_NAME} | tr '/' '-')
DUMP_NAME=${DUMP_NAME#-}
DUMP_NAME=${DUMP_NAME##-}

# Checks
# Existieren die angegebenen Verzeichnisse?

if [ ! -d ${SCRIPT_DIR} ]
then
    echo "SCRIPT_DIR: Verzeichnis ${SCRIPT_DIR} existiert nicht"
    exit 1
fi

if [ ! -d ${CONTAO_DIR} ]
then
    echo "CONTAO_DIR: Verzeichnis ${CONTAO_DIR} existiert nicht"
    exit 1
fi

if [ ! -d ${TARGET_DIR} ]
then
    echo "TARGET_DIR: Verzeichnis ${TARGET_DIR} existiert nicht"
    exit 1
fi


# Aktuelles Datum

NOW=$(date +"%Y-%m-%d")


# Backup des files/ Verzeichnisses erstellen?

if [ ${BACKUP_CONTAO_FILES} -gt 0 ]
then
    ( cd ${CONTAO_DIR} && tar cfz ${TARGET_DIR}/${DUMP_NAME}_files_${NOW}.tar.gz files )
fi


# Backup "der anderen" Dateien.

# read
# ### -r        ... raw input - disables interpretion of backslash escapes and line-continuation in the read data
# -d<DELIM> ... recognize <DELIM> as data-end, rather than <newline>

read -d '' FILE_LIST <<- EOF
  app/config/parameters.yml
  composer.json composer.lock
  system/config/localconfig.php
  templates
  web/.htaccess
EOF


( cd ${CONTAO_DIR} && tar cfz ${TARGET_DIR}/${DUMP_NAME}_${NOW}.tar.gz ${FILE_LIST} )


# Datenbank Verbindungsdaten

# Datenbank Verbindungsdaten aus der Installation holen
# Ausgabe z.B.
#
# --------------- -------
#   Parameter       Value
#  --------------- -------
#   database_user   jdbc
#  --------------- -------

function get_db_param() {
    PARAMETER=$1
    ${PHP_CLI} ${CONTAO_DIR}/vendor/bin/contao-console debug:container --parameter=${PARAMETER} \
      | sed -n 4p \
      | sed -e's/^ *//' \
      | cut -d' ' -f2-
    return 0
}

function get_db_user() {
    echo $(get_db_param 'database_user')
}
function get_db_password() {
    echo $(get_db_param 'database_password')
}
function get_db_host() {
    echo $(get_db_param 'database_host')
}
function get_db_name() {
    echo $(get_db_param 'database_name')
}
function get_db_port() {
    echo $(get_db_param 'database_port')
}

DBUSER=$(get_db_user)
DBPASSWORD=$(get_db_password)
DBHOST=$(get_db_host)
DBNAME=$(get_db_name)
DBPORT=$(get_db_port)

${MYSQLDUMP} \
    --user=${DBUSER} \
    --password=${DBPASSWORD} \
    --host=${DBHOST} \
    --port=${DBPORT} \
    ${DBOPTIONS} \
    ${DBNAME} \
    > ${TARGET_DIR}/${DUMP_NAME}_${NOW}.sql && gzip --force ${TARGET_DIR}/${DUMP_NAME}_${NOW}.sql


# Alte Backups rollierend löschen

if [ ${PURGE_AFTER_DAYS} -gt 0 ]
then
    # Betriebssystem ermitteln um den date-Aufruf entsprechend zu parametrisieren.
    # Linux vs. BSD (also auch MacOS).

    UNAME=$(uname)

    if [ "${UNAME}" = 'Linux' ]
    then
        OLD=$(date +"%Y-%m-%d" -d"${PURGE_AFTER_DAYS} days ago")
    elif [[ ("${UNAME}" == 'FreeBSD') || ("${UNAME}" == 'Darwin') ]]
    then
        OLD=$(date -v -${PURGE_AFTER_DAYS}d +"%Y-%m-%d")
    else
        echo "unknown operating system"
        exit 1
    fi

    echo "loesche altes Backup vom '${OLD}'"
    rm -f ${TARGET_DIR}/${DUMP_NAME}_${OLD}*
    ls -lh ${TARGET_DIR}/${DUMP_NAME}_*
fi

## EOF ##
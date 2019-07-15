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
else
    ( echo "Dateisicherung übersprungen, da BACKUP_CONTAO_FILES=${BACKUP_CONTAO_FILES} in $0" > ${TARGET_DIR}/${DUMP_NAME}_files_${NOW}.txt )
fi


# Backup "der anderen" Dateien.
# (a) Dateien, die in einer Standard Managed-Edition vorhanden sind

read -d '' FILE_LIST <<- EOF
    composer.json composer.lock
    system/config/localconfig.php
    app/
    templates/
    web/.htaccess
EOF

# (b) ggf. vorhandenes Verzeichnis src/ (anwendungsspezifische Erweiterungen)

if [ -d ${CONTAO_DIR}/src ]
then
    FILE_LIST="${FILE_LIST} src/"
fi

# (c) Benutzerdefinierte Verzeichnisse (können in der Konfiguration angegeben werden)

if [[ ! -z ${BACKUP_USER_DIRS} ]]
then
    for d in ${BACKUP_USER_DIRS}
    do
        if [ -d ${CONTAO_DIR}/$d ]
        then
            FILE_LIST="${FILE_LIST} ${d}"
        fi
    done
fi

# (d) Wie (c), nur für einzelne Dateien

if [[ ! -z ${BACKUP_USER_FILES} ]]
then
    for f in ${BACKUP_USER_FILES}
    do
        if [ -e ${CONTAO_DIR}/${f} ]
        then
            FILE_LIST="${FILE_LIST} ${f}"
        fi
    done
fi


#  FILE_LIST sichern

( cd ${CONTAO_DIR} && tar cfz ${TARGET_DIR}/${DUMP_NAME}_${NOW}.tar.gz ${FILE_LIST} )


# Datenbank Verbindungsdaten bestimmen

# Dazu die Datenbank Verbindungsdaten aus der Installation holen.
# Die Ausgabe sieht z.B. so aus:
#
# --------------- -------
#   Parameter       Value
#  --------------- -------
#   database_user   jdbc
#  --------------- -------
#
# Wir benötigen "das zweite Wort der vierten Zeile" (den "Value")

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


IGNORE_TABLES=''

if [ ! -z "${SKIP_THESE_TABLES}" ]
then
    # die angegebenen Tabellen nicht in die Datenbanksicherung aufnehmen
    for TABLE in ${SKIP_THESE_TABLES}
    do
        IGNORE_TABLES="${IGNORE_TABLES} --ignore-table=${DBNAME}.${TABLE}"
    done
fi

${MYSQLDUMP} \
    --user="${DBUSER}" \
    --password="${DBPASSWORD}" \
    --host="${DBHOST}" \
    --port="${DBPORT}" \
    ${DBOPTIONS} \
    ${IGNORE_TABLES} \
    ${DBNAME} \
    > ${TARGET_DIR}/${DUMP_NAME}_${NOW}.sql \
    && ${MYSQLDUMP} \
    --user="${DBUSER}" \
    --password="${DBPASSWORD}" \
    --host="${DBHOST}" \
    --port="${DBPORT}" \
    --no-data \
    ${DBOPTIONS} \
    ${DBNAME} \
    ${SKIP_THESE_TABLES} \
    >> ${TARGET_DIR}/${DUMP_NAME}_${NOW}.sql \
    && gzip --force ${TARGET_DIR}/${DUMP_NAME}_${NOW}.sql


# Alte Backups rollierend löschen

if [ ${PURGE_AFTER_DAYS} -gt 0 ]
then
    # Betriebssystem ermitteln um den date-Aufruf entsprechend zu parametrisieren.
    # Linux vs. BSD (also auch MacOS).
    #
    # Nur, falls das Betriebssystem nicht bereits in der Variablen OS angegeben wurde (siehe main.sh)

    if [ -z ${OS} ]
    then

        if [ -z $(which uname) ]
        then
            echo "Kann Betriebssystem nicht bestimmen. Bitte in main.sh die Variable 'OS' setzen!"
            exit 1
        else
            OS=$(uname)
        fi
    fi

    if [ "${OS}" = 'Linux' ]
    then
        OLD=$(date +"%Y-%m-%d" -d"${PURGE_AFTER_DAYS} days ago")
    elif [[ ("${OS}" == 'FreeBSD') || ("${OS}" == 'Darwin') ]]
    then
        OLD=$(date -v -${PURGE_AFTER_DAYS}d +"%Y-%m-%d")
    else
        echo "unknown operating system"
        exit 1
    fi

    echo "loesche altes Backup vom '${OLD}'"
    rm -f ${TARGET_DIR}/${DUMP_NAME}_*${OLD}*
    ls -lh ${TARGET_DIR}/${DUMP_NAME}_*
fi

## EOF ##

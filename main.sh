#!/usr/bin/env bash

#
# Backup einer Contao 4 Installation (Dateien und Datenbank)
#

# - - - - - - - - - -
# Start Konfiguration
# - - - - - - - - - -


# Pfade zu den benötigten Programmen
# Hier ggf. den vollständigen Pfad angeben

PHP_CLI=php
MYSQLDUMP=mysqldump


# Zielverzeichnis = Wo sollen die erzeugten Backups abgelegt werden.
# Auf einem Produktivsystem ist ein öffentlich zugängliches Verzeichnis
# keine tolle Idee ...

TARGET_DIR=/some/dir/outside/the/webroot


# Basisname der erzeugten Backupdateien
# (z.B. Projektname oder Domain).

DUMP_NAME=myprojekt


# Name des Contao Installationsverzeichnises.
#
# Achtung: hier wird das Verzeichnis angegeben, in Contao installiert wurde.
# Das ist das Verzeichnis, in dem die composer.json der Installation liegt.
# NICHT gemeint ist das Unterverzeichnis web/, auf das die Domain gesetzt wurde!

CONTAO_DIR=/path/to/contao/installation/directory


# Soll das files Verzeichnis auch gesichert werden?
#
# Wenn das files/ Verzeichnis sehr groß ist, ist es evtl sinnvoll,
# hier das Backup auszuschalten und dieses Verzeichnis mit einem anderen
# Mechanismus zu sichern (z.B. via rsync).

BACKUP_CONTAO_FILES=1
#BACKUP_CONTAO_FILES=0


# Zusätzlich zum Standard (composer.{json,lock}, app/, ..., src/) zu
# sichernde Verzeichnisse und Dateien.
# Pfadangabe jeweils relativ zum CONTAO_DIR.

BACKUP_USER_DIRS=''


# Verzeichnis in dem das Haupt-Skript (c4-backup.sh) gespeichert ist.
# Wird u.A. für absolute Pfade in cron jobs benötigt.

SCRIPT_DIR=/dir/where/the/main/backup_script/is/located


# Optionen für mysqldump (Datenbankdump)
# siehe 'man mysqldump'

#DBOPTIONS=''
DBOPTIONS='--hex-blob --add-drop-table --comments --dump-date'


# Nicht zu sichernde Datenbanktabellen
# Eine durch Leerzeichen getrennte Liste, die aber auch leer sein darf.
# Von diesen Tabellen wird nur die Tabellenstruktur, aber keine Daten gesichert.

#SKIP_THESE_TABLES=''
SKIP_THESE_TABLES='tl_log tl_search tl_search_index tl_session'


# Alte Backups nach x Tagen periodisch löschen?
# Auf 0 setzen um das Löschen zu deaktivieren.

#PURGE_AFTER_DAYS=0
PURGE_AFTER_DAYS=14


# - - - - - - - - - -
# Ende Konfiguration
# - - - - - - - - - -


# Das Haupt-Skript aufrufen, das die eigentliche Backup-Logik enthält.

source ${SCRIPT_DIR}/c4-backup.sh

## EOF ##
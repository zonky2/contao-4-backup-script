# Backup Script für Contao 4 Installationen

Erstellt ein Backup einer Contao 4 Installation. Erzeugt werden drei Dateien:

* Datenbankdump
* Sicherung der für eine Wiederherstellung benötigten Dateien 
* Sicherung des `files/` Verzeichnisses

## Requirements

* bash
* PHP-Cli
* `mysqldump`

## Verwendung

* Anpassen der Datei `main.sh` an den eigenen Bedarf (siehe Kommentare in der Datei) 
* Aufruf der `main.sh` in einem cron-job


## Was noch fehlt

* Liste der gesicherten Dateien auf ist "alles benötigte" dabei prüfen
* `mysqldump` ohne (direkte) Angabe des Passworts: `mysqldump --defaults-file=/path-to-file/my.cnf` 
und `my.cnf` so: 
 
 ```
 [mysqldump]
 password=my_password
 ```
 

## Restore

* Backup-Dateien in das entsprechende Verzeichnis auf dem Server entpacken
* Datenbankdump einspielen (Datenbank ggf. neu anlegen)
* `composer install`
* Aufruf des Contao Installtools im Browser

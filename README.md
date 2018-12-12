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
* Aufruf der `main.sh` manuell oder periodisch in einem cron-job
* Für All-Incl (siehe https://community.contao.org/de/showthread.php?72870-All-Inkl-und-fiedsch-contao-4-backup-script):
  * In der `main.sh` die Variable `TAR`auf `ptar` (https://perldoc.perl.org/ptar.html)
  * Wenn `PURGE_AFTER_DAYS=0` gesetzt ist, werden alte Backups nicht "aufgeräumt", aber
    dadurch die bei All-Incl mutmaßlich auch gesperrten Befehle `ls` und `rm` nicht
    ausgeführt.


## Was noch fehlt

* Liste der gesicherten Dateien auf "ist alles benötigte dabei" prüfen (möglichst viele
  Spezialfälle berücksichtigen; Danke für Feedback/"Issues" falls ihr etwas findet!)
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

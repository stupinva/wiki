#!/bin/sh

BACKUPS=/backups/

DT=`date '+%Y%m%d'`

umask 0137
echo "SHOW DATABASES;" \
	| clickhouse-client \
	| grep -Eiv 'default|information_schema|system' \
	| while read DB ;
	do
		echo -n "`date '+%Y:%m:%d %H:%M:%S'` Backing up database $DB..."
		if [ -f "$BACKUPS$DT/$DB.zip.lock" ] ; then
			rm -f "$BACKUPS$DB.$DT.zip"
			rm -f "$BACKUPS$DB.$DT.zip.lock"
		fi
		if [ -f "$BACKUPS$DB.$DT.zip" ] ; then
			echo " already done"
			continue
		fi

		echo "BACKUP DATABASE $DB TO Disk('backups', '$DB.$DT.zip');" | clickhouse-client >/dev/null 2>&1
		if [ "$?" -eq "0" ] ; then
			find $BACKUPS -mindepth 1 -maxdepth 1 -type f -name $DB.\*.zip -mtime +2 -delete
			echo " done"

		else
			rm -f "$BACKUPS$DB.$DT.zip"
			echo " failed"
		fi
	done

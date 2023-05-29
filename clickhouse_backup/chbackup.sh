#!/bin/sh

BACKUPS=/backup/
DAYS=3

DT=`date '+%Y%m%d'`

umask 0137
echo "SHOW DATABASES;" \
	| clickhouse-client \
	| grep -Eiv 'default|information_schema|system' \
	| while read DB ;
	do
		echo -n "`date '+%Y:%m:%d %H:%M:%S'` Backing up database $DB..."
		if [ -f "$BACKUPS$DB.$DT.zip.lock" ] ; then
			rm -f "$BACKUPS$DB.$DT.zip"
			rm -f "$BACKUPS$DB.$DT.zip.lock"
		fi
		if [ -f "$BACKUPS$DB.$DT.zip" ] ; then
			echo " already done"
			continue
		fi

		echo "BACKUP DATABASE $DB TO Disk('backup', '$DB.$DT.zip');" | clickhouse-client >/dev/null 2>&1
		if [ "$?" -eq "0" ] ; then
			echo " done"

			echo -n "`date '+%Y:%m:%d %H:%M:%S'` Removing old backups of database $DB..."
			FULL_LIST=`find "$BACKUPS" -mindepth 1 -maxdepth 1 -type f -name "$DB.*.zip" | sort`
			NEED_LIST=`echo "$FULL_LIST" | tail -n "$DAYS"`
			(echo "$FULL_LIST" ; echo "$NEED_LIST") \
				| sort \
				| uniq -u \
				| xargs -r rm
			echo " done"
		else
			rm -f "$BACKUPS$DB.$DT.zip"
			echo " failed"
		fi
	done

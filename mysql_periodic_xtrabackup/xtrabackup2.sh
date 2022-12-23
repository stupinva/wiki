#!/bin/sh

BACKUP_PATH=/backup/db/
INCREMENT_PATH=/backup/inc/
EXCLUDE_TABLES=''
GRANTS_FILE=/backup/grants.sql

#RUSER=archive
#RSERVER=archive.server.tld
#RPATH=/archive/db.tgz
#RKEY=/root/.ssh/archive_key

DAYS=0

remove_full() {
	echo -n `date '+%Y-%m-%d %H:%M:%S'`
	echo -n " Removing broken backup..."
	rm -fR "$BACKUP_PATH"
	if [ "$?" -eq "0" ] ; then
		echo " done"
	else
		echo " failed"
		exit 1
	fi
}

purge_bitmaps() {
	awk '/^to_lsn = / { print "PURGE CHANGED_PAGE_BITMAPS BEFORE " $3 ";"; }' "$BACKUP_PATH/xtrabackup_checkpoints" | mysql
}

create_full() {
	echo -n `date '+%Y-%m-%d %H:%M:%S'`
	echo -n " Doing full backup..."
	mkdir "$BACKUP_PATH" \
		&& xtrabackup --backup --open-files-limit=100000 --tables-exclude="$EXCLUDE_TABLES" --target-dir="$BACKUP_PATH" 2> "$BACKUP_PATH/log"
	if [ "$?" -eq "0" ] ; then
		echo " done"

		echo -n `date '+%Y-%m-%d %H:%M:%S'`
		echo -n " Preparing full backup..."
		xtrabackup --prepare --apply-log-only --target-dir="$BACKUP_PATH" 2> "$BACKUP_PATH/log"
		if [ "$?" -eq "0" ] ; then
			touch "$BACKUP_PATH/ok"
			rm -f "$BACKUP_PATH/log"
			purge_bitmaps
			echo " done"
		else
			echo " failed"
			exit 2
		fi
	else
		echo " failed"
		exit 3
	fi
}

refresh_full() {
	echo -n `date '+%Y-%m-%d %H:%M:%S'`
	echo -n " Doing incremental backup..."
	mkdir "$INCREMENT_PATH" \
		&& xtrabackup --backup --open-files-limit=100000 --tables-exclude="$EXCLUDE_TABLES" --target-dir="$INCREMENT_PATH" --incremental-basedir="$BACKUP_PATH" 2> "$INCREMENT_PATH/log"
	if [ "$?" -eq "0" ] ; then
		echo " done"

		echo -n `date '+%Y-%m-%d %H:%M:%S'`
		echo -n " Applying incremental backup over top of full backup..."
		xtrabackup --prepare --apply-log-only --target-dir="$BACKUP_PATH" --incremental-dir="$INCREMENT_PATH" 2> "$INCREMENT_PATH/log"
		if [ "$?" -eq "0" ] ; then
			touch "$BACKUP_PATH/ok"
			purge_bitmaps
			echo " done"

			echo -n `date '+%Y-%m-%d %H:%M:%S'`
			echo -n " Removing incremental backup..."
			rm -fR "$INCREMENT_PATH"
			if [ "$?" -eq "0" ] ; then
				echo " done"
			else
				echo " failed"
				exit 4
			fi
		else
			rm -f "$BACKUP_PATH/ok"
			echo " failed"
			exit 5
		fi
	else
		echo " failed"
		exit 6
	fi
}

remove_inc() {
	echo -n `date '+%Y-%m-%d %H:%M:%S'`
	echo -n " Removing incremental backup..."
	rm -fR "$INCREMENT_PATH"
	if [ "$?" -eq "0" ] ; then
		echo " done"
	else
		echo " failed"
		exit 7
	fi
}

save_grants() {
	echo -n `date '+%Y-%m-%d %H:%M:%S'`
	echo -n " Saving grants..."
	pt-show-grants > "$GRANTS_FILE" \
		&& chmod 600 "$GRANTS_FILE"
	if [ "$?" -eq "0" ] ; then
		echo " done"
	else
		echo " failed"
		exit 8
	fi
}

send_archive() {
	D=`dirname "$BACKUP_PATH"`
	B=`basename "$BACKUP_PATH"`

	echo -n `date '+%Y-%m-%d %H:%M:%S'`
	echo -n " Archiving to remote storage..."
	tar -cSf - -C "$D" --exclude="$B/ok" "$B" \
		| pigz \
		| ssh -i "$RKEY" $RUSER@$RSERVER "dd of=$RPATH 2>/dev/null"
	if [ "$?" -eq "0" ] ; then
		echo " done"
	else
		echo " failed"
		exit 9
	fi
}

save_archive() {
	D=`dirname "$BACKUP_PATH"`
	B=`basename "$BACKUP_PATH"`
	S=`date '+%Y%m%d'`

	echo -n `date '+%Y-%m-%d %H:%M:%S'`
	echo -n " Archiving..."

	tar -cSjf "${D}/${B}_${S}.tbz" -C "$D" --exclude="$B/ok" "$B"
	if [ "$?" -eq "0" ] ; then
		echo " done"
	else
		echo " failed"
		exit 10
	fi
}

remove_old_archives() {
	D=`dirname "$BACKUP_PATH"`
	B=`basename "$BACKUP_PATH"`

	echo -n `date '+%Y-%m-%d %H:%M:%S'`
	echo -n " Remove old archives..."
	FULL_LIST=`find "${D}" -type f -name "${B}_*.tbz" | sort`
	NEED_LIST=`echo "$FULL_LIST" | tail -n "$DAYS"`
	(echo "$FULL_LIST" ; echo "$NEED_LIST") \
		| sort \
		| uniq -u \
		| xargs rm
	echo " done"
}

save_grants

if [ -f "$BACKUP_PATH/ok" ] ; then
	if [ -d "$INCREMENT_PATH" ] ; then
		remove_inc
	fi

	refresh_full
else
	remove_full
fi

if [ ! -d "$BACKUP_PATH" ] ; then
	create_full
fi

if [ -n "$RUSER" -a -n "$RSERVER" -a -n "$RPATH" -a -n "$RKEY" ] ; then
	send_archive
elif [ "$DAYS" -gt 0 ] ; then
	save_archive
	remove_old_archives
fi

echo -n `date '+%Y-%m-%d %H:%M:%S'`
echo " Finished"

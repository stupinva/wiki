#!/bin/sh

CONFIG=/etc/xtrabackup2.conf
if [ ! -f "$CONFIG" ] ; then
	echo "Config file $CONFIG not exist!"
	exit 1
fi
. "$CONFIG"

remove_full() {
	echo -n `date '+%Y-%m-%d %H:%M:%S'`
	echo -n " Removing broken backup..."
	rm -fR "$BACKUP_PATH/db/"
	if [ "$?" -eq "0" ] ; then
		echo " done"
	else
		echo " failed"
		exit 2
	fi
}

purge_bitmaps() {
	awk '/^to_lsn = / { print "PURGE CHANGED_PAGE_BITMAPS BEFORE " $3 ";"; }' "$BACKUP_PATH/db/xtrabackup_checkpoints" | mysql
}

create_full() {
	echo -n `date '+%Y-%m-%d %H:%M:%S'`
	echo -n " Doing full backup..."
	mkdir "$BACKUP_PATH/db/" \
		&& xtrabackup --backup --open-files-limit=100000 --tables-exclude="$EXCLUDE_TABLES" --target-dir="$BACKUP_PATH/db/" 2> "$BACKUP_PATH/log"
	if [ "$?" -eq "0" ] ; then
		echo " done"

		echo -n `date '+%Y-%m-%d %H:%M:%S'`
		echo -n " Preparing full backup..."
		xtrabackup --prepare --apply-log-only --target-dir="$BACKUP_PATH/db/" 2> "$BACKUP_PATH/log"
		if [ "$?" -eq "0" ] ; then
			touch "$BACKUP_PATH/ok"
			rm -f "$BACKUP_PATH/log"
			purge_bitmaps
			echo " done"
		else
			echo " failed"
			exit 3
		fi
	else
		echo " failed"
		exit 4
	fi
}

remove_inc() {
	echo -n `date '+%Y-%m-%d %H:%M:%S'`
	echo -n " Removing incremental backup..."
	rm -fR "$BACKUP_PATH/inc/"
	if [ "$?" -eq "0" ] ; then
		echo " done"
	else
		echo " failed"
		exit 5
	fi
}

refresh_full() {
	echo -n `date '+%Y-%m-%d %H:%M:%S'`
	echo -n " Doing incremental backup..."
	mkdir "$BACKUP_PATH/inc/" \
		&& xtrabackup --backup --open-files-limit=100000 --tables-exclude="$EXCLUDE_TABLES" --target-dir="$BACKUP_PATH/inc/" --incremental-basedir="$BACKUP_PATH/db/" 2> "$BACKUP_PATH/log"
	if [ "$?" -eq "0" ] ; then
		echo " done"

		echo -n `date '+%Y-%m-%d %H:%M:%S'`
		echo -n " Applying incremental backup over top of full backup..."
		xtrabackup --prepare --apply-log-only --target-dir="$BACKUP_PATH/db/" --incremental-dir="$BACKUP_PATH/inc/" 2> "$BACKUP_PATH/log"
		if [ "$?" -eq "0" ] ; then
			touch "$BACKUP_PATH/ok"
			rm -f "$BACKUP_PATH/log"
			purge_bitmaps
			echo " done"

			remove_inc
		else
			rm -f "$BACKUP_PATH/ok"
			echo " failed"
			exit 6
		fi
	else
		echo " failed"
		exit 7
	fi
}

send_archive() {
	echo -n `date '+%Y-%m-%d %H:%M:%S'`
	echo -n " Archiving to remote storage..."
	tar -cSf - -C "$BACKUP_PATH" db \
		| pigz \
		| ssh -i "$RKEY" $RUSER@$RSERVER "dd of=$RPATH 2>/dev/null"
	if [ "$?" -eq "0" ] ; then
		echo " done"
	else
		echo " failed"
		exit 8
	fi
}

save_archive() {
	S=`date '+%Y%m%d'`

	echo -n `date '+%Y-%m-%d %H:%M:%S'`
	echo -n " Archiving..."

	tar -cSjf "$BACKUP_PATH/db_${S}.tbz" -C "$BACKUP_PATH" db
	if [ "$?" -eq "0" ] ; then
		echo " done"
	else
		echo " failed"
		exit 9
	fi
}

remove_old_archives() {
	echo -n `date '+%Y-%m-%d %H:%M:%S'`
	echo -n " Remove old archives..."
	FULL_LIST=`find "$BACKUP_PATH" -type f -name "db_*.tbz" | sort`
	NEED_LIST=`echo "$FULL_LIST" | tail -n "$DAYS"`
	(echo "$FULL_LIST" ; echo "$NEED_LIST") \
		| sort \
		| uniq -u \
		| xargs -r rm
	echo " done"
}

if [ -d "$BACKUP_PATH/inc/" ] ; then
	remove_inc
fi

if [ -f "$BACKUP_PATH/ok" ] ; then
	refresh_full
else
	remove_full
fi

if [ ! -d "$BACKUP_PATH/db/" ] ; then
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

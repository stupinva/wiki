#!/bin/sh

# GRANT SELECT, DROP, ALTER ON `bgbilling`.* TO 'archive'@'192.168.164.7'

CONFIG=/etc/archive_tables.conf
if [ ! -f "$CONFIG" ] ; then
	echo "Config file $CONFIG not exist!"
	exit 1
fi
. "$CONFIG"
MYSQL="/usr/bin/mysql --defaults-file=$PROFILE"
MYSQLDUMP=/usr/bin/mysqldump

wait_wsrep() {
	echo "$PXC_HOSTS" \
		| sed -re 's/^\s*//g; s/#.*$//g; /^\s*$/d' \
		| while read PXC_HOST ; do
			WSREP_STATE=`$MYSQL -h $PXC_HOST -Ne 'SELECT variable_value FROM performance_schema.global_status WHERE variable_name = "wsrep_ready";'`
			if [ "$WSREP_STATE" != "ON" ] ; then
				echo "Cluster is out of sync, exiting"
				exit 2
			fi

			while true ; do
				#WSREP_CAP=`$MYSQL -h $PXC_HOST -Ne 'SELECT variable_value FROM performance_schema.global_status WHERE variable_name = "wsrep_flow_control_interval_high";'`
				CURRENT_QUEUE=`$MYSQL -h $PXC_HOST -Ne 'SELECT variable_value FROM performance_schema.global_status WHERE variable_name = "wsrep_local_recv_queue";'`
				if [ "$CURRENT_QUEUE" -eq 0 ] ; then
					break
				fi

				#echo "There still writesets in queue, sleeping..."
				sleep 15
			done
		done
}

move_archive() {
	DB="$1"
	TABLE="$2"

	if [ -z "$RUSER" -o -z "$RSERVER" -o -z "$RPATH" -o -z "$RKEY" ] ; then
		return 0
	fi

	LFILE="$BACKUP_PATH$DB/$TABLE.sql.bz2"
	RFILE="$RPATH$DB/$TABLE.sql.bz2"

	#echo "$LFILE -> $RUSER@$RSERVER:$RFILE"

	LSIZE=`du -bs "$LFILE" | sed -r 's/^([0-9]+)[^0-9].*$/\1/g'`
	RSIZE=`ssh -n -i $RKEY $RUSER@$RSERVER du -bs "$RFILE" 2>/dev/null`
	if [ "$?" -ne "0" ] ; then
		rsync -e "ssh -i $RKEY" --remove-source-files "$LFILE" $RUSER@$RSERVER:"$RFILE"
		if [ "$?" -ne "0" ] ; then
			return 1
		fi
	else
		RSIZE=`echo -n "$RSIZE" | sed -r 's/^([0-9]+)[^0-9].*$/\1/g'`
		#echo "$LSIZE" "$RSIZE"
		if [ "$LSIZE" -gt "$RSIZE" ] ; then
			rsync -e "ssh -i $RKEY" --remove-source-files "$LFILE" $RUSER@$RSERVER:"$RFILE"
			if [ "$?" -ne "0" ] ; then
				return 1
			fi
		else
			echo "$LFILE already exist!"
			rm "$LFILE"
		fi
	fi
	return 0
}

move_archives() {
	DB="$1"

	if [ ! -d "$BACKUP_PATH/$DB" ] ; then
		return
	fi

	O=`pwd`
	cd "$BACKUP_PATH/$DB"
	ls -1 \
		| sed -r '/\.sql\.bz2$/!d ; s/\.sql\.bz2$//g' \
		| while read TABLE ; do
			move_archive "$DB" "$TABLE"
			RET="$?"
			if [ "$RET" -ne "0" ] ; then
				echo "$DB.$TABLE: Error moving - $RET"
			fi
		done

	cd "$O"
}

archive_table() {
	DB="$1"
	TABLE="$2"
	ARCHIVE="$3"
	DROP="$4"

	COUNT=`$MYSQL "$DB" -BNe "SELECT COUNT(*) FROM $TABLE;"`
	if [ "$COUNT" -ne "0" -a "$ARCHIVE" -ne "0" ] ; then
		if [ ! -d "$BACKUP_PATH/$DB" ] ; then
			mkdir -p "$BACKUP_PATH/$DB"
		fi

		#echo "$BACKUP_PATH/$DB/$TABLE.sql.bz2"
		$MYSQLDUMP --single-transaction "$DB" "$TABLE" | sed 's/ENGINE=MyISAM/ENGINE=InnoDB/g' | bzip2 -9 -c > "$BACKUP_PATH/$DB/$TABLE.sql.bz2"
		RET="$?"
		if [ "$RET" -ne "0" ] ; then
			rm "$BACKUP_PATH/$DB/$TABLE.sql.bz2"
			echo "$DB.$TABLE: Error dump - $RET"
			return
		fi

		bzgrep -qE "^CREATE TABLE " "$BACKUP_PATH/$DB/$TABLE.sql.bz2"
		if [ "$?" -ne "0" ] ; then
			echo "$DB.$TABLE: No CREATE TABLE in dump"
			return
		fi

		bzgrep -qE "^INSERT INTO " "$BACKUP_PATH/$DB/$TABLE.sql.bz2"
		if [ "$?" -ne "0" ] ; then
			echo "$DB.$TABLE: No INSERT INTO in dump"
			return
		fi

		move_archive "$DB" "$TABLE"
		RET="$?"
		if [ "$RET" -ne "0" ] ; then
			echo "$DB.$TABLE: Error moving - $RET"
		fi
	fi

	if [ "$DROP" -ne "0" ] ; then
		wait_wsrep
		#echo "DROP TABLE $TABLE;"
		$MYSQL "$DB" -BNe "DROP TABLE $TABLE;"
	else
		wait_wsrep
		#echo "TRUNCATE TABLE $TABLE;"
		$MYSQL "$DB" -BNe "TRUNCATE TABLE $TABLE;"

		wait_wsrep
		#echo "ALTER TABLE $TABLE ENGINE=InnoDB;"
		$MYSQL "$DB" -BNe "ALTER TABLE $TABLE ENGINE=InnoDB;"
	fi
}

archive_month_tables() {
	DB="$1"
	PATTERN="$2"
	KEEP_MONTHS="$3"
	ARCHIVE="$4"
	DROP="$5"

	KEEP_FROM_YYYYMM=`$MYSQL -BNe "SELECT DATE_FORMAT(DATE_SUB(NOW(), INTERVAL $KEEP_MONTHS MONTH), '%Y%m');"`

	$MYSQL "$DB" -BNe "SHOW TABLES LIKE '%\_______';" \
		| grep -E "$PATTERN" \
		| while read TABLE ; do
			YYYYMM=`echo -n "$TABLE" | sed -re 's/^.*_([0-9]{6})$/\1/g'`
			if [ "$YYYYMM" -lt "$KEEP_FROM_YYYYMM" ] ; then
				archive_table "$DB" "$TABLE" "$ARCHIVE" "$DROP"
			fi
		done
}

archive_day_tables() {
	DB="$1"
	PATTERN="$2"
	KEEP_DAYS="$3"
	ARCHIVE="$4"
	DROP="$5"

	KEEP_FROM_YYYYMMDD=`$MYSQL -BNe "SELECT DATE_FORMAT(DATE_SUB(NOW(), INTERVAL $KEEP_DAYS DAY), '%Y%m%d');"`

	$MYSQL "$DB" -BNe "SHOW TABLES LIKE '%\_________';" \
		| grep -E "$PATTERN" \
		| while read TABLE ; do
			YYYYMMDD=`echo -n "$TABLE" | sed -re 's/^.*_([0-9]{8})$/\1/g'`
			if [ "$YYYYMMDD" -lt "$KEEP_FROM_YYYYMMDD" ] ; then
				archive_table "$DB" "$TABLE" "$ARCHIVE" "$DROP"
			fi
		done
}

echo "$ARCHIVE_SETS" \
	| sed -re 's/^\s*//g; s/#.*$//g; /^\s*$/d' \
	| while read SET ; do
		eval "DBS=\$DATABASES_$SET"
		eval "MONTH_TABLES=\$MONTH_TABLES_$SET"
		eval "DAY_TABLES=\$DAY_TABLES_$SET"

		echo "$DBS" \
			| sed -re 's/^\s*//g; s/#.*$//g; /^\s*$/d' \
			| while read DB ; do
				echo "$MONTH_TABLES" \
					| sed -re 's/^\s*//g; s/#.*$//g; /^\s*$/d' \
					| while read PATTERN KEEP_MONTHS ARCHIVE DROP ; do
						#echo "$DB - $PATTERN"
						archive_month_tables "$DB" "$PATTERN" "$KEEP_MONTHS" "$ARCHIVE" "$DROP"
					done

				echo "$DAY_TABLES" \
					| sed -re 's/^\s*//g; s/#.*$//g; /^\s*$/d' \
					| while read PATTERN KEEP_DAYS ARCHIVE DROP ; do
						#echo "$DB - $PATTERN"
						archive_day_tables "$DB" "$PATTERN" "$KEEP_DAYS" "$ARCHIVE" "$DROP"
					done

				move_archives "$DB"
			done
	done

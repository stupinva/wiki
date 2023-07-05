#!/bin/sh

PATH=/usr/sbin:/usr/bin:/sbin:/bin

CONFIG=/etc/lvbackup.conf
if [ ! -f "$CONFIG" ] ; then
	echo "Config file $CONFIG not exist!"
	exit 1
fi
. "$CONFIG"

mount_snap() {
	echo -n `date '+%Y-%m-%d %H:%M:%S'`
	echo -n " Mounting snapshot $VGNAME/$LVSNAP to $SNAP_PATH..."
	mount -o ro "/dev/$VGNAME/$LVSNAP" "$SNAP_PATH"
	if [ "$?" -ne "0" ] ; then
		echo " failed"
		exit 2
	fi
	echo " done"
}

unmount_snap() {
	mountpoint -q "$SNAP_PATH"
	if [ "$?" -ne "0" ] ; then
		return
	fi

	echo -n `date '+%Y-%m-%d %H:%M:%S'`
	echo -n " Unmounting snapshot $VGNAME/$LVSNAP..."
	umount "$SNAP_PATH" 2>/dev/null
	if [ "$?" -ne "0" ] ; then
		echo " failed"
		exit 3
	fi
	echo " done"

}

remove_snap() {
	lvs -qq "$VGNAME/$LVSNAP" >/dev/null 2>&1
	if [ "$?" -ne "0" ] ; then
		return
	fi

	echo -n `date '+%Y-%m-%d %H:%M:%S'`
	echo -n " Removing snapshot $VGNAME/$LVSNAP..."
	lvremove -qf "$VGNAME/$LVSNAP" >/dev/null 2>&1
	if [ "$?" -ne "0" ] ; then
		echo " failed"
		exit 4
	fi
	echo " done"
}

create_snap() {
	if [ ! -d "${BACKUP_PATH}db" ] ; then
		echo -n `date '+%Y-%m-%d %H:%M:%S'`
		echo -n " Creating backup directory ${BACKUP_PATH}db..."
		mkdir -p "${BACKUP_PATH}db"
		if [ "$?" -ne "0" ] ; then
			echo " failed"
			exit 5
		fi
		echo " done"
	fi

	unmount_snap
	remove_snap

	echo -n `date '+%Y-%m-%d %H:%M:%S'`
	echo -n " Creating snapshot $VGNAME/$LVSNAP..."
	lvs -qq "$VGNAME/$LVNAME" >/dev/null 2>&1
	if [ "$?" -ne "0" ] ; then
		echo " failed"
		exit 6
	fi
	for retry in 1 2 3 ; do
		case "$FOLLOW" in
			"me")
				LVM_SUPPRESS_FD_WARNINGS=1 mysql -BN >"${BACKUP_PATH}db/xtrabackup_binlog_info.new" 2>/dev/null <<END
-- SET lock_wait_timeout = 60;
FLUSH LOCAL TABLES WITH READ LOCK;
SHOW MASTER STATUS;
system lvcreate -qqL 10G -s "$VGNAME/$LVNAME" -n "$LVSNAP"
UNLOCK TABLES;
END
				RC="$?"
				awk '{ $3 = ""; $4 = ""; print $0; }' "${BACKUP_PATH}db/xtrabackup_binlog_info.new" > "${BACKUP_PATH}db/xtrabackup_binlog_info"
				rm -f "${BACKUP_PATH}db/xtrabackup_binlog_info.new"
				;;
			"master")
				LVM_SUPPRESS_FD_WARNINGS=1 mysql -BN 2>/dev/null <<END
-- SET lock_wait_timeout = 60;
FLUSH LOCAL TABLES WITH READ LOCK;
system lvcreate -qqL 10G -s "$VGNAME/$LVNAME" -n "$LVSNAP"
UNLOCK TABLES;
END
				RC="$?"
				;;
			*)
				echo " failed"
				exit 7
		esac
		if [ "$RC" -ne "0" ] ; then
			remove_snap
			continue
		fi
		lvs -qq "$VGNAME/$LVSNAP" >/dev/null 2>&1
		if [ "$?" -ne "0" ] ; then
			continue
		fi
		echo " done"
		return
	done
	echo " failed"
	exit 8
}

copy_snap() {
	echo -n `date '+%Y-%m-%d %H:%M:%S'`
	echo -n " Copying data from $SNAP_PATH$SRC to ${BACKUP_PATH}db..."
	nice -n 19 rsync --delete-before -qa "$SNAP_PATH$SRC" "${BACKUP_PATH}db"
	if [ "$?" -ne "0" ] ; then
		echo " failed"

		echo -n `date '+%Y-%m-%d %H:%M:%S'`
		echo -n " Removing broken backup at ${BACKUP_PATH}db..."
		rm -R "${BACKUP_PATH}db"
		if [ "$?" -ne "0" ] ; then
			echo " failed"
		else
			echo " done"
		fi
		exit 9
	fi
	echo " done"
}

send_archive() {
	echo -n `date '+%Y-%m-%d %H:%M:%S'`
	echo -n " Archiving to remote storage..."
	tar -cSf - -C "$BACKUP_PATH" db \
		| pigz \
		| ssh -i "$RKEY" $RUSER@$RSERVER "dd of=$RPATH 2>/dev/null"
	if [ "$?" -ne "0" ] ; then
		echo " failed"
		exit 10
	fi
	echo " done"
}

save_archive() {
	S=`date '+%Y%m%d'`
	
	echo -n `date '+%Y-%m-%d %H:%M:%S'`
	echo -n " Archiving..."
	
	tar -cSjf "${BACKUP_PATH}db_${S}.tbz" -C "$BACKUP_PATH" db
	if [ "$?" -ne "0" ] ; then
		echo " failed"
		exit 11
	fi
	echo " done"
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

create_snap
mount_snap
copy_snap
unmount_snap
remove_snap

if [ -n "$RUSER" -a -n "$RSERVER" -a -n "$RPATH" -a -n "$RKEY" ] ; then
	send_archive
elif [ "$DAYS" -gt "0" ] ; then
	save_archive
	remove_old_archives
fi

echo -n `date '+%Y-%m-%d %H:%M:%S'`
echo " Finished"

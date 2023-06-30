#!/bin/sh

CONFIG=/etc/lvbackup.conf
if [ ! -f "$CONFIG" ] ; then
	echo "Config file $CONFIG not exist!"
	exit 1
fi
. "$CONFIG"

mount_snap() {
	echo -n `date '+%Y-%m-%d %H:%M:%S'`
	echo -n " Mounting snapshot $PVNAME/$LVSNAP to $SNAP_PATH..."
	mount -o ro "/dev/$PVNAME/$LVSNAP" "$SNAP_PATH"
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
	echo -n " Unmounting snapshot $PVNAME/$LVSNAP..."
	umount "$SNAP_PATH" 2>/dev/null
	if [ "$?" -ne "0" ] ; then
		echo " failed"
		exit 3
	fi
	echo " done"

}

remove_snap() {
	lvs -qq "$PVNAME/$LVSNAP" >/dev/null 2>&1
	if [ "$?" -ne "0" ] ; then
		return
	fi

	echo -n `date '+%Y-%m-%d %H:%M:%S'`
	echo -n " Removing snapshot $PVNAME/$LVSNAP..."
	lvremove -qf "$PVNAME/$LVSNAP" >/dev/null 2>&1
	if [ "$?" -ne "0" ] ; then
		echo " failed"
		exit 4
	fi
	echo " done"
}

create_snap() {
	FOLLOW="$1"

	unmount_snap
	remove_snap

	echo -n `date '+%Y-%m-%d %H:%M:%S'`
	echo -n " Creating snapshot $PVNAME/$LVSNAP..."
	lvs -qq "$PVNAME/$LVNAME" 2>&1 >/dev/null
	if [ "$?" -ne "0" ] ; then
		echo " failed"
		exit 6
	fi
	case "$FOLLOW" in
		"me")
			LVM_SUPPRESS_FD_WARNINGS=1 mysql -BN >"/tmp/xtrabackup_binlog_info.new" 2>/dev/null <<END
-- SET lock_wait_timeout = 60;
FLUSH LOCAL TABLES WITH READ LOCK;
system lvcreate -qqL 10G -s "$PVNAME/$LVNAME" -n "$LVSNAP"
SHOW MASTER STATUS;
UNLOCK TABLES;
END
			RC="$?"
			awk '{ $3 = ""; $4 = ""; print $0; }' "/tmp/xtrabackup_binlog_info.new" > "/tmp/xtrabackup_binlog_info"
			rm -f "/tmp/xtrabackup_binlog_info.new"
			;;
		"master")
			LVM_SUPPRESS_FD_WARNINGS=1 mysql -BN 2>/dev/null <<END
-- SET lock_wait_timeout = 60;
FLUSH LOCAL TABLES WITH READ LOCK;
system lvcreate -qqL 10G -s "$PVNAME/$LVNAME" -n "$LVSNAP"
UNLOCK TABLES;
END
			RC="$?"
			;;
		*)
			echo " failed"
			exit 7
	esac
	if [ "$RC" -ne "0" ] ; then
		echo " failed"

		lvs -qq $PVNAME/$LVSNAP >/dev/null 2>&1
		if [ "$?" -eq "0" ] ; then
			echo -n `date '+%Y-%m-%d %H:%M:%S'`
			echo -n " Removing broken snapshot $PVNAME/$LVSNAP..."
			lvremove -qf "$PVNAME/$LVSNAP" >/dev/null 2>&1
			if [ "$?" -ne "0" ] ; then
				echo " failed"
			else
				echo " done"
			fi
		fi
		exit 7
	fi
	echo " done"
}

send_snap() {
	IP="$1"
	PORT="$2"

	echo -n `date '+%Y-%m-%d %H:%M:%S'`
	echo -n " Sending data from $SNAP_PATH$SRC to $IP:$PORT..."
	(cd "$SNAP_PATH$SRC" &&  tar cvf - . | pigz -k -1 -p4 - | socat -u stdio TCP:$IP:$PORT) 2>/dev/null
	if [ "$?" -ne "0" ] ; then
		echo " failed"
		exit 8
	fi
	echo " done"
}

if [ "$#" -ne "3" ] ; then
	echo "Usage: $0 me|master <ip> <port>"
	exit
fi

create_snap "$1"
mount_snap
send_snap "$2" "$3"
unmount_snap
remove_snap

echo -n `date '+%Y-%m-%d %H:%M:%S'`
echo " Finished"

cat /tmp/xtrabackup_binlog_info
rm -f /tmp/xtrabackup_binlog_info

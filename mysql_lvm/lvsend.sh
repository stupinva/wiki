#!/bin/sh

VGNAME=vg0
LVNAME=srv
LVSNAP=srv-snapshot
SNAP_PATH=/mnt/
SRC=mysql

DST_IP=192.168.1.1
DST_PORT=4444

P=`pwd`
LVM_SUPPRESS_FD_WARNINGS=1 mysql -BN <<END | \
	awk '{ $3 = ""; $4 = ""; print $0; }' && \
	mount "/dev/$VGNAME/$LVSNAP" "$SNAP_PATH" && \
	(cd "$SNAP_PATH$SRC" && \
		tar cf - . | pigz -k -1 -p4 - | socat -u stdio TCP:$DST_IP:$DST_PORT)
-- SET lock_wait_timeout = 60;
FLUSH LOCAL TABLES WITH READ LOCK;
system lvcreate -qqL 10G -s "$VGNAME/$LVNAME" -n "$LVSNAP"
SHOW MASTER STATUS;
UNLOCK TABLES;
END

cd "$P" && \
	umount "$SNAP_PATH" && \
	lvremove -qqy "$VGNAME/$LVSNAP"

#!/bin/sh

BACKUPDIR=/home/ufanet/los_backup/

adb=`which adb`

if [ ! -x "$adb" ]
then
        echo "adb not found"
        echo "Please, install package with it and repeat"
        echo "For example, on Debian-based distributions run command 'apt-get install adb' from root user"
        exit
fi

case "$1" in
	backup)
		CURRENT_PATH=`pwd`
		mkdir -p "$BACKUPDIR"
		cd "$BACKUPDIR" || exit $?

		$adb kill-server
		$adb start-server
		$adb root || exit 1

		$adb pull -a data/user/0 # User data
		$adb pull -a data/app    # apk-files
		$adb pull -a mnt/sdcard  # Internal storage

		#rm -rf com.android.* android* com.caf.fmradio org.lineageos* lineageos.platform *qualcomm*
		cd "$CURRENT_PATH"
		;;
	restore)
		CURRENT_PATH=`pwd`
		cd "$BACKUPDIR" || exit $?

		$adb kill-server
		$adb start-server
		$adb root || exit 1

		$adb push sdcard/ /mnt/                                           # Internal storage
		find app/ -type f -name base.apk -print0 -exec $adb install {} \; # apk-files
		$adb push 0/ /data/user/                                          # User data

		# Applying permissions from /data/system/packages.list
		$adb shell "cat /data/system/packages.list" | awk '{ print "chown -R " $2 ":" $2 " /data/data/" $1; }' | $adb shell sh

		$adb reboot
		cd "$CURRENT_PATH"
		;;
	*)
		echo "Usage: $0 <backup|restore>"
		;;
esac	

#!/bin/sh

DB_REMOTE_BACKUP="backups.vm.stupin.su:/home/stupin/backups/ncc_ncc.bak"
DB_LOCAL_BACKUP="/home/stupin/backups/ncc_ncc.bak"
DB_NAME="ncc_test"
DB_USER="ncc_test"
DB_PASSWORD="ohc7thea5Vethohm"

case $1 in
	create)
		psql -qd postgres <<END
CREATE ROLE $DB_USER WITH LOGIN PASSWORD '$DB_PASSWORD';
END
		createdb -O "$DB_USER" -E UTF-8 "$DB_NAME"
		;;

	drop)
		dropdb "$DB_NAME"
		dropuser "$DB_USER"
		;;

	test)
		PGPASSWORD="$DB_PASSWORD" psql -At -U "$DB_USER" -d "$DB_NAME" <<END
SELECT 'OK';
END
		;;

	fetch)
		scp "$DB_REMOTE_BACKUP" "$DB_LOCAL_BACKUP"
		;;

	restore)
		PGPASSWORD="$DB_PASSWORD" pg_restore -U "$DB_USER" -d "$DB_NAME" "$DB_LOCAL_BACKUP"
		;;

	*)
		echo "$0 create | drop | test | fetch | restore"
esac

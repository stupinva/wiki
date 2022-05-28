#!/bin/sh

MYSQL="mysql --defaults-file=/etc/zabbix/my.cnf"
MYSQLADMIN="mysqladmin --defaults-file=/etc/zabbix/my.cnf"
MODE="$1"

case "$MODE" in
	version)
		$MYSQL -V
		;;
	ping)
		$MYSQLADMIN ping |\
			fgrep -c alive
		;;
	global_status)
		$MYSQL -BNe "SHOW GLOBAL STATUS WHERE variable_name='"$2"'" |\
			awk '
				{
					gsub("ON", "1", $2);
					gsub("OFF", "0", $2);

					gsub("Non-Primary", "2", $2);
					gsub("Primary", "1", $2);
					gsub("Disconnected", "0", $2);

					print $2;
				}'
		;;
	global_variables)
		$MYSQL -BNe "SHOW GLOBAL VARIABLES WHERE variable_name='"$2"'" |\
			awk '
				{ 
					gsub("one-thread-per-connection", "0", $2);
					gsub("pool-of-threads", "1", $2);
					gsub("no-threads", "2", $2);

					print $2;
				}'
		;;
	extended_status)
		$MYSQLADMIN extended-status |\
			awk -F"|" -v NAME=$2 '
				{
					gsub(" ", "", $2);
					if ($2 == NAME) {
						gsub(" ", "", $3);
						print $3;
					}
				}'
		;;
	innodb_metrics)
		$MYSQL -BNe "SELECT $3 FROM information_schema.innodb_metrics WHERE name = '"$2"'"
		;;
	trx_rseg_history_len)
		$MYSQL -BNe 'SHOW ENGINE INNODB STATUS\G' |\
			awk '/^History list length/ { print $4; }'
		;;
	trx_duration_max)
		$MYSQL -BNe '
				SELECT IFNULL(MAX(UNIX_TIMESTAMP(NOW()) - UNIX_TIMESTAMP(trx_started)), 0)
				FROM information_schema.innodb_trx;'
		;;
	slave_workers_idle)
		$MYSQL -BNe "
				SELECT COUNT(*)
				FROM information_schema.processlist
				WHERE user = 'system user'
				  AND state = 'Waiting for an event from Coordinator'"
		;;
	slave_status)
		$MYSQL -e "SHOW SLAVE STATUS\G" |\
			awk -F":" -v NAME="$2" '
				{
					gsub(/^ *| *$/, "", $1);
					gsub(/^ *| *$/, "", $2);

					if ($1 == NAME) {
						gsub("Yes", "1", $2);
						gsub("No", "0", $2);
						print $2;
					}
				}'
		;;
	wsrep_hang_count)
		$MYSQL -BNe "SELECT COUNT(*) FROM information_schema.processlist WHERE time > 10 AND state LIKE 'wsrep: initiating replication for write set (-1)'"
		;;
esac

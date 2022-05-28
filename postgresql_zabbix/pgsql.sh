#!/bin/sh

psql() {
PGPASSFILE=/etc/zabbix/pgpass /usr/bin/psql -h localhost -d "$1" -U zabbix -At <<END
$2
END
}

psql_db_ratio() {
	if [ -z "$1" ] ; then
		v=`psql postgres "$2"`
	else
		v=`psql postgres "$3"`
	fi

	if [ -z "$v" ] ; then
		echo "0.0"
	else
		echo "$v"
	fi
}

psql_table_ratio() {
	if [ -z "$2" -a -z "$3" ] ; then
		v=`psql "$1" "$4"`
	else
		v=`psql "$1" "$5"`
	fi

	if [ -z "$v" ] ; then
		echo "0.0"
	else
		echo "$v"
	fi
}

case "$1" in
	version)
		psql postgres "SELECT current_setting('server_version_num')" |\
			/usr/bin/awk '
				{
					fix = $0 % 100;
					$0 = int($0 / 100);
					minor = $0 % 100;
					major = int($0 / 100);
					print major "." minor "." fix;
				}'	
		;;
	max_connections)
		psql postgres "
			SELECT setting::int
			FROM pg_settings
			WHERE name = 'max_connections'"
		;;
	active_connections)
		psql postgres "
			SELECT COUNT(*)
			FROM pg_stat_activity
			WHERE state = 'active'"
		;;
	idle_connections)
		psql postgres "
			SELECT COUNT(*)
			FROM pg_stat_activity
			WHERE state = 'idle'"
		;;
	idle_trx_connections)
		psql postgres "
			SELECT COUNT(*)
			FROM pg_stat_activity
			WHERE state = 'idle in transaction'"
		;;
	lock_waiting_connections)
		ver=`psql postgres "SELECT current_setting('server_version_num')"`
		if [ "$ver" -ge 100000 ] ; then
			psql postgres "
				SELECT COUNT(*)
				FROM pg_stat_activity
				WHERE backend_type = 'client backend'
				  AND wait_event_type like '%Lock%'"
		elif [ "$ver" -ge 90600 ] ; then
			psql postgres "
				SELECT COUNT(*)
				FROM pg_stat_activity
				WHERE wait_event_type like '%Lock%'"
		else
			psql postgres "
				SELECT COUNT(*)
				FROM pg_stat_activity
				WHERE waiting = true"
		fi
		;;
	total_connections)
		ver=`psql postgres "SELECT current_setting('server_version_num')"`
		if [ "$ver" -ge 100000 ] ; then
			psql postgres "
				SELECT COUNT(*)
				FROM pg_stat_activity
				WHERE backend_type = 'client backend'"
		else
			psql postgres "
				SELECT COUNT(*)
				FROM pg_stat_activity"
		fi
		;;
	slow_queries)
		psql postgres "
			SELECT COUNT(*)
			FROM pg_stat_activity
			WHERE state = 'active'
			  AND NOW() - query_start > '300 sec'::interval"
		;;
	slow_select_queries)
		psql postgres "
			SELECT COUNT(*)
			FROM pg_stat_activity
			WHERE state = 'active'
			  AND NOW() - query_start > '300 sec'::interval
			  AND query !~* '^(INSERT|UPDATE|DELETE)'"
		;;
	slow_dml_queries)
		psql postgres "
			SELECT COUNT(*)
			FROM pg_stat_activity
			WHERE state = 'active'
			  AND NOW() - query_start > '300 sec'::interval
			  AND query ~* '^(INSERT|UPDATE|DELETE)'"
		;;
	buffers_alloc|buffers_backend|buffers_backend_fsync|buffers_checkpoint|buffers_clean|checkpoints_req|checkpoints_timed|maxwritten_clean)
		psql postgres "
			SELECT $1
			FROM pg_stat_bgwriter"
		;;
	discover_databases)
		psql postgres "
			SELECT datname
			FROM pg_database
			WHERE datistemplate = false" \
				| /usr/bin/awk '
					BEGIN {
						printf "{\"data\":[\n";
						n = 0;
					}

					!/^$/ {
						if (n > 0) {
							printf ",\n";
						}
						printf "{\"{#DB}\":\"%s\"}", $0;
						n++;
					}

					END { printf "\n]}"; }'
		;;
	database_extensions)
		psql "$2" '\dx' \
			| awk -F \| '
				BEGIN {
					n = "";
				}

				!/^$/ {
					printf "%s%s", n, $1;
					n = " ";
				}'
		;;
	numbackends|temp_files|temp_bytes|xact_commit|xact_rollback|tup_deleted|tup_fetched|tup_inserted|tup_returned|tup_updated|deadlocks)
		if [ -z "$2" ] ; then
			psql postgres "
				SELECT SUM($1)
				FROM pg_stat_database"
		else
			psql postgres "
				SELECT $1
				FROM pg_stat_database
				WHERE datname = '$2'"
		fi
		;;
	cache_hit_ratio)
		psql_db_ratio "$2" \
			"SELECT SUM(blks_hit) / SUM(blks_hit + blks_read)
			FROM pg_stat_database
			WHERE blks_read > 0" \
			"SELECT CAST(blks_hit AS DOUBLE PRECISION) / (blks_hit + blks_read)
			FROM pg_stat_database
			WHERE datname = '$2'
			  AND blks_read > 0"
		;;
	commit_ratio)
		psql_db_ratio "$2" \
			"SELECT SUM(xact_commit) / SUM(xact_commit + xact_rollback)
			FROM pg_stat_database
			WHERE xact_commit > 0 OR xact_rollback > 0" \
			"SELECT CAST(xact_commit AS DOUBLE PRECISION) / (xact_commit + xact_rollback)
			FROM pg_stat_database
			WHERE datname = '$2'
			  AND (xact_commit > 0 OR xact_rollback > 0)"
		;;
	db_size)
		psql_db_ratio "$2" \
			"SELECT SUM(pg_database_size(datname))
			FROM pg_database
			WHERE datistemplate = false" \
			"SELECT pg_database_size('$2')"
		;;
	discover_tables)
		psql postgres "
			SELECT datname
			FROM pg_database
			WHERE datistemplate = false
			ORDER BY datname" \
				| while read database ; do
					psql "$database" "
						SELECT '$database',
						       schemaname,
						       relname
						FROM pg_stat_user_tables
						WHERE schemaname = 'public'
						  AND relid NOT IN (
						       SELECT inhrelid
						       FROM pg_inherits
						  )
						ORDER BY relname"
				done \
					| /usr/bin/awk -F\| '
						BEGIN {
							printf "{\"data\":[\n";
							n = 0;
						}

						!/^$/ {
							if (n > 0) {
								printf ",\n";
							}
							printf "{\"{#DB}\":\"%s\", \"{#SCHEMA}\":\"%s\", \"{#TABLE}\":\"%s\"}", $1, $2, $3;
							n++;
						}

						END { printf "\n]}"; }'
		;;
	table_size)
		psql_table_ratio "$2" "$3" "$4" \
			"SELECT SUM(pg_total_relation_size(relid))
			FROM pg_stat_user_tables" \
			"SELECT SUM(pg_total_relation_size(oid))
			FROM (
				SELECT relid AS oid
				FROM pg_stat_user_tables
				WHERE schemaname = '$3'
				  AND relname = '$4'

				UNION ALL SELECT c.oid AS oid
				FROM pg_stat_user_tables AS p
				JOIN pg_inherits ON pg_inherits.inhparent = p.relid
				JOIN pg_class AS c ON c.oid = pg_inherits.inhrelid
				WHERE p.schemaname = '$3'
				  AND p.relname = '$4'
			) AS oids"
		;;
	seq_scan|idx_scan|n_tup_ins|n_tup_upd|n_tup_del|n_tup_hot_upd)
		psql_table_ratio "$2" "$3" "$4" \
			"SELECT SUM($1)
			FROM pg_stat_user_tables" \
			"SELECT SUM($1)
			FROM pg_stat_user_tables
			WHERE relid IN (
				SELECT relid AS oid
				FROM pg_stat_user_tables
				WHERE schemaname = '$3'
				  AND relname = '$4'

				UNION ALL SELECT c.oid AS oid
				FROM pg_stat_user_tables AS p
				JOIN pg_inherits ON pg_inherits.inhparent = p.relid
				JOIN pg_class AS c ON c.oid = pg_inherits.inhrelid
				WHERE p.schemaname = '$3'
				  AND p.relname = '$4'
			)"
		;;
	n_tup_hot_upd_ratio)
		psql_table_ratio "$2" "$3" "$4" \
			"SELECT SUM(n_tup_hot_upd) / SUM(n_tup_hot_upd + n_tup_upd)
			FROM pg_stat_user_tables
			WHERE n_tup_hot_upd > 0 OR n_tup_upd > 0" \
			"SELECT CAST(SUM(n_tup_hot_upd) AS DOUBLE PRECISION) / SUM(n_tup_hot_upd + n_tup_upd)
			FROM pg_stat_user_tables
			WHERE (n_tup_hot_upd > 0 OR n_tup_upd > 0)
			  AND relid IN (
				SELECT relid AS oid
				FROM pg_stat_user_tables
				WHERE schemaname = '$3'
				  AND relname = '$4'

				UNION ALL SELECT c.oid AS oid
				FROM pg_stat_user_tables AS p
				JOIN pg_inherits ON pg_inherits.inhparent = p.relid
				JOIN pg_class AS c ON c.oid = pg_inherits.inhrelid
				WHERE p.schemaname = '$3'
				  AND p.relname = '$4'
			)"
		;;
	idx_scan_ratio)
		psql_table_ratio "$2" "$3" "$4" \
			"SELECT SUM(idx_scan) / SUM(idx_scan + seq_scan)
			FROM pg_stat_user_tables
			WHERE idx_scan > 0 AND seq_scan > 0" \
			"SELECT CAST(SUM(idx_scan) AS DOUBLE PRECISION) / SUM(idx_scan + seq_scan)
			FROM pg_stat_user_tables
			WHERE (idx_scan > 0 OR seq_scan > 0)
			  AND relid IN (
				SELECT relid AS oid
				FROM pg_stat_user_tables
				WHERE schemaname = '$3'
				  AND relname = '$4'

				UNION ALL SELECT c.oid AS oid
				FROM pg_stat_user_tables AS p
				JOIN pg_inherits ON pg_inherits.inhparent = p.relid
				JOIN pg_class AS c ON c.oid = pg_inherits.inhrelid
				WHERE p.schemaname = '$3'
				  AND p.relname = '$4'
			)"
		;;
	*)
		;;
esac

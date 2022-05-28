#!/bin/sh

skip_fillrate=90
skip_size=104857600
pg_repack=/usr/lib/postgresql/9.6/bin/pg_repack

pgsql() {
psql -d "$1" -Aqt <<END
SET SESSION statement_timeout = 0;
$2
END
}

pgsql "postgres" "
	SELECT datname
	FROM pg_database
	WHERE datistemplate = false;" \
	| while read database ; do
		echo "$database: checking extension pgstattuple"
		pgstattuple=`pgsql "$database" "
			SELECT COUNT(*)
			FROM pg_catalog.pg_extension e
			WHERE e.extname = 'pgstattuple';"`
		if [ "$pgstattuple" != "1" ]; then
			echo "$database: installing extension pgstattuple"
			pgsql "$database" "
				CREATE EXTENSION pgstattuple;"
		fi

		echo "$database: checking extension pg_repack"
		pgrepack=`pgsql "$database" "
			SELECT COUNT(*)
			FROM pg_catalog.pg_extension e
			WHERE e.extname = 'pg_repack';"`
		if [ "$pgrepack" != "1" ]; then
			echo "$database: installing extension pg_repack"
			pgsql "$database" "
				CREATE EXTENSION pg_repack;"
		fi

		echo "$database: requesting tables in database"
		pgsql "$database" "
			SELECT '\"' || schemaname || '\".\"' || relname || '\"'
			FROM pg_stat_user_tables
			WHERE schemaname = 'public'
                          AND relid NOT IN (
			       SELECT inhrelid
			       FROM pg_inherits
			  )
			ORDER BY relname;" \
			| while read table ; do
				echo "$database: checking properties of table $table"
				size=`pgsql "$database" "
					SELECT table_len
					FROM pgstattuple('$table')
					WHERE tuple_percent < $skip_fillrate
						AND table_len > $skip_size;"`
				if [ -n "$size" ] ; then
					echo "$database: repack table $table"
					$pg_repack -d "$database" -t "$table"
				fi
			done

		echo "$database: vacuum and analyze"
		pgsql "$database" "
			VACUUM ANALYZE;"
	done

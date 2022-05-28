#!/bin/sh

skip_fillrate=90
skip_size=1048576
full_vacuum_size=1073741824

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
		echo "$database: checking installed extensions"
		pgstattuple=`pgsql "$database" "
			SELECT COUNT(*)
			FROM pg_catalog.pg_extension e
			WHERE e.extname = 'pgstattuple';"`
		if [ "$pgstattuple" != "1" ]; then
			echo "$database: installing extension pgstattuple"
			pgsql "$database" "
				CREATE EXTENSION pgstattuple;"
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
				if [ "$size" != "" ]; then
					if [ "$size" -gt "$full_vacuum_size" ] ; then
						echo "$database: simple vacuum and analyze table $table"
						pgsql "$database" "
							VACUUM ANALYZE $table;"
					else
						echo "$database: full vacuum and analyze table $table"
						pgsql "$database" "
							VACUUM FULL ANALYZE $table;"
					fi
				fi
			done

		echo "$database: vacuum and analyze"
		pgsql "$database" "
			VACUUM ANALYZE;"
	done

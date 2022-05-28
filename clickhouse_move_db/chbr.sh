#!/bin/sh

# Перед использованием скрипта нужно создать файл с настройками подключения к ClickHouse:
#cat > ~/.clickhouse-client/config.xml <<END
#<config>
#        <host>127.0.0.1</host>
#        <port>9000</port>
#        <user>user</user>
#        <password></password>
#</config>
#END

MODE="$1"
DATABASE="$2"

case "$MODE" in
	"backup")
		if [ "$DATABASE" = "" ]
		then
			echo "No database specified"
			exit 1
		fi

		if [ -f "$DATABASE.tar" ]
		then
			echo "$DATABASE.tar already exist"
			exit 1
		fi

		if [ -d "$DATABASE" ]
		then
			echo "$DATABASE directory already exist"
			exit 1
		fi

		mkdir "$DATABASE"

		CC='clickhouse-client -d '"$DATABASE"' -q'

		tables=$($CC 'SHOW TABLES;')
		echo "$tables" |\
			while read table
			do
				echo -n "$table" && \
				table_schema=`$CC "SHOW CREATE $table;" | sed -Ee "s/^CREATE TABLE '$DATABASE'\./CREATE TABLE /g; s/\\\\\'/'/g"` && \
				printf "$table_schema;" > "$DATABASE/$table.sql" && \
				echo -n "..." && \
				$CC "SELECT * FROM $table FORMAT TabSeparated;" | gzip > "$DATABASE/$table.tsv.gz" && \
				echo "OK" || (echo "Failed" && exit 1)
			done

		echo -n "Compressing..."
		tar cf "$DATABASE.tar" "$DATABASE" && \
		rm -R "$DATABASE" && \
		echo "OK" || (echo "Failed" && exit 1)
		;;
	"restore")
		if [ "$DATABASE" = "" ]
		then
			echo "No database specified"
			exit 1
		fi

		if [ -f "$DATABASE.tar" ]
		then
			if [ -d "$DATABASE" ]
			then
				echo "$DATABASE directory already exist"
				exit 1
			fi

			echo -n "Decompressing..." && \
			tar xf "$DATABASE.tar" && \
			rm "$DATABASE.tar" && \
			echo "OK" || (echo "Failed" && exit 1)
		fi

		CC='clickhouse-client -d '"$DATABASE"

		tables=`ls -1 "$DATABASE" | egrep '\.sql$' | sed 's/\.sql$//'`
		echo "$tables" |\
			while read table
			do
				echo -n "$table" && \
				table_schema=`cat "$DATABASE/$table.sql"` && \
				$CC -m -q "$table_schema" && \
				echo -n "..." && \
				$CC -q "INSERT INTO $table FROM INFILE '"$DATABASE/$table.tsv.gz"' COMPRESSION 'gzip' FORMAT TabSeparated;" && \
				echo "OK" || (echo "Failed" && exit 1)
			done
		;;
	*)
		echo "Usage: $0 backup|restore <db>"
		exit 1
esac

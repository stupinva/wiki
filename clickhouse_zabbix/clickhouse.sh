#!/bin/sh

CH='clickhouse-client -C /etc/zabbix/clickhouse.xml -q '

case $1 in
	Version)
		$CH "SELECT value FROM metrics WHERE metric = 'VersionInteger'" \
			| awk '{
					major = int($0 / 1000000);
					minor = int($0 / 1000) % 1000;
					patch = $0 % 1000;
					print major "." minor "." patch;
				}'
		;;
	Query|TCPConnection|HTTPConnection|MySQLConnection|PostgreSQLConnection|\
	InterserverConnection|TotalTemporaryFiles|MemoryTracking|DelayedInserts|\
	GlobalThread|GlobalThreadActive|ContextLockWait|RWLockWaitingReaders|\
	RWLockWaitingWriters|RWLockActiveReaders|RWLockActiveWriters)
		$CH "SELECT value FROM metrics WHERE metric = '$1'"
		;;
	Uptime|NumberOfDatabases|NumberOfTables)
		$CH "SELECT value FROM asynchronous_metrics WHERE metric = '$1'"
		;;
	TotalQuery)
		$CH "SELECT value FROM events WHERE event = 'Query'"
		;;
	SelectQuery|InsertQuery|FailedQuery|FailedSelectQuery|FailedInsertQuery|\
	QueryTimeMicroseconds|SelectQueryTimeMicroseconds|InsertQueryTimeMicroseconds|\
	OtherQueryTimeMicroseconds|NetworkReceiveBytes|NetworkSendBytes|InsertedRows|\
	SelectedRows)
		$CH "SELECT SUM(value) FROM events WHERE event = '$1'"
		;;
	MaxQueryDuration)
		$CH "SELECT MAX(elapsed) FROM processes"
		;;
esac

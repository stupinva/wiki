#!/usr/bin/mawk -f

function parse_posgresql_log(connections, postgresql_log) {
	num_connections = 0;
	all_postgresql_logs = "sh -c 'cat " postgresql_log " 2>/dev/null ; zcat " postgresql_log ".*.gz 2>/dev/null'";
	while (all_postgresql_logs | getline) {
		# for PostgreSQL 9.5
		if (/connection received/) {
			split($9, a, /=/);
			ip = a[2];
			gsub(/\[|\]/, "", ip);

			split($4, a, /-/);
			id = a[1];

			id_ip[id] = ip;
		} else if (/connection authorized/) {
			# for PostgreSQL 9.5
			if ($6 == "LOG:") {
				split($4, a, /-/);
				id = a[1];

				# No appropriate "connection received" for "connection authorized"
				if (!(id in id_ip)) {
					continue;
				}

				ip = id_ip[id];

				split($9, a, /=/);
				user = a[2];

				split($10, a, /=/);
				db = a[2];
			} else {
				split($6, a, /\(/);
				ip = a[1];
				gsub(/\[|\]/, "", ip);

				split($10, a, /=/);
				user = a[2];

				split($11, a, /=/);
				db = a[2];
			}

			# Skip IPv6
			if (ip ~ /:/) {
				continue;
			}

			key = db " " user " " ip;
			if (key in connections) {
				continue;
			}
			#print "Client connection: " key;
			connections[key] = 1;
			num_connections++;
		}
	}
	return num_connections;
}

function parse_pgbouncer_log(connections, reconnections, pgbouncer_log) {
	num_connections = 0;
	all_pgbouncer_logs = "sh -c 'cat " pgbouncer_log " 2>/dev/null ; zcat " pgbouncer_log ".*.gz 2>/dev/null'";
	while (all_pgbouncer_logs | getline) {
		if (/login attempt/) {
			split($7, a, /:/);
			split(a[1], a, /@/);
			ip = a[2];
			gsub(/\[|\]/, "", ip);

			split($10, a, /=/);
			db = a[2];

			split($11, a, /=/);
			user = a[2];

			# Skip IPv6
			if (ip ~ /:/) {
				continue;
			}

			key = db " " user " " ip;
			if (key in connections) {
				continue;
			}
			#print "PgBouncer connection: " key;
			connections[key] = 1;
			num_connections++;
		} else if (/new connection to server/) {
			split($7, a, /:/);
			split(a[1], a, /@/);
			ip = a[2];
			if (ip == "unix") {
				ip = "local";
			}
			gsub(/\[|\]/, "", ip);

			split(a[1], a, /\//);
			db = a[1];
			user = a[2];

			key = db " " user " " ip;
			if (key in reconnections) {
				continue;
			}
			#print "PgBouncer reconnection: " key;
			reconnections[key] = 1;
			num_connections++;
                }
	}
	return num_connections;
}

function ip2i(ip) {
	split(ip, octets, /\./);
	if (split(ip, octets, /\./) != 4) {
		print "Wrong IP: " ip > "/dev/stderr";
		exit 1;
	}
	return octets[1] * 256 * 256 * 256 + octets[2] * 256 * 256 + octets[3] * 256 + octets[4];
}

function matchip(ip, network_mask) {
	if (split(network_mask, a, /\//) != 2) {
		print "Wrong network and mask: " net_mask > "/dev/stderr";
		exit 2;
	}
	network = a[1];
	mask = a[2];

	if (mask > 32) {
		print "Wrong network mask: " mask > "/dev/stderr";
		exit 2;
	}

	ip = ip2i(ip);
	network = ip2i(network);
	i = 32 - mask;
	while (i > 0) {
		ip = (ip - ip % 2) / 2;
		network = (network - network % 2) / 2;
		i--;
	}
	return ip == network;
}

function matchconnection(connections, db, user, hosts) {
	for(connection in connections) {
		split(connection, fields, " ");
		cdb = fields[1];
		cuser = fields[2];
		chost = fields[3];

		if ((db == "all" || db == cdb) &&
		    (user == "all" || user == cuser)) {
			if (chost == "local" || hosts == "skip") {
				# Matched db and user
				return 1;
			} else if (matchip(chost, hosts)) {
				# Full match
				return 2;
			}
		}
	}
	# No match
	return 0;
}

BEGIN {
	postgresql_log = "/var/log/postgresql/postgresql-9.6-main.log";
	pgbouncer_log = "/var/log/pgbouncer/pgbouncer.log";
	postgresql_hba = "/etc/postgresql/9.6/main/pg_hba.conf";

        num_clients_connections = parse_posgresql_log(clients_connections, postgresql_log);
        num_pgbouncer_connections = parse_pgbouncer_log(pgbouncer_connections, pgbouncer_reconnections, pgbouncer_log);
	if (num_clients_connections + num_pgbouncer_connections == 0) {
		print "Connections not found!" > "/dev/stderr";
		exit 3;
	}

	while (getline < postgresql_hba) {
		if (/^host/) {
			db = $2;
			gsub(/\"/, "", db);

			user = $3;
			gsub(/\"/, "", user);

			ip = $4;

			# Skip IPv6
			if (ip ~ /:/) {
				continue;
			}

			if (matchconnection(clients_connections, db, user, ip) == 2) {
				print "Used by client:             " $0;
			} else if (matchconnection(pgbouncer_connections, db, user, ip) == 2) {
				print "Used by PgBouncer:          " $0;
			} else if (matchconnection(pgbouncer_reconnections, db, user, ip) == 1) {
				print "Probably used by PgBouncer: " $0;
			} else {
				print "Unused:                     " $0;
			}
		} else if (/^local/) {
			db = $2;
			gsub(/\"/, "", db);

			user = $3;
			gsub(/\"/, "", user);

			if (matchconnection(clients_connections, db, user, "skip") == 1) {
				print "Used by client:             " $0;
			} else if (matchconnection(pgbouncer_connections, db, user, "skip") == 1) {
				print "Used by PgBouncer:          " $0;
			} else if (matchconnection(pgbouncer_reconnections, db, user, "skip") == 1) {
				print "Probably used by PgBouncer: " $0;
			} else {
				print "Unused:                     " $0;
			}
		} else if (!/^(#|$)/) {
			print "Skipped:                    " $0;
			continue;
		}
	}
}

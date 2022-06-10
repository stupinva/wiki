#!/usr/bin/mawk -f

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

BEGIN {
	postgresql_log = "/var/log/postgresql/postgresql-12-main.log";
	pgbouncer_log = "/var/log/pgbouncer/pgbouncer.log";
	postgresql_hba = "/etc/postgresql/12/main/pg_hba.conf";

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

				ip = id_ip[id];

				split($9, a, /=/);
				user = a[2];

				split($10, a, /=/);
				db = a[1];
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
			#print "postgresql " key;
			connections[key] = 1;
			num_connections++;
		}
	}

	all_pgbouncer_logs = "sh -c 'cat " pgbouncer_log " 2>/dev/null ; zcat " pgbouncer_log ".*.gz 2>/dev/null'";
	while (all_bgbouncer_logs | getline) {
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
			#print "pgbouncer " key;
			connections[key] = 2;
			num_connections++;
		}
	}

	if (num_connections == 0) {
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

			used = 0;
			for(connection in connections) {
				split(connection, fields, " ");
				cdb = fields[1];
				cuser = fields[2];
				chosts = fields[3];

				if ((db == "all" || db == cdb) &&
				    (user == "all" || user == cuser) &&
				    (chosts != "local") &&
				    matchip(chosts, ip)) {
					used = 1;
					break;
				}
			}
			if (used == 0) {
				print "Unused hba: " $0;
			}
		} else if (/^local/) {
			db = $2;
			gsub(/\"/, "", db);

			user = $3;
			gsub(/\"/, "", user);

			used = 0;
			for(connection in connections) {
				split(connection, fields, " ");
				cdb = fields[1];
				cuser = fields[2];
				chosts = fields[3];

				if ((db == "all" || db == cdb) &&
				    (user == "all" || user == cuser) &&
				    chosts == "local") {
					used = 1;
					break;
				}
			}
			if (used == 0) {
				print "Unused hba: " $0;
			}
		} else if (!/^(#|$)/) {
			print "Skiped hba: " $0;
			continue;
		}
	}
}

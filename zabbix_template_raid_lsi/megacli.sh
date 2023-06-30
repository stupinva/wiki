#!/bin/sh

if [ -x /usr/bin/sudo ] ; then
	SUDO=/usr/bin/sudo
else
	echo "sudo not found"
	exit
fi

if [ -x /usr/bin/gawk ] ; then
	AWK=/usr/bin/gawk
else
	echo "gawk not found"
	exit
fi

if [ -x /usr/sbin/megacli ] ; then
	MC=/usr/sbin/megacli
elif [ -x /sbin/MegaCli ] ; then
	MC=/sbin/MegaCli
else
	echo "MegaCli not found"
	exit
fi

case $1 in
	discover_adapters)
		$SUDO $MC -LDInfo -Lall -aALL -NoLog 2>&1 \
			| $AWK -F: '
				BEGIN {
					print "{\"data\": [\n";
					n = 0;
				}

				$0 ~ /^Adapter [0-9]+ --/ {
					split($0, cols, / /);

					if (n > 0) {
						printf ",\n";
					}
					printf "{\"{#ADAPTER}\": \"%d\"}", cols[2];
					n++;
				}

				END { printf "\n]}"; }'
		;;
	battery_missing)
		$SUDO $MC -AdpBbuCmd -GetBbuStatus -a$2 -NoLog 2>&1 \
			| $AWK '
				BEGIN { s = 0; }

				/(Battery Pack Missing.*es|Battery State.*issing|The required hardware component is not present)/ { s = 1; }

				END { print s; }'
		;;
	battery_state)
		$SUDO $MC -AdpBbuCmd -GetBbuStatus -a$2 -NoLog 2>&1 \
			| $AWK '
				BEGIN { s = "N/A"; }

				/^Battery State: *Not? (Optimal|Operational)/ { s = 0; }

				/^Battery State: *(Optimal|Operational)/ { s = 1; }

				/^Battery State: *Learning/ { s = 2; }

				/^Battery State: *Charging/ { s = 3; }

				/^Battery State: *Discharging/ { s = 4; }
				
				END { print s; }'
		;;
	discover_arrays)
		$SUDO $MC -LDInfo -Lall -aALL -NoLog 2>&1 \
			| $AWK -F: '
				BEGIN {
					print "{\"data\": [\n";
					n = 0;
				}

				/^Adapter / {
					split($0, cols, / /);
					adapter = cols[2];
				}

				$1 ~ /^Virtual Drive$/ {
					gsub(/^ +/, "", $2);
					split($2, cols, / /);
					array = cols[1];

					if (n > 0) {
						printf ",\n";
					}
					printf "{\"{#ADAPTER}\": \"%d\", ", adapter;
					printf "\"{#ARRAY}\": \"%d\"}", array;
					n++;
				}

				END { printf "\n]}"; }'
		;;
	array_state)
		$SUDO $MC -LDInfo -L$3 -a$2 -NoLog \
			| $AWK '
				BEGIN { s = 1; }

				/^State.*:.*(No.*ptimal|Degraded)$/ { s = 0; }

				END { print s; }'
		;;
	discover_disks)
		$SUDO $MC -PdList -aALL -NoLog 2>&1 \
			| $AWK -F: '
				BEGIN {
					printf "{\"data\": [\n";
					n = 0;
				}

				/^Adapter #/ {
					split($0, cols, /#/);
					adapter = cols[2];
				}

				$1 ~ /^Drive.s position$/ {
					array = $3;
				}

				$1 ~ /^Enclosure Device ID$/ {
					edid = $2;
				}

				$1 ~ /^Slot Number$/ {
					slot = $2;
				}

				$1 ~ /^Media Type$/ {
					if ($2 ~ /Solid State Device/) {
						type = "SSD";
					} else {
						type = "HDD";
					}

					if (n > 0) {
						printf ",\n";
					}
					printf "{\"{#ADAPTER}\": \"%d\", ", adapter;
					printf "\"{#ARRAY}\": \"%d\", ", array;
					printf "\"{#EDID}\": \"%d\", ", edid;
					printf "\"{#SLOT}\": \"%d\", ", slot;
					printf "\"{#TYPE}\": \"%s\"}", type;
					n++;
				}

				END { printf "\n]}"; }'
		;;
	model)
		$SUDO $MC -PdInfo -PhysDrv\[$3:$4\] -a$2 -NoLog 2>&1 \
			| $AWK -F: '
				$1 ~ /^Inquiry Data$/ {
					if (match($2, /(WDC |)WD[^-][^ ]+|Micron[^ ]+/)) {
						model = substr($2, RSTART, RLENGTH);
						gsub(/_/, " ", model);
						print model;
					} else if (match($2, /[^ ]+ [^ ]+/)) {
						# Two tokens, separated by space, is vendor and model
						print substr($2, RSTART, RLENGTH);
					}
				}'
		;;
	serial)
		$SUDO $MC -PdInfo -PhysDrv\[$3:$4\] -a$2 -NoLog 2>&1 \
			| $AWK -F: '
				$1 ~/^Device Firmware Level$/ {
						firmware = $2;
					}

				$1 ~ /^Inquiry Data$/ {
					if (match($2, /(WDC |)WD[^-][^ ]+|Micron[^ ]+/)) {
						model = substr($2, RSTART, RLENGTH);
					} else if (match($2, /[^ ]+ [^ ]+/)) {
						# Two tokens, separated by space, is vendor and model
						model = substr($2, RSTART, RLENGTH);
					}

					gsub(model, "", $2);
					split($2, tokens, / +/);

					# Most long token is serial, firmware should not be substring of it
					n = 0;
					serial = "";
					for(i in tokens) {
						if ((length(tokens[i]) > n) && (firmware !~ tokens[i])) {
							n = length(tokens[i]);
							serial = tokens[i];
						}
					}
					print serial;
				}'
		;;
	health)
		$SUDO $MC -PdInfo -PhysDrv\[$3:$4\] -a$2 -NoLog 2>&1 \
			| $AWK -F: '
				/^Drive has flagged a S.M.A.R.T alert *: *Yes$/ { print 0; }

				/^Drive has flagged a S.M.A.R.T alert *: *No$/ { print 1; }'
		;;
	reallocated)
		$SUDO $MC -PdInfo -PhysDrv\[$3:$4\] -a$2 -NoLog 2>&1 \
			| $AWK -F: '
				$1 ~ /^Media Error Count$/ {
					gsub(/(^ +| +$)/, "", $2);
					print $2;
				}'
		;;
	temperature)
		$SUDO $MC -PdInfo -PhysDrv\[$3:$4\] -a$2 -NoLog 2>&1 \
			| $AWK -F: '
				BEGIN { temperature = "N/A"; }

				$1 ~ /^Drive Temperature/ {
					split($2, a, /C/);
					gsub(/(^ +| +$)/, "", a[1]);
					temperature = a[1];
				}

				END { print temperature; }'
		;;
	spare)
		$SUDO $MC -PdInfo -PhysDrv\[$3:$4\] -a$2 -NoLog 2>&1 \
			| $AWK '
				BEGIN { spare = 0; }

				/^Firmware state: *Hotspare/ { spare = 1; }

				/^Firmware state: *Unconfigured/ { spare = 2; }

				END {
					# 0 - not a spare
					# 1 - good spare
					# 2 - bad spare
					print spare;
				}'
		;;
	*)
		echo "Usage: $0 discover_adapters"
		echo "       $0 battery_missing|battery_state <adapter>"
		echo "       $0 discover_arrays"
		echo "       $0 array_state <adapter> <array>"
		echo "       $0 discover_disks"
		echo "       $0 model|serial|health|reallocated|temperature|spare <adapter> <enclosure_id> <slot>"
		;;
esac

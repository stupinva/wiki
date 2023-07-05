#!/bin/sh

DIR=/srv/mysql.new
PORT=4444

P=`pwd`
mkdir -p "$DIR" && \
	cd "$DIR" && \
	socat -u TCP-LISTEN:$PORT,reuseaddr stdio | pigz -dc -p 4 - | tar xf - && \
	chown -R mysql:mysql "$DIR" && \
	rm "$DIR"/auto.cnf 
cd "$P"

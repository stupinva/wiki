#!/bin/sh

mkdir -p /srv/mysql.new && cd /srv/mysql.new && socat -u TCP-LISTEN:4444,reuseaddr stdio | pigz -dc -p 4 - | tar xvf - && chown -R mysql:mysql /srv/mysql.new

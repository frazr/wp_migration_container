#!/bin/bash

# Always chown webroot for better mounting
chown -Rf www-data. /var/www/html

if [ ! -d "/data/etc" ]; then

  mkdir -p /data/
  mkdir /data/sites
  mkdir /data/logs
  mkdir /data/php-fpm.d
  mkdir /data/nginx.d
  mkdir /data/etc
	cp /etc/passwd /data/etc/
	cp /etc/shadow /data/etc/
	cp /etc/group /data/etc/
  touch /data/etc/hosts
	cat /etc/hosts > /data/etc/hosts
  mysql_install_db \
        --user=mysql \
        --datadir=/data/mysql/data 
else
  cp /data/etc/passwd /etc/passwd
  cp /data/etc/shadow /etc/shadow
  cp /data/etc/group /etc/group
	cat /data/etc/hosts >> /etc/hosts
fi

send-router-domains

# Start supervisord and services
/usr/bin/supervisord -n -c /etc/supervisord.conf

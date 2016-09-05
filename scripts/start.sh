#!/bin/bash

# Always chown webroot for better mounting
chown -Rf www-data. /var/www/html

# Display PHP error's or not
if [[ "$ERRORS" != "1" ]] ; then
	echo php_flag[display_errors] = off >> /etc/php/php-fpm.conf
else
	echo php_flag[display_errors] = on >> /etc/php/php-fpm.conf
fi

# Display Version Details or not
if [[ "$HIDE_NGINX_HEADERS" == "0" ]] ; then
	sed -i "s/server_tokens off;/server_tokens on;/g" /etc/nginx/nginx.conf
else
	sed -i "s/expose_php = On/expose_php = Off/g" /etc/php/conf.d/php.ini
fi

# Increase the memory_limit
if [ ! -z "$PHP_MEM_LIMIT" ]; then
	sed -i "s/memory_limit = 128M/memory_limit = ${PHP_MEM_LIMIT}M/g" /etc/php/conf.d/php.ini
fi

# Increase the post_max_size
if [ ! -z "$PHP_POST_MAX_SIZE" ]; then
	sed -i "s/post_max_size = 100M/post_max_size = ${PHP_POST_MAX_SIZE}M/g" /etc/php/conf.d/php.ini
fi

# Increase the upload_max_filesize
if [ ! -z "$PHP_UPLOAD_MAX_FILESIZE" ]; then                                                                      
	sed -i "s/upload_max_filesize = 100M/upload_max_filesize= ${PHP_UPLOAD_MAX_FILESIZE}M/g" /etc/php/conf.d/php.ini
fi

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

FROM debian:jessie

ENV DEBIAN_FRONTEND noninteractive
ENV php_conf /etc/php/7.0/fpm/php.ini 
ENV fpm_conf /etc/php/7.0/fpm/pool.d/www.conf 
ENV composer_hash e115a8dc7871f15d853148a7fbac7da27d6c0030b848d9b3dc09e2a0388afed865e6a3d6b3c0fad45c48e2b5fc1196ae


RUN echo "deb http://ftp.se.debian.org/debian/ jessie main" > /etc/apt/sources.list
RUN echo "deb http://security.debian.org/ jessie/updates main" >> /etc/apt/sources.list

RUN apt-get -y update
RUN apt-get -y install wget

RUN echo "deb http://packages.dotdeb.org jessie all" >> /etc/apt/sources.list
RUN echo "deb-src http://packages.dotdeb.org jessie all" >> /etc/apt/sources.list

RUN wget https://www.dotdeb.org/dotdeb.gpg
RUN apt-key add dotdeb.gpg

RUN apt-get update && \
    apt-get -y install bash \
    openssh-client \
    nginx \
		pwgen \
		logrotate \
		mariadb-server \
		mariadb-client \
		supervisor \
		php7.0-cli \
		php7.0-curl \
		php7.0-dev \
		php7.0-fpm \
		php7.0-gd \
		php7.0-imagick \
		php7.0-intl \
		php7.0-json \
		php7.0-imap \
		php7.0-xml \
		php7.0-mysql \
		php7.0-mcrypt \
		php7.0-opcache \
		php7.0-mbstring \
		openssh-server \
		libffi-dev \
    curl \
    git \
    python \
    python-dev \
    python-pip \
    ca-certificates \
		libssl-dev \
    gcc && \
    mkdir -p /etc/nginx && \
    mkdir -p /var/www/app && \
    mkdir -p /run/nginx && \
    mkdir -p /var/log/supervisor && \
    php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" && \
    php -r "if (hash_file('SHA384', 'composer-setup.php') === '${composer_hash}') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;" && \
    php composer-setup.php --install-dir=/usr/bin --filename=composer && \
    php -r "unlink('composer-setup.php');" && \
    pip install -U certbot && \
    mkdir -p /etc/letsencrypt/webrootauth

# Copy our nginx config
RUN rm -Rf /etc/nginx/nginx.conf
ADD conf/nginx/nginx.conf /etc/nginx/nginx.conf
ADD conf/nginx/restrictions /etc/nginx/restrictions
ADD conf/nginx/wordpress /etc/nginx/wordpress

# nginx site conf
RUN mkdir -p /etc/nginx/sites-available/ && \
mkdir -p /etc/nginx/sites-enabled/ && \
mkdir -p /etc/nginx/ssl/ && \
rm -Rf /var/www/* && \
mkdir /var/www/html/

ADD conf/nginx/nginx-site.conf /etc/nginx/sites-available/default.conf
ADD conf/nginx/nginx-site-ssl.conf /etc/nginx/sites-available/default-ssl.conf
ADD conf/php-fpm.conf /etc/php/7.0/fpm/php-fpm.conf

# Symbolic link for php-fpm
RUN ln -s /usr/sbin/php-fpm7.0 /usr/sbin/php-fpm

ADD conf/my.cnf /etc/mysql/my.cnf

# tweak php-fpm config
RUN sed -i -e "s/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/g" ${php_conf} && \
sed -i -e "s/upload_max_filesize\s*=\s*2M/upload_max_filesize = 100M/g" ${php_conf} && \
sed -i -e "s/post_max_size\s*=\s*8M/post_max_size = 100M/g" ${php_conf} && \
sed -i -e "s/variables_order = \"GPCS\"/variables_order = \"EGPCS\"/g" ${php_conf} && \
sed -i -e "s/;daemonize\s*=\s*yes/daemonize = no/g" ${fpm_conf} && \
sed -i -e "s/;catch_workers_output\s*=\s*yes/catch_workers_output = yes/g" ${fpm_conf} && \
sed -i -e "s/pm.max_children = 4/pm.max_children = 4/g" ${fpm_conf} && \
sed -i -e "s/pm.start_servers = 2/pm.start_servers = 3/g" ${fpm_conf} && \
sed -i -e "s/pm.min_spare_servers = 1/pm.min_spare_servers = 2/g" ${fpm_conf} && \
sed -i -e "s/pm.max_spare_servers = 3/pm.max_spare_servers = 4/g" ${fpm_conf} && \
sed -i -e "s/pm.max_requests = 500/pm.max_requests = 200/g" ${fpm_conf} && \
sed -i -e "s/user = nobody/user = www-data/g" ${fpm_conf} && \
sed -i -e "s/group = nobody/group = www-data/g" ${fpm_conf} && \
sed -i -e "s/;listen.mode = 0660/listen.mode = 0666/g" ${fpm_conf} && \
sed -i -e "s/;listen.owner = nobody/listen.owner = www-data/g" ${fpm_conf} && \
sed -i -e "s/;listen.group = nobody/listen.group = www-data/g" ${fpm_conf} && \
sed -i -e "s/listen = 127.0.0.1:9000/listen = \/var\/run\/php-fpm.sock/g" ${fpm_conf} && \
sed -i -e "s/^;clear_env = no$/clear_env = no/" ${fpm_conf} && \
mkdir -p /etc/php/conf.d && \
ln -s /etc/php/7.0/fpm/php.ini /etc/php/conf.d/php.ini && \
find /etc/php/conf.d/ -name "*.ini" -exec sed -i -re 's/^(\s*)#(.*)/\1;\2/g' {} \;

# Add Scripts

ADD scripts/pull /usr/bin/pull
ADD scripts/push /usr/bin/push
ADD scripts/letsencrypt-setup /usr/bin/letsencrypt-setup
ADD scripts/letsencrypt-renew /usr/bin/letsencrypt-renew
ADD scripts/send-router-domains /usr/bin/send-router-domains
RUN chmod 755 /usr/bin/pull && \
    chmod 755 /usr/bin/push && \
    chmod 755 /usr/bin/letsencrypt-setup && \
    chmod 755 /usr/bin/letsencrypt-renew && \
    chmod 755 /usr/bin/send-router-domains

ADD conf/logrotate/nginx /etc/logrotate.d/nginx
ADD conf/logrotate/php-fpm7 /etc/logrotate.d/php-fpm7

RUN mkdir /var/run/mysql && \
		mkdir /var/run/sshd && \
    touch /var/run/mysql/mysqld.pid && \
    chown -R mysql. /var/run/mysql && \
    chmod 766 /var/run/mysql/mysqld.pid


# copy in code
ADD src/ /var/www/html/

ADD conf/supervisord.conf /etc/supervisord.conf
ADD scripts/start.sh /start.sh
ADD scripts/new /usr/bin/new
ADD scripts/move /usr/bin/move

RUN chmod 755 /usr/bin/new && \
    chmod 755 /start.sh
    

EXPOSE 3306 443 80

CMD ["/start.sh"]

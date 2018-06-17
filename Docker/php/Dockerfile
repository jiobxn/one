FROM centos:latest
MAINTAINER "The CentOS Project" <admin@jiobxn.com>
ARG LATEST="0"
ARG php_v="7.0"
#7.0\7.1\7.2

RUN \cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
RUN yum clean all; yum -y install epel-release; yum -y update \
        && yum -y install net-tools bash-completion vim wget strace make gcc-c++ autoconf iptables bzip2 unzip bzip2-devel mingw64-win-iconv libmcrypt-devel libxml2-devel libcurl-devel libpng-devel libc-client-devel krb5-devel libicu-devel libjpeg libjpeg-devel libXpm-devel freetype-devel gmp-devel readline-devel net-snmp-devel libtidy-devel libgcrypt-devel gd-devel gdbm-devel libxslt-devel mhash-devel openldap-devel libacl-devel enchant-devel libwebp-devel libedit-devel libmemcached-devel \
        && yum clean all

RUN cd /usr/local/src \
        && PHP_VERSION="$(curl -s http://php.net/downloads.php |egrep php-${mysql_v}.*.tar.gz |awk -F/ '{print $3}')" \
        && wget -c http://php.net/distributions/${PHP_VERSION} \
        && wget -c https://github.com/phpredis/phpredis/archive/php7.zip \
        && wget -c "https://github.com$(curl -s https://github.com/php-memcached-dev/php-memcached/releases |grep tar.gz |awk -F\" 'NR==1{print $2}')" 

RUN cd /usr/local/src \
        && tar zxf php-*.tar.gz \
        && unzip php7.zip \
        && tar zxf v*.tar.gz \
        && cd /usr/local/src/php-* \
        && ./configure --prefix=/usr/local/php \
           --with-config-file-path=/usr/local/php/etc \
           --with-pdo-mysql \
           --with-mysqli \
           --with-iconv-dir=/usr \
           --with-mcrypt=/usr \
           --with-libdir=lib64 \
           --with-mhash \
           --with-curl \
           --with-xmlrpc \
           --with-gettext \
           --with-imap-ssl \
           --with-imap \
           --with-pear \
           --with-gd \
           --with-kerberos \
           --with-pcre-regex \
           --with-snmp \
           --with-gmp \
           --with-openssl \
           --with-zlib \
           --with-pcre-dir \
           --with-libxml-dir \
           --with-png-dir \
           --with-freetype-dir  \
           --with-icu-dir=/usr \
           --with-jpeg-dir \
           --with-xpm-dir \
           --with-readline \
           --with-ldap-sasl \
           --with-ldap \
           --with-tidy \
           --with-xsl \
           --with-gdbm \
           --with-bz2 \
           --with-fpm-acl \
           --with-enchant \
           --with-webp-dir \
           --with-pcre-jit \
           --with-libedit \
           --with-system-ciphers \
           --enable-zend-signals \
           --enable-calendar \
           --enable-opcache \
           --enable-exif \
           --enable-intl \
           --enable-mysqlnd \
           --enable-dba \
           --enable-fpm \
           --enable-xml \
           --enable-ftp \
           --enable-zip \
           --enable-soap \
           --enable-shmop \
           --enable-wddx \
           --enable-pcntl \
           --enable-bcmath \
           --enable-sockets \
           --enable-sysvsem \
           --enable-sysvmsg \
           --enable-sysvshm \
           --enable-mbregex \
           --enable-mbstring \
           --enable-session \
           --enable-embedded-mysqli \
           --enable-gd-native-ttf \
           --enable-inline-optimization \
        && make -j8 && make install \
        && \cp /usr/local/src/php-*/php.ini-development /usr/local/php/etc/php.ini \
        && ln -s /usr/local/php/bin/* /usr/local/bin/ \
        && ln -s /usr/local/php/sbin/* /usr/local/bin/ \
        && cd /usr/local/src/phpredis-php7 \
        && phpize && ./configure && make -j8 && make install \
        && sed -i '876 i extension=redis.so' /usr/local/php/etc/php.ini \
        && cd /usr/local/src/php-memcached-* \
        && phpize && ./configure && make -j8 && make install \
        && sed -i '877 i extension=memcached.so' /usr/local/php/etc/php.ini \
        && \cp /usr/local/php/etc/php-fpm.conf.default /usr/local/php/etc/php-fpm.conf \
        && \cp /usr/local/php/etc/php-fpm.d/www.conf.default /usr/local/php/etc/php-fpm.d/www.conf \
        && sed -i 's/listen = 127.0.0.1:9000/listen = [::]:9000/' /usr/local/php/etc/php-fpm.d/www.conf \
        && sed -i 's/;daemonize = yes/daemonize = no/' /usr/local/php/etc/php-fpm.conf \
        && sed -i 's/;date.timezone =/date.timezone = PRC/' /usr/local/php/etc/php.ini \
        && rm -rf /usr/local/src/*

VOLUME /var/www

COPY php.sh /php.sh
RUN chmod +x /php.sh

ENTRYPOINT ["/php.sh"]

EXPOSE 9000

CMD ["php-fpm"]

# docker build -t php:7 .
# docker run -d --restart always -p 9000:9000 -v /docker/www:/var/www --hostname php --name php php:7

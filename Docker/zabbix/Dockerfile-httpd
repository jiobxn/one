FROM centos:latest
MAINTAINER "The CentOS Project" <admin@jiobxn.com>
ARG LATEST="0"

RUN \cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
RUN rpm -ivh http://repo.mysql.com/$(curl -s "https://dev.mysql.com/downloads/repo/yum/" |grep "noarch.rpm" |head -1 |grep -Po '(?<=\()[^)]*(?=\))')
RUN yum clean all; yum -y install epel-release; yum -y update \
        && yum -y install httpd mod_ssl python2-simplejson net-tools bash-completion vim wget make gcc cronie \
        && yum -y install OpenIPMI-devel libssh2-devel unixODBC-devel iksemel-devel net-snmp-devel mysql-community-devel mysql-community-client libxml2-devel curl-devel java-1.8.0-openjdk-devel openldap-devel fping wqy-zenhei-fonts libevent-devel \
        && yum clean all

RUN useradd -r -s /sbin/nologin zabbix \
        && cd /usr/local/src \
        && wget -c https://sourceforge.net/projects/zabbix/files/latest/download?source=files -O zabbix.tar.gz

RUN cd /usr/local/src \
        && tar zxf zabbix.tar.gz \
        && cd /usr/local/src/zabbix-* \
        && ./configure --prefix=/usr/local/zabbix \
           --enable-server \
           --enable-agent \
           --enable-java \
           --with-mysql \
           --with-net-snmp \
           --with-libcurl \
           --with-libxml2 \
           --with-openipmi \
           --with-ssh2 \
           --with-iconv \
           --with-unixodbc \
           --with-jabber \
           --with-openssl \
           --with-ldap \
        && make install \
        && cp -a database/mysql /usr/local/zabbix/mysql \
        && cp -a frontends/php /usr/local/zabbix/php \
        && rm -rf /usr/local/src/* \
        && ln -s /usr/local/zabbix/sbin/zabbix_* /usr/local/bin/ \
        && ln -s /usr/local/zabbix/bin/* /usr/local/bin/

VOLUME /var/www/html /usr/local/zabbix/etc

COPY zabbix-httpd.sh /zabbix.sh
RUN chmod +x /zabbix.sh

ENTRYPOINT ["/zabbix.sh"]

EXPOSE 80 443

CMD ["httpd", "-DFOREGROUND"]

# docker build -t zabbix-httpd .
# docker run -d --restart always --privileged -p 11080:80 -p 11443:443 -v /docker/www:/var/www/html -e PHP_SERVER=redhat.xyz -e ZBX_DB_SERVER=redhat.xyz --hostname zabbix --name zabbix zabbix-httpd
# docker run -it --rm zabbix-httpd --help

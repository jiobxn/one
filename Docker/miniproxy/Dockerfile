FROM centos:latest
MAINTAINER "The CentOS Project" <admin@jiobxn.com>
ARG LATEST="0"

RUN yum clean all; yum -y update; yum -y install httpd mod_ssl php php-mysql php-xml php-mbstring; yum clean all
RUN curl -s https://raw.githubusercontent.com/joshdick/miniProxy/master/miniProxy.php -o /var/www/html/index.php

EXPOSE 80 443

CMD ["httpd", "-DFOREGROUND"]

# docker build -t miniproxy .
# docker run -d --restart always -p 8080:80 -p 8444:443 --name miniproxy miniproxy
# -v /docker/key/server.crt:/etc/pki/tls/certs/localhost.crt:ro -v /docker/key/server.key:/etc/pki/tls/private/localhost.key:ro

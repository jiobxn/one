FROM centos:7
MAINTAINER "The CentOS Project" <admin@jiobxn.com>

ARG LATEST="0"
ARG php_v="56"

RUN yum clean all; yum -y install epel-release; yum -y update; yum -y install httpd mod_ssl net-tools; yum clean all
RUN rpm -ivh http://rpms.famillecollet.com/enterprise/remi-release-7.rpm
RUN if [ "${php_v}" -ge 70 ];then redis=5; fi; yum -y install --enablerepo=remi --enablerepo=remi-php${php_v} php php-fpm php-pecl-redis${redis} php-mysqlnd php-opcache php-zip php-gd php-mbstring php-xml php-mcrypt; yum clean all

VOLUME /var/www/html

COPY apache.sh /apache.sh
RUN chmod +x /apache.sh

ENTRYPOINT ["/apache.sh"]

EXPOSE 80 443 9000

CMD ["httpd", "-DFOREGROUND"]

# docker build --build-arg php_v=56 -t apache:56 .
# docker run -d --restart unless-stopped -p 80:80 -p 443:443 -v /docker/www:/var/www/html -e TZ=Asia/Shanghai --name httpd apache:56
# docker run -d --restart unless-stopped -p 9000:9000 -v /docker/www:/var/www -e TZ=Asia/Shanghai --name php apache:56 php-fpm -F
# docker run -it --rm apache --help

FROM centos:7
MAINTAINER "The CentOS Project" <admin@jiobxn.com>

ARG LATEST="0"
ARG php_v="56"

RUN yum clean all; yum -y install epel-release; yum -y update; yum -y install httpd mod_ssl net-tools unzip wget cronie; yum clean all
RUN rpm -ivh http://rpms.remirepo.net/enterprise/remi-release-7.rpm
RUN if [ "${php_v}" -ge 70 ];then redis=5; fi; yum -y install --enablerepo=remi --enablerepo=remi-php${php_v} php php-fpm php-pecl-redis${redis} php-mysqlnd php-opcache php-zip php-gd php-bcmath php-mbstring php-xml php-mcrypt php-posix; yum clean all
RUN cd /mnt && php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" && php composer-setup.php && mv composer.phar /usr/local/bin/composer \
    && wget -c https://downloads.ioncube.com/loader_downloads/ioncube_loaders_lin_x86-64.tar.gz && tar zxf ioncube_loaders_lin_x86-64.tar.gz && mv ioncube /usr/local/ioncube \
    && wget -c https://www.sourceguardian.com/loaders/download/loaders.linux-x86_64.tar.gz && tar zxf loaders.linux-x86_64.tar.gz \
    && mv ixed.$(php -v |awk 'NR==1{print $2}' |awk -F. '{print $1"."$2}').lin /usr/lib64/php/modules/ \
    && rm -rf /mnt/*

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

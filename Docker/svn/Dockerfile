FROM centos:latest
MAINTAINER "The CentOS Project" <admin@jiobxn.com>
ARG LATEST="0"

RUN yum clean all; yum -y update; yum -y install httpd mod_ssl subversion mod_dav_svn php wget unzip net-tools; yum clean all

RUN cd /mnt \
    && wget -c https://github.com/mfreiholz/iF.SVNAdmin/archive/master.zip \
    && unzip master.zip \
    && mv iF.SVNAdmin-master /var/www/html/svnadmin \
    && \rm *

VOLUME /home/svn

COPY svn.sh /svn.sh
RUN chmod +x /svn.sh

ENTRYPOINT ["/svn.sh"]

EXPOSE 80 443 3690

CMD ["httpd", "-DFOREGROUND"]

# docker build -t svn .
# docker run -d --restart unless-stopped -p 10080:80 -p 10443:443 -v /docker/svn:/home/svn --name svn svn
# docker logs svn

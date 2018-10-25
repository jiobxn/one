FROM centos:latest
MAINTAINER "The CentOS Project" <admin@jiobxn.com>
ARG LATEST="0"

RUN \cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
RUN yum clean all; yum -y update; yum -y install httpd mod_ssl subversion mod_dav_svn net-tools iptables; yum clean all

VOLUME /home/svn

COPY svn.sh /svn.sh
RUN chmod +x /svn.sh

ENTRYPOINT ["/svn.sh"]

EXPOSE 80 443 3690

CMD ["httpd", "-DFOREGROUND"]

# docker build -t svn .
# docker run -d --restart always -p 10080:80 -p 10443:443 -v /docker/svn:/home/svn --hostname svn --name svn svn
# docker logs svn

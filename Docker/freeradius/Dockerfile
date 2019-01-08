FROM centos:latest
MAINTAINER "The CentOS Project" <admin@jiobxn.com>
ARG LATEST="0"

RUN \cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
RUN yum clean all; yum -y update; yum -y install net-tools iptables freeradius freeradius-utils freeradius-mysql mariadb; yum clean all

VOLUME /key

COPY freeradius.sh /freeradius.sh
RUN chmod +x /freeradius.sh

ENTRYPOINT ["/freeradius.sh"]

EXPOSE 1812/udp 1813/udp

CMD ["radiusd", "-f"]

# docker build -t freeradius .
# docker run -d --restart unless-stopped -p 1812:1812/udp -p 1813:1813/udp -v /docker/freeradius:/key --name freeradius freeradius
# docker logs freeradius

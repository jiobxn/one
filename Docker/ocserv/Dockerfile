FROM centos:7
MAINTAINER "The CentOS Project" <admin@jiobxn.com>
ARG LATEST="0"

RUN yum -y install epel-release; yum -y update; yum -y install ocserv iptables radiusclient-ng net-tools; yum clean all

VOLUME /key

COPY ocserv.sh /ocserv.sh
RUN chmod +x /ocserv.sh

WORKDIR /usr/sbin

ENTRYPOINT ["/ocserv.sh"]

EXPOSE 443

CMD ["ocserv", "-d", "1", "-f"]

# docker build -t ocserv .
# docker run -d --restart always --privileged -v /docker/ocserv:/key -p 443:443 -e VPN_USER=jiobxn --name ocserv ocserv
# cat /docker/ocserv/ocserv.log

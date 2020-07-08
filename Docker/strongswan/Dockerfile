FROM centos:7
MAINTAINER "The CentOS Project" <admin@jiobxn.com>
ARG LATEST="0"

RUN yum -y install epel-release; yum -y update; yum -y install strongswan openssl iptables net-tools; yum clean all

VOLUME /key

COPY strongswan.sh /strongswan.sh
RUN chmod +x /strongswan.sh

WORKDIR /usr/sbin

ENTRYPOINT ["/strongswan.sh"]

EXPOSE 500/udp 4500/udp

CMD ["strongswan", "start", "--nofork"]

# docker build -t strongswan .
# docker run -d --restart unless-stopped -p 500:500/udp -p 4500:4500/udp --cap-add NET_ADMIN --device /dev/net/tun -v /docker/strongswan:/key --name strongswan strongswan
# cat /docker/strongswan/strongswan.log

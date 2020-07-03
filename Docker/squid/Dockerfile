FROM centos:latest
MAINTAINER "The CentOS Project" <admin@jiobxn.com>
ARG LATEST="0"

RUN yum clean all; yum -y update; yum -y install squid openssl net-tools; yum clean all

COPY squid.sh /squid.sh
RUN chmod +x /squid.sh

ENTRYPOINT ["/squid.sh"]

EXPOSE 3128 43128

CMD ["squid", "-N", "-f", "/etc/squid/squid.conf"]

# docker build -t squid .
# docker run -d --restart unless-stopped -p 8081:3128 -p 8082:3129 -e SQUID_USER=jiobxn --name squid squid
# docker logs squid

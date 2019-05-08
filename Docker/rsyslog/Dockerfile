FROM centos:latest
MAINTAINER "The CentOS Project" <admin@jiobxn.com>
ARG LATEST="0"

RUN yum clean all; yum -y update; yum -y install rsyslog httpd net-tools cronie; yum clean all

VOLUME /var/log/rsyslog

COPY rsyslog.sh /rsyslog.sh
RUN chmod +x /rsyslog.sh

ENTRYPOINT ["/rsyslog.sh"]

EXPOSE 80 514 514/udp

CMD ["rsyslogd", "-n"]

# docker build -t rsyslog .
# docker run -d --restart unless-stopped -p 80:80 -p 514:514 -p 514:514/udp -v /docker/rsyslog:/var/log/rsyslog --name rsyslog rsyslog

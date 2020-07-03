FROM centos:latest
MAINTAINER "The CentOS Project" <admin@jiobxn.com>
ARG LATEST="0"

RUN yum clean all; yum -y update; yum -y install rsyslog httpd net-tools; yum clean all

RUN ln -s /var/log/rsyslog /var/www/html/down \
        && curl -s https://raw.githubusercontent.com/jiobxn/one/master/Docker/rsyslog/index.html >/var/www/html/index.html \
        && curl -s https://raw.githubusercontent.com/jiobxn/one/master/Docker/rsyslog/hello.cgi >/var/www/cgi-bin/hello.cgi \
        && curl -s https://raw.githubusercontent.com/jiobxn/one/master/Docker/rsyslog/loginfo.sh >/var/www/cgi-bin/loginfo.sh \
        && chown apache.apache /var/www/cgi-bin/* \
        && chmod 700 /var/www/cgi-bin/*

VOLUME /var/log/rsyslog

COPY rsyslog.sh /rsyslog.sh
RUN chmod +x /rsyslog.sh

ENTRYPOINT ["/rsyslog.sh"]

EXPOSE 80 514 514/udp

CMD ["rsyslogd", "-n"]

# docker build -t rsyslog .
# docker run -d --restart unless-stopped -p 80:80 -p 514:514 -p 514:514/udp -v /docker/rsyslog:/var/log/rsyslog --name rsyslog rsyslog

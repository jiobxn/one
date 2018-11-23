FROM centos:latest
MAINTAINER "The CentOS Project" <admin@jiobxn.com>
ARG LATEST="0"

RUN yum clean all; yum -y update; yum -y install rsyslog net-tools ; yum clean all
RUN echo -e '#### \
	\n$ModLoad imudp \
	\n$UDPServerRun 514 \
	\n$ModLoad imtcp \
	\n$InputTCPServerRun 514 \
	\n$DirCreateMode 0755 \
	\n$FileCreateMode 0644 \
	\n$Umask 0022 \
	\n$template Remote,"/var/log/rsyslog/%fromhost-ip%/%fromhost-ip%_%$YEAR%-%$MONTH%-%$DAY%_%PROGRAMNAME%.log" \
	\n:fromhost-ip, !isequal, "127.0.0.1" ?Remote \
	\n& ~' >/etc/rsyslog.d/remote.conf

VOLUME /var/log/rsyslog

EXPOSE 514 514/udp

CMD ["rsyslogd", "-n"]

# docker build -t rsyslog .
# docker run -d --restart unless-stopped -p 514:514 -p 514:514/udp -v /docker/rsyslog:/var/log/rsyslog --name rsyslog rsyslog

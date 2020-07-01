FROM centos:latest
MAINTAINER "The CentOS Project" <admin@jiobxn.com>
ARG LATEST="0"

RUN yum clean all; yum -y update; yum -y install net-tools openssl bc vsftpd; yum clean all

VOLUME /home /key

COPY vsftpd.sh /vsftpd.sh
RUN chmod +x /vsftpd.sh

ENTRYPOINT ["/vsftpd.sh"]

EXPOSE 21 25000:25100

CMD ["/usr/sbin/init"]

# docker build -t vsftpd .
# docker run -d --restart unless-stopped -p 21:21 -v /docker:/home --name vsftp jiobxn/vsftpd
# cat /docker/ftp/ftp.log

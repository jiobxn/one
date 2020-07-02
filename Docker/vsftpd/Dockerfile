FROM centos:latest
MAINTAINER "The CentOS Project" <admin@jiobxn.com>
ARG LATEST="0"

RUN yum clean all; yum -y update; yum -y install net-tools openssl iptables bc vsftpd; yum clean all

VOLUME /home /key

COPY vsftpd.sh /vsftpd.sh
RUN chmod +x /vsftpd.sh

ENTRYPOINT ["/vsftpd.sh"]

EXPOSE 21 25000:25100

CMD ["/usr/sbin/init"]

# docker build -t vsftpd .
# docker run -d --restart unless-stopped --network host --cap-add NET_ADMIN -v /docker:/home -e IPTABLES=Y --name vsftp jiobxn/vsftpd
# docker logs vsftp

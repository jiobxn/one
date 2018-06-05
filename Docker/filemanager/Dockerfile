FROM centos:latest
MAINTAINER "The CentOS Project" <admin@jiobxn.com>
ARG LATEST="0"

RUN yum clean all; yum -y update; yum -y install openssl net-tools bash-completion vim wget cronie iptables; yum clean all

RUN cd /usr/local/src/ \
        && wget -c https://github.com$(curl -s https://github.com/filebrowser/filebrowser/releases |grep linux-amd64-filemanager.tar.gz |head -1 |awk -F\" '{print $2}') \
        && tar zxf linux-amd64-filemanager.tar.gz \
        && mv filemanager /usr/local/bin/ \
        && rm -rf /usr/local/src/*

VOLUME /key /srv

COPY filemanager.sh /filemanager.sh
RUN chmod +x /filemanager.sh

ENTRYPOINT ["/filemanager.sh"]

EXPOSE 80

CMD ["filemanager", "--config", "/key/config.json"]

# docker build -t filemanager .
# docker run -d --restart always -p 8080:80 --name filemanager filemanager
# docker logs filemanager

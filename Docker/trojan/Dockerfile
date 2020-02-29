FROM centos:latest
MAINTAINER "The Alpine Project" <admin@jiobxn.com>
ARG LATEST="0"

RUN yum clean all; yum -y update; yum -y install net-tools openssl wget; yum clean all

RUN cd /mnt \
    && wget -c https://github.com/$(curl -s https://github.com/trojan-gfw/trojan/releases |grep amd64.tar.xz |awk -F\" 'NR==1{print $2}') \
    && xz -d trojan-*.xz \
    && tar xf trojan-*.tar \
    && mv trojan/trojan /usr/local/bin/ \
    && rm -rf /mnt/* 

VOLUME /key

COPY trojan.sh /trojan.sh
RUN chmod +x /trojan.sh

EXPOSE 443

ENTRYPOINT ["/trojan.sh"]

CMD ["trojan", "/etc/config.json"]

# docker build -t trojan .
# docker run -d --restart unless-stopped -p 443:443 --name trojan trojan
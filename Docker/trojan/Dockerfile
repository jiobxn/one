FROM centos:latest
MAINTAINER "The Alpine Project" <admin@jiobxn.com>
ARG LATEST="0"

RUN yum clean all; yum -y update; yum -y install net-tools openssl wget unzip; yum clean all

RUN cd /mnt \
    && wget -c https://github.com/$(curl -s https://github.com/trojan-gfw/trojan/releases |grep linux-amd64.tar.xz |awk -F\" 'NR==1{print $2}') \
    && wget -c https://github.com/$(curl -s https://github.com/p4gefau1t/trojan-go/releases |grep linux-amd64.zip |awk -F\" 'NR==1{print $2}') \
    && xz -d trojan-*.xz \
    && tar xf trojan-*.tar \
    && unzip *linux-amd64.zip \
    && mv trojan-go /usr/local/bin/ \
    && mv trojan/trojan /usr/local/bin/ \
    && rm -rf /mnt/* 

VOLUME /key

COPY trojan.sh /trojan.sh
RUN chmod +x /trojan.sh

EXPOSE 443

WORKDIR /key

ENTRYPOINT ["/trojan.sh"]

CMD ["trojan", "/key/config.json"]

# docker build -t trojan .
# docker run -d --restart unless-stopped -p 443:443 --name trojan trojan

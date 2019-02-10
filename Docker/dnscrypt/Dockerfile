FROM centos:latest
MAINTAINER "The CentOS Project" <admin@jiobxn.com>
ARG LATEST="0"

RUN \cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
RUN yum clean all; yum -y update; yum -y install net-tools wget bind bind-utils; yum clean all

RUN cd /usr/local/src \
        && wget -c https://github.com/$(curl -s https://github.com/jedisct1/dnscrypt-proxy/releases |grep dnscrypt-proxy-linux_x86_64 |awk -F\" 'NR==1{print $2}')

RUN cd /usr/local/src \
        && tar zxf dnscrypt-proxy-*.tar.gz \
        && mv /usr/local/src/linux-x86_64 /usr/local/dnscrypt-proxy \
        && \cp /usr/local/dnscrypt-proxy/example-dnscrypt-proxy.toml /usr/local/dnscrypt-proxy/dnscrypt-proxy.toml \
        && ln -s /usr/local/dnscrypt-proxy/dnscrypt-proxy /usr/local/bin/ \
        && rm -rf /usr/local/src/*

COPY dnscrypt.sh /dnscrypt.sh
RUN chmod +x /dnscrypt.sh

ENTRYPOINT ["/dnscrypt.sh"]

EXPOSE 53/udp

CMD ["dnscrypt"]

# docker build -t dnscrypt .
# docker run -d --restart unless-stopped -p 53:53/udp --name dns dnscrypt

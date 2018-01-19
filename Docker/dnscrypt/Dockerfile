FROM centos:latest
MAINTAINER "The CentOS Project" <admin@jiobxn.com>
ARG LATEST="0"

RUN \cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
RUN yum clean all; yum -y update; yum -y install net-tools iproute bash-completion vim wget git file rng-tools ldns-devel make gcc autoconf bind bind-utils iptables cronie; yum clean all

RUN cd /usr/local/src \
        && wget -c $(curl -s http://libevent.org/ |grep stable.tar.gz |awk -F\" 'NR==1{print $4}') \
        && wget -c https://download.libsodium.org/libsodium/releases/LATEST.tar.gz -O libsodium.tar.gz \
        && git clone --recursive git://github.com/cofyc/dnscrypt-wrapper.git \
        && wget -c https://github.com/$(curl -s https://github.com/jedisct1/dnscrypt-proxy/releases |grep dnscrypt-proxy-linux_x86_64 |awk -F\" 'NR==1{print $2}') \
        && wget -c https://github.com/shadowsocks/ChinaDNS/releases/download/1.3.2/chinadns-1.3.2.tar.gz \
        && wget -c http://ftp.apnic.net/apnic/stats/apnic/delegated-apnic-latest -O /etc/delegated-apnic-latest

RUN cd /usr/local/src \
        && tar zxf libevent-*.tar.gz \
        && tar zxf libsodium.tar.gz \
        && tar zxf dnscrypt-proxy-*.tar.gz \
        && tar zxf chinadns-1.3.2.tar.gz \
        && \rm *.tar.gz \
        && cd /usr/local/src/libevent-* \
        && ./configure && make -j8 && make install \
        && cd /usr/local/src/libsodium-* \
        && ./configure && make -j8 && make install \
        && cd /usr/local/src/dnscrypt-wrapper \
        && make configure && ./configure && make install \
        && echo /usr/local/lib > /etc/ld.so.conf.d/usr_local_lib.conf && ldconfig \
        && mv /usr/local/src/linux-x86_64 /usr/local/dnscrypt-proxy \
        && ln -s /usr/local/dnscrypt-proxy/dnscrypt-proxy /usr/local/bin/ \
        && cd /usr/local/src/chinadns-1.3.2 \
        && ./configure && make && cp src/chinadns /usr/local/bin/chinadns \
        && rm -rf /usr/local/src/*

VOLUME /key

COPY dnscrypt.sh /dnscrypt.sh
RUN chmod +x /dnscrypt.sh

WORKDIR /key

ENTRYPOINT ["/dnscrypt.sh"]

EXPOSE 5443/udp 53/udp

CMD ["dnscrypt"]

# docker build -t dnscrypt .
# docker run -d --restart unless-stopped -p 53:53/udp --name dns dnscrypt
# docker run -it --rm dnscrypt --help

FROM centos:7
MAINTAINER "The CentOS Project" <admin@jiobxn.com>
ARG LATEST="0"

RUN yum clean all; yum -y update; yum -y install net-tools ipset wget bind bind-utils make gcc unzip; yum clean all

RUN cd /mnt \
        && wget -c https://github.com/$(curl -s https://github.com/DNSCrypt/dnscrypt-proxy/releases |grep dnscrypt-proxy-linux_x86_64 |awk -F\" 'NR==1{print $2}') \
        && wget -c https://github.com/jiobxn/one/raw/master/Docker/dnscrypt/chnroute.ipset -O /chnroute.ipset \
        && curl -4sSkL 'http://ftp.apnic.net/apnic/stats/apnic/delegated-apnic-latest' |egrep 'CN\|ipv4' |awk -F'|' '{printf("add chnroute %s/%d\n", $4, 32-log($5)/log(2))}' >>/chnroute.ipset \
        && wget -c https://github.com/zfl9/chinadns-ng/archive/master.zip \
        && unzip master.zip \
        && tar zxf dnscrypt-proxy-*.tar.gz \
        && mv /mnt/linux-x86_64 /dnscrypt-proxy \
        && \cp /dnscrypt-proxy/example-dnscrypt-proxy.toml /dnscrypt-proxy/dnscrypt-proxy.toml \
        && ln -s /dnscrypt-proxy/dnscrypt-proxy /usr/local/bin/ \
        && cd /mnt/chinadns-ng-master \
        && make -j8 && make install \
        && rm -rf /mnt/*

VOLUME /dnslog

COPY dnscrypt.sh /dnscrypt.sh
RUN chmod +x /dnscrypt.sh

ENTRYPOINT ["/dnscrypt.sh"]

EXPOSE 53/udp

CMD ["dnscrypt"]

# docker build -t dnscrypt .
# docker run -d --restart unless-stopped -p 53:53/udp --name dns dnscrypt

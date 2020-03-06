FROM alpine:latest
MAINTAINER "The Alpine Project" <admin@jiobxn.com>
ARG LATEST="0"

RUN apk update && apk add curl openssl iptables tzdata bash && rm -rf /var/cache/apk/*

RUN cd /mnt \
        && wget -c https://github.com/$(curl -s https://github.com/wangyu-/udp2raw-tunnel/releases |grep tar.gz |awk -F\" 'NR==1{print $2}') \
        && wget -c https://github.com/$(curl -s https://github.com/xtaci/kcptun/releases |grep kcptun-linux-amd64 |awk -F\" 'NR==2{print $2}') \
        && tar zxf kcptun-linux-amd64-*.tar.gz \
        && tar zxf udp2raw_binaries.tar.gz \
        && mv client_linux_amd64 /usr/local/bin/ \
        && mv server_linux_amd64 /usr/local/bin/ \
        && mv udp2raw_amd64 /usr/local/bin/ \
        && \rm *

COPY kcp2raw.sh /kcp2raw.sh
RUN chmod +x /kcp2raw.sh

EXPOSE 20000

ENTRYPOINT ["/kcp2raw.sh"]

CMD ["kcp2raw"]

# docker build -t kcp2raw .
# docker run -d --restart unless-stopped --cap-add=NET_ADMIN --network host -e SERVICE=127.0.0.1:80 --name kcp2raw kcp2raw
# docker logs kcp2raw

FROM alpine:latest
MAINTAINER "The Alpine Project" <admin@jiobxn.com>
ARG LATEST="0"

RUN apk update && apk add git python2 curl openssl libsodium tzdata bash && rm -rf /var/cache/apk/*

#Use pip to install: apk add py2-pip && pip install shadowsocks
RUN cd / \
        && git clone https://github.com/shadowsocks/shadowsocks.git -b master \
        && git clone https://github.com/shadowsocksr-backup/shadowsocksr.git -b manyuser

COPY ssserver.sh /ssserver.sh
RUN chmod +x /ssserver.sh

EXPOSE 8443

ENTRYPOINT ["/ssserver.sh"]

CMD ["shadowsocks"]

# docker build -t shadowsocks .
# docker run -d --restart always -p 8443:8443 --hostname shadowsocks --name shadowsocks shadowsocks

FROM alpine:latest
MAINTAINER "The Alpine Project" <admin@jiobxn.com>
ARG LATEST="0"

RUN apk update && apk add curl openssl tzdata bash && rm -rf /var/cache/apk/*

RUN cd /mnt \
        && wget -c https://github.com/$(curl -s https://github.com/txthinking/brook/releases |grep '/brook" rel' |awk -F\" 'NR==1{print $2}') \
        && wget -c https://github.com/$(curl -s https://github.com/v2ray/v2ray-core/releases |grep v2ray-linux-64.zip |awk -F\" 'NR==1{print $2}') \
        && mkdir v2ray \
        && unzip -d v2ray v2ray-linux-64.zip \
        && mv brook /usr/local/bin/ \
        && mv v2ray / \
        && chmod +x /usr/local/bin/brook \
        && ln -s /v2ray/v2ray /usr/local/bin/ \
        && rm -rf *

COPY v2ray-brook.sh /v2ray-brook.sh
RUN chmod +x /v2ray-brook.sh

EXPOSE 19443

ENTRYPOINT ["/v2ray-brook.sh"]

CMD ["v2ray-brook"]

# docker build -t v2ray-brook .
# docker run -d --restart always -p 19443:19443 --hostname v2ray-brook --name v2ray-brook v2ray-brook
# docker logs v2ray-brook

FROM alpine:latest
MAINTAINER "The Alpine Project" <admin@jiobxn.com>
ARG LATEST="0"

RUN apk update && apk add nginx openssl tzdata bash && rm -rf /var/cache/apk/*
RUN mkdir /run/nginx

VOLUME /key

COPY nginx.sh /nginx.sh
RUN chmod +x /nginx.sh

EXPOSE 80 443

ENTRYPOINT ["/nginx.sh"]

CMD ["nginx"]

# docker build -t registry-proxy .
# docker run -d --restart unless-stopped --network host -e NGX_USER=admin -e NGX_PASS=123456 -e REG_SERVER=127.0.0.1:5000 --name=registry-proxy registry-proxy
# docker logs registry-proxy

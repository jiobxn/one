FROM alpine:latest
MAINTAINER "The Alpine Project" <admin@jiobxn.com>
ARG LATEST="0"

RUN apk update && apk add iproute2 mtr curl bash && rm -rf /var/cache/apk/*
RUN curl -4sSkL 'http://ftp.apnic.net/apnic/stats/apnic/delegated-apnic-latest' |egrep 'CN\|ipv4' |awk -F'|' '{printf("%s/%d \n", $4, 32-log($5)/log(2))}' >/chnroute.txt

COPY chnroute.sh /chnroute.sh
RUN chmod +x /chnroute.sh

ENTRYPOINT ["/chnroute.sh"]

CMD ["crond", "-f"]

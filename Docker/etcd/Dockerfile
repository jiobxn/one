FROM alpine:latest
MAINTAINER "The Alpine Project" <admin@jiobxn.com>
ARG LATEST="0"

RUN apk update --no-cache && apk add curl openssl tzdata bash --no-cache

RUN cd /tmp \
        && wget -c $(curl -s https://github.com/etcd-io/etcd/releases |awk -F\" '$2~"linux-amd64.tar$"{print "https://github.com"$2}' |egrep -v 'rc|beta|alpha' |head -1) \
        && tar zxf etcd-*-linux-amd64.tar.gz \
        && mv etcd-*-linux-amd64/etcd* /usr/local/bin/ \
        && rm -rf /tmp/*

COPY etcd.sh /etcd.sh
RUN chmod +x /etcd.sh

VOLUME /etcd/data /key

ENTRYPOINT ["/etcd.sh"]

EXPOSE 2379 2380

CMD ["ETCD"]

# docker build -t etcd .
# docker run -d --restart unless-stopped --network host --name etcd etcd

FROM alpine:latest
MAINTAINER "The Alpine Project" <admin@jiobxn.com>
ARG LATEST="0"

RUN echo $(awk -F/ '{print $1"//"$3"/"$4"/edge/"$6}' /etc/apk/repositories) |tr -s ' ' '\n' >/etc/apk/repositories

RUN apk upgrade --no-cache --available && apk add -U wireguard-tools curl openssl tzdata bash --no-cache
RUN cd /tmp \
        && wget -c $(curl -s https://github.com/etcd-io/etcd/releases |awk -F\" '$2~"linux-amd64.tar.gz$"{print "https://github.com"$2}' |egrep -v 'rc|beta' |head -1) \
        && tar zxf etcd-*-linux-amd64.tar.gz \
        && mv etcd-*-linux-amd64/etcdctl /usr/local/bin/ \
        && rm -rf /tmp/*

COPY wireguard.sh /wireguard.sh
RUN chmod +x /wireguard.sh

ENTRYPOINT ["/wireguard.sh"]

EXPOSE 20000

CMD ["WG"]

# docker build -t wireguard .
# docker run -itd --privileged -p 20000:20000 --name wireguard wireguard

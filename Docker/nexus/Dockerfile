FROM alpine:latest
MAINTAINER "The Alpine Project" <admin@jiobxn.com>
ARG LATEST="0"

RUN apk update && apk add sudo openjdk8 tzdata && rm -rf /var/cache/apk/*
RUN adduser -D -h /sonatype-work -s /sbin/nologin nexus
 
RUN cd /mnt/ \
        && wget -c http://download.sonatype.com/nexus/3/latest-unix.tar.gz \
        && tar zxf latest-unix.tar.gz \
        && mv nexus-* /nexus \
        && rm -rf /mnt/*

VOLUME /sonatype-work

COPY nexus.sh /nexus.sh
RUN chmod +x /nexus.sh

WORKDIR /nexus

ENTRYPOINT ["/nexus.sh"]

EXPOSE 8081

CMD ["sudo", "-u", "nexus", "bin/nexus", "run"]

# docker build -t nexus .
# docker run -d --restart unless-stopped -p 8081:8081 -v /docker/nexus:/sonatype-work --name nexus nexus

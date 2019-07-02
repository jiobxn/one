FROM centos:latest
MAINTAINER "The CentOS Project" <admin@jiobxn.com>
ARG LATEST="0"

RUN yum clean all; yum -y update; yum -y install sudo net-tools wget java-1.8.0-openjdk; yum clean all

RUN useradd -r -d /usr/local/sonatype-work -s /sbin/nologin nexus \
        && cd /usr/local/src \
        && wget -c http://download.sonatype.com/nexus/3/latest-unix.tar.gz \
        && tar zxf latest-unix.tar.gz \
        && mv nexus-* /usr/local/nexus \
        && rm -rf /usr/local/src/*

VOLUME /usr/local/sonatype-work

COPY nexus.sh /nexus.sh
RUN chmod +x /nexus.sh

WORKDIR /usr/local/nexus

ENTRYPOINT ["/nexus.sh"]

EXPOSE 8081

CMD ["sudo", "-u", "nexus", "bin/nexus", "run"]

# docker build -t nexus .
# docker run -d --restart unless-stopped -p 8081:8081 -v /docker/nexus:/usr/local/sonatype-work --name nexus nexus

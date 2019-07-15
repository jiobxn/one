FROM centos:latest
MAINTAINER "The CentOS Project" <admin@jiobxn.com>
ARG LATEST="0"

RUN yum clean all; yum -y update; yum -y install java-1.8.0-openjdk-devel nmap-ncat net-tools wget cronie; yum clean all

RUN cd /mnt \
        && wget -c https://apache.org/dist/zookeeper/stable/$(curl -s https://apache.org/dist/zookeeper/stable/ |grep tar.gz |awk -F\" 'NR==1{print $6}') \
        && tar zxf apache-zookeeper-*.tar.gz \
        && \rm apache-zookeeper-*.tar.gz \
        && mv apache-zookeeper-* /zookeeper

VOLUME /zookeeper/data

COPY zookeeper.sh /zookeeper.sh
RUN chmod +x /zookeeper.sh

WORKDIR /zookeeper

ENTRYPOINT ["/zookeeper.sh"]

EXPOSE 2181 2888 3888

CMD ["bin/zkServer.sh", "start-foreground"]

# docker build -t zookeeper .
# docker run -d --restart unless-stopped -p 2181:2181 -v /docker/zookeeper:/zookeeper/data --name zookeeper zookeeper

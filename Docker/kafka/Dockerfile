FROM centos:latest
MAINTAINER "The CentOS Project" <admin@jiobxn.com>
ARG LATEST="0"

RUN yum clean all; yum -y update; yum -y install java-1.8.0-openjdk-devel nmap-ncat net-tools wget at; yum clean all

RUN cd /mnt \
        && kafka_v=$(curl -s https://apache.org/dist/kafka/ |grep folder |awk -F\" 'END{print $6}') \
        && kafka_f=$(curl -s https://apache.org/dist/kafka/$kafka_v |grep 'tgz</a>' |tail -1 |awk -F\" '{print $6}') \
        && wget -c https://apache.org/dist/kafka/$kafka_v/$kafka_f \
        && tar xf kafka_*.tgz \
        && \rm kafka_*.tgz \
        && mv kafka_* /kafka

VOLUME /kafka/data

COPY kafka.sh /kafka.sh
RUN chmod +x /kafka.sh

WORKDIR /kafka

ENTRYPOINT ["/kafka.sh"]

EXPOSE 9092

CMD ["bin/kafka-server-start.sh", "config/server.properties"]

# docker build -t kafka .
# docker run -d --restart unless-stopped --network=mynetwork --ip=10.0.0.100 -p 9092:9092 -v /docker/kafka:/kafka/data -e ZK_SERVER=10.0.0.70:2181 -e KK_TOPIC=test:1:1 --name kafka kafka

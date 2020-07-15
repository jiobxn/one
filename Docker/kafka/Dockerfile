FROM alpine:latest
MAINTAINER "The Alpine Project" <admin@jiobxn.com>
ARG LATEST="0"

RUN apk update --no-cache && apk add openjdk8 nmap-ncat at curl tzdata bash --no-cache

RUN cd /mnt \
        && kafka_v=$(curl -s https://downloads.apache.org/kafka/ |grep folder |awk -F\" 'END{print $6}') \
        && kafka_f=$(curl -s https://downloads.apache.org/kafka/$kafka_v |grep 'tgz</a>' |tail -1 |awk -F\" '{print $6}') \
        && wget -c https://downloads.apache.org/kafka/$kafka_v/$kafka_f \
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
# docker run -d --restart unless-stopped -p 9092:9092 -v /docker/kafka:/kafka/data -e ZK_SERVER=172.17.0.1:2181 -e KK_TOPIC=test:1:1 --name kafka kafka

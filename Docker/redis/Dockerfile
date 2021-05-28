FROM centos:latest
MAINTAINER "The CentOS Project" <admin@jiobxn.com>
ARG LATEST="0"

RUN yum clean all; yum -y update; yum -y install net-tools wget cronie make gcc; yum clean all

RUN cd /mnt \
        && wget -c $(curl -s https://redis.io/ |grep tar.gz |awk -F\' '{print $2}') \
        && tar zxf redis-*.tar.gz \
	&& \rm *.tar.gz \ 
        && cd /mnt/redis-* \
        && make -j8 PREFIX=/redis \
        && make PREFIX=/redis install \
        && cp *.conf /redis/ \
        && for i in $(find ./src/* -type f -perm -755);do \cp $i /redis/bin/;done \
        && ln -s /redis/bin/* /usr/local/bin/ \
        && rm -rf /mnt/*

VOLUME /redis/data

COPY redis.sh /redis.sh
RUN chmod +x /redis.sh

ENTRYPOINT ["/redis.sh"]

EXPOSE 6379 16379

CMD ["REDIS"]

# docker build -t redis .
# docker run -d --restart unless-stopped -v /docker/redis:/redis/data -p 6379:6379  -e REDIS_PASS=bigpass --name redis redis

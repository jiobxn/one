FROM centos:latest
MAINTAINER "The CentOS Project" <admin@jiobxn.com>
ARG LATEST="0"

RUN yum clean all; yum -y update; yum -y install net-tools wget cronie make gcc-c++ autoconf zlib-devel openssl-devel bison; yum clean all

RUN cd /mnt \
        && wget -c $(curl -s https://redis.io/ |grep tar.gz |awk -F\' '{print $2}') \
        && wget -c $(curl -s https://www.ruby-lang.org/zh_cn/downloads/ |grep tar.gz |awk -F\" 'NR==1{print $2}')

RUN cd /mnt \
        && tar zxf ruby-*.tar.gz \
        && tar zxf redis-*.tar.gz \
        && cd /mnt/ruby-* \
        && autoconf && ./configure --disable-install-rdoc \
        && make -j8 && make install \
        && gem install json_pure \
        && gem update --system \
        && gem install redis \
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

EXPOSE 6379

CMD ["redis-server", "/redis/redis.conf"]

# docker build -t redis .
# docker run -d --restart unless-stopped -v /docker/redis:/redis/data -p 16379:6379  -e REDIS_PASS=bigpass --name redis redis

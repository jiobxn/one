FROM centos:latest
MAINTAINER "The CentOS Project" <admin@jiobxn.com>
ARG LATEST="0"

RUN \cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
RUN yum clean all; yum -y update; yum -y install net-tools bash-completion vim wget make gcc-c++ iptables cronie autoconf zlib-devel openssl-devel bison; yum clean all

RUN cd /usr/local/src \
        && wget -c $(curl -s https://redis.io/ |grep tar.gz |awk -F\' '{print $2}') \
        && wget -c $(curl -s https://www.ruby-lang.org/zh_cn/downloads/ |grep tar.gz |awk -F\" 'NR==1{print $2}')

RUN cd /usr/local/src \
        && tar zxf ruby-*.tar.gz \
        && tar zxf redis-*.tar.gz \
        && cd /usr/local/src/ruby-* \
        && autoconf && ./configure --disable-install-rdoc \
        && make -j8 && make install \
        && gem install json_pure \
        && gem update --system \
        && gem install redis \
        && cd /usr/local/src/redis-* \
        && make -j8 PREFIX=/usr/local/redis \
        && make PREFIX=/usr/local/redis install \
        && cp *.conf /usr/local/redis/ \
        && for i in $(find ./src/* -perm -755);do \cp $i /usr/local/redis/bin/;done \
        && ln -s /usr/local/redis/bin/* /usr/local/bin/ \
        && rm -rf /usr/local/src/*

VOLUME /usr/local/redis/data

COPY redis.sh /redis.sh
RUN chmod +x /redis.sh

ENTRYPOINT ["/redis.sh"]

EXPOSE 6379

CMD ["redis-server", "/usr/local/redis/redis.conf"]

# docker build -t redis .
# docker run -d --restart always -v /docker/redis:/usr/local/redis/data -p 16379:6379  -e REDIS_PASS=bigpass --hostname redis --name redis redis
# docker run -it --rm redis --help

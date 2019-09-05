FROM centos:latest
MAINTAINER "The CentOS Project" <admin@jiobxn.com>
ARG LATEST="0"

RUN yum -y install epel-release && yum clean all && yum -y update && yum -y install net-tools iproute wget openssl pwgen at cronie && yum clean all

RUN mongo_v=$(curl -s https://www.mongodb.com/download-center/community |awk -F' selected>' '{print $2}' |awk '{print $1}' |grep -v ^$) \
        && wget -c https://fastdl.mongodb.org/linux/mongodb-linux-x86_64-rhel70-${mongo_v}.tgz \
        && wget -c https://raw.githubusercontent.com/jiobxn/one/master/Docker/mongodb/mongod.conf -O /etc/mongod.conf \
        && tar zxf mongodb-linux-x86_64-rhel70-${mongo_v}.tgz \
        && \cp -a mongodb-linux-x86_64-rhel70-${mongo_v}/bin/* /usr/local/bin/ \
        && rm -rf mongodb-linux-x86_64-rhel70-*

VOLUME /mongo/data /mongo/log

COPY mongodb.sh /mongodb.sh
COPY backup.sh /backup.sh
RUN chmod +x /*.sh

ENTRYPOINT ["/mongodb.sh"]

EXPOSE 27017

CMD ["MONGOD"]

# docker build -t mongodb .
# docker run -d --restart unless-stopped -p 27017:27017 -v /docker/mongodb:/mongo/data -e MONGO_ROOT_PASS=newpass --name mongodb mongodb

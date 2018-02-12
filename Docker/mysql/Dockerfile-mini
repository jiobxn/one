FROM centos:latest
MAINTAINER "The CentOS Project" <admin@jiobxn.com>
ARG LATEST="0"
ARG mysql_v="5.7"

RUN \cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
RUN yum clean all; yum -y update; yum -y install net-tools bash-completion vim wget cronie at openssl iptables; yum clean all

RUN mysql_V=$(curl -s https://dev.mysql.com/downloads/mysql/$mysql_v.html#downloads |grep "<h1>" |awk '{print $4}') \
        && mysql_rpm=$(curl -s https://repo.mysql.com/yum/mysql-$mysql_v-community/docker/x86_64/ |grep server-minimal |grep $mysql_V |awk -F\" '{print $6}') \
        && yum install -y https://repo.mysql.com/yum/mysql-${mysql_v}-community/docker/x86_64/$mysql_rpm \
        && yum clean all

RUN mkdir /docker-entrypoint-initdb.d

VOLUME /var/lib/mysql

COPY mysql-mini.sh /mysql.sh
COPY backup.sh /backup.sh
RUN chmod +x /*.sh

ENTRYPOINT ["/mysql.sh"]

EXPOSE 3306

CMD ["mysqld"]

# docker build --build-arg mysql_v=5.7 -t mysql-mini:5.7 .
# docker run -d --restart always -p 3306:3306 -v /docker/mysql-mini:/var/lib/mysql -e MYSQL_ROOT_PASSWORD=newpass -e MYSQL_DATABASE=zabbix -e MYSQL_USER=zabbix -e MYSQL_PASSWORD=newpass -e MYSQL_BACK=Y --hostname mysql --name mysql mysql-mini:5.7
# docker logs mysql |grep "PASSWORD"
# docker run -it --rm mysql-mini --help

FROM centos:8
MAINTAINER "The CentOS Project" <admin@jiobxn.com>
ARG LATEST="0"

RUN yum clean all && yum -y update \
        && zabbix_v=$(curl -s https://repo.zabbix.com/zabbix/ |awk -F\" '$1=="<a href="{print $2}' |tail -1) \
        && zabbix_f=$(curl -s https://repo.zabbix.com/zabbix/$zabbix_v/rhel/8/x86_64/ |awk -F\" '{print $2}' |grep zabbix-release |tail -1) \
        && rpm -ivh https://repo.zabbix.com/zabbix/$zabbix_v/rhel/8/x86_64/$zabbix_f \
        && mysql_v=$(curl -s https://repo.mysql.com/yum/ |awk -F- '$2~"^[0-9]"{print $2}' |tail -1) \
        && mysql_V=$(curl -s https://dev.mysql.com/downloads/mysql/$mysql_v.html#downloads |grep "<h1>" |awk '{print $4}') \
        && mysql_f=$(curl -s https://repo.mysql.com/yum/mysql-$mysql_v-community/docker/x86_64/ |grep server-minimal |grep $mysql_V |awk -F\" '{print $6}') \
        && yum install -y https://repo.mysql.com/yum/mysql-$mysql_v-community/docker/x86_64/$mysql_f \
        && rpm -ivh http://mirror.centos.org/centos/7/os/x86_64/Packages/libssh2-1.8.0-3.el7.x86_64.rpm \
        && yum -y install zabbix-server-mysql zabbix-web-mysql zabbix-agent zabbix-apache-conf zabbix-get langpacks-zh_CN net-tools wget \
        && yum clean all

RUN wget -c https://github.com/jiobxn/one/raw/master/Docker/zabbix/wqy-zenhei.ttc && \mv wqy-zenhei.ttc /usr/share/zabbix/assets/fonts/graphfont.ttf

VOLUME /var/lib/mysql

COPY zabbix.sh /zabbix.sh
RUN chmod +x /zabbix.sh

ENTRYPOINT ["/zabbix.sh"]

EXPOSE 80

CMD ["/usr/sbin/init"]

# docker build -t zabbix . 
# docker run -d --restart unless-stopped -v /docker/zabbix-db:/var/lib/mysql -p 9900:80 --name zabbix zabbix

FROM centos:latest
MAINTAINER "The CentOS Project" <admin@jiobxn.com>
ARG LATEST="0"

RUN rpm -ivh http://nginx.org/packages/centos/7/noarch/RPMS/nginx-release-centos-7-0.el7.ngx.noarch.rpm
RUN yum clean all; yum -y install epel-release; yum -y update; yum -y install nginx keepalived net-tools iproute iptables cronie; yum clean all

VOLUME /usr/share/nginx/html /key /var/log/nginx

COPY nginx-rpm.sh /nginx-rpm.sh
RUN chmod +x /nginx-rpm.sh

ENTRYPOINT ["/nginx-rpm.sh"]

EXPOSE 80 443

CMD ["nginx"]

# docker build -t nginx-rpm .
# docker run -d --restart unless-stopped -p 80:80 -p 443:443 -v /docker/www:/www -v /docker/nginx:/key -e DOMAIN_PROXY="fqhub.com%backend_https=y" -e PROXY_SERVER="jiobxn.com,www.jiobxn.com|jiobxn.wordpress.com%backend_https=y,alias=/down|/www" --name wordpress-nginx jiobxn/nginx-rpm
# docker run -it --rm nginx-rpm --help

FROM centos:latest
MAINTAINER "The CentOS Project" <admin@jiobxn.com>
ARG LATEST="0"

RUN \cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
RUN yum -y install epel-release; yum -y update; yum -y install pptpd radiusclient-ng iptables wget net-tools; yum clean all
RUN wget -c https://github.com/jiobxn/one/raw/master/Docker/pptpd/dictionary.microsoft -O /usr/share/radiusclient-ng/dictionary.microsoft

VOLUME /key

COPY pptpd.sh /pptpd.sh
RUN chmod +x /pptpd.sh

ENTRYPOINT ["/pptpd.sh"]

EXPOSE 1723

CMD ["pptpd", "-f"]

# docker build -t pptpd .
# docker run -d --restart unless-stopped --privileged --network host -e VPN_PASS=123456 --name pptpd pptpd
# docker logs pptpd

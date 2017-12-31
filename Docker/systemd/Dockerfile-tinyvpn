FROM centos:latest
MAINTAINER "The CentOS Project" <admin@jiobxn.com>
ARG LATEST="0"

RUN yum clean all; yum -y update; yum -y install openssl net-tools bash-completion vim wget cronie iptables; yum clean all

RUN cd /usr/local/src/ \
        && wget -c https://github.com$(curl -s https://github.com/wangyu-/tinyFecVPN/releases |grep tinyvpn_binaries.tar.gz |head -1 |awk -F\" '{print $2}') \
        && tar zxf tinyvpn_binaries.tar.gz \
        && mv tinyvpn_amd64 /usr/local/bin/ \
        && rm -rf /usr/local/src/*

COPY tinyvpn.sh /tinyvpn.sh
RUN chmod +x /tinyvpn.sh

ENTRYPOINT ["/tinyvpn.sh"]

EXPOSE 8000/udp

CMD ["tinyvpn"]

# docker build -t tinyvpn .
# docker run -d --restart always --privileged -p 8000:8000/udp --name tinyvpn tinyvpn
# docker logs tinyvpn

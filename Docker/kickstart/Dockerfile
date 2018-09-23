FROM centos:latest
MAINTAINER "The CentOS Project" <admin@jiobxn.com>
ARG LATEST="0"

RUN \cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
RUN yum clean all; yum -y update; yum -y install httpd tftp-server dhcp syslinux xinetd net-tools iproute bash-completion vim wget iptables cronie; yum clean all

RUN mkdir -p /var/www/html/{os,ks} \
        && mkdir -p /var/lib/tftpboot/pxelinux.cfg \
        && \cp /usr/share/syslinux/pxelinux.0 /var/lib/tftpboot/ \
        && wget -c http://mirror.centos.org/centos/7/os/x86_64/isolinux/initrd.img -O /var/lib/tftpboot/initrd.img \
        && wget -c http://mirror.centos.org/centos/7/os/x86_64/isolinux/vmlinuz -O /var/lib/tftpboot/vmlinuz \
        && wget -c http://mirror.centos.org/centos/7/os/x86_64/isolinux/vesamenu.c32 -O /var/lib/tftpboot/vesamenu.c32

RUN sed -i '14s/= yes/= no/' /etc/xinetd.d/tftp \
        && \rm /etc/dhcp/dhcpd.conf

VOLUME /var/www/html/os

COPY kickstart.sh /kickstart.sh
RUN chmod +x /kickstart.sh

ENTRYPOINT ["/kickstart.sh"]

EXPOSE 80 67/udp 69/udp

CMD ["/usr/sbin/init"]

# docker build -t kickstart .
# docker run -d --restart always --network host -v /docker/ks:/key -v /docker/os:/var/www/html/os -e RANGE="192.168.80.200 192.168.80.210" -e BOOT=INSTALL --name kickstart kickstart
# vim /docker/ks/ks.cfg  #配置磁盘分区
# docker cp /docker/ks/ks.cfg kickstart:/var/www/html/ks/ks.cfg

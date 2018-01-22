FROM centos:latest
MAINTAINER "The CentOS Project" <admin@jiobxn.com>
ARG LATEST="0"
ENV container docker

RUN \cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
RUN yum clean all; yum -y install epel-release; yum -y update
RUN yum -y install cockpit bash-completion vim wget python34-setuptools aria2 openssh-server openssh-clients initscripts iptables-services bind-utils net-tools cronie at; yum clean all
RUN easy_install-3.4 pip; pip install --upgrade youtube-dl you-get
RUN (cd /lib/systemd/system/sysinit.target.wants/; for i in *; do [ $i == \
systemd-tmpfiles-setup.service ] || rm -f $i; done); \
rm -f /lib/systemd/system/multi-user.target.wants/*;\
rm -f /etc/systemd/system/*.wants/*;\
rm -f /lib/systemd/system/local-fs.target.wants/*; \
rm -f /lib/systemd/system/sockets.target.wants/*udev*; \
rm -f /lib/systemd/system/sockets.target.wants/*initctl*; \
rm -f /lib/systemd/system/basic.target.wants/*;\
rm -f /lib/systemd/system/anaconda.target.wants/*;

RUN systemctl enable cockpit.socket
RUN echo -e '#!/bin/bash\n: ${PASS:=$(pwmake 128)}\n\nif [ ! -f /init.ok ]; then \n  echo "root:$PASS" | chpasswd\n  echo -e "root password: $PASS"\n  touch /init.ok\nfi\n\nexec "$@"' >/init.sh
RUN chmod +x /init.sh

VOLUME [ "/sys/fs/cgroup" ]
ENTRYPOINT ["/init.sh"]
CMD ["/usr/sbin/init"]

# docker build -t cockpit .
# docker run -d --restart always --privileged -p 9090:9090 -v /sys/fs/cgroup:/sys/fs/cgroup:ro --name webshell cockpit

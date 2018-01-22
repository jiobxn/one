FROM centos:latest
MAINTAINER "The CentOS Project" <admin@jiobxn.com>
ENV container docker
RUN yum clean all; yum -y install epel-release; yum -y update
RUN yum groups install -y gnome-desktop; yum -y install tigervnc-server expect python34-setuptools aria2; yum clean all
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

COPY gnome.sh /gnome.sh
RUN chmod +x /gnome.sh

VOLUME [ "/sys/fs/cgroup" ]
ENTRYPOINT ["/gnome.sh"]
CMD ["/usr/sbin/init"]

# docker build -t gnome .
# docker run -d --restart always --privileged --network host -v /sys/fs/cgroup:/sys/fs/cgroup:ro --name gnome gnome

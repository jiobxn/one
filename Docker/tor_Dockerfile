FROM centos:7
MAINTAINER "The CentOS Project" <admin@jiobxn.com>
ARG LATEST="0"

RUN yum -y install epel-release; yum -y update; yum -y install net-tools tor; yum clean all
RUN echo -e '#!/bin/bash\nif [ "$1" == "/usr/bin/tor" ];then\n: ${PORT:=80}\n: ${WEB:=127.0.0.1:8080}\n[ -z "$(grep ^HiddenServiceDir /etc/tor/torrc)" ] && echo -e "HiddenServiceDir /var/lib/tor/hidden_service/\\nHiddenServicePort $PORT $WEB" >>/etc/tor/torrc\necho "Start ****"\nexec "$@"\nelse\necho "docker run -d --restart unless-stopped -v /docker/tor:/var/lib/tor -e PORT=80 -e WEB=127.0.0.1:8080 --name tor jiobxn/tor"\nfi' >/tor.sh
RUN chmod +x /tor.sh

VOLUME /var/lib/tor

ENTRYPOINT ["/tor.sh"]

EXPOSE 80

CMD ["/usr/bin/tor", "--runasdaemon", "0", "--defaults-torrc", "/usr/share/tor/defaults-torrc", "-f", "/etc/tor/torrc"]

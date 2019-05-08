#!/bin/bash
set -e

: ${UDP_PORT:="514"}
: ${TCP_PORT:="514"}
: ${HTTP_PORT:=80}


if [ "$1" = 'rsyslogd' ]; then

if [ -z "$(grep "redhat.xyz" /etc/rsyslog.d/remote.conf)" ]; then
	\cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime

	cat >>/etc/rsyslog.d/remote.conf <<-END
	#redhat.xyz	
	\$ModLoad imudp
	\$UDPServerRun $UDP_PORT
	\$ModLoad imtcp
	\$InputTCPServerRun $TCP_PORT
	\$DirCreateMode 0755
	\$FileCreateMode 0644
	\$Umask 0022
	\$template Remote,"/var/log/rsyslog/%fromhost-ip%/%fromhost-ip%_%\$YEAR%-%\$MONTH%-%\$DAY%_%PROGRAMNAME%.log"
	:fromhost-ip, !isequal, "127.0.0.1" ?Remote
	& ~
	END

	sed -i 's/Listen 80/Listen '$HTTP_PORT'/;/Listen/a ServerName localhost:'$HTTP_PORT'' /etc/httpd/conf/httpd.conf
	sed -i '/^IndexOptions/a IndexOptions FancyIndexing NameWidth=*' /etc/httpd/conf.d/autoindex.conf
fi

	echo "Start ****"
	httpd
	exec $@
else
	echo -e "
	Example:
				docker run -d --restart unless-stopped \\
				-v /docker/rsyslog:/var/log/rsyslog \\
				-p 80:80 \\
				-p 514:514 \\
				-p 514:514/udp \\
				-e HTTP_PORT=[80] \\
				-e UDP_PORT=[514] \\
				-e TCP_PORT=[514] \\
				--name rsyslog rsyslog
	"
fi

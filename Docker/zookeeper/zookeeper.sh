#!/bin/bash
set -e

: ${ZK_MEM:="1G"}
: ${ZK_APORT:="8080"}
: ${ZK_CPORT:="2181"}
: ${ZK_SPORT:="2888"}

if [ "$1" = 'bin/zkServer.sh' ]; then
  if [ -z "$(grep "redhat.xyz" /zookeeper/conf/zoo.cfg 2>/dev/null)" ]; then
	echo "Initialize zookeeper"
	\cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
	cp /zookeeper/conf/zoo_sample.cfg /zookeeper/conf/zoo.cfg
	sed -i '1 i #redhat.xyz' /zookeeper/conf/zoo.cfg
	sed -i 's#/tmp/zookeeper#/zookeeper/data#' /zookeeper/conf/zoo.cfg
	sed -i 's/#maxClientCnxns=60/maxClientCnxns=0/' /zookeeper/conf/zoo.cfg
	sed -i 's/syncLimit=5/syncLimit=2/' /zookeeper/conf/zoo.cfg
	echo "admin.serverPort=$ZK_APORT" >>/zookeeper/conf/zoo.cfg
	sed -i "s/2181/$ZK_CPORT/" /zookeeper/conf/zoo.cfg
	echo "export JVMFLAGS=\"-Xms$ZK_MEM -Xmx$ZK_MEM \$JVMFLAGS\"" >/zookeeper/conf/java.env 

	#Clustered
	if [ "$ZK_SERVER" ]; then
		n=0
		for i in $(echo $ZK_SERVER |sed 's/,/\n/g'); do
			[ $(echo $ZK_SERVER |sed 's/,/\n/g' |wc -l) -lt 3 ] && echo "nodes is greater than or equal to 3" && exit 1
			n=$[$n+1]
			echo "server.$n=$i:$ZK_SPORT:$[$ZK_SPORT+1000]" >>/zookeeper/conf/zoo.cfg
			[ -n "$(ifconfig |grep $i)" ] && echo $n >/zookeeper/data/myid
		done
		echo "echo stat | nc 127.0.0.1 $ZK_CPORT |awk '\$1==\"Mode:\"{print \$2}'" >/usr/local/bin/zoo
		chmod +x /usr/local/bin/zoo
	fi
	
	#VIP
	if [ "$VIP" ]; then
		cat >/vip.sh<<-END
		#!/bin/bash
		for i in {1..29}; do
		if [ -n "\$(netstat -tpnl |grep ":$ZK_SPORT ")" ]; then
		    if [ -z "\$(ifconfig |grep $VIP)" ]; then
		        ifconfig lo:0 $VIP broadcast $VIP netmask 255.255.255.255 up || echo
		    fi
		    sleep 2
		else
		    if [ -n "\$(ifconfig |grep $VIP)" ]; then
		        ifconfig lo:0 del $VIP || echo
		    fi
		    sleep 2
		fi
		done
		END
		chmod +x /vip.sh
		echo "* * * * * . /etc/profile;/bin/sh /vip.sh &>/dev/null" >>/var/spool/cron/root
	fi
  fi

	echo "Start ZooKeeper ****"
	crond
	exec "$@" 1>/dev/null

else

    echo -e "
    Example:
				docker run -d --restart unless-stopped [--privileged] \\
				-v /docker/zookeeper:/zookeeper/data \\
				-p 2181:2181 \\
				-e ZK_MEM=[1G] \\
				-e ZK_APORT=[8080] \\
				-e ZK_CPORT=[2181] \\
				-e ZK_SPORT=[2888] \\
				-e ZK_SERVER=<"10.0.0.71,10.0.0.72,10.0.0.73"> \\
				-e VIP=<10.0.0.70> \\
				--name zookeeper zookeeper
	"
fi

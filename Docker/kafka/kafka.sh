#!/bin/bash
set -e

if [ "$1" = 'bin/kafka-server-start.sh' ]; then
  if [ -z "$(grep "redhat.xyz" /usr/local/kafka/config/server.properties)" ]; then
	echo "Initialize kafka"
	sed -i '1 i #redhat.xyz' /usr/local/kafka/config/server.properties
	sed -i 's#log.dirs=/tmp#log.dirs=/var/lib#' /usr/local/kafka/config/server.properties

	#zookeeper server
	if [ $ZK_SERVER ]; then
		sed -i 's/zookeeper.connect=localhost:2181/zookeeper.connect='$ZK_SERVER'/' /usr/local/kafka/config/server.properties
	else
		echo "Need to specify one or more zookeeper"
		exit 1
	fi

	#local ip address
	if [ $KK_SERVER ]; then
		echo "advertised.host.name=$KK_SERVER" >>/usr/local/kafka/config/server.properties
	else
		DEV=$(route -n |awk '$1=="0.0.0.0"{print $NF }')
		echo -e "\nadvertised.host.name=$(ifconfig $DEV |awk '$3=="netmask"{print $2}')" >>/usr/local/kafka/config/server.properties
	fi

	#broker id
	if [ $KK_ID ]; then
		sed -i 's/broker.id=0/broker.id='$KK_ID'/' /usr/local/kafka/config/server.properties
	fi
	
	#Mem
	if [ $KK_MEM ]; then
		sed -i 's/-Xmx1G -Xms1G/-Xmx'$KK_MEM' -Xms'$KK_MEM'/' /usr/local/kafka/bin/kafka-server-start.sh
	fi

	#network threads
	if [ $KK_NET ]; then
		sed -i 's/network.threads=3/network.threads='$KK_NET'/' /usr/local/kafka/config/server.properties
	fi

	#io threads
	if [ $KK_IO ]; then
		sed -i 's/io.threads=8/io.threads='$KK_IO'/' /usr/local/kafka/config/server.properties
	fi

	#log time
	if [ $KK_LOG_TIME ]; then
		sed -i 's/hours=168/hours='$KK_LOG_TIME'/' /usr/local/kafka/config/server.properties
	fi
	
	#consumer rebalance time
	if [ $KK_REBA_TIME ]; then
		sed -i 's/delay.ms=0/delay.ms=3000/' /usr/local/kafka/config/server.properties
	fi

	#create topic
	if [ $KK_TOPIC ]; then
		for i in $(echo $KK_TOPIC |sed 's/,/\n/g'); do
			TOPIC=$(echo $i |awk -F: '{print $1}')
			REFA=$(echo $i |awk -F: '{print $2}')
			PART=$(echo $i |awk -F: '{print $3}')
			[ -z $REFA ] && REFA=1
			[ -z $PART ] && PART=1

			echo "create topic: $TOPIC  $REFA  $PART"
			echo "/usr/local/kafka/bin/kafka-topics.sh --create --zookeeper $(echo $ZK_SERVER |awk -F, '{print $1}') --replication-factor $REFA --partitions $PART --topic $TOPIC" >>/topic.sh
		done

		sleep 2
		atd
		echo "sh /topic.sh" |at now +1 minutes
		echo "/usr/local/kafka/bin/kafka-topics.sh --list --zookeeper $(echo $ZK_SERVER |awk -F, '{print $1}') >/var/lib/kafka-logs/topic_info" >>/topic.sh
	fi

	#iptables, Need root authority "--privileged"
	if [ $IPTABLES ]; then
		cat > /iptables.sh <<-END
		iptables -I INPUT -p tcp --dport 9092 -j DROP
		iptables -I INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT
		iptables -I INPUT -s 127.0.0.1 -j ACCEPT
		iptables -I INPUT -s $IPTABLES -p tcp -m state --state NEW -m tcp --dport 9092 -m comment --comment KAFKA -j ACCEPT
		END
	fi

  fi

	echo "Start Kafka ****"
	[ -f /iptables.sh ] && [ -z "`iptables -S |grep KAFKA`" ] && . /iptables.sh
	exec "$@" 1>/dev/null

else

    echo -e "
    Example:
				docker run -d --restart always [--privileged] \\
				-v /docker/kafka:/var/lib/kafka-logs \\
				-p 9092:9092 \\
				-e KK_MEM=[1G] \\
				-e KK_NET=[3] \\
				-e KK_IO=[8] \\
				-e KK_LOG_TIME=[168]
				-e KK_REBA_TIME=[0] \\
				-e KK_SERVER=[ethX ip]
				-e KK_ID=[0] \\
				-e KK_TOPIC=<test:1:1> \\
				-e ZK_SERVER=<"10.0.0.71:2181"> \\
				-e IPTABLES=<"192.168.10.0/24,10.0.0.0/24"> \\
				--hostname kafka \\
				--name kafka kafka
	"
fi

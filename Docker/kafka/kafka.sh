#!/bin/bash
set -e

: ${KK_PORT:="9092"}

if [ "$1" = 'bin/kafka-server-start.sh' ]; then
  if [ -z "$(grep "redhat.xyz" /kafka/config/server.properties)" ]; then
	echo "Initialize kafka"
	\cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
	sed -i '1 i #redhat.xyz' /kafka/config/server.properties
	sed -i 's#log.dirs=/tmp/kafka-logs#log.dirs=/kafka/data#' /kafka/config/server.properties

	#zookeeper server
	if [ "$ZK_SERVER" ]; then
		sed -i 's/zookeeper.connect=localhost:2181/zookeeper.connect='$ZK_SERVER'/' /kafka/config/server.properties
	else
		echo "Need to specify one or more zookeeper"
		exit 1
	fi

	#listen address
	if [ "$KK_LISTEN" ]; then
		echo -e "\nlisteners=PLAINTEXT://$KK_LISTEN:$KK_PORT" >>/kafka/config/server.properties
	else
		DEV=$(route -n |awk '$1=="0.0.0.0"{print $NF}')
		echo -e "\nlisteners=PLAINTEXT://$(ifconfig $DEV |awk '$3=="netmask"{print $2}'):$KK_PORT" >>/kafka/config/server.properties
	fi

	#consumers to hostname
	if [ "$KK_SERVER" ]; then
		echo -e "\nadvertised.listeners=PLAINTEXT://$KK_SERVER:$KK_PORT" >>/kafka/config/server.properties
	fi

	#broker id
	if [ "$KK_ID" ]; then
		sed -i 's/broker.id=0/broker.id='$KK_ID'/' /kafka/config/server.properties
	fi
	
	#Mem
	if [ "$KK_MEM" ]; then
		sed -i 's/-Xmx1G -Xms1G/-Xmx'$KK_MEM' -Xms'$KK_MEM'/' /kafka/bin/kafka-server-start.sh
	fi

	#network threads
	if [ "$KK_NET" ]; then
		sed -i 's/network.threads=3/network.threads='$KK_NET'/' /kafka/config/server.properties
	fi

	#io threads
	if [ "$KK_IO" ]; then
		sed -i 's/io.threads=8/io.threads='$KK_IO'/' /kafka/config/server.properties
	fi

	#log time
	if [ "$KK_LOG_TIME" ]; then
		sed -i 's/hours=168/hours='$KK_LOG_TIME'/' /kafka/config/server.properties
	fi
	
	#consumer rebalance time
	if [ "$KK_REBA_TIME" ]; then
		sed -i 's/delay.ms=0/delay.ms=3000/' /kafka/config/server.properties
	fi

	#create topic
	if [ "$KK_TOPIC" ]; then
		for i in $(echo $KK_TOPIC |sed 's/,/\n/g'); do
			TOPIC=$(echo $i |awk -F: '{print $1}')
			REFA=$(echo $i |awk -F: '{print $2}')
			PART=$(echo $i |awk -F: '{print $3}')
			[ -z $REFA ] && REFA=1
			[ -z $PART ] && PART=1

			echo "create topic: $TOPIC  $REFA  $PART"
			echo "/kafka/bin/kafka-topics.sh --create --zookeeper $(echo $ZK_SERVER |awk -F, '{print $1}') --replication-factor $REFA --partitions $PART --topic $TOPIC" >>/topic.sh
		done

		sleep 2
		atd
		echo "sh /topic.sh" |at now +1 minutes
		echo "/kafka/bin/kafka-topics.sh --list --zookeeper $(echo $ZK_SERVER |awk -F, '{print $1}') >/kafka/data/topic_info" >>/topic.sh
	fi
  fi

	echo "Start Kafka ****"
	exec "$@" 1>/dev/null

else

    echo -e "
    Example:
				docker run -d --restart unless-stopped \\
				-v /docker/kafka:/kafka/data \\
				-p 9092:9092 \\
				-e KK_MEM=[1G] \\
				-e KK_NET=[3] \\
				-e KK_IO=[8] \\
				-e KK_LOG_TIME=[168]
				-e KK_REBA_TIME=[0] \\
				-e KK_LISTEN=[eth ip] \\
				-e KK_PORT=[9092] \\
				-e KK_SERVER=<kafka.redhat.xyz> \\
				-e KK_ID=[0] \\
				-e KK_TOPIC=<test:1:1> \\
				-e ZK_SERVER=<"10.0.0.71:2181"> \\
				--name kafka kafka
	"
fi

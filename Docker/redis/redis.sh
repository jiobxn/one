#!/bin/bash
set -e

if [ "$1" = 'REDIS' ]; then

: ${REDIS_PORT:="6379"}
: ${SLAVE_QUORUM:="2"}
: ${NODE_TIMEOUT:="5000"}
: ${MAX_CLIENTS:="10000"}

  if [ ! -f /usr/local/bin/REDIS ]; then
	echo "Initialize redis"
	#bind
	sed -i 's/^bind 127.0.0.1/bind 0.0.0.0/' /redis/redis.conf
	
	#port
	sed -i 's/^port 6379/port '$REDIS_PORT'/' /redis/redis.conf

	#maxclients
	sed -i 's/# maxclients 10000/maxclients '$MAX_CLIENTS'/' /redis/redis.conf

	#Ignore errors
	sed -i 's/stop-writes-on-bgsave-error yes/stop-writes-on-bgsave-error no/' /redis/redis.conf

	#persistence
	if [ "$LOCAL_STROGE" ]; then
		sed -i 's@dir \./@dir /redis/data@' /redis/redis.conf
		sed -i 's@appendonly no@appendonly yes@' /redis/redis.conf
	fi

	#user auth
	if [ "$REDIS_PASS" ]; then
		echo "requirepass $REDIS_PASS" >>/redis/redis.conf
		echo "Redis password: $REDIS_PASS" |tee /redis/data/info
		AUTH="-a $REDIS_PASS"
	fi

	echo "redis-server /redis/redis.conf" >/usr/local/bin/REDIS
	chmod +x /usr/local/bin/REDIS

	#redis cluster
	if [ "$REDIS_CLUSTER" ]; then
		sed -i 's/# cluster-enabled yes/cluster-enabled yes/' /redis/redis.conf
		sed -i 's/# cluster-config-file nodes-6379.conf/cluster-config-file nodes.conf/' /redis/redis.conf
		sed -i 's/# cluster-node-timeout 15000/cluster-node-timeout '$NODE_TIMEOUT'/' /redis/redis.conf
		sed -i 's/# cluster-require-full-coverage yes/cluster-require-full-coverage no/' /redis/redis.conf
		sed -i 's/^appendonly no/appendonly yes/' /redis/redis.conf
	fi

	#redis master
	if [ "$REDIS_MASTER" ]; then
		if [ -z "$(ip route |grep -wo $REDIS_MASTER)" ]; then
			echo "replicaof $REDIS_MASTER $REDIS_PORT" >>/redis/redis.conf
		fi
		
		sed -i 's/port 26379/port '$[$REDIS_PORT+10000]'/' /redis/sentinel.conf
		sed -i 's/mymaster 127.0.0.1/mymaster '$REDIS_MASTER'/' /redis/sentinel.conf
		echo "sentinel down-after-milliseconds mymaster $NODE_TIMEOUT" >>/redis/sentinel.conf
		sed -i 's/daemonize no/daemonize yes/' /redis/redis.conf
		echo -e "/redis/bin/redis-server /redis/redis.conf\n/redis/bin/redis-sentinel /redis/sentinel.conf" >/usr/local/bin/REDIS
	fi

	#master pass
	if [ "$MASTER_PASS" ]; then
		echo "masterauth $MASTER_PASS" >>/redis/redis.conf
		echo "sentinel auth-pass mymaster $MASTER_PASS" >>/redis/sentinel.conf
		
		if [ -z "$(grep "^requirepass" /redis/redis.conf)" ]; then
			echo "requirepass $MASTER_PASS" >>/redis/redis.conf
			echo "Redis password: $MASTER_PASS" |tee /redis/data/info
			AUTH="-a $MASTER_PASS"
		fi
	fi

	#VIP, Need root authority "--privileged"
	if [ "$VIP" ]; then
		#vip
		cat >/vip.sh<<-END
		#!/bin/bash
		PASS="$AUTH"
		for i in {1..29}; do
		if [ -n "\$(echo "info Replication" |/redis/bin/redis-cli \$PASS |grep "role:" |awk -F: '{print \$2}' |egrep -o master)" ]; then
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

	echo
	echo "Start Redis ****"
	crond
	exec "$@" 1>/dev/null

else
	echo -e "
	Example
					docker run -d --restart unless-stopped [--cap-add NET_ADMIN] \\
					-v /docker/redis:/redis/data \\
					-p 6379:6379 \\
					-p 16379:16379 \\
					-e REDIS_PORT=[6379] \\
					-e REDIS_PASS=<bigpass> \\
					-e LOCAL_STROGE=<Y> \\
					-e REDIS_MASTER=<10.0.0.91> \\
					-e MASTER_PASS=<bigpass> \\
					-e VIP=<10.0.0.90> \\
					-e SLAVE_QUORUM=[2] \\
					-e NODE_TIMEOUT=[5000] \\
					-e MAX_CLIENTS=[10000] \\
					-e REDIS_CLUSTER=<Y> \\
					--name redis redis
	"
fi

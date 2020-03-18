#!/bin/bash
set -e

if [ "$1" = 'redis-server' ]; then

: ${REDIS_PORT:="6379"}
: ${MASTER_NAME:="mymaster"}
: ${SLAVE_QUORUM:="2"}
: ${DOWN_TIME:="6000"}

  if [ -z "$(grep "redhat.xyz" /redis/redis.conf)" ]; then
	echo "Initialize redis"
	sed -i '1 i #redhat.xyz' /redis/redis.conf

	#bind
	sed -i 's/^bind 127.0.0.1/bind 0.0.0.0/' /redis/redis.conf
	
	#port
	sed -i 's/^port 6379/port '$REDIS_PORT'/' /redis/redis.conf

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

	#redis master
	if [ "$REDIS_MASTER" ]; then
		echo "slaveof $REDIS_MASTER $REDIS_PORT" >>/redis/redis.conf
		
		#sentinel
		cat >/sentinel.txt<<-END
		port $[$REDIS_PORT+10000]
		dir /tmp
		protected-mode no
		sentinel monitor $MASTER_NAME $REDIS_MASTER $REDIS_PORT $SLAVE_QUORUM
		sentinel down-after-milliseconds $MASTER_NAME $DOWN_TIME
		sentinel parallel-syncs $MASTER_NAME 1
		sentinel failover-timeout $MASTER_NAME 180000
		#daemonize yes
		END
	fi

	#master pass
	if [ "$MASTER_PASS" ]; then
		echo "masterauth $MASTER_PASS" >>/redis/redis.conf
		echo "sentinel auth-pass $MASTER_NAME $MASTER_PASS" >>/sentinel.txt
		
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

		if [ "$REDIS_MASTER" ]; then
			\cp /sentinel.txt /redis/sentinel.conf
			echo -e "/redis/bin/redis-server /redis/redis.conf\n/redis/bin/redis-server /redis/sentinel.conf --sentinel" >/sentinel.sh
			sed -i 's/daemonize no/daemonize yes/' /redis/redis.conf
		fi
	fi
  fi

	echo
	echo "Start Redis ****"
	crond
	[ -f /sentinel.sh ] && . /sentinel.sh
	exec "$@" 1>/dev/null

else
	echo -e "
	Example
					docker run -d --restart unless-stopped [--privileged] \\
					-v /docker/redis:/redis/data \\
					-p 16379:6379 \\
					-e REDIS_PORT=[6379] \\
					-e REDIS_PASS=<bigpass> \\
					-e LOCAL_STROGE=<Y> \\
					-e REDIS_MASTER=<10.0.0.91> \\
					-e MASTER_PASS=<bigpass> \\
					-e VIP=<10.0.0.90> \\
					-e MASTER_NAME=[mymaster] \\
					-e SLAVE_QUORUM=[2] \\
					-e DOWN_TIME=[6000] \\
					--name redis redis
	"
fi

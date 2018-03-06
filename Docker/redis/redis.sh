#!/bin/bash
set -e

if [ "$1" = 'redis-server' ]; then

: ${REDIS_PORT:="6379"}
: ${MASTER_NAME:="mymaster"}
: ${SLAVE_QUORUM:="2"}
: ${DOWN_TIME:="6000"}

  if [ -z "$(grep "redhat.xyz" /usr/local/redis/redis.conf)" ]; then
	echo "Initialize redis"
	sed -i '1 i #redhat.xyz' /usr/local/redis/redis.conf

	#bind
	sed -i 's/^bind 127.0.0.1/bind 0.0.0.0/' /usr/local/redis/redis.conf
	
	#port
	sed -i 's/^port 6379/port '$REDIS_PORT'/' /usr/local/redis/redis.conf

	#persistence
	if [ $LOCAL_STROGE ]; then
		sed -i 's@dir \./@dir /usr/local/redis/data@' /usr/local/redis/redis.conf
		sed -i 's@appendonly no@appendonly yes@' /usr/local/redis/redis.conf
	fi

	#user auth
	if [ $REDIS_PASS ]; then
		echo "requirepass $REDIS_PASS" >>/usr/local/redis/redis.conf
		echo "Redis password: $REDIS_PASS" |tee /usr/local/redis/data/info
		AUTH="-a $REDIS_PASS"
	fi

	#redis master
	if [ $REDIS_MASTER ]; then
		echo "slaveof $REDIS_MASTER 6379" >>/usr/local/redis/redis.conf
		
		#sentinel
		cat >/sentinel.txt<<-END
		port 26379
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
	if [ $MASTER_PASS ]; then
		echo "masterauth $MASTER_PASS" >>/usr/local/redis/redis.conf
		echo "sentinel auth-pass $MASTER_NAME $MASTER_PASS" >>/sentinel.txt
		
		if [ -z "$(grep "^requirepass" /usr/local/redis/redis.conf)" ]; then
			echo "requirepass $MASTER_PASS" >>/usr/local/redis/redis.conf
			echo "Redis password: $MASTER_PASS" |tee /usr/local/redis/data/info
			AUTH="-a $MASTER_PASS"
		fi
	fi

	#VIP, Need root authority "--privileged"
	if [ $VIP ]; then
		#vip
		cat >/vip.sh<<-END
		#!/bin/bash
		PASS="$AUTH"

		for i in {1..29}; do
		if [ -n "\$(echo "info Replication" |/usr/local/bin/redis-cli \$PASS |grep "role:" |awk -F: '{print \$2}' |egrep -o master)" ]; then
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

		if [ $REDIS_MASTER ]; then
			\cp /sentinel.txt /usr/local/redis/sentinel.conf
			echo -e "/usr/local/redis/bin/redis-server /usr/local/redis/redis.conf\n/usr/local/redis/bin/redis-server /usr/local/redis/sentinel.conf --sentinel" >/sentinel.sh
			sed -i 's/daemonize no/daemonize yes/' /usr/local/redis/redis.conf
		fi
	fi

	#iptables, Need root authority "--privileged"
	if [ $IPTABLES ]; then
		cat > /iptables.sh <<-END
		iptables -I INPUT -p tcp -m multiport --dport $REDIS_PORT,26379 -j DROP
		iptables -I INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT
		iptables -I INPUT -s $IPTABLES -p tcp -m state --state NEW -m tcp --dport $REDIS_PORT -m comment --comment REDIS -j ACCEPT
		iptables -I INPUT -s $IPTABLES -p tcp -m state --state NEW -m tcp --dport 26379 -m comment --comment REDIS -j ACCEPT
		END
	fi
  fi

	echo
	echo "Start Redis ****"
	crond
	[ -f /iptables.sh ] && [ -z "`iptables -S |grep REDIS`" ] && . /iptables.sh
	[ -f /sentinel.sh ] && . /sentinel.sh

	exec "$@" 1>/dev/null

else
	echo -e "
	Example
					docker run -d --restart always [--privileged] \\
					-v /docker/redis:/usr/local/redis/data \\
					-p 6379:6379 \\
					-e REDIS_PORT=[6379] \\
					-e REDIS_PASS=<bigpass> \\
					-e LOCAL_STROGE=<Y> \\
					-e REDIS_MASTER=<10.0.0.91> \\
					-e MASTER_PASS=<bigpass> \\
					-e VIP=<10.0.0.90> \\
					-e MASTER_NAME=[mymaster] \\
					-e SLAVE_QUORUM=[2] \\
					-e DOWN_TIME=[6000] \\
					-e IPTABLES=<"192.168.10.0/24,10.0.0.0/24"> \\
					--hostname redis \\
					--name redis redis
	"
fi

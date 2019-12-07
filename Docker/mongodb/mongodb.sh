#!/bin/bash
set -e

: ${MONGO_PORT:="27017"}

if [ "$1" = 'MONGOD' ]; then

##USER
mongo_user() {
	#Create root
	if [ "$MONGO_ROOT_PASS" ]; then
		cat >/admin.json<<-END
		use admin
		db.createUser({user: "root",pwd: "$MONGO_ROOT_PASS",roles: ["root"]})
		END

		echo "/usr/local/bin/mongo < /admin.json --quiet" >> /init.sh
		echo "MongoDB ROOT PASSWORD: $MONGO_ROOT_PASS" |tee /mongo/data/root_info
		AUTH="-u root -p $MONGO_ROOT_PASS --authenticationDatabase admin"
		sed -i "s/PASS=/PASS=\"$AUTH\"/" /backup.sh
	fi

	#Create a database and database user
	if [ -n "$MONGO_USER" -a -n "$MONGO_PASS" ]; then
		[ -z "$MONGO_DB" ] && MONGO_DB=$MONGO_USER
		
		cat >/user.json<<-END
		use $MONGO_DB
		db.createUser({user: "$MONGO_USER",pwd: "$MONGO_PASS",roles: [ { role: "dbOwner", db: "$MONGO_DB" } ]})
		END

		echo "/usr/local/bin/mongo $AUTH < /user.json --quiet" >> /init.sh
		echo "MongoDB USER AND PASSWORD: $MONGO_USER  $MONGO_PASS" |tee /mongo/data/user_info
	fi
}


##Clustered
mongo_gluster() {
	if [ "$VIP" ]; then
		cat >/vip.sh<<-END
		#!/bin/sh
		for i in {1..29}; do
		if [ "\$(echo 'rs.status()' |/usr/local/bin/mongo |grep -A 3 '"name" : "'\$(cat /mongo/data/myid)'"' |awk -F\" '\$2=="stateStr"{print \$4}')" == "PRIMARY" ]; then
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
		\cp /vip.sh /mongo/data/vip.sh
	fi
	
	
	
	if [ "$MONGO_SERVER" ]; then
		for i in $(echo "$MONGO_SERVER" |sed 's/,/\n/g'); do
			if [ -n "$(ifconfig |grep "$(echo $i |awk -F: '{print $1}')")" ]; then
				cat >/replset.json<<-END
				rs.initiate( {
					_id : "$REPL_NAME",
					$OPTION
					members: [ { _id : 0, host : "$i" } ]
				})
				END
				echo "$REPL_NAME" >/mongo/data/repl_info
			fi
		done

		for i in $(echo "$MONGO_SERVER" |sed 's/,/\n/g'); do
			[ -z "$(ifconfig |grep "$(echo $i |awk -F: '{print $1}')")" ] && echo 'echo "rs.add(\"'$i'\")" |/usr/local/bin/mongo --quiet' >> /rsadd.txt
		done
		chmod +r /rsadd.txt
	fi
}


##Start Configuration
	if [ -d "/mongo/data/diagnostic.data" -a ! -f /usr/local/bin/MONGOD ]; then
		echo "/mongo/data/diagnostic.data already exists, skip"
		\cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
		sed -i 's/127.0.0.1/0.0.0.0/' /etc/mongod.conf
		sed -i 's/fork: true/#fork: true/' /etc/mongod.conf

		[ -f "/mongo/data/repl_info" ] && REPL_NAME=$(cat /mongo/data/repl_info)
		[ "$REPL_NAME" ] && sed -i 's/#replication:/replication:/;/replication:/ a \  replSetName: '$REPL_NAME'' /etc/mongod.conf
		[ "$CLUSTER" == "CONFIG" ] && sed -i 's/#sharding:/sharding:/;/sharding:/ a \  clusterRole: configsvr' /etc/mongod.conf
		[ "$CLUSTER" == "SHARD" ] && sed -i 's/#sharding:/sharding:/;/sharding:/ a \  clusterRole: shardsvr' /etc/mongod.conf
		[ -f "/mongo/data/myid" ] && MONGO_PORT=$(cat /mongo/data/myid |awk -F: '{print $2}')
		[ "$MONGO_PORT" ] && sed -i "s/27017/$MONGO_PORT/" /etc/mongod.conf
		\cp /mongo/data/.MONGOD /usr/local/bin/ && chmod +x /usr/local/bin/MONGOD

		[ -f "/mongo/data/vip.sh" ] && \cp /mongo/data/vip.sh /vip.sh && echo "* * * * * . /etc/profile;/bin/sh /vip.sh &>/dev/null" >>/var/spool/cron/root
		
	elif [ ! -f /usr/local/bin/MONGOD ]; then
		echo "Initializing MongoDB"
		\cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
		if [ "$REPL_NAME" ]; then
			sed -i 's/#replication:/replication:/;/replication:/ a \  replSetName: '$REPL_NAME'' /etc/mongod.conf
			[ "$CLUSTER" == "CONFIG" ] && sed -i 's/#sharding:/sharding:/;/sharding:/ a \  clusterRole: configsvr' /etc/mongod.conf && OPTION="configsvr: true,"
			[ "$CLUSTER" == "SHARD" ] && sed -i 's/#sharding:/sharding:/;/sharding:/ a \  clusterRole: shardsvr' /etc/mongod.conf
			
			sed -i 's/127.0.0.1/0.0.0.0/' /etc/mongod.conf
			sed -i "s/27017/$MONGO_PORT/" /etc/mongod.conf
			sed -i 's/fork: true/#fork: true/' /etc/mongod.conf
			echo "$(ip address |grep -A2 ": $(ip route |awk '$1=="default"{print $5}')" |awk '$1=="inet"{print $2}' |awk -F/ '{print $1}'):$MONGO_PORT" >/mongo/data/myid

			mongo_gluster
			[ -f /replset.json ] && echo "/usr/local/bin/mongo < /replset.json --quiet" >>/init.sh && echo "sleep 5" >>/init.sh
			[ -f /rsadd.txt ] && cat /rsadd.txt >>/init.sh
			[ "$ARB_SERVER" ] && echo "echo 'rs.addArb(\"'$ARB_SERVER'\")' | /usr/local/bin/mongo --quiet" >>/init.sh
			echo "mongod -f /etc/mongod.conf" >/usr/local/bin/MONGOD
		else
			if [ "$CLUSTER" == "ROUTER" ]; then
				sed -i 's/#sharding:/sharding:/;/sharding:/ a \  configDB: '$CONFIG_SERVER'' /etc/mongod.conf
				sed -i '/storage:/d;/dbPath:/d;/journal:/d;/enabled:/d' /etc/mongod.conf
				for i in $(echo "$SHARD_SERVER" |sed 's/;/\n/g'); do
					echo "echo 'sh.addShard(\"'$i'\")' | /usr/local/bin/mongo --quiet" >>/init.sh
				done
				echo "mongos -f /etc/mongod.conf" >/usr/local/bin/MONGOD
			else
				sed -i 's/#security:/security:/;/security:/ a \  authorization: enabled' /etc/mongod.conf
				mongo_user
				echo "mongod -f /etc/mongod.conf" >/usr/local/bin/MONGOD
			fi
			
			sed -i 's/127.0.0.1/0.0.0.0/' /etc/mongod.conf
			sed -i "s/27017/$MONGO_PORT/" /etc/mongod.conf
			sed -i 's/fork: true/#fork: true/' /etc/mongod.conf
		fi
		
		chmod +x /usr/local/bin/MONGOD && \cp /usr/local/bin/MONGOD /mongo/data/
		[ -f /init.sh ] && atd && echo "$(cat /init.sh)" |at now +1 minutes
		[ "$MONGO_BACK" ] && echo "0 3 * * * . /etc/profile;/bin/sh /backup.sh &>/dev/null" >>/var/spool/cron/root
	else
		echo
	fi


	echo "Start MongoDB ****"
	crond
	exec "$@"

else

    echo -e "
    Example:
				docker run -d --restart unless-stopped [--cap-add net_admin] \\
				-v /docker/mongodb:/mongo/data \\
				-v /docker/mongolog:/mongo/log \\
				-p 27017:27017 \\
				-e MONGO_PORT=[27017] \\
				-e MONGO_ROOT_PASS=<youpasswd> \\
				-e MONGO_USER=<user1> \\
				-e MONGO_PASS=<newpass> \\
				-e MONGO_DB=<user1> \\
				-e MONGO_BACK=<Y> \\
				-e REPL_NAME=<rs0> \\
				-e VIP=<10.0.0.80> \\
				-e MONGO_SERVER=<10.0.0.81:27017,10.0.0.82:27017>
				-e ARB_SERVER=<10.0.0.83:27017> \\
				-e CLUSTER=<CONFIG | SHARD | ROUTER> \\
				-e CONFIG_SERVER=<rsc0/10.0.0.81:27017,10.0.0.82:27017,10.0.0.83:27017> \\
				-e SHARD_SERVER=<rss0/10.0.0.84:27017,10.0.0.85:27017,10.0.0.86:27017> \\
				--name mongodb mongodb
	"
fi

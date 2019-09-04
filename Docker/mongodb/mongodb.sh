#!/bin/bash
set -e

: ${MONGO_PORT:="27017"}
: ${MONGO_ROOT_PASS:="$(pwgen 20 |awk '{print $NF}')"}

if [ "$1" = 'mongod' ]; then
##USER
mongo_user() {
	#Create root
	if [ "$MONGO_ROOT_PASS" ]; then
		cat >/admin.json<<-END
		use admin
		db.createUser({user: "root",pwd: "$MONGO_ROOT_PASS",roles: ["root"]})
		END

		echo "/usr/local/bin/mongo < /admin.json &>/dev/null" >> /init.sh
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

		echo "/usr/local/bin/mongo $AUTH < /user.json &>/dev/null" >> /init.sh
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
					members: [ { _id : 0, host : "$i" } ]
				})
				END
				echo "$REPL_NAME" >/mongo/data/repl_info
			fi
		done

		for i in $(echo "$MONGO_SERVER" |sed 's/,/\n/g'); do
			[ -z "$(ifconfig |grep "$(echo $i |awk -F: '{print $1}')")" ] && echo 'echo "rs.add(\"'$i'\")" |/usr/local/bin/mongo 1>/dev/null' >> /rsadd.txt
		done
		chmod +x /rsadd.txt
	fi
}


##Start Configuration
	if [ -d "/mongo/data/diagnostic.data" ]; then
		echo "/mongo/data/diagnostic.data already exists, skip"
		if [ -z "$(grep "redhat.xyz" /etc/mongod.conf)" ]; then
			echo "Initializing MongoDB"
			\cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
			sed -i '1 i #redhat.xyz' /etc/mongod.conf
			sed -i 's/127.0.0.1/0.0.0.0/' /etc/mongod.conf
			sed -i 's/fork: true/#fork: true/' /etc/mongod.conf

			[ -z "$REPL_NAME" ] && [ -f "/mongo/data/repl_info" ] && REPL_NAME=$(cat /mongo/data/repl_info)
			if [ "$REPL_NAME" ]; then
				sed -i 's/#replication:/replication:/' /etc/mongod.conf
				sed -i '/replication:/ a \  replSetName: '$REPL_NAME'' /etc/mongod.conf
				[ -f "/mongo/data/myid" ] && MONGO_PORT=$(cat /mongo/data/myid |awk -F: '{print $2}')
				[ -n "$MONGO_PORT" ] && sed -i "s/27017/$MONGO_PORT/" /etc/mongod.conf
			else
				sed -i "s/27017/$MONGO_PORT/" /etc/mongod.conf
			fi

			[ -f "/mongo/data/vip.sh" ] && \cp /mongo/data/vip.sh /vip.sh && echo "* * * * * . /etc/profile;/bin/sh /vip.sh &>/dev/null" >>/var/spool/cron/root
		fi
	else
		echo "Initializing MongoDB"
		\cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
		if [ "$REPL_NAME" ]; then
			sed -i '1 i #redhat.xyz' /etc/mongod.conf
			sed -i 's/#replication:/replication:/' /etc/mongod.conf
			sed -i '/replication:/ a \  replSetName: '$REPL_NAME'' /etc/mongod.conf
			sed -i 's/127.0.0.1/0.0.0.0/' /etc/mongod.conf
			sed -i "s/27017/$MONGO_PORT/" /etc/mongod.conf
			sed -i 's/fork: true/#fork: true/' /etc/mongod.conf
			echo "$(ip route |awk '$3=="'$(ip route |awk '$1=="default"{print $NF}')'" && $NR1~"src"{print $NF}'):$MONGO_PORT" >/mongo/data/myid

			mongo_gluster
			[ -f /replset.json ] && echo "/usr/local/bin/mongo < /replset.json 1>/dev/null" >>/init.sh && echo "sleep 5" >>/init.sh
			[ -f /rsadd.txt ] && cat /rsadd.txt >>/init.sh
		else
			sed -i '1 i #redhat.xyz' /etc/mongod.conf
			sed -i 's/#security:/security:/' /etc/mongod.conf
			sed -i '/security:/ a \  authorization: enabled' /etc/mongod.conf
			sed -i 's/127.0.0.1/0.0.0.0/' /etc/mongod.conf
			sed -i "s/27017/$MONGO_PORT/" /etc/mongod.conf
			sed -i 's/fork: true/#fork: true/' /etc/mongod.conf
			
			mongo_user
		fi

		[ -f /init.sh ] && chmod +x /init.sh && atd && echo "bash /init.sh" |at now +1 minutes
	fi


	#Backup Database
	if [ "$MONGO_BACK" ]; then
		echo "0 3 * * * . /etc/profile;/bin/sh /backup.sh &>/dev/null" >>/var/spool/cron/root
	fi


	echo "Start MongoDB ****"
	crond
	exec "$@" 1>/dev/null

else

    echo -e "
    Example:
				docker run -d --restart unless-stopped [--privileged] \\
				-v /docker/mongodb:/mongo/data \\
				-p 27017:27017 \\
				-e MONGO_PORT=[27017] \\
				-e MONGO_ROOT_PASS=[$(pwgen 20 |awk '{print $NF}')] \\
				-e MONGO_USER=<user1> \\
				-e MONGO_PASS=<newpass> \\
				-e MONGO_DB=<user1> \\
				-e MONGO_BACK=<Y> \\
				-e REPL_NAME=<rs0> \\
				-e VIP=<10.0.0.80> \\
				-e MONGO_SERVER=<10.0.0.81:27017,10.0.0.82:27017,10.0.0.83:27017>
				--name mongodb mongodb
	"
fi

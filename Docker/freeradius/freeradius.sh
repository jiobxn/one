#!/bin/bash
set -e

: ${MYSQL_PORT:="3306"}
: ${MYSQL_DB:="radius"}
: ${MYSQL_USER:="radius"}
: ${MYSQL_PASS:="radpass"}
: ${USER_PASS:="testing,password"}
: ${IPADDR_SECRET:="127.0.0.1,testing123"}


#MYSQL
MYSQL() {
	if [ $MYSQL_HOST ];then
		if [ "$(mysql -u$MYSQL_USER -p$MYSQL_PASS -h$MYSQL_HOST -P$MYSQL_PORT -e "use $MYSQL_DB; show tables;" |awk 'NR!=1' |wc -l)" -eq 0 ];then
			mysql -u$MYSQL_USER -p$MYSQL_PASS -h$MYSQL_HOST -P$MYSQL_PORT $MYSQL_DB </etc/raddb/mods-config/sql/main/mysql/schema.sql
		fi
		[ $? -eq 1 ] && echo "MySQL import failed .." && exit 1
		sed -i 's/driver = "rlm_sql_null"/driver = "rlm_sql_mysql"/' /etc/raddb/mods-available/sql
		sed -i 's/dialect = "sqlite"/dialect = "mysql"/' /etc/raddb/mods-available/sql
		sed -i '/dialect = "mysql"/a \        server = "127.0.0.1"' /etc/raddb/mods-available/sql
		sed -i '/dialect = "mysql"/a \        port = 3306' /etc/raddb/mods-available/sql
		sed -i '/dialect = "mysql"/a \        login = "radius"' /etc/raddb/mods-available/sql
		sed -i '/dialect = "mysql"/a \        password = "radpass"' /etc/raddb/mods-available/sql
		sed -i 's/radius_db = "radius"/radius_db = "radius"/' /etc/raddb/mods-available/sql
		ln -s /etc/raddb/mods-available/sql /etc/raddb/mods-enabled/
		chgrp -h radiusd /etc/raddb/mods-enabled/sql
	fi
}


#authentication
AUTHEN() {
	if [ $USER_PASS ];then
		if [ -n "$(echo $USER_PASS |grep ';')" ];then
			for i in $(echo $USER_PASS |sed 's/;/\n/g');do
				if [ -n "$(echo $i |grep ,)" ];then
					USER=$(echo $i |awk -F, '{print $1}')
					PASS=$(echo $i |awk -F, '{print $2}')
					echo "$USER $PASS" >>/key/user_pass.txt
				else
					PASS=$(openssl rand -hex 8)
					echo "$USER $PASS" >>/key/user_pass.txt
				fi
			done
		else
			if [ -n "$(echo $USER_PASS |grep ',')" ];then
				USER=$(echo $USER_PASS |awk -F, '{print $1}')
				PASS=$(echo $USER_PASS |awk -F, '{print $2}')
				echo "$USER $PASS" >>/key/user_pass.txt
			else
				PASS=$(openssl rand -hex 8)
				echo "$USER $PASS" >>/key/user_pass.txt
			fi
		fi
	fi
}


#authorization
AUTHOR() {
	if [ $IPADDR_SECRET ];then
		if [ -n "$(echo $IPADDR_SECRET |grep ';')" ];then
			for i in $(echo $IPADDR_SECRET |sed 's/;/\n/g');do
				if [ -n "$(echo $i |grep ,)" ];then
					IPADDR=$(echo $i |awk -F, '{print $1}')
					SECRET=$(echo $i |awk -F, '{print $2}')
					echo "$IPADDR $SECRET" >>/key/ipaddr_secret.txt
				else
					SECRET=$(openssl rand -hex 8)
					echo "$IPADDR $SECRET" >>/key/ipaddr_secret.txt
				fi
			done
		else
			if [ -n "$(echo $IPADDR_SECRET |grep ',')" ];then
				IPADDR=$(echo $IPADDR_SECRET |awk -F, '{print $1}')
				SECRET=$(echo $IPADDR_SECRET |awk -F, '{print $2}')
				echo "$IPADDR $SECRET" >>/key/ipaddr_secret.txt
			else
				SECRET=$(openssl rand -hex 8)
				echo "$IPADDR $SECRET" >>/key/ipaddr_secret.txt
			fi
		fi
	fi
}


#help
HELP() {
	echo -e "
	Example:
				docker run -d --restart unless-stopped --network host --cap-add=NET_ADMIN \\
				-v /docker/freeradius:/key \\
				-p 1812:1812/udp \\
				-p 1813:1813/udp \\
				-e USER_PASS=[testing,password] \\
				-e IPADDR_SECRET=[127.0.0.1,testing123] \\
				-e MYSQL_HOST=<MYSQL IP ADDRESS> \\
				-e MYSQL_PORT=[3306] \\
				-e MYSQL_DB=[radius] \\
				-e MYSQL_USER=[radius] \\
				-e MYSQL_PASS=[radpass] \\
				--name freeradius freeradius
				"
}


#init
if [ "$1" = 'radiusd' ]; then
	if [ -z "$(grep "redhat.xyz" /etc/raddb/clients.conf)" ]; then
		if [ ! -f /key/user_pass.txt ];then
			AUTHEN
		fi

		#authentication
		if [ $MYSQL_HOST ];then
			MYSQL

			N=$(grep -v ^# /key/user_pass.txt |grep -v ^$ |wc -l)
			i=1
			while [ $i -le $N ];do
				USER=$(grep -v ^# /key/user_pass.txt |grep -v ^$ |sed -n ''$i'p' |awk '{print $1}')
				PASS=$(grep -v ^# /key/user_pass.txt |grep -v ^$ |sed -n ''$i'p' |awk '{print $2}')
				if [ -z "$(mysql -u$MYSQL_USER -p$MYSQL_PASS -h$MYSQL_HOST -P$MYSQL_PORT -e "SELECT username FROM $MYSQL_DB.radcheck;" |awk 'NR!=1' |grep -w $USER)" ];then
					mysql -u$MYSQL_USER -p$MYSQL_PASS -h$MYSQL_HOST -P$MYSQL_PORT -e "INSERT INTO $MYSQL_DB.radcheck (username, attribute, op, value) VALUES ('$USER','Cleartext-Password',':=','$PASS');"
					echo "$USER $PASS"
				else
					echo "user '$USER' already exists"
				fi
				let  i++
			done
		else
			if [ ! -f /key/authorize ];then
				N=$(grep -v ^# /key/user_pass.txt |grep -v ^$ |wc -l)
				i=1
				while [ $i -le $N ];do
					USER=$(grep -v ^# /key/user_pass.txt |grep -v ^$ |sed -n ''$i'p' |awk '{print $1}')
					PASS=$(grep -v ^# /key/user_pass.txt |grep -v ^$ |sed -n ''$i'p' |awk '{print $2}')
					echo "$USER Cleartext-Password := \"$PASS\"" >>/etc/raddb/mods-config/files/authorize
					echo "$USER $PASS"
					let  i++
				done
				\cp /etc/raddb/mods-config/files/authorize /key/
			else
				echo "/key/authorize already exists"
				\cp /key/authorize /etc/raddb/mods-config/files/
			fi
		fi


		if [ ! -f /key/ipaddr_secret.txt ];then
			AUTHOR
		fi
		echo "#redhat.xyz" >/etc/raddb/clients.conf

		#authorization
		if [ ! -f /key/clients.conf ];then
			N=$(grep -v ^# /key/ipaddr_secret.txt |grep -v ^$ |wc -l)
			i=1
			n=1
			while [ $i -le $N ];do
				IPADDR=$(grep -v ^# /key/ipaddr_secret.txt |grep -v ^$ |sed -n ''$i'p' |awk '{print $1}')
				SECRET=$(grep -v ^# /key/ipaddr_secret.txt |grep -v ^$ |sed -n ''$i'p' |awk '{print $2}')
				echo -e "\nclient client_$n {\n    ipaddr = $IPADDR\n    secret = $SECRET\n    require_message_authenticator = no\n}" >>/etc/raddb/clients.conf
				echo "$IPADDR $SECRET"
				let  i++
				let  n++
			done
			\cp /etc/raddb/clients.conf /key/
		else
			echo "/key/clients.conf already exists"
			\cp /key/clients.conf /etc/raddb/
		fi
		
		#iptables
		if [ "$IPTABLES" == "Y" ]; then
			cat > /iptables.sh <<-END
			iptables -I INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT
			iptables -I INPUT -p udp -m state --state NEW -m udp --dport 1812:1813 -m comment --comment RADIUS -j ACCEPT
			END
		fi
	fi

	[ -f /iptables.sh ] && [ -z "`iptables -S |grep RADIUS`" ] && . /iptables.sh
	exec "$@"
else
	HELP
fi

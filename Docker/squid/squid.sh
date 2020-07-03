#!/bin/bash
set -e

if [ "$1" = 'squid' ]; then

: ${SQUID_PASS:="$(openssl rand -base64 10 |tr -dc [:alnum:])"}
: ${MAX_AUTH:="5"}
: ${HTTP_PORT="3128"}
: ${HTTPS_PORT="43128"}


if [ -z "$(grep "redhat.xyz" /etc/squid/squid.conf)" ]; then
	echo "Initialize Squid"
	sed -i '1 i #redhat.xyz' /etc/squid/squid.conf
	
	if [ -f /key/server.crt -a -f /key/server.key ]; then
		\cp /key/{server.crt,server.key} /etc/squid/
	else
		openssl genrsa -out /etc/squid/server.key 4096 2>/dev/null
		openssl req -new -key /etc/squid/server.key -out /etc/squid/server.csr -subj "/C=CN/ST=GuangDong/L=GuangZhou/O=JIOBXN Ltd/CN=Squid-docker" 2>/dev/null
		openssl x509 -req -days 3650 -in /etc/squid/server.csr -signkey /etc/squid/server.key -out /etc/squid/server.crt 2>/dev/null
	fi
	
	if [ "$SQUID_USER" ]; then
		cat >>/squid-auth.txt <<-END
		auth_param basic program /usr/lib64/squid/basic_ncsa_auth /etc/squid/passwd 
		auth_param basic children $MAX_AUTH 
		auth_param basic realm Squid proxy-caching web server 
		auth_param basic credentialsttl 2 hours 
		auth_param basic casesensitive off 
		acl authuser proxy_auth REQUIRED 
		http_access allow authuser
		END
	
		sed -i '/# Recommended minimum configuration:/ r /squid-auth.txt' /etc/squid/squid.conf
		echo "$SQUID_USER:$(openssl passwd -apr1 $SQUID_PASS)" > /etc/squid/passwd
		echo "Squid user AND password: $SQUID_USER  $SQUID_PASS"
	else
		sed -i '1 i http_access allow all' /etc/squid/squid.conf
	fi


	sed -i 's@http_port 3128@http_port '$HTTP_PORT'\nhttps_port '$HTTPS_PORT' cert=/etc/squid/server.crt key=/etc/squid/server.key@' /etc/squid/squid.conf


	if [ "$PROXY_SERVER" ]; then
		if [ -z "$(echo $PROXY_SERVER |egrep '\||;')" ]; then
			for i in $(echo $PROXY_SERVER |sed 's/,/\n/g'); do
				if [ -n "$(echo $i |grep ':')" ]; then
					sed -i '/http_port/ a cache_peer  '$(echo $i |cut -d: -f1)'  parent  '$(echo $i |cut -d: -f2)'  0  originserver' /etc/squid/squid.conf
				else
					sed -i '/http_port/ a cache_peer  '$i'  parent  80  0  originserver' /etc/squid/squid.conf
				fi
			done
			sed -i 's/http_port '$HTTP_PORT'/http_port '$HTTP_PORT' accel/' /etc/squid/squid.conf
			sed -i 's/https_port '$HTTPS_PORT'/https_port '$HTTPS_PORT' accel/' /etc/squid/squid.conf
		else
			n=0
			for i in $(echo "$PROXY_SERVER" |sed 's/;/\n/g'); do
				if [ -n "$(echo $i |grep '|')" ]; then
					n=$(($n+1))
					for x in $(echo $i |awk -F'|' '{print $1}' |sed 's/,/\n/g'); do
						sed -i '/http_port/ a cache_peer_domain  proxy'$n'  '$x'' /etc/squid/squid.conf
					done
				
					for x in $(echo $i |awk -F'|' '{print $2}' |sed 's/,/\n/g'); do
						if [ -n "$(echo $x |grep ':')" ]; then
							sed -i '/http_port/ a cache_peer  '$(echo $x |cut -d: -f1)'  parent  '$(echo $x |cut -d: -f2)'  0  originserver  name=proxy'$n'' /etc/squid/squid.conf
						else
							sed -i '/http_port/ a cache_peer  '$x'  parent  80  0  originserver  name=proxy'$n'' /etc/squid/squid.conf
						fi
					done
				fi
			done
			sed -i 's/http_port '$HTTP_PORT'/http_port '$HTTP_PORT' vhost/' /etc/squid/squid.conf
			sed -i 's/https_port '$HTTPS_PORT'/https_port '$HTTPS_PORT' vhost/' /etc/squid/squid.conf
		fi
	fi

	if [ $PROXY_HTTPS ]; then
		sed -i 's/originserver/originserver  ssl sslflags=DONT_VERIFY_PEER/g' /etc/squid/squid.conf
	fi
fi

	echo "Start ****"
	exec "$@"

esle
	echo -e "
	Example
			docker run -d --restart unless-stopped \\
			-p 8080:3128 \\
			-p 8443:43128 \\
			-e SQUID_USER=<jiobxn> \\
			-e SQUID_PASS=[RANDOM] \\
			-e MAX_AUTH=[5] \\
			-e PROXY_SERVER=<"10.0.0.2,10.0.0.3" | "www.example.com|10.0.0.4;test.example.com|10.0.0.5"> \\
			-e PROXY_HTTPS=<Y> \\
			--name squid squid
	"
fi

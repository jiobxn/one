#!/bin/bash
set -e

if [ "$1" = 'dnscrypt' ]; then

: ${VERSION:="windows 2003 DNS"}
: ${LISTEN_ADDR:="0.0.0.0"}
: ${LOG_SIZE:="100"}
: ${CACHE_SIZE:="256"}
: ${MAX_CLIENT:="250"}
: ${TRUSE_DNS:="127.0.0.1#55"}
: ${CHINA_DNS:="114.114.114.114,223.5.5.5"}


if [ ! -f /usr/local/bin/dnscrypt ]; then
	\cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
	#bind
	BIND() {
		sed -i '/recursion yes;/ a \\n\        \/* #jiobxn.com# *\/' /etc/named.conf
		sed -i '/#jiobxn.com#/ a \        version  "'"$VERSION"'";' /etc/named.conf
		[ "$LISTEN_ADDR" == "0.0.0.0" ] && LISTEN_ADDR="any"
		sed -i 's/127.0.0.1;/'$LISTEN_ADDR';/' /etc/named.conf
		sed -i '/listen-on-v6/d' /etc/named.conf
		[ "$LISTEN_PORT" ] && sed -i 's/53/'$LISTEN_PORT'/' /etc/named.conf
		sed -i 's/localhost;/any;/' /etc/named.conf
		[ "$BIND_DNS" ] && sed -i '/#jiobxn.com#/ a \\n\        forwarders   { '$BIND_DNS'; };' /etc/named.conf
		[ "$FORWARD_ONLY"  ] && sed -i '/#jiobxn.com#/ a \\n\        forward only;' /etc/named.conf
		sed -i '/#jiobxn.com#/ a \\n\        max-cache-size '$CACHE_SIZE'm;' /etc/named.conf
	
		if [ "$QUERY_LOG" ]; then
			sed -i '/logging {/ a \        channel query_log {\n\            file "/dnslog/query.log" versions 2 size '$LOG_SIZE'm;\n\            severity info;\n\            print-time yes;\n\            print-category   yes;\n\        };' /etc/named.conf
			sed -i '/logging {/ a \        category queries {\n\            query_log;\n\        };' /etc/named.conf
		fi
	
		echo "/usr/sbin/named -u named -c /etc/named.conf -f" >/usr/local/bin/dnscrypt
	}


	#dnscrypt
	DNSCRYPT() {
		sed -i "s/'127.0.0.1/'$LISTEN_ADDR/" /usr/local/dnscrypt-proxy/dnscrypt-proxy.toml
		sed -i "s/, '\[::1\]:53'//" /usr/local/dnscrypt-proxy/dnscrypt-proxy.toml
		[ "$LISTEN_PORT" ] && sed -i "s/:53']/:$LISTEN_PORT']/" /usr/local/dnscrypt-proxy/dnscrypt-proxy.toml
		sed -i 's/cache_size = 256/cache_size = '$CACHE_SIZE'/' /usr/local/dnscrypt-proxy/dnscrypt-proxy.toml
		sed -i 's/max_clients = 250/max_clients = '$MAX_CLIENT'/' /usr/local/dnscrypt-proxy/dnscrypt-proxy.toml
	
		if [ "$QUERY_LOG" ]; then
			sed -i "s@# file = 'query.log'@file = '/dnslog/query.log'@" /usr/local/dnscrypt-proxy/dnscrypt-proxy.toml
			sed -i 's/log_files_max_size = 10/log_files_max_size = '$LOG_SIZE'/' /usr/local/dnscrypt-proxy/dnscrypt-proxy.toml
		fi
	
		echo "dnscrypt-proxy" >/usr/local/bin/dnscrypt
	}


	#init
	if [ "$CHINADNS" ]; then
		[ -z "$LISTEN_PORT" ] && LISTEN_PORT=55
		DNSCRYPT
		echo "nohup dnscrypt-proxy &" >/usr/local/bin/dnscrypt
		echo "sleep 50" >>/usr/local/bin/dnscrypt
		echo "ipset -R < /chnroute.ipset" >>/usr/local/bin/dnscrypt
		echo "chinadns-ng -b $LISTEN_ADDR -l 53 -t $TRUSE_DNS -c $CHINA_DNS" >>/usr/local/bin/dnscrypt
	elif [ "$DNSCRYPT" ]; then
		DNSCRYPT
	else
		BIND
	fi
	
	chmod +x /usr/local/bin/dnscrypt
fi

	echo "Start ****"
	exec $@
else
	echo -e "
	Example:
				docker run -d --restart unless-stopped \\
				-p 53:53/udp \\
				-e VERSION=["windows 2003 DNS"] \\
				-e BIND_DNS=<8.8.8.8;9.9.9.9> \\
				-e FORWARD_ONLY=<Y> \\
				-e LISTEN_ADDR=[0.0.0.0] \\
				-e LISTEN_PORT=[53] \\
				-e MAX_CLIENT=[250] \\
				-e CACHE_SIZE=[256] \\
				-e QUERY_LOG=<Y> \\
				-e LOG_SIZE=[100] \\
				-e DNSCRYPT=<Y> \\
				-e CHINADNS=<Y> \\
				-e TRUSE_DNS=[127.0.0.1#55] \\
				-e CHINA_DNS=[114.114.114.114,223.5.5.5] \\
				--name dns dnscrypt
	"
fi

#!/bin/bash
set -e

if [ "$1" = 'dnscrypt' ]; then

: ${VERSION:="windows 2003 DNS"}
: ${LOG_SIZE:="100m"}
: ${LISTEN:="any;"}
: ${ALLOW_QUERY:="any;"}
: ${CACHE_SIZE:="100m"}


if [ ! -f /usr/bin/dnscrypt ]; then
	#bind
	init_bind() {
		sed -i '/recursion yes;/ a \\n\        \/* #jiobxn.com# *\/' /etc/named.conf
		sed -i '/#jiobxn.com#/ a \        version  "'"$VERSION"'";' /etc/named.conf
		sed -i 's/127.0.0.1;/'$LISTEN'/' /etc/named.conf
		sed -i 's/localhost;/'$ALLOW_QUERY'/' /etc/named.conf

		[ "$FORWARD" ] && sed -i '/#jiobxn.com#/ a \\n\        forwarders   { '$FORWARD' };' /etc/named.conf
		sed -i '/#jiobxn.com#/ a \\n\        max-cache-size '$CACHE_SIZE';' /etc/named.conf
		
		if [ "$QUERY_LOG" ]; then
			sed -i '/logging {/ a \        channel query_log {\n\            file "data/query.log" versions 3 size '$LOG_SIZE';\n\            severity info;\n\            print-time yes;\n\            print-category   yes;\n\        };' /etc/named.conf
			sed -i '/logging {/ a \        category queries {\n\            query_log;\n\        };' /etc/named.conf
		fi
		
		echo "/usr/sbin/named -u named -c /etc/named.conf -f" >/usr/bin/dnscrypt
	}


	#dnscrypt
	init_dnscrypt() {
		[ "$LISTEN" == "any;" ] && LISTEN="0.0.0.0:53"
		sed -i 's/127.0.0.1:53/'$(echo $LISTEN)'/' /usr/local/dnscrypt-proxy/dnscrypt-proxy.toml
		sed -i "s/, '\[::1\]:53'//" /usr/local/dnscrypt-proxy/dnscrypt-proxy.toml
		
		[ "$QUERY_LOG" ] && sed -i "s@# file = 'query.log'@file = '/var/named/data/query.log'@" /usr/local/dnscrypt-proxy/dnscrypt-proxy.toml
		sed -i "s/cache_size = 256/cache_size = $(echo $CACHE_SIZE |sed 's/[m|g]//')/" /usr/local/dnscrypt-proxy/dnscrypt-proxy.toml
		echo "dnscrypt-proxy" >/usr/bin/dnscrypt
	}


	#default
	if [ "$DNSCRYPT" ]; then
		init_dnscrypt
	else
		init_bind
	fi
	
	chmod +x /usr/bin/dnscrypt
fi

	echo "Start ****"
	exec $@
else
	echo -e "
	Example:
				docker run -d --restart unless-stopped \\
				-p 53:53/udp \\
				-e VERSION=["windows 2003 DNS"] \\
				-e LISTEN=["any;"] \\
				-e ALLOW_QUERY=["any;"] \\
				-e FORWARD=<9.9.9.9;> \\
				-e CACHE_SIZE=[100m] \\
				-e QUERY_LOG=<Y> \\
				-e LOG_SIZE=[100m] \\
				-e DNSCRYPT=<Y> \\
				--name dns dnscrypt
	"
fi

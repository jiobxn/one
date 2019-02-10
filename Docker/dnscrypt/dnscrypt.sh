#!/bin/bash
set -e

if [ "$1" = 'dnscrypt' ]; then

: ${VERSION:="windows 2003 DNS"}
: ${BIND_ADDR:="0.0.0.0"}
: ${BIND_PORT:="53"}
: ${LOG_SIZE:="100"}
: ${CACHE_SIZE:="256"}
: ${MAX_CLIENT:="250"}


if [ ! -f /usr/bin/dnscrypt ]; then
	#bind
	BIND() {
		sed -i '/recursion yes;/ a \\n\        \/* #jiobxn.com# *\/' /etc/named.conf
		sed -i '/#jiobxn.com#/ a \        version  "'"$VERSION"'";' /etc/named.conf
		[ "$BIND_ADDR" == "0.0.0.0" ] && BIND_ADDR="any"
		sed -i 's/127.0.0.1;/'$BIND_ADDR';/' /etc/named.conf
		sed -i '/listen-on-v6/d' /etc/named.conf
		sed -i 's/53/'$BIND_PORT'/' /etc/named.conf
		sed -i 's/localhost;/any;/' /etc/named.conf
		[ "$DNS" ] && sed -i '/#jiobxn.com#/ a \\n\        forwarders   { '$DNS' };' /etc/named.conf
		[ "$DNS_ONLY"  ] && sed -i '/#jiobxn.com#/ a \\n\        forward only;' /etc/named.conf
		sed -i '/#jiobxn.com#/ a \\n\        max-cache-size '$CACHE_SIZE'm;' /etc/named.conf
	
		if [ "$QUERY_LOG" ]; then
			sed -i '/logging {/ a \        channel query_log {\n\            file "data/query.log" versions 2 size '$LOG_SIZE'm;\n\            severity info;\n\            print-time yes;\n\            print-category   yes;\n\        };' /etc/named.conf
			sed -i '/logging {/ a \        category queries {\n\            query_log;\n\        };' /etc/named.conf
		fi
	
		echo "/usr/sbin/named -u named -c /etc/named.conf -f" >/usr/bin/dnscrypt
	}


	#dnscrypt
	DNSCRYPT() {
		sed -i "s/'127.0.0.1/'$BIND_ADDR/" /usr/local/dnscrypt-proxy/dnscrypt-proxy.toml
		sed -i "s/, '\[::1\]:53'//" /usr/local/dnscrypt-proxy/dnscrypt-proxy.toml
		sed -i "s/:53']/:$BIND_PORT']/" /usr/local/dnscrypt-proxy/dnscrypt-proxy.toml
		sed -i 's/cache_size = 256/cache_size = '$CACHE_SIZE'/' /usr/local/dnscrypt-proxy/dnscrypt-proxy.toml
		sed -i 's/max_clients = 250/max_clients = '$MAX_CLIENT'/' /usr/local/dnscrypt-proxy/dnscrypt-proxy.toml
	
		if [ "$QUERY_LOG" ]; then
			sed -i "s@# file = 'query.log'@file = '/var/named/data/query.log'@" /usr/local/dnscrypt-proxy/dnscrypt-proxy.toml
			sed -i 's/log_files_max_size = 10/log_files_max_size = '$LOG_SIZE'/' /usr/local/dnscrypt-proxy/dnscrypt-proxy.toml
		fi
	
		echo "dnscrypt-proxy" >/usr/bin/dnscrypt
	}


	#init
	if [ "$DNSCRYPT" ]; then
		DNSCRYPT
	else
		BIND
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
				-e DNS=<9.9.9.9;8.8.8.8;> \\
				-e DNS_ONLY=<Y> \\
				-e BIND_ADDR=[0.0.0.0] \\
				-e BIND_PORT=[53] \\
				-e MAX_CLIENT=[250] \\
				-e CACHE_SIZE=[256] \\
				-e QUERY_LOG=<Y> \\
				-e LOG_SIZE=[100] \\
				-e DNSCRYPT=<Y> \\
				--name dns dnscrypt
	"
fi

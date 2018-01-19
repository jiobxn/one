#!/bin/bash
set -e

if [ "$1" = 'dnscrypt' ]; then

: ${SERVER_LISTEN:="0.0.0.0:5443"}
: ${CLIENT_LISTEN:="0.0.0.0:53"}
: ${BIND_VERSION:="windows 2003 DNS"}
: ${BIND_LOG_SIZE:="100m"}
: ${BIND_LISTEN:="any;"}
: ${BIND_ALLOW_QUERY:="any;"}


if [ ! -f /usr/bin/dnscrypt ]; then
	#bind
	init_bind() {
		sed -i '/recursion yes;/ a \\n\        \/* #jiobxn.com# *\/' /etc/named.conf
		sed -i '/#jiobxn.com#/ a \        version  "'"$BIND_VERSION"'";' /etc/named.conf
		sed -i 's/127.0.0.1;/'$BIND_LISTEN'/' /etc/named.conf
		sed -i 's/localhost;/'$BIND_ALLOW_QUERY'/' /etc/named.conf

		[ $BIND_FORWARDERS ] && sed -i '/#jiobxn.com#/ a \\n\        forwarders   { '$BIND_FORWARDERS' };' /etc/named.conf
		[ $BIND_CACHE_SIZE ] && sed -i '/#jiobxn.com#/ a \\n\        max-cache-size '$BIND_CACHE_SIZE';' /etc/named.conf
		
		if [ $BIND_QUERY_LOG ]; then
			sed -i '/logging {/ a \        channel query_log {\n\            file "data/query.log" versions 3 size '$BIND_LOG_SIZE';\n\            severity info;\n\            print-time yes;\n\            print-category   yes;\n\        };' /etc/named.conf
			sed -i '/logging {/ a \        category queries {\n\            query_log;\n\        };' /etc/named.conf
		fi
	}

	#server
	if [ "$SERVER_UPSTREAM" -a "$SERVER_DOMAIN" ]; then
		cd /key/
		if [ ! -f /key/dnscrypt.key -a ! -f /key/dnscrypt.cert -a ! -f /key/public.key ]; then
			dnscrypt-wrapper --gen-provider-keypair &>/dev/null
			dnscrypt-wrapper --gen-crypt-keypair --crypt-secretkey-file=dnscrypt.key &>/dev/null
			dnscrypt-wrapper --gen-cert-file --crypt-secretkey-file=dnscrypt.key --provider-cert-file=dnscrypt.cert --provider-publickey-file=public.key --provider-secretkey-file=secret.key --cert-file-expire-days=999 &>/dev/null
		fi

		echo "$SERVER_DOMAIN" |tee dnscrypt.log
		dnscrypt-wrapper --show-provider-publickey --provider-publickey-file public.key |tee -a dnscrypt.log
		dnscrypt-wrapper --show-provider-publickey-dns-records --provider-cert-file dnscrypt.cert |grep '"DNSC' |tee -a dnscrypt.log

		echo "/usr/sbin/named -u named -c /etc/named.conf" >/usr/bin/dnscrypt
		echo "dnscrypt-wrapper --resolver-address=$SERVER_UPSTREAM --listen-address=$SERVER_LISTEN --provider-name=2.dnscrypt-cert.$SERVER_DOMAIN --crypt-secretkey-file=dnscrypt.key --provider-cert-file=dnscrypt.cert" >>/usr/bin/dnscrypt
	fi

	#Client
	sed -i 's/127.0.0.1:53/'$CLIENT_LISTEN'/' /usr/local/dnscrypt-proxy/dnscrypt-proxy.toml
	sed -i "s/, '\[::1\]:53'//" /usr/local/dnscrypt-proxy/dnscrypt-proxy.toml
	
	#public DNS
	if [ "$CLIENT_UPSTREAM" == "PUBLIC" ]; then
		echo "dnscrypt-proxy" >/usr/bin/dnscrypt
	fi

	#private DNS
	if [ "$CLIENT_UPSTREAM" -a "$PROVIDER_KEY" -a "$SERVER_DOMAIN" ]; then
		sed -i 's/# server_names/server_names/' /usr/local/dnscrypt-proxy/dnscrypt-proxy.toml
		sed -i 's/fr.dnscrypt.org/'$SERVER_DOMAIN'/' /usr/local/dnscrypt-proxy/dnscrypt-proxy.toml
		sed -i 's/212.47.228.136:443/'$CLIENT_UPSTREAM'/' /usr/local/dnscrypt-proxy/dnscrypt-proxy.toml
		sed -i 's/E801:B84E:A606:BFB0:BAC0:CE43:445B:B15E:BA64:B02F:A3C4:AA31:AE10:636A:0790:324D/'$PROVIDER_KEY'/' /usr/local/dnscrypt-proxy/dnscrypt-proxy.toml
		echo "dnscrypt-proxy" >/usr/bin/dnscrypt
	fi

	#default
	if [ -z "$SERVER_UPSTREAM" -a -z "$CLIENT_UPSTREAM" ]; then
		echo "/usr/sbin/named -u named -c /etc/named.conf -f" >/usr/bin/dnscrypt
	fi

	#chinadns
	if [ "$CHINADNS" -a "$CLIENT_UPSTREAM" ]; then
		sed -i 's/'$CLIENT_LISTEN'/0.0.0.0:54/' /usr/local/dnscrypt-proxy/dnscrypt-proxy.toml
		sed -i 's/daemonize = false/daemonize = true/' /usr/local/dnscrypt-proxy/dnscrypt-proxy.toml
		echo "/usr/sbin/named -u named -c /etc/named.conf" >>/usr/bin/dnscrypt
		echo "chinadns -c /key/chnroute.txt -b 0.0.0.0 -p 53 -s '127.0.0.1:54,127.0.0.1:55' -d -v" >>/usr/bin/dnscrypt
		sed -i 's/port 53/port 55/g' /etc/named.conf

		if [ ! -f /key/chnroute.txt ]; then
			grep "CN|ipv4" /etc/delegated-apnic-latest |awk -F\| '{ printf("%s/%d\n", $4, 32-log($5)/log(2)) }' >/key/chnroute.txt
		fi
	fi

	init_bind
	chmod +x /usr/bin/dnscrypt
fi

	echo "Start ****"
	exec $@
else
	echo -e "
	Example:
				docker run -d \\
				-v /docker/dnscrypt:/key \\
				-p 5443:5443/udp \\
				-p 53:53/udp \\
				-e SERVER_DOMAIN=<jiobxn.com> \\
				-e SERVER_LISTEN=[0.0.0.0:5443] \\
				-e SERVER_UPSTREAM=<8.8.8.8:53> \\
				-e CLIENT_LISTEN=[0.0.0.0:53] \\
				-e CLIENT_UPSTREAM=<server_address:port | PUBLIC> \\
				-e PROVIDER_KEY=<Provider public key>
				-e CHINADNS=<Y> \\
				-e BIND_VERSION=["windows 2003 DNS"] \\
				-e BIND_LOG_SIZE=[100m] \\
				-e BIND_LISTEN=["any;"] \\
				-e BIND_ALLOW_QUERY=["any;"] \\
				-e BIND_FORWARDERS=<8.8.8.8;> \\
				-e BIND_CACHE_SIZE=[32m] \\
				-e BIND_QUERY_LOG=<Y> \\
				--hostname dns --name dns dnscrypt
	"
fi

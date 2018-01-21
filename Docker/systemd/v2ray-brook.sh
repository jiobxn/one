#!/bin/bash
set -e

if [ "$1" = 'v2ray-brook' ]; then

: ${PASS:="$(openssl passwd $RANDOM)"}
: ${PORT:="19443"}
: ${MODE:="server"}
: ${UUID:="$(cat /proc/sys/kernel/random/uuid)"}
: ${LOG:="none"}

if [ ! -f /usr/bin/v2ray-brook ]; then 
	if [ "$MODE" == "v2ray" ]; then
		mkdir /var/log/v2ray
		sed -i "s/10086/${PORT}/g" /v2ray/vpoint_vmess_freedom.json
		sed -i "s/23ad6b10-8d1a-40f7-8ad0-e3e35cd38297/${UUID}/g" /v2ray/vpoint_vmess_freedom.json
		sed -i "s/warning/${LOG}/" /v2ray/vpoint_vmess_freedom.json
		echo -e "mode: v2ray \nport: $PORT \nUUID: $UUID"
		echo "v2ray -config /v2ray/vpoint_vmess_freedom.json" >/usr/bin/v2ray-brook
	else
		if [ $HTTP ]; then
			HTTP="--http"
			TYPE="http"
		else
			TYPE="socks5"
		fi
		
		if [ $SERVER ]; then
			echo -e "mode: $MODE \nport: $PORT \ntype: $TYPE"
			echo "brook $MODE -l :$PORT -i 0.0.0.0 -s $SERVER -p $PASS $HTTP" >/usr/bin/v2ray-brook
		else
			echo -e "mode: $MODE \nport: $PORT \npassword: $PASS"
			echo "brook $MODE -l :$PORT -p $PASS" >/usr/bin/v2ray-brook
		fi
	fi
	chmod +x /usr/bin/v2ray-brook
fi

	echo "Start ****"
	exec $@
else
	echo -e "
	Example:
				docker run -d --restart always \\
				-p 19443:19443 \
				-e PASS=[Random] \\
				-e PORT=[19443] \\
				-e MODE=[server] \\ <v2ray| [server|streamserver|ssserver] | [client|streamclient|ssclient]>
				-e UUID=[Random] \\
				-e LOG=[none] \\ <debug|info|warning|error|none>
				-e HTTP=<Y> \\
				-e SERVER=<server_address:port> \\
				--hostname v2ray-brook --name v2ray-brook v2ray-brook
	"
fi

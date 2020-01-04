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
		if [ "$WSPATH" ]; then
		    sed -i '/"vmess"/ a \    "streamSettings": {\n      "network": "ws",\n      "wsSettings": {\n        "path": "'$WSPATH'",\n        "headers": {}\n      }\n    },' /v2ray/vpoint_vmess_freedom.json
		    echo "PATH: $WSPATH"
		fi
		
		echo "v2ray -config /v2ray/vpoint_vmess_freedom.json" >/usr/bin/v2ray-brook
	else
		if [ "$HTTP" ]; then
			HTTP="--http"
			TYPE="http"
		else
			TYPE="socks5"
		fi

		if [ "$DOMAIN" ]; then
			DOMAIN="--domain $DOMAIN"
			TLS=s
		else
			DOMAIN="-l :$PORT"
		fi
		
		if [ "$SERVER" ]; then
			if [ "$MODE" == "wsclient" ]; then
				echo -e "mode: $MODE \nport: $PORT \ntype: $TYPE"
				echo "brook $MODE -l :$PORT -i 0.0.0.0 -s ws$TLS://$SERVER -p $PASS $HTTP" >/usr/bin/v2ray-brook
			else
				echo -e "mode: $MODE \nport: $PORT \ntype: $TYPE"
				echo "brook $MODE -l :$PORT -i 0.0.0.0 -s $SERVER -p $PASS $HTTP" >/usr/bin/v2ray-brook
			fi
		else
			if [ "$MODE" == "wsserver" ]; then
                        	echo -e "mode: $MODE \nport: $PORT \npassword: $PASS"
                        	echo "brook $MODE $DOMAIN -p $PASS" >/usr/bin/v2ray-brook
			else
				echo -e "mode: $MODE \nport: $PORT \npassword: $PASS"
				echo "brook $MODE -l :$PORT -p $PASS" >/usr/bin/v2ray-brook
			fi
		fi
	fi
	chmod +x /usr/bin/v2ray-brook
fi

	echo "Start ****"
	exec $@
else
	echo -e "
	Example:
				docker run -d --restart unless-stopped \\
				-p 19443:19443 \
				-e PASS=[Random] \\
				-e PORT=[19443] \\
				-e MODE=[server] \\ <v2ray| [server|ssserver|wsserver] | [client|ssclient|wsclient]>
				-e UUID=[Random] \\
				-e WSPATH=</mp4> \\
				-e DOMAIN=<jiobxn.com> \\
				-e LOG=[none] \\ <debug|info|warning|error|none>
				-e HTTP=<Y> \\
				-e SERVER=<server_address:port> \\
				--name v2ray-brook v2ray-brook
	"
fi

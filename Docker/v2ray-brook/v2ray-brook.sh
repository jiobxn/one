#!/bin/bash
set -e

if [ "$1" = 'v2ray-brook' ]; then

: ${PORT:="19443"}
: ${LPORT:="1080"}
: ${MODE:="server"}
: ${LOG:="none"}

if [ ! -f /usr/bin/v2ray-brook ]; then
	if [ "$MODE" == "v2server" ]; then
	: ${UUID:="$(cat /proc/sys/kernel/random/uuid)"}
		mkdir /var/log/v2ray
		sed -i "s/10086/${PORT}/" /v2ray/vpoint_vmess_freedom.json
		sed -i "s/23ad6b10-8d1a-40f7-8ad0-e3e35cd38297/${UUID}/" /v2ray/vpoint_vmess_freedom.json
		sed -i "s/warning/${LOG}/" /v2ray/vpoint_vmess_freedom.json
		echo -e "mode: v2ray server \nport: $PORT \nUUID: $UUID \nsocks5"
		if [ "$WSPATH" ]; then
		    sed -i '/"vmess"/ a \    "streamSettings": {\n      "network": "ws",\n      "wsSettings": {\n        "path": "'$WSPATH'",\n        "headers": {}\n      }\n    },' /v2ray/vpoint_vmess_freedom.json
		    echo "PATH: $WSPATH"
		fi
		
		echo "v2ray -config /v2ray/vpoint_vmess_freedom.json" >/usr/bin/v2ray-brook
	elif [ "$MODE" == "v2client" ]; then
		if [ -n "$SERVER" -a -n "$UUID" ]; then
			if [ "$WSPATH" ]; then
				ws=ws
				sed -i 's/\/mp4/\'$WSPATH'/'  /v2ray/v2ray$ws-client.json
			fi
			sed -i "s/10086/${PORT}/" /v2ray/v2ray$ws-client.json
			sed -i "s/1080/${LPORT}/" /v2ray/v2ray$ws-client.json
			sed -i "s/mydomain.me/${SERVER}/" /v2ray/v2ray$ws-client.json
			sed -i "s/23ad6b10-8d1a-40f7-8ad0-e3e35cd38297/${UUID}/" /v2ray/v2ray$ws-client.json
			echo -e "mode: v2ray $ws client \nport: $LPORT \n$WSPATH socks5"
			
			echo "v2ray -config /v2ray/v2ray$ws-client.json" >/usr/bin/v2ray-brook
		else
			echo "error. Need to specify SERVER and UUID"
			exit 1
		fi
	else
		if [ "$DOMAIN" ]; then
			TLS=s
			PORT=443
		fi
		
		if [ "$SERVER" ]; then
			if [ "$PASS" ]; then
				if [ "$MODE" == "dns" ]; then
					echo -e "mode: $MODE \nport: 53 \ntype: dns"
					echo "brook $MODE -s $SERVER -p $PASS -l 0.0.0.0:53" >/usr/bin/v2ray-brook
				elif [ "$MODE" == "relayoverbrook" ]; then
					echo -e "mode: $MODE \nport: $LPORT \ntype: relay"
					echo "brook $MODE -s $SERVER -p $PASS -f 0.0.0.0:$LPORT -t $TO" >/usr/bin/v2ray-brook
				elif [ "$MODE" == "wsclient" -o  "$MODE" == "wssclient" ]; then
					echo -e "mode: $MODE \nport: $LPORT \ntype: socks5"
					echo "brook $MODE -s ws$TLS://$SERVER -p $PASS --socks5 0.0.0.0:$LPORT" >/usr/bin/v2ray-brook
				else
					echo -e "mode: $MODE \nport: $LPORT \ntype: socks5"
					echo "brook $MODE -s $SERVER -p $PASS --socks5 0.0.0.0:$LPORT" >/usr/bin/v2ray-brook
				fi
			else
				if [ "$MODE" == "socks5tohttp" ]; then
					echo -e "mode: $MODE \nport: $PORT \ntype: http"
					echo "brook $MODE --socks5 $SERVER --listen 0.0.0.0:$PORT" >/usr/bin/v2ray-brook
				else
					echo "error. Need to specify PASS"
					exit 1
				fi
			fi
		else
		: ${PASS:="$(openssl rand -base64 10 |tr -dc [:alnum:])"}
			if [ "$MODE" == "wssserver" ]; then
				[ -z "$DOMAIN" ] && echo "error. Need to specify DOMAIN" && exit 1
				echo -e "mode: $MODE \nport: $PORT \npassword: $PASS \ndomain: $DOMAIN"
				echo "brook $MODE --domain $DOMAIN -p $PASS" >/usr/bin/v2ray-brook
			elif [ "$MODE" == "socks5" ]; then
				[ -n "$USER" ] && AUTH="--username $USER --password $PASS"
				echo -e "mode: $MODE \nport: $PORT \nauth: $AUTH"
				echo "brook $MODE --socks5 0.0.0.0:$PORT $AUTH" >/usr/bin/v2ray-brook
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
				-e LPORT=[1080] \\
				-e MODE=[server] \\ <v2server | v2client | [server|wsserver|wssserver] | [client|wsclient|wssclient] | [socks5|socks5tohttp|relayoverbrook|dns]>
				-e UUID=[Random] \\
				-e WSPATH=</mp4> \\
				-e DOMAIN=<jiobxn.com> \\
				-e LOG=[none] \\ <debug|info|warning|error|none>
				-e SERVER=<server_address:port> \\
				-e TO=<1.1.1.1:3128> \\
				-e USER=<jiobxn> \\
				--name v2ray-brook v2ray-brook
	"
fi

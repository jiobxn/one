#!/bin/bash

if [ "$1" = 'trojan' ]; then


SET_SERVER(){
: ${LOCAL_ADDR:="0.0.0.0"}
: ${LOCAL_PORT:="443"}
: ${REMOT_ADDR:="127.0.0.1"}
: ${REMOT_PORT:="80"}
: ${PASS:="$(openssl rand -base64 12 |tr -dc [:alnum:])"}
: ${SNICN:="$(ifconfig $(route -n |awk '$1=="0.0.0.0"{print $NF }' |head -1) |awk '$3=="netmask"{print $2}')"}

cat >>/key/config.json <<-END
{
    "run_type": "server",
    "local_addr": "$LOCAL_ADDR",
    "local_port": $LOCAL_PORT,
    "remote_addr": "$REMOT_ADDR",
    "remote_port": $REMOT_PORT,
    "password": [
        "$PASS"
    ],
    "log_level": 1,
    "ssl": {
        "cert": "/key/server.crt",
        "key": "/key/server.key",
        "key_password": "",
        "cipher": "ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384",
        "cipher_tls13": "TLS_AES_128_GCM_SHA256:TLS_CHACHA20_POLY1305_SHA256:TLS_AES_256_GCM_SHA384",
        "prefer_server_cipher": true,
        "alpn": [
            "http/1.1"
        ],
        "reuse_session": true,
        "session_ticket": false,
        "session_timeout": 600,
        "plain_http_response": "",
        "curves": "",
        "dhparam": ""
    },
    "tcp": {
        "prefer_ipv4": false,
        "no_delay": true,
        "keep_alive": true,
        "reuse_port": false,
        "fast_open": false,
        "fast_open_qlen": 20
    },
    "mysql": {
        "enabled": false,
        "server_addr": "127.0.0.1",
        "server_port": 3306,
        "database": "trojan",
        "username": "trojan",
        "password": ""
    }
}
END

echo password: $PASS
}


SET_CLIENT(){
: ${LOCAL_ADDR:="0.0.0.0"}
: ${LOCAL_PORT:="1080"}
: ${REMOT_PORT:="443"}

cat >>/key/config.json <<-END
{
    "run_type": "client",
    "local_addr": "$LOCAL_ADDR",
    "local_port": $LOCAL_PORT,
    "remote_addr": "$REMOT_ADDR",
    "remote_port": $REMOT_PORT,
    "password": [
        "$PASS"
    ],
    "log_level": 1,
    "ssl": {
        "verify": false,
        "verify_hostname": true,
        "cert": "",
        "cipher": "ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES256-SHA:ECDHE-ECDSA-AES128-SHA:ECDHE-RSA-AES128-SHA:ECDHE-RSA-AES256-SHA:DHE-RSA-AES128-SHA:DHE-RSA-AES256-SHA:AES128-SHA:AES256-SHA:DES-CBC3-SHA",
        "cipher_tls13": "TLS_AES_128_GCM_SHA256:TLS_CHACHA20_POLY1305_SHA256:TLS_AES_256_GCM_SHA384",
        "sni": "",
        "alpn": [
            "h2",
            "http/1.1"
        ],
        "reuse_session": true,
        "session_ticket": false,
        "curves": ""
    },
    "tcp": {
        "no_delay": true,
        "keep_alive": true,
        "reuse_port": false,
        "fast_open": false,
        "fast_open_qlen": 20
    }
}
END
}


  if [ ! -f /key/config.json ]; then
	echo "Initialize trojan"
	if [ ! -f /key/server.crt -o ! -f /key/server.key ]; then
		openssl genrsa -out /key/server.key 4096 2>/dev/null
		openssl req -new -key /key/server.key -out /key/server.csr -subj "/C=CN/L=London/O=Company Ltd/CN=$SNICN" 2>/dev/null
		openssl x509 -req -days 3650 -in /key/server.csr -signkey /key/server.key -out /key/server.crt 2>/dev/null
		echo "SNICN: $SNICN"
	fi


	if [ -n "$REMOT_ADDR" -a -n "$PASS" -a -n "$CLIENT" ];then
		SET_CLIENT
	else
		SET_SERVER
	fi

        if [ "$WSPATH" ];then
                sed -i '/"tcp":/i \    "websocket": {\n\        "enabled": true,\n\        "path": "'$WSPATH'",\n\        "host": ""\n\    },' /key/config.json
		\mv /usr/local/bin/trojan-go /usr/local/bin/trojan
		echo "WSPATH: $WSPATH"
        fi
  fi
  
  echo "Start ****"
  exec "$@"

else

	echo -e " 
	Example:
				docker run -d --restart unless-stopped \\
				-v /docker/key:/key \\
				-p 443:443 \\
				-e LOCAL_ADDR=[0.0.0.0] \\
				-e LOCAL_PORT=[443 | 1080] \\
				-e REMOT_ADDR=[127.0.0.1 | trojan.example.com] \\
				-e REMOT_PORT=[80 | 443] \\
				-e SNICN=[local ip] \\
				-e WSPATH=</mp3> \\
				-e CLIENT=<Y> \\
				-e PASS:=[RANDOM] \\
				--name trojan trojan
	"
fi

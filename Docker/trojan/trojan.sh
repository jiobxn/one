#!/bin/bash

if [ "$1" = 'trojan' ]; then


SET_SERVER(){
: ${LOCAL_ADDR:="0.0.0.0"}
: ${LOCAL_PORT:="443"}
: ${REMOT_ADDR:="127.0.0.1"}
: ${REMOT_PORT:="80"}
: ${PASS:="$(openssl rand -hex 8)"}

cat >>/etc/config.json <<-END
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
        "cert": "/etc/server.crt",
        "key": "/etc/server.key",
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

cat >>/etc/config.json <<-END
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


  if [ ! -f /etc/config.json ]; then
	echo "Initialize trojan"
	if [ -f /key/server.crt -a -f /key/server.key ]; then
		\cp /key/*.{crt,key} /etc/
	else
		openssl genrsa -out /etc/server.key 4096 2>/dev/null
		openssl req -new -key /etc/server.key -out /etc/server.csr -subj "/C=CN/L=London/O=Company Ltd/CN=trojan-docker" 2>/dev/null
		openssl x509 -req -days 3650 -in /etc/server.csr -signkey /etc/server.key -out /etc/server.crt 2>/dev/null
		\cp /etc/server.{crt,key} /key/
	fi


	if [ -n "$REMOT_ADDR" -a -n "$PASS" -a -n "$CLIENT" ];then
		SET_CLIENT
	else
		SET_SERVER
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
				-e CLIENT=<Y> \\
				-e PASS:=[openssl rand -hex 8] \\
				--name trojan trojan
	"
fi

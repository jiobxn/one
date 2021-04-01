#!/bin/bash
set -e

if [ "$1" = 'kcp2raw' ]; then

: ${PORT:="20000"}
: ${RPORT:="4000"}


if [ ! -f /usr/bin/kcp2raw ]; then 
    if [ "$SERVICE" ]; then
        : ${PASS:="$(openssl rand -base64 10 |tr -dc '_A-Za-z0-9')"}
        echo -e "port: $PORT \npass: $PASS"
        echo "nohup server_linux_amd64 -t \"$SERVICE\" -l \":$RPORT\" -mode fast2 -mtu 1300 -key \"it's a secrect\" -crypt aes &" >/usr/bin/kcp2raw
        echo "udp2raw_amd64 -s -l 0.0.0.0:$PORT -r 127.0.0.1:$RPORT -k \"$PASS\" --raw-mode faketcp --cipher-mode aes128cbc" >>/usr/bin/kcp2raw
    elif [ "$SERVER" -a "$PASS" ]; then
        echo -e "port: $PORT"
        echo "nohup udp2raw_amd64 -c -r $SERVER -l 0.0.0.0:$RPORT -k \"$PASS\" --raw-mode faketcp --cipher-mode aes128cbc &" >/usr/bin/kcp2raw
        echo "client_linux_amd64 -r \"127.0.0.1:$RPORT\" -l \":$PORT\" -mode fast2 -mtu 1300 -key \"it's a secrect\" -crypt aes" >>/usr/bin/kcp2raw
    else
        echo "example"
        echo "server: docker run -d --restart unless-stopped --network host -e SERVICE=<serviceip:port> --name kcp2raw kcp2raw"
        echo "client: docker run -d --restart unless-stopped --network host -e SERVER=<serverip:port> -e PASS=<passwd> --name kcp2raw kcp2raw"
        exit 2
    fi
    chmod +x /usr/bin/kcp2raw 
fi

    echo "Start ****"
    exec $@
else
	echo -e "
	Example:
				docker run -d --restart unless-stopped \\
				-p 20000:20000 \
				-e PORT=[20000] \\
				-e RPORT=[4000] \\
				-e PASS=[RANDOM] \\
				-e SERVICE=<172.17.0.1:22> \\
				-e SERVER=<12.34.56.78:20000> \\
				--name kcp2raw kcp2raw
	"
fi

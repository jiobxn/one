#!/bin/bash
set -e

if [ "$1" = 'shadowsocks' ]; then

: ${SS_K:="$(openssl rand -base64 10 |tr -dc [:alnum:])"}
: ${SS_M:="aes-256-cfb"}
: ${SS_P:="8443"}
: ${SS_o:="tls1.2_ticket_auth_compatible"}
: ${SS_O:="auth_aes128_sha1"}
: ${SS_B:="127.0.0.1"}
: ${SS_L:="1080"}


if [ ! -f /usr/bin/shadowsocks ]; then 
        if [ "$SS_S" ]; then
                if [ "$SSR" ]; then
                        echo -e "shadowsocks type: SSR \nlocal port: $SS_L"
                        echo "/shadowsocksr/shadowsocks/local.py -s $SS_S -p $SS_P -k $SS_K -m $SS_M -O $SS_O -o $SS_o -b $SS_B -l $SS_L" >/usr/bin/shadowsocks
                else
                        echo -e "shadowsocks type: SS \nlocal port: $SS_L"
                        echo "/shadowsocks/shadowsocks/local.py -s $SS_S -p $SS_P -k $SS_K -m $SS_M -b $SS_B -l $SS_L" >/usr/bin/shadowsocks
                fi
        else
                if [ "$SSR" ]; then
                        echo -e "shadowsocks type: SSR \npassword: $SS_K \nencryption mode: $SS_M \nservice port: $SS_P \nprotocol: $SS_O \nobfs: $SS_o"
                        echo "/shadowsocksr/shadowsocks/server.py -p $SS_P -k $SS_K -m $SS_M -O $SS_O -o $SS_o" >/usr/bin/shadowsocks
                else
                        echo -e "shadowsocks type: SS \npassword: $SS_K \nencryption mode: $SS_M \nservice port: $SS_P"
                        echo "/shadowsocks/shadowsocks/server.py -p $SS_P -k $SS_K -m $SS_M" >/usr/bin/shadowsocks
                fi
        fi
        chmod +x /usr/bin/shadowsocks 
fi

        echo "Start ****"
        exec $@
else
	echo -e "
	Example:
				docker run -d --restart unless-stopped \\
				-p 8443:8443 \
				-e SS_K=[RANDOM] \\
				-e SS_M=[aes-256-cfb] \\
				-e SS_P=[8443] \\
				-e SS_o=[tls1.2_ticket_auth_compatible] \\
				-e SS_O=[auth_aes128_sha1] \\
				-e SSR=<Y> \\
				-e SS_S=<SS_SERVER> \\
				-e SS_B=[127.0.0.1] \\
				-e SS_L=[1080] \\
				--name shadowsocks shadowsocks
	"
fi

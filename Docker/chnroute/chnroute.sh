#!/bin/bash
set -e

: ${LOCAL_GW:="172.17.0.1"}
: ${UP_TIME:="daily"}

if [ "$1" = 'crond' ]; then

    if [ ! -f /usr/local/bin/chnroute ]; then
        echo "curl -4sSkL 'http://ftp.apnic.net/apnic/stats/apnic/delegated-apnic-latest' |egrep 'CN\|ipv4' |awk -F\| '{printf(\"%s/%d \\n\", \$4, 32-log(\$5)/log(2))}' >/2chnroute.txt" >/etc/periodic/$UP_TIME/route.sh
        echo "[ \"\$(wc -l /2chnroute.txt |awk '{print \$1}')\" -gt \"\$(wc -l /chnroute.txt |awk '{print \$1}')\"  ] && \cp /2chnroute.txt /chnroute.txt" >>/etc/periodic/$UP_TIME/route.sh

        if [ "$LOCAL_ROUTE" ]; then
            for i in $(echo $LOCAL_ROUTE |sed 's/,/\n/g'); do
                echo "$i" |tee -a /local.ip >>/chnroute.txt
            done
        fi

        echo "[ -f /local.ip ] && cat /local.ip >>/chnroute.txt" >>/etc/periodic/$UP_TIME/route.sh
        echo "chnroute" >>/etc/periodic/$UP_TIME/route.sh
        chmod +x /etc/periodic/$UP_TIME/route.sh

        echo "awk '{print \"ip route add\",\$1,\"via $LOCAL_GW\"}' /chnroute.txt |sh 2>/dev/null || echo" >/usr/local/bin/chnroute
        chmod +x /usr/local/bin/chnroute
    fi

    echo "Start ****"
    chnroute
    exec "$@"

else
    echo -e "example:\ndocker run -d --restart unless-stopped --network container:openvpn [-e LOCAL_GW=172.17.0.0.1] [-e UP_TIME=daily] <-e LOCAL_ROUTE=192.168.0.0/24,10.10.0.0/24> --name chnroute jiobxn/chnroute"
fi

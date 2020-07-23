#!/bin/bash
set -e

: ${HTTP_PORT:="8080"}
: ${HTTPS_PORT:="8443"}

if [ "$1" = 'jsproxy' ]; then

    if [ ! -f /usr/local/bin/jsproxy ]; then
        if [ "$HTTP_PORT" -ne 8080 ]; then
                        sed -i "s/8080;/$HTTP_PORT;/" /server/nginx.conf
        fi


                if [ -f /key/server.crt -a -f /key/server.key ]; then
                        \cp /key/server.crt /server/cert/server.crt
                        \cp /key/server.key /server/cert/server.key
                        echo -e "listen                $HTTPS_PORT ssl http2;\nssl_certificate       cert/server.crt;\nssl_certificate_key   cert/server.key;" >/server/cert/cert.conf
                fi


        if [ "$DROP_LAN" ]; then
                        echo "/server/setup-ipset.sh" >/usr/local/bin/jsproxy
                fi


        echo 'sudo -u jsproxy -H /openresty/nginx/sbin/nginx -c /server/nginx.conf -p /server/nginx -g "daemon off;"' >>/usr/local/bin/jsproxy
                chmod +x /usr/local/bin/jsproxy
    fi

    echo "Start ****"
    exec "$@"

else
        echo -e "
        Example:
                                docker run -d --restart unless-stopped --cap-add NET_ADMIN \\
                                -e HTTP_PORT=[8080] \\
                                -e HTTPS_PORT=[8443] \\
                                -e DROP_LAN=<Y> \\
                                --name jsproxy jiobxn/jsproxy
        "
fi

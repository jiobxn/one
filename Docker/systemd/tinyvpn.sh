#!/bin/bash
set -e

if [ "$1" = 'tinyvpn' ]; then

: ${IP_RANGE:=10.12.0}
: ${VPN_PORT:=8000}
: ${VPN_PASS:=2017126@Guo}

if [ ! -f /usr/bin/tinyvpn ]; then
	if [ $VPN_SERVER ]; then
		echo "service ip: $IP_RANGE.1"
		echo "tinyvpn_amd64 -c -r$VPN_SERVER:$VPN_PORT -f20:10 -k \"$VPN_PASS\" --sub-net $IP_RANGE.0" >/usr/bin/tinyvpn
	else
		echo -e "service port: $VPN_PORT \npassword: $VPN_PASS"
		echo "tinyvpn_amd64 -s -l0.0.0.0:$VPN_PORT -f20:10 -k \"$VPN_PASS\" --sub-net $IP_RANGE.0" >/usr/bin/tinyvpn
	fi

	chmod +x /usr/bin/tinyvpn
fi

	echo "Start ****"
	exec $@
else
	echo -e "
	Example:
				docker run -d --restart always --privileged \\
				-p 8000:8000/udp \
				-e VPN_PORT=[80] \\
				-e VPN_PASS=[2017126@Guo] \\
				--name filemanager filemanager
	"
fi

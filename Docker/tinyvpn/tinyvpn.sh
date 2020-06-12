#!/bin/bash
set -e

if [ "$1" = 'TINYVPN' ]; then

: ${TUN_DEV:="tun10"}
: ${IP_RANGE:="10.22.0"}
: ${VPN_PORT:="8000"}
: ${VPN_PASS:="NFSC@202064"}

if [ ! -f /usr/local/bin/TINYVPN ]; then
	#VPN
	if [ "$VPN_SERVER" ]; then
		echo "service ip: $IP_RANGE.1"
		echo "nohup tinyvpn -c -r$VPN_SERVER:$VPN_PORT -f20:10 -k \"$VPN_PASS\" --tun-dev $TUN_DEV --sub-net $IP_RANGE.0 &" >/usr/local/bin/TINYVPN
		ADDR="$IP_RANGE.1"
	else
		echo -e "service port: $VPN_PORT \npassword: $VPN_PASS"
		echo "nohup tinyvpn -s -l0.0.0.0:$VPN_PORT -f20:10 -k \"$VPN_PASS\" --tun-dev $TUN_DEV --sub-net $IP_RANGE.0 &" >/usr/local/bin/TINYVPN
		ADDR="$IP_RANGE.2"
	fi

	#DNAT
	if [ "$DNAT" ]; then
		for i in $(echo $DNAT |sed 's/,/\n/g'); do
			LPORT=$(echo "$i" |awk -F\| '{print $1}')
			RPORT=$(echo "$i" |awk -F\| '{print $2}')
			[ -z "$(echo "$RPORT" |grep :)" ] && RADDR="$ADDR:"
			echo "nohup tinymapper -l0.0.0.0:$LPORT -r$RADDR$RPORT -t -u &" >>/usr/local/bin/TINYVPN
		done
	fi

	#SNAT
	if [ "$SNAT" ]; then
		: ${DEV:="$(route -n |awk '$1=="0.0.0.0"{print $NF }')"}
		
		sysctl -w net.ipv4.ip_forward=1
		echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf

		cat > /iptables.sh <<-END
		iptables -t nat -I POSTROUTING -s $ADDR -o $DEV -j MASQUERADE
		iptables -I FORWARD -s $ADDR -j ACCEPT
		iptables -I FORWARD -m state --state RELATED,ESTABLISHED -j ACCEPT
		iptables -I INPUT -p udp -m state --state NEW -m udp --dport $VPN_PORT -m comment --comment TINYVPN -j ACCEPT
		iptables -I INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT
		chmod +x /iptables.sh
		END
	fi

	sed -i '$s/nohup //;$s/ &$//' /usr/local/bin/TINYVPN
	chmod +x /usr/local/bin/TINYVPN
fi

	echo "Start ****"
	[ -f /iptables.sh ] && . /iptables.sh
	exec $@
else
	echo -e "
	Example:
				docker run -d --restart unless-stopped --privileged \\
				-p 8000:8000/udp \\
				-p TUN_DEV=[tun10] \\
				-e VPN_PORT=[8000] \\
				-e VPN_SERVER=<IPADDR> \\
				-e IP_RANGE=[10.22.0] \\
				-e VPN_PASS=[NFSC@202064] \\
				-e DNAT=<2222:22,53|1.1.1.1:53> \\
				-e SNAT=<Y> \\
				--name tinyvpn tinyvpn
	"
fi

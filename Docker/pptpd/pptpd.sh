#!/bin/bash
set -e

if [ "$1" = 'pptpd' ]; then

: ${IP_RANGE:=10.9.0}
: ${VPN_USER:=jiobxn}
: ${VPN_PASS:=$(pwmake 64)}
: ${DNS1:=9.9.9.9}
: ${DNS2:=8.8.8.8}
: ${RADIUS_SECRET:=testing123}


if [ -z "$(grep "redhat.xyz" /etc/ppp/options.pptpd)" ]; then
	echo "#redhat.xyz" >>/etc/ppp/options.pptpd
	# Get ip address
	DEV=$(route -n |awk '$1=="0.0.0.0"{print $NF }')
	if [ -z $SERVER_IP ]; then
		SERVER_IP=$(curl -s http://ip.sb)
	fi

	if [ -z $SERVER_IP ]; then
		SERVER_IP=$(curl -s https://httpbin.org/ip |awk -F\" 'NR==2{print $4}')
	fi

	if [ -z $SERVER_IP ]; then
		SERVER_IP=$(ifconfig $DEV |awk '$3=="netmask"{print $2}')
	fi

	# Configure pptpd
	sed -i "/# or/i localip $IP_RANGE.1\nremoteip $IP_RANGE.5-254" /etc/pptpd.conf
	sed -i "s/#connections 100/connections 253/g" /etc/pptpd.conf
	sed -i "s/#ms-dns 10.0.0.1/ms-dns $DNS1\nms-dns $DNS2/g" /etc/ppp/options.pptpd

	# redius
	if [ $RADIUS_SERVER ];then
		echo "plugin /usr/lib64/pppd/$(rpm -qa ppp |awk -F- '{print $2}')/radius.so" >>/etc/ppp/options.pptpd
		echo "plugin /usr/lib64/pppd/$(rpm -qa ppp |awk -F- '{print $2}')/radattr.so" >>/etc/ppp/options.pptpd
		echo "radius-config-file /etc/radiusclient-ng/radiusclient.conf" >>/etc/ppp/options.pptpd
		sed -i "s/localhost/$RADIUS_SERVER/g" /etc/radiusclient-ng/radiusclient.conf
		echo "$RADIUS_SERVER  $RADIUS_SECRET" >>/etc/radiusclient-ng/servers
		echo "INCLUDE /usr/share/radiusclient-ng/dictionary.merit" >>/usr/share/radiusclient-ng/dictionary
		echo "INCLUDE /usr/share/radiusclient-ng/dictionary.microsoft" >>/usr/share/radiusclient-ng/dictionary
		echo "Radiud $RADIUS_SERVER" |tee /key/pptpd.log
	else
		echo "$VPN_USER       pptpd      $VPN_PASS          *" >> /etc/ppp/chap-secrets
		echo -e "
		VPN USER: $VPN_USER
		VPN PASS: $VPN_PASS
		SERVER: $SERVER_IP" |tee /key/pptpd.log
	fi

	# router forward
	sysctl -w net.ipv4.ip_forward=1
	echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf

	# iptables
	cat > /iptables.sh <<-END
	iptables -t nat -I POSTROUTING -s $IP_RANGE.0/24 -o $DEV -j MASQUERADE
	iptables -I FORWARD -s $IP_RANGE.0/24 -j ACCEPT
	iptables -I FORWARD -m state --state RELATED,ESTABLISHED -j ACCEPT
	iptables -I INPUT -p 47 -j ACCEPT
	iptables -I INPUT -p tcp -m state --state NEW -m tcp --dport 1723 -m comment --comment PPTPD -j ACCEPT
	iptables -I INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT
	END
fi

	echo
	echo "Start ****"
	[ -z "`iptables -S |grep PPTPD`" ] && . /iptables.sh
	exec "$@"

else

	echo -e "
	Example
			docker run -d --restart unless-stopped --privileged \\
			-v /docker/pptpd:/key \\
			--network host \\
			-e VPN_USER=[jiobxn] \\
			-e VPN_PASS=<123456> \\
			-e DNS1:=[9.9.9.9] \\
			-e DNS2:=[8.8.8.8] \\
			-e RADIUS_SERVER:=<radius ip> \\
			-e RADIUS_SECRET:=[testing123] \\
			--name pptpd pptpd"

fi

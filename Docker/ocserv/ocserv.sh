#!/bin/bash
set -e

if [ "$1" = 'ocserv' ]; then

: ${IP_RANGE:=10.10.0.0/24}
: ${VPN_PORT:=443}
: ${VPN_PASS:=$(pwmake 64)}
: ${P12_PASS:=jiobxn.com}
: ${MAX_CONN:=3}
: ${MAX_CLIENT:=253}
: ${CA_CN:="OpenConnect CA"}
: ${CLIENT_CN:="AnyConnect VPN"}
: ${GATEWAY_VPN:=Y}
: ${DNS1:=9.9.9.9}
: ${DNS2:=8.8.8.8}
: ${RADIUS_SECRET:=testing123}


if [ -z "$(grep "redhat.xyz" /etc/ocserv/ocserv.conf)" ]; then
	# Get ip address
	DEV=$(route -n |awk '$1=="0.0.0.0"{print $NF }')
	if [ -z $SERVER_CN ]; then
		SERVER_CN=$(curl -s https://httpbin.org/ip |awk -F\" 'NR==2{print $4}')
	fi

	if [ -z $SERVER_CN ]; then
		SERVER_CN=$(curl -s https://showip.net/)
	fi

	if [ -z $SERVER_CN ]; then
		SERVER_CN=$(ifconfig $DEV |awk '$3=="netmask"{print $2}')
	fi

	echo "Initialize OCSERV"
	if [ "$(ls /key/ |egrep -c "server.crt|server.key|ca.crt|ca.key|ocserv.p12")" -ne 5 ]; then
		#Create CA
		cd /etc/pki/ocserv/
		certtool --generate-privkey --outfile ca-key.pem 2>/dev/null 
		cat >>ca.tmpl <<-END
		cn = "$CA_CN" 
		organization = "Big Corp" 
		serial = 1 
		expiration_days = 3650 
		ca 
		signing_key 
		cert_signing_key 
		crl_signing_key 
		END
		certtool --generate-self-signed --load-privkey ca-key.pem --template ca.tmpl --outfile ca-cert.pem 2>/dev/null

		#Create Server key
		certtool --generate-privkey --outfile server-key.pem 2>/dev/null
		cat >>server.tmpl <<-END 
		cn = "$SERVER_CN"   
		organization = "My Company" 
		expiration_days = 3650 
		signing_key 
		encryption_key #only if the generated key is an RSA one 
		tls_www_server 
		END
		certtool --generate-certificate --load-privkey server-key.pem --load-ca-certificate ca-cert.pem --load-ca-privkey ca-key.pem --template server.tmpl --outfile server-cert.pem 2>/dev/null

		#Create Client key
		certtool --generate-privkey --outfile client-key.pem 2>/dev/null
		cat >>client.tmpl <<-END 
		cn = "$CLIENT_CN" 
		uid = "989"
		unit = "admins" 
		expiration_days = 3650 
		signing_key 
		tls_www_client 
		END
		
		certtool --generate-certificate --load-privkey client-key.pem --load-ca-certificate ca-cert.pem --load-ca-privkey ca-key.pem --template client.tmpl --outfile client-cert.pem 2>/dev/null
		certtool --to-p12 --load-privkey client-key.pem --pkcs-cipher 3des-pkcs12 --load-certificate client-cert.pem --outfile ocserv.p12 --outder --p12-name=$P12_PASS --password=$P12_PASS 2>/dev/null

		\cp server-cert.pem /etc/pki/ocserv/public/server.crt
		\cp server-key.pem /etc/pki/ocserv/private/server.key
		\cp ca-cert.pem /etc/pki/ocserv/cacerts/ca.crt
		\cp ca-key.pem /etc/pki/ocserv/private/ca.key
		\cp ocserv.p12 /key/
		\cp server-cert.pem /key/server.crt
		\cp server-key.pem /key/server.key
		\cp ca-cert.pem /key/ca.crt
		\cp ca-key.pem /key/ca.key
	else
		\cp /key/server.crt /etc/pki/ocserv/public/
		\cp /key/server.key /etc/pki/ocserv/private/
		\cp /key/ca.crt /etc/pki/ocserv/cacerts/
		\cp /key/ca.key /etc/pki/ocserv/private/
		echo "Certificate already exists, skip"
	fi
	
	
	#Configure
	sed -i '1 i #redhat.xyz' /etc/ocserv/ocserv.conf
	sed -i 's/auth = "pam"/#auth = "pam"/' /etc/ocserv/ocserv.conf
	sed -i "s#./sample.passwd,otp=./sample.otp#/etc/ocserv/ocpasswd#" /etc/ocserv/ocserv.conf
	sed -i "s/max-same-clients = 2/max-same-clients = ${MAX_CONN}/" /etc/ocserv/ocserv.conf
	sed -i "s/max-clients = 16/max-clients = ${MAX_CLIENT}/" /etc/ocserv/ocserv.conf
	sed -i "s/tcp-port = 443/tcp-port = ${VPN_PORT}/" /etc/ocserv/ocserv.conf
	sed -i "s/udp-port = 443/udp-port = ${VPN_PORT}/" /etc/ocserv/ocserv.conf
	sed -i "s/default-domain = example.com/#&/" /etc/ocserv/ocserv.conf
	sed -i "s@#ipv4-network = 192.168.1.0/24@ipv4-network = $IP_RANGE@" /etc/ocserv/ocserv.conf
	sed -i "s/#dns = 192.168.1.2/dns = $DNS1\ndns = $DNS2/" /etc/ocserv/ocserv.conf
	sed -i "s@user-profile = profile.xml@#user-profile = profile.xml@" /etc/ocserv/ocserv.conf

	
	if [ $VPN_USER ]; then
		sed -i 's/#auth = "plain/auth = "plain/g' /etc/ocserv/ocserv.conf
		(echo "${VPN_PASS}"; sleep 1; echo "${VPN_PASS}") | ocpasswd -c "/etc/ocserv/ocpasswd" ${VPN_USER}
		INFOU="VPN USER: $VPN_USER\n	VPN PASS: $VPN_PASS"
	else
		sed -i 's@#auth = "certificate"@auth = "certificate"@g' /etc/ocserv/ocserv.conf
		INFOC="p12 PASS: $P12_PASS"
	fi


	if [ $RADIUS_SERVER ];then
		sed -i "s/localhost/$RADIUS_SERVER/g" /etc/radiusclient-ng/radiusclient.conf
		echo "$RADIUS_SERVER  $RADIUS_SECRET" >>/etc/radiusclient-ng/servers
		sed -i 's/^auth /#auth /' /etc/ocserv/ocserv.conf
		sed -i '/#auth = "certificate"/ a #acct = "radius[config=/etc/radiusclient-ng/radiusclient.conf,groupconfig=true]"' /etc/ocserv/ocserv.conf
		sed -i '/#auth = "certificate"/ a auth = "radius[config=/etc/radiusclient-ng/radiusclient.conf,groupconfig=true]"' /etc/ocserv/ocserv.conf
		INFOU="Radius: $RADIUS_SERVER"
	fi


	if [ "$GATEWAY_VPN" = "Y" ]; then
		sed -i "s@# 'default'.@route = default@g" /etc/ocserv/ocserv.conf
	else
		sed -i "/# the server/i route = $DNS1/255.255.255.255\nroute = $DNS2/255.255.255.255" /etc/ocserv/ocserv.conf
	fi


	sysctl -w net.ipv4.ip_forward=1
	echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf


	# iptables
	cat > /iptables.sh <<-END
	iptables -t nat -I POSTROUTING -s $IP_RANGE.0/24 -o $DEV -j MASQUERADE
	iptables -I FORWARD -s $IP_RANGE.0/24 -j ACCEPT
	iptables -I FORWARD -m state --state RELATED,ESTABLISHED -j ACCEPT
	iptables -I INPUT -p tcp -m state --state NEW -m tcp --dport $VPN_PORT -m comment --comment OCSERV -j ACCEPT
	iptables -I INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT
	END

	echo -e "
	$INFOC
	$INFOU
	SERVER: $SERVER_CN" |tee /key/ocserv.log
fi

	echo
	echo "Start ****"
	[ -z "`iptables -S |grep OCSERV`" ] && . /iptables.sh

	exec "$@" &>/dev/null

else
	echo -e "
	Example
			docker run -d --restart always --privileged \\
			-v /docker/ocserv:/key \\
			-p 443:443 \\
			-e VPN_PORT=[443] \\
			-e VPN_USER=<jiobxn> \\
			-e VPN_PASS=<123456> \\
			-e P12_PASS=[jiobxn.com] \\
			-e MAX_CONN=[3] \\
			-e MAX_CLIENT=[253] \\
			-e SERVER_CN=[SERVER_IP] \\
			-e CLIENT_CN=["AnyConnect VPN"] \\
			-e CA_CN=["OpenConnect CA"] \\
			-e GATEWAY_VPN=[Y] \\
			-e IP_RANGE=[10.10.0.0/24] \\
			-e DNS1:=[9.9.9.9] \\
			-e DNS2:=[8.8.8.8] \\
			-e RADIUS_SERVER:=<radius ip> \\
			-e RADIUS_SECRET:=[testing123] \\
			--name ocserv ocserv
	"
fi

#IOS Client:
# Into the App Store is installed AnyConnect.
# Will ca.crt and ocserv.p12 import the certificate to IOS.

#Linux Client:
# yum -y install openconnect
# openconnect -c ocserv.p12 https://Server-IP-Address:Port --no-cert-check --key-password=$P12_PASS -q &
# echo "$VPN_PASS" | openconnect https://Server-IP-Address:Port --no-cert-check --user=$VPN_USER --passwd-on-stdin -q &

#Windows Client:
# download anyconnect-win-x.x.msi tool for ftp://ftp.noao.edu/pub/grandi/
# Will ca.crt and ocserv.p12 import the certificate to Windows. Certificate manage: certmgr.msc
# Uncheck: Block connections to untusted server

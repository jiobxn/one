#!/bin/bash
set -e

if [ "$1" = 'strongswan' ]; then

: ${IP_RANGE:="10.11.0"}
: ${VPN_USER:="jiobxn"}
: ${VPN_PASS:="$(openssl rand -base64 10 |tr -dc [:alnum:])"}
: ${VPN_PSK:="jiobxn.com"}
: ${P12_PASS:="jiobxn.com"}
: ${CLIENT_CN:="strongSwan VPN"}
: ${CA_CN:="strongSwan CA"}

	
if [ -z "$(grep "redhat.xyz" /etc/strongswan/ipsec.conf)" ]; then
	# Get ip address
	DEV=$(route -n |awk '$1=="0.0.0.0"{print $NF }' |head -1)
	if [ -z $SERVER_CN ]; then
		SERVER_CN=$(curl -s http://ip.sb)
	fi

	if [ -z $SERVER_CN ]; then
		SERVER_CN=$(curl -s https://showip.net/)
	fi

	if [ -z $SERVER_CN ]; then
		SERVER_CN=$(ifconfig $DEV |awk '$3=="netmask"{print $2}')
	fi

	echo "Initialize strongswan"
	if [ "$(ls /key/ |egrep -c "server.crt|server.key|ca.crt|ca.key|client.crt|client.key|strongswan.p12")" -ne 7 ]; then
		#Create certificate
		cd /etc/strongswan/ipsec.d
		strongswan pki --gen --type rsa --size 4096 --outform pem > ca-key.pem
		chmod 600 ca-key.pem
		strongswan pki --self --ca --lifetime 3650 --in ca-key.pem --type rsa --dn "C=CH, O=strongSwan, CN=$CA_CN" --outform pem > ca-cert.pem

		strongswan pki --gen --type rsa --size 2048 --outform pem > server-key.pem
		chmod 600 server-key.pem
		strongswan pki --pub --in server-key.pem --type rsa | strongswan pki --issue --lifetime 3650 --cacert ca-cert.pem --cakey ca-key.pem --dn "C=CH, O=strongSwan, CN=$SERVER_CN" --san $SERVER_CN --flag serverAuth --flag ikeIntermediate --outform pem > server-cert.pem 

		strongswan pki --gen --type rsa --size 2048 --outform pem > client-key.pem
		chmod 600 client-key.pem
		strongswan pki --pub --in client-key.pem --type rsa | strongswan pki --issue --lifetime 3650 --cacert ca-cert.pem --cakey ca-key.pem --dn "C=CH, O=strongSwan, CN=$CLIENT_CN" --outform pem > client-cert.pem

		openssl pkcs12 -export -inkey client-key.pem -in client-cert.pem -name "IPSec's VPN Certificate" -certfile ca-cert.pem -caname "strongSwan CA" -out strongswan.p12 -password "pass:$P12_PASS"

		\cp ca-key.pem /etc/strongswan/ipsec.d/private/ca.key
		\cp ca-cert.pem /etc/strongswan/ipsec.d/cacerts/ca.crt
		\cp server-key.pem /etc/strongswan/ipsec.d/private/server.key
		\cp server-cert.pem /etc/strongswan/ipsec.d/certs/server.crt
		\cp client-key.pem /etc/strongswan/ipsec.d/private/client.key
		\cp client-cert.pem /etc/strongswan/ipsec.d/certs/client.crt
		\cp ca-key.pem /key/ca.key
		\cp ca-cert.pem /key/ca.crt
		\cp server-key.pem /key/server.key
		\cp server-cert.pem /key/server.crt
		\cp client-key.pem /key/client.key
		\cp client-cert.pem /key/client.crt
		\cp strongswan.p12 /key/strongswan.p12

	else
		\cp /key/ca.key /etc/strongswan/ipsec.d/private/ca.key
		\cp /key/ca.crt /etc/strongswan/ipsec.d/cacerts/ca.crt
		\cp /key/server.key /etc/strongswan/ipsec.d/private/server.key
		\cp /key/server.crt /etc/strongswan/ipsec.d/certs/server.crt
		\cp /key/client.key /etc/strongswan/ipsec.d/private/client.key
		\cp /key/client.crt /etc/strongswan/ipsec.d/certs/client.crt
		echo "Certificate already exists, skip"
	fi
	
	
	# IPSec configuration file
	cat >/etc/strongswan/ipsec.conf <<-END
	#redhat.xyz
	config setup
	    uniqueids=never 
	conn user_pass_cert
	    keyexchange=ikev1
	    fragmentation=yes
	    left=%defaultroute
	    leftauth=pubkey
	    leftsubnet=0.0.0.0/0
	    leftcert=server.crt
	    right=%any
	    rightauth=pubkey
	    rightauth2=xauth
	    rightsourceip=$IP_RANGE.0/25
	    rightdns=8.8.8.8,1.1.1.1
	    rightcert=client.crt
	    auto=add
	conn user_pass_xauth_psk
	    keyexchange=ikev1
	    left=%defaultroute
	    leftauth=psk
	    leftsubnet=0.0.0.0/0
	    right=%any
	    rightauth=psk
	    rightauth2=xauth
	    rightsourceip=$IP_RANGE.128/25
	    rightdns=8.8.8.8,1.1.1.1
	    auto=add
	END
	
	
	# IPSec auth file
	cat >/etc/strongswan/ipsec.secrets <<-END
	: RSA server.key
	: PSK "$VPN_PSK"
	$VPN_USER %any : EAP "$VPN_PASS"
	$VPN_USER %any : XAUTH "$VPN_PASS"
	END
	
	
	# iptables
	cat > /iptables.sh <<-END
	iptables -t nat -I POSTROUTING -s $IP_RANGE.0/24 -o $DEV -j MASQUERADE
	iptables -I FORWARD -s $IP_RANGE.0/24 -j ACCEPT
	iptables -I FORWARD -m state --state RELATED,ESTABLISHED -j ACCEPT
	iptables -I INPUT -p udp -m state --state NEW -m udp --dport 500 -m comment --comment IPSEC -j ACCEPT
	iptables -I INPUT -p udp -m state --state NEW -m udp --dport 4500 -m comment --comment IPSEC -j ACCEPT
	iptables -I INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT
	END

	echo -e "
	VPN USER: $VPN_USER
	VPN PASS: $VPN_PASS
	VPN PSK: $VPN_PSK
	P12 PASS: $P12_PASS
	SERVER: $SERVER_CN" |tee /key/strongswan.log
fi

	echo
	echo "Start ****"
	[ -z "`iptables -S |grep IPSEC`" ] && . /iptables.sh
	
	exec "$@"

else

	echo -e "
	Example
			docker run -d --restart --cap-add NET_ADMIN --device /dev/net/tun \\
			-v /docker/strongswan:/key \\
			-p 500:500/udp \\
			-p 4500:4500/udp \\
			-e VPN_USER=[jiobxn] \\
			-e VPN_PASS=[RANDOM] \\
			-e VPN_PSK=[jiobxn.com] \\
			-e P12_PASS=[jiobxn.com] \\
			-e SERVER_CN=<SERVER_IP> \\
			-e CLIENT_CN=["strongSwan VPN"] \\
			-e CA_CN=["strongSwan CA"] \\
			-e IP_RANGE=[10.11.0] \\
			--name strongswan strongswan
	"
fi

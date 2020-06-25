#!/bin/bash
set -e

if [ "$1" = 'openvpn' ]; then

: ${IP_RANGE:=10.8}
: ${VPN_PORT:=1194}
: ${TCP_UDP:=tcp}
: ${TAP_TUN:=tun}
: ${VPN_PASS:=$(strings /dev/urandom |tr -dc A-Za-z0-9 |head -c15)}
: ${GATEWAY_VPN:=Y}
: ${C_TO_C:=Y}
: ${PROXY_PASS:=$(strings /dev/urandom |tr -dc A-Za-z0-9 |head -c15)}
: ${PROXY_PORT:=8080}
: ${DNS1:=9.9.9.9}
: ${DNS2:=8.8.8.8}
: ${RADIUS_SECRET:=testing123}


if [ -z "$(grep "redhat.xyz" /etc/openvpn/server.conf)" ]; then
	# Get ip address
	DEV=$(route -n |awk '$1=="0.0.0.0"{print $NF }' |head -1)
	if [ -z "$SERVER_IP" ]; then
		SERVER_IP=$(curl -s http://ip.sb/)
	fi

	if [ -z "$SERVER_IP" ]; then
		SERVER_IP=$(curl -s https://httpbin.org/ip |awk -F\" 'NR==2{print $4}')
	fi

	if [ -z "$SERVER_IP" ]; then
		SERVER_IP=$(ifconfig $DEV |awk '$3=="netmask"{print $2}')
	fi

	echo "Initialize openvpn"
	if [ "$(ls /key/ |egrep -w -c "ca.crt|server.crt|server.key|dh2048.pem|ta.key")" -ne 5 ]; then
		# Create certificate
		cd /etc/openvpn/server/3
		./easyrsa init-pki &>/dev/null
		echo | ./easyrsa gen-req server nopass &>/dev/null
	
		cd /etc/openvpn/client/3
		./easyrsa init-pki &>/dev/null
		echo | ./easyrsa build-ca nopass &>/dev/null
		echo | ./easyrsa import-req /etc/openvpn/server/3/pki/reqs/server.req server &>/dev/null
		echo yes | ./easyrsa sign-req server server &>/dev/null
		./easyrsa gen-dh &>/dev/null
	
		# Certificate or user
		if [ "$MAX_STATICIP" -a ! "$VPN_USER" ]; then
			if [ "$MAX_STATICIP" -gt 1000 ]; then
				MAX_STATICIP=1000
			fi
		
			i=1
			while [ $i -le "$MAX_STATICIP" ]; do
				echo | ./easyrsa gen-req client$i nopass &>/dev/null
				echo yes | ./easyrsa sign-req client client$i &>/dev/null
				let i++
			done
		else
			echo | ./easyrsa gen-req client nopass &>/dev/null
			echo yes | ./easyrsa sign-req client client &>/dev/null
		fi
	
		openvpn --genkey --secret /etc/openvpn/ta.key
	
		\cp /etc/openvpn/client/3/pki/issued/* /etc/openvpn/
		\cp /etc/openvpn/server/3/pki/private/* /etc/openvpn/
		\cp /etc/openvpn/client/3/pki/private/* /etc/openvpn/
		\cp /etc/openvpn/client/3/pki/ca.crt /etc/openvpn/
		\cp /etc/openvpn/client/3/pki/dh.pem /etc/openvpn/dh2048.pem
		\cp /etc/openvpn/*.crt /key/
		\cp /etc/openvpn/*.key /key/
		\cp /etc/openvpn/dh2048.pem /key/
		\cp /etc/openvpn/ta.key /key/
	else
		\cp /key/*.crt /etc/openvpn/
		\cp /key/*.key /etc/openvpn/
		\cp /key/dh2048.pem /etc/openvpn/
		\cp /key/ta.key /etc/openvpn/
		[ -f /key/psw-file ] && \cp /key/psw-file /etc/openvpn/
		echo "Certificate already exists, skip"
	fi

	# server.conf configuration file
	sed -i '1 i #redhat.xyz' /etc/openvpn/server.conf
	sed -i "s/port 1194/port $VPN_PORT/" /etc/openvpn/server.conf
	sed -i "s/proto udp/proto $TCP_UDP/" /etc/openvpn/server.conf

	# "dev tun" will create a routed IP tunnel. "dev tap" will create an ethernet tunnel,IOS
	sed -i "s/^dev tun/dev $TAP_TUN/" /etc/openvpn/server.conf
	sed -i "s/server 10.8.0.0 255.255.255.0/server $IP_RANGE.0.0 255.255.0.0/" /etc/openvpn/server.conf

	# Allow duplicate using a client certificate
	if [ ! "$MAX_STATICIP" ]; then
		sed -i 's/;duplicate-cn/duplicate-cn/' /etc/openvpn/server.conf
		sed -i 's/ifconfig-pool-persist/;ifconfig-pool-persist/' /etc/openvpn/server.conf
	else
		sed -i "s/;max-clients 100/max-clients $MAX_STATICIP/" /etc/openvpn/server.conf
		sed -i 's/;route 10.9.0.0 255.255.255.252/route '$IP_RANGE'.0.0 255.255.255.252\nclient-config-dir ccd/' /etc/openvpn/server.conf
		mkdir /etc/openvpn/ccd
	fi

	# [UDP]Notify the client that when the server restarts so it can automatically reconnect
	sed -i 's/explicit-exit-notify/;explicit-exit-notify/' /etc/openvpn/server.conf

	# tls-auth
	sed -i 's/;tls-auth ta.key 0/tls-auth ta.key 0/' /etc/openvpn/server.conf

	# GATEWAY
	if [ "$GATEWAY_VPN" = "Y" ]; then
		sed -i 's/;push "redirect-gateway def1 bypass-dhcp"/push "redirect-gateway def1 bypass-dhcp"/' /etc/openvpn/server.conf
	else
		sed -i 's/;push "dhcp-option DNS 208.67.222.222"/push "dhcp-option DNS '$DNS1'"\npush "route '$DNS1' 255.255.255.255"/' /etc/openvpn/server.conf
		sed -i 's/;push "dhcp-option DNS 208.67.220.220"/push "dhcp-option DNS '$DNS2'"\npush "route '$DNS2' 255.255.255.255"/' /etc/openvpn/server.conf
	fi

	# Router push
	if [ "$PUSH_ROUTE" ]; then
		for i in $(echo $PUSH_ROUTE |sed 's/,/\n/g'); do
			echo -e '\npush "route '$(echo $i |sed 's#/# #')'"' >>/etc/openvpn/server.conf
		done
	fi

	# client to client
	if [ "$C_TO_C" = "Y" ]; then
		sed -i "s/;client-to-client/client-to-client/" /etc/openvpn/server.conf
	fi

	# client.conf configuration file
	echo "auth-nocache" >>/etc/openvpn/client.conf
	sed -i 's/;tls-auth ta.key 1/tls-auth ta.key 1/' /etc/openvpn/client.conf
	echo "remote-cert-tls server" >>/etc/openvpn/client.conf
	sed -i "s/^dev tun/dev $TAP_TUN/" /etc/openvpn/client.conf
	sed -i "s/proto udp/proto $TCP_UDP/" /etc/openvpn/client.conf
	sed -i "s/remote my-server-1 1194/remote $SERVER_IP $VPN_PORT/" /etc/openvpn/client.conf

	# certificates to the client.conf
	sed -i 's/ca ca.crt/;ca ca.crt/' /etc/openvpn/client.conf
	sed -i 's/cert client.crt/;cert client.crt/' /etc/openvpn/client.conf
	sed -i 's/key client.key/;key client.key/' /etc/openvpn/client.conf
	echo -e "# ca.crt\n<ca>\n</ca>" >>/etc/openvpn/client.conf
	echo -e "# ta.key\n<tls-auth>\n</tls-auth>" >>/etc/openvpn/client.conf
	sed -i '/<ca>/ r /etc/openvpn/ca.crt' /etc/openvpn/client.conf
	sed -i '/<tls-auth>/ r /etc/openvpn/ta.key' /etc/openvpn/client.conf
	echo -e "# client.crt\n<cert>\n</cert>" >>/etc/openvpn/client.conf
	echo -e "# client.key\n<key>\n</key>" >>/etc/openvpn/client.conf

	\rm /etc/keepalived/keepalived.conf

	# Bind user and IP
	if [ "$MAX_STATICIP" ]; then
		if [ "$MAX_STATICIP" -gt 1000 ]; then
			MAX_STATICIP=1000
		fi

		if [ "$NAT_RANGE" ];then
			cat >/etc/keepalived/keepalived.conf <<-END
			! Configuration File for keepalived
			vrrp_instance VPN_IP {
				state BACKUP
				interface $DEV
				virtual_router_id 81
				priority 100
				advert_int 1
				authentication {
					auth_type PASS
					auth_pass $(openssl rand -hex 6)
				}
				virtual_ipaddress {
				}
			}
			END

			y1=$(echo $NAT_RANGE |awk -F. '{print $1"."$2}')
			y3=$(echo $NAT_RANGE |awk -F. '{print $3}')
			y4=$(echo $NAT_RANGE |awk -F. '{print $4}')
			[ -z $y3 ] && y3=0
			[ -z $y4 ] && y4=1
		fi
	
		[ -f /key/client.txt ] && \rm /key/client.txt
		i=1
		n=5
		m=6
		while [ $i -le "$MAX_STATICIP" ]; do
			[ $n -gt 256 ] && n=$(($n-256))
			[ $m -gt 256 ] && m=$(($m-256))
			x=$(($i/64))
			echo "ifconfig-push $IP_RANGE.$x.$n $IP_RANGE.$x.$m" >/etc/openvpn/ccd/client$i
			echo "$IP_RANGE.$x.$n user$i" >>/key/client.txt
		
			# add user
			if [ "$VPN_USER" -a ! -f /key/psw-file ];then
				PASS=$(strings /dev/urandom |tr -dc A-Za-z0-9 |head -c15)
				echo "client$i       $PASS" >> /etc/openvpn/psw-file
			fi
			
			# add Certificate
			if [ -z "$VPN_USER" ];then
				\cp /etc/openvpn/client.conf /etc/openvpn/client$i.conf
				sed -i '/<cert>/ r /etc/openvpn/client'$i'.crt' /etc/openvpn/client$i.conf
				sed -i '/<key>/ r /etc/openvpn/client'$i'.key' /etc/openvpn/client$i.conf
				\cp /etc/openvpn/client$i.conf /etc/openvpn/client$i.ovpn
				\cp /etc/openvpn/client$i.conf /key/client$i.ovpn
				\cp /etc/openvpn/client$i.conf /key/client$i.conf
			fi		
		
			if [ "$NAT_RANGE" ];then
				y3=$(($y3+$y4/256))
				[ $y4 -eq 256 ] && y4=$(($y4-256))
				sed -i "/virtual_ipaddress/a \        $y1.$y3.$y4" /etc/keepalived/keepalived.conf
				echo "iptables -t nat -A POSTROUTING -s $IP_RANGE.$x.$n/32 -o $DEV -m comment --comment user$i -j SNAT --to-source $y1.$y3.$y4" >>/iptables.sh
				y4=`expr $y4 + 1`  #Using "let y4++" will have an error
			fi
		
			n=$(($n+4))
			m=$(($m+4))
			let i++
		done
	else
		sed -i '/<cert>/ r /etc/openvpn/client.crt' /etc/openvpn/client.conf
		sed -i '/<key>/ r /etc/openvpn/client.key' /etc/openvpn/client.conf
		\cp /etc/openvpn/client.conf /etc/openvpn/client.ovpn
		\cp /etc/openvpn/client.conf /key/client.ovpn
		\cp /etc/openvpn/client.conf /key/client.conf
	fi


	# user
	if [ "$VPN_USER" ]; then
		cat >/etc/openvpn/checkpsw.sh <<-END
		#!/bin/sh
		###########################################################
		# checkpsw.sh (C) 2004 Mathias Sundman <mathias@openvpn.se>
		#
		# This script will authenticate OpenVPN users against
		# a plain text file. The passfile should simply contain
		# one row per user with the username first followed by
		# one or more space(s) or tab(s) and then the password.

		PASSFILE="/etc/openvpn/psw-file"
		LOG_FILE="/key/openvpn-password.log"
		TIME_STAMP=\`date "+%Y-%m-%d %T"\`

		###########################################################

		if [ ! -r "\${PASSFILE}" ]; then
			echo "\${TIME_STAMP}: Could not open password file \"\${PASSFILE}\" for reading." >> \${LOG_FILE}
			exit 1
		fi

		CORRECT_PASSWORD=\`awk '!/^;/&&!/^#/&&\$1=="'\${username}'"{print \$2;exit}' \${PASSFILE}\`

		if [ "\${CORRECT_PASSWORD}" = "" ]; then 
			echo "\${TIME_STAMP}: User does not exist: username=\"\${username}\", password=\"\${password}\"." >> \${LOG_FILE}
			exit 1
		fi

		if [ "\${password}" = "\${CORRECT_PASSWORD}" ]; then 
			echo "\${TIME_STAMP}: Successful authentication: username=\"\${username}\"." >> \${LOG_FILE}
			exit 0
		fi

		echo "\${TIME_STAMP}: Incorrect password: username=\"\${username}\", password=\"\${password}\"." >> \${LOG_FILE}
		exit 1
		END
	
		chown nobody:nobody /etc/openvpn/checkpsw.sh
		chmod u+x /etc/openvpn/checkpsw.sh
	
		if [ ! -f /etc/openvpn/psw-file ]; then
			echo "$VPN_USER       $VPN_PASS" >> /etc/openvpn/psw-file
		fi
	
		chmod 400 /etc/openvpn/psw-file
		\cp /etc/openvpn/psw-file /key/
	
		cat >>/etc/openvpn/server.conf <<-END
		
		#verify-client-cert none|optional|require
		verify-client-cert require
		#use checkpaw.sh to verify the connection client username/password
		auth-user-pass-verify /etc/openvpn/checkpsw.sh via-env
		#The user name used to index
		username-as-common-name
		script-security 3
		END

		if [ "$MAX_STATICIP" ]; then
			sed -i '/<cert>/ r /etc/openvpn/client.crt' /etc/openvpn/client.conf
			sed -i '/<key>/ r /etc/openvpn/client.key' /etc/openvpn/client.conf
			\cp /etc/openvpn/client.conf /etc/openvpn/client.ovpn
			\cp /etc/openvpn/client.conf /key/client.ovpn
			\cp /etc/openvpn/client.conf /key/client.conf
		fi

		for i in $(find /etc/openvpn/ -name client*.conf); do
			sed -i '/;key client.key/ a auth-user-pass' $i
			\cp $i /key/
		done

		for i in $(find /etc/openvpn/ -name client*.ovpn); do
			sed -i '/;key client.key/ a auth-user-pass' $i
			\cp $i /key/
		done
	else
		[ -f /etc/openvpn/psw-file ] && \rm /etc/openvpn/psw-file
	fi


	# Redius
	if [ "$RADIUS_SERVER" ];then
		cat >/etc/openvpn/checkpsw.sh <<-END
		#!/bin/sh
		LOG_FILE="/key/openvpn-password.log"
		TIME_STAMP=\`date "+%Y-%m-%d %T"\`
		
		echo "User-Name=\${username},User-Password=\${password}" |radclient $RADIUS_SERVER auth $RADIUS_SECRET -q -r 1
		
		if [ \$? -eq 0 ];then
		  echo "\${TIME_STAMP}: Successful authentication: username=\"\${username}\"." >> \${LOG_FILE}
		  exit 0
		fi
		
		echo "\${TIME_STAMP}: Incorrect password: username=\"\${username}\", password=\"\${password}\"." >> \${LOG_FILE}
		exit 1
		END
		[ -f /key/psw-file ] && \rm /key/psw-file
	fi


	# Squid
	if [ "$PROXY_USER" ]; then
		cat >>/squid-auth.txt <<-END
		auth_param basic program /usr/lib64/squid/basic_ncsa_auth /etc/squid/passwd 
		auth_param basic children 1000 
		auth_param basic realm Squid proxy-caching web server 
		auth_param basic credentialsttl 2 hours 
		auth_param basic casesensitive off 
		acl authuser proxy_auth REQUIRED 
		http_access allow authuser
		END

		sed -i '/# Recommended minimum configuration:/ r /squid-auth.txt' /etc/squid/squid.conf
		echo "$PROXY_USER:$(openssl passwd -apr1 $PROXY_PASS)" > /etc/squid/passwd
		echo -e "$PROXY_USER\n$PROXY_PASS" >/key/auth.txt
		sed -i "s/http_port 3128/http_port $PROXY_PORT/" /etc/squid/squid.conf
		sed -i "s/proto udp/proto $TCP_UDP/g" /etc/openvpn/server.conf

		for i in $(find /etc/openvpn/ -name client*.conf); do
			echo "http-proxy $SERVER_IP $PROXY_PORT auth.txt" >>$i
			#echo "http-proxy $SERVER_IP $PROXY_PORT stdin basic" >>$i
			sed -i "s/remote $SERVER_IP/remote 127.0.0.1/g" $i
			\cp $i /key/
		done

		for i in $(find /etc/openvpn/ -name client*.ovpn); do
			echo "http-proxy $SERVER_IP $PROXY_PORT auth.txt" >>$i
			#echo "http-proxy $SERVER_IP $PROXY_PORT stdin basic" >>$i
			sed -i "s/remote $SERVER_IP/remote 127.0.0.1/g" $i
			\cp $i /key/
		done

		SQUID_INFO="Squid user AND password: $PROXY_USER  $PROXY_PASS"

		echo "squid" >/usr/local/bin/SQUID && chmod +x /usr/local/bin/SQUID
		echo "iptables -I INPUT -p tcp -m state --state NEW -m tcp --dport $PROXY_PORT -m comment --comment OPENVPN -j ACCEPT" >>/iptables.sh
	else	
		echo "iptables -I INPUT -p $TCP_UDP -m state --state NEW -m $TCP_UDP --dport $VPN_PORT -m comment --comment OPENVPN -j ACCEPT" >>/iptables.sh
	fi


	# iptables
	if [ "$NAT_RANGE" ];then
		cat >> /iptables.sh <<-END
		iptables -I INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT
		iptables -I FORWARD -s $IP_RANGE.0.0/16 -j ACCEPT
		iptables -I FORWARD -m state --state RELATED,ESTABLISHED -j ACCEPT
		END
	else
		cat >> /iptables.sh <<-END
		iptables -I INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT
		iptables -t nat -I POSTROUTING -s $IP_RANGE.0/16 -o $DEV -j MASQUERADE
		iptables -I FORWARD -s $IP_RANGE.0.0/16 -j ACCEPT
		iptables -I FORWARD -m state --state RELATED,ESTABLISHED -j ACCEPT
		END
	fi

	echo -e "$(openvpn --help |awk 'NR==1{print $1"-"$2}')" |tee /key/openvpn.log

	if [ "$RADIUS_SERVER" ];then
		echo "Radiud $RADIUS_SERVER" |tee -a /key/openvpn.log
	else
		[ -f /etc/openvpn/psw-file ] && echo "VPN user AND password:" |tee -a /key/openvpn.log && cat /etc/openvpn/psw-file |tee -a /key/openvpn.log
	fi

	echo $SQUID_INFO |tee -a /key/openvpn.log
fi

	echo "Start ****"
	[ -f /etc/keepalived/keepalived.conf ] && keepalived -f /etc/keepalived/keepalived.conf -P -l
	[ -z "$(iptables -S |grep OPENVPN)" ] && . /iptables.sh
	[ -f /usr/local/bin/SQUID ] && SQUID
	exec "$@"

else

	echo -e "
	Example
			docker run -d --restart unless-stopped --cap-add=NET_ADMIN --device=/dev/net/tun \\
			-v /docker/openvpn:/key \\
			-p 1194:1194 \\
			-p <8080:8080> \\
			-e TCP_UDP=[tcp] \\
			-e TAP_TUN=[tun] \\
			-e VPN_PORT=[1194] \\
			-e VPN_USER=<jiobxn> \\
			-e VPN_PASS=<123456> \\
			-e MAX_STATICIP=<1000> \\
			-e C_TO_C=[Y] \\
			-e GATEWAY_VPN=[Y] \\
			-e SERVER_IP=[SERVER_IP] \\
			-e IP_RANGE=[10.8] \\
			-e PROXY_USER=<jiobxn> \\
			-e PROXY_PASS=<123456> \\
			-e PROXY_PORT=[8080] \\
			-e DNS1=[9.9.9.9] \\
			-e DNS2=[8.8.8.8] \\
			-e PUSH_ROUTE=<"172.31.10.0/255.255.0.0,10.10.0.0/255.255.0.0">
			-e RADIUS_SERVER=<radius ip> \\
			-e RADIUS_SECRET=[testing123] \\
			-e NAT_RANGE=<10.10.100 | 10.10.100.100> \\
			--name openvpn openvpn
	"
fi

#IOS Client:
# Into the App Store is installed OpenVPN.
# Use iTunes will client.ovpn、ta.key and auth.txt import the to OpenVPN.

#Linux Client:
# yum -y install openvpn
# scp OpenVPN-Server-IP:/etc/openvpn/easy-rsa/2.0/keys/keys/{client.conf,auth.txt} /etc/openvpn/
# systemctl start openvpn@client.service
# openvpn --writepid /var/run/openvpn-client/client.pid --cd /etc/openvpn/ --config /etc/openvpn/client.conf

#Windows Client:
# download install openvpn-install-x.x.x-I601.exe for https://openvpn.net/index.php/open-source/downloads.html
# Will client.ovpn and auth.txt(If there is)  import the to "C:\Program Files\OpenVPN\config\".

#!/bin/bash

if [ "$1" = 'WG' ]; then

: ${WG_TOKEN:="TEST"}
: ${LOCAL_ID:="$(openssl rand -hex 5)"}
: ${WGVETH_IP:="10.0.0"}
: ${WGVETHG_IP:="10.0"}
: ${ETCD:="http://etcd.redhat.xyz:12379"}
: ${MAX_CLIENT:="10"}

  if [ ! -f /usr/local/bin/WG ]; then
	echo "Initialize wireguard"
	export ETCDCTL_API=3
	if [ -n "$CLUSTER" -a "$WG_TOKEN" == "TEST" ]; then
		WG_TOKEN="$WG_TOKEN"G
	fi

	# clean key
	if [ "$CLUSTER" == "INIT" ]; then
		etcdctl --endpoints=$ETCD del "$WG_TOKEN/" --from-key
		for i in $(etcdctl --endpoints=$ETCD get "PUBNET/" --prefix --keys-only |grep ":$WG_TOKEN$"); do
			etcdctl --endpoints=$ETCD del $i
		done
	fi

	if [ -z "$WG_VPN" -a -z "$CLUSTER" -a "$(etcdctl --endpoints=$ETCD get "PUBNET/" --prefix --keys-only |grep -c ":$WG_TOKEN$")" -ge 2 ]; then
		for i in $(etcdctl --endpoints=$ETCD get "$WG_TOKEN/" --prefix --keys-only); do
			etcdctl --endpoints=$ETCD del $i
		done
		
		for i in $(etcdctl --endpoints=$ETCD get "PUBNET/" --prefix --keys-only |grep ":$WG_TOKEN$"); do
			etcdctl --endpoints=$ETCD del $i
		done
	fi

	if [ "$WG_VPN" == "SERVER" -a -n "$(etcdctl --endpoints=$ETCD get "$WG_TOKEN/" --prefix --keys-only |grep "/public_ip_port$")" ]; then
		etcdctl --endpoints=$ETCD del "$WG_TOKEN/" --from-key
		for i in $(etcdctl --endpoints=$ETCD get "PUBNET/" --prefix --keys-only |grep ":$WG_TOKEN$"); do
			etcdctl --endpoints=$ETCD del $i
		done
	fi

	# public IP
	if [ -z "$PUBLIC_IP" ]; then
		PUBLIC_IP=$(curl -s ip.sb)
	fi

	if [ -z "$PUBLIC_IP" ]; then
		PUBLIC_IP=$(ip address |grep -A2 ": $(ip route |awk '$1=="default"{print $5}')" |awk '$1=="inet"{print $2}' |awk -F/ '{print $1}')
	fi

	# public port
	PUBLIC_PORT=$(etcdctl --endpoints=$ETCD get "" --prefix --keys-only |egrep '^PUBNET/' |awk -F: '$1=="PUBNET/'$PUBLIC_IP'"{print $2}' |sort -n |tail -1)
	if [ -n "$PUBLIC_PORT" ]; then
		PUBLIC_PORT=$[$PUBLIC_PORT+1]
	else
		PUBLIC_PORT=20000
	fi

	# local IP
	if [ -z "$LOCAL_IP" ]; then
		LOCAL_IP=$(ip address |grep -A2 ": $(ip route |awk '$1=="default"{print $5}')" |awk '$1=="inet"{print $2}' |awk -F/ '{print $1}')
	fi
	DEV=$(ip route |awk '$NF=="'$LOCAL_IP'"{print $3}')

	# local port
	if [ -z "$LOCAL_PORT" ]; then
		LOCAL_PORT=$PUBLIC_PORT
	fi

	# local pubkey
	if [ "$PRIVATE_KEY" ]; then
		echo $PRIVATE_KEY >/private
		PUBLIC_KEY=$(wg pubkey < /private)
	else
		umask 077
		wg genkey > /private
		PUBLIC_KEY=$(wg pubkey < /private)
	fi

	# put ETCD
	if [ "$WG_VPN" != "CLIENT" ]; then
		etcdctl --endpoints=$ETCD put PUBNET/$PUBLIC_IP:$PUBLIC_PORT:$WG_TOKEN $LOCAL_ID
		etcdctl --endpoints=$ETCD put $WG_TOKEN/$LOCAL_ID/public_ip_port $PUBLIC_IP:$PUBLIC_PORT
		etcdctl --endpoints=$ETCD put $WG_TOKEN/$LOCAL_ID/local_ip_port  $LOCAL_IP:$LOCAL_PORT
		etcdctl --endpoints=$ETCD put $WG_TOKEN/$LOCAL_ID/public_key     $PUBLIC_KEY
	fi

	CONFIG() {
	# perr ID
	while [ -z "$PEER_ID" -a "$WG_VPN" != "SERVER" ]; do
		PEER_ID=$(etcdctl --endpoints=$ETCD get "$WG_TOKEN/" --prefix --keys-only |grep -v $LOCAL_ID |grep public_ip_port |awk -F/ '{print $2}')
		sleep 5
	done

	# peer ip and port
	if [ -z "$PEER_IP_PORT" ]; then
		PEER_IP_PORT=$(etcdctl --endpoints=$ETCD get $WG_TOKEN/$PEER_ID/public_ip_port |tail -1)
	fi

	# peer pubkey
	if [ -z "$PEER_PUBLIC_KEY" ]; then
		PEER_PUBLIC_KEY=$(etcdctl --endpoints=$ETCD get $WG_TOKEN/$PEER_ID/public_key |tail -1)
	fi
	}

	# real veth
	realeth=$(ip address |grep default |awk -F: '$2~"wg"{print $2}' |sed 's/ wg//g' |sort -n |tail -1)
	if [ -z "$realeth" ]; then
		realeth=wg0
	else
		realeth="wg$[$realeth+1]"
	fi

	# P2P or VPN
	if [ "$WG_VPN" == "SERVER" ]; then
		# VPM SERVER
		CONFIG
		echo '#!/bin/bash' > /usr/local/bin/WG
		echo "ip link add $realeth type wireguard" >> /usr/local/bin/WG
		echo "ip addr add $WGVETH_IP.1/24 dev $realeth" >> /usr/local/bin/WG
		echo "ip link set $realeth up" >> /usr/local/bin/WG
		echo "wg set $realeth listen-port $LOCAL_PORT private-key /private" >> /usr/local/bin/WG
		[ "$MAX_CLIENT" -gt 253 ] && MAX_CLIENT=253
		i=2

		while [ $i -le $MAX_CLIENT ]; do
			umask 077
			wg genkey > /mnt/private$i
			PUBKEY=$(wg pubkey < /mnt/private$i)
			etcdctl --endpoints=$ETCD put $WG_TOKEN/$LOCAL_ID/peerip_$i $WGVETH_IP.$i/24
			etcdctl --endpoints=$ETCD put $WG_TOKEN/$LOCAL_ID/peer_pubkey_$i $PUBKEY
			etcdctl --endpoints=$ETCD put $WG_TOKEN/$LOCAL_ID/peer_prikey_$i $(cat /mnt/private$i)
			echo "wg set $realeth peer $PUBKEY allowed-ips $WGVETH_IP.$i/32" >> /usr/local/bin/WG
			let  i++
		done
		echo "iptables -t nat -A  POSTROUTING -s $WGVETH_IP.0/24 -o $DEV -j MASQUERADE" >> /usr/local/bin/WG
	elif [ "$WG_VPN" == "CLIENT" ]; then
		# CLIENT
		CONFIG
		WGVETH=$(etcdctl --endpoints=$ETCD get "$WG_TOKEN/" --prefix --keys-only |grep wgveth_ |awk -F_ '{print $2}' |sort -n |tail -1)

		echo '#!/bin/bash' > /usr/local/bin/WG

		if [ -z "$WGVETH" ]; then
			wgip=$(etcdctl --endpoints=$ETCD get "$WG_TOKEN/$PEER_ID/peerip_2" |tail -1)
			etcdctl --endpoints=$ETCD put $WG_TOKEN/$LOCAL_ID/wgveth_2 $wgip
			wgeth=2
			echo $(etcdctl --endpoints=$ETCD get "$WG_TOKEN/$PEER_ID/peer_prikey_2" |tail -1) > /private
			PUBKEY=$(etcdctl --endpoints=$ETCD get "$WG_TOKEN/$PEER_ID/public_key" |tail -1)
		else
			wgip=$(etcdctl --endpoints=$ETCD get "$WG_TOKEN/$PEER_ID/peerip_$[$WGVETH+1]" |tail -1)
			etcdctl --endpoints=$ETCD put $WG_TOKEN/$LOCAL_ID/wgveth_$[$WGVETH+1] $wgip
			wgeth=$[$WGVETH+1]
			echo $(etcdctl --endpoints=$ETCD get "$WG_TOKEN/$PEER_ID/peer_prikey_$[$WGVETH+1]" |tail -1) > /private
			PUBKEY=$(etcdctl --endpoints=$ETCD get "$WG_TOKEN/$PEER_ID/public_key" |tail -1)
		fi

		echo "ip link add $realeth type wireguard" >> /usr/local/bin/WG
		echo "ip addr add $wgip dev $realeth" >> /usr/local/bin/WG
		echo "ip link set $realeth up" >> /usr/local/bin/WG
		echo "wg set $realeth private-key /private" >> /usr/local/bin/WG
		echo "wg set $realeth peer $PUBKEY allowed-ips 0.0.0.0/0 endpoint $PEER_IP_PORT persistent-keepalive 25" >> /usr/local/bin/WG
	elif [ "$CLUSTER" == "Y" -o "$CLUSTER" == "INIT" ]; then
		# CLUSTER
		WGVETH=${WGVETH:-$(etcdctl --endpoints=$ETCD get "$WG_TOKEN/" --prefix --keys-only |grep wgveth_ |awk -F_ '{print $2}' |sort -n |tail -1)}

		if [ -z "$WGVETH" ]; then
			etcdctl --endpoints=$ETCD put $WG_TOKEN/$LOCAL_ID/wgveth_1 $WGVETHG_IP.0.1/16
		else
			etcdctl --endpoints=$ETCD put $WG_TOKEN/$LOCAL_ID/wgveth_$[$WGVETH+1] $WGVETHG_IP.$[$WGVETH+1].1/16
		fi

		wgeth=$(etcdctl --endpoints=$ETCD get "$WG_TOKEN/$LOCAL_ID/wgveth_" --prefix --keys-only |awk -F_ 'NR=="1"{print $2}')
		wgip=$(etcdctl --endpoints=$ETCD get "$WG_TOKEN/$LOCAL_ID/wgveth_$wgeth" |tail -1)

		echo '#!/bin/bash' > /usr/local/bin/WG
		echo "ip link add $realeth type wireguard" >> /usr/local/bin/WG
		echo "ip addr add $wgip dev $realeth" >> /usr/local/bin/WG
		echo "ip link set $realeth up" >> /usr/local/bin/WG
		echo "wg set $realeth listen-port $LOCAL_PORT private-key /private" >> /usr/local/bin/WG

		# perr
		cat >/usr/local/bin/PERR <<-END
		#!/bin/bash
		export ETCDCTL_API=3
		PEER_ID=\$(etcdctl --endpoints=$ETCD get "$WG_TOKEN/" --prefix --keys-only |grep -v $LOCAL_ID |grep public_ip_port |awk -F/ '{print \$2}')
		
		for i in \$PEER_ID;do
			if [ -z "\$(grep -w \$i /peer.txt)" ]; then
				wgeth=\$(etcdctl --endpoints=$ETCD get "$WG_TOKEN/\$i/wgveth_" --prefix --keys-only |awk -F_ 'NR=="1"{print \$2}')
				wgip=\$(etcdctl --endpoints=$ETCD get "$WG_TOKEN/\$i/wgveth_\$wgeth" |tail -1 |sed 's/\/16/\/24/')
				PEER_IP_PORT=\$(etcdctl --endpoints=$ETCD get $WG_TOKEN/\$i/public_ip_port |tail -1)
				PEER_PUBLIC_KEY=\$(etcdctl --endpoints=$ETCD get $WG_TOKEN/\$i/public_key |tail -1)
				wg set $realeth peer \$PEER_PUBLIC_KEY allowed-ips \$wgip endpoint \$PEER_IP_PORT persistent-keepalive 25
				sed -i '/^bash/i wg set wg0 peer '\$PEER_PUBLIC_KEY' allowed-ips '\$wgip' endpoint '\$PEER_IP_PORT' persistent-keepalive 25' /usr/local/bin/WG
				echo \$i >>/peer.txt
			fi
		done
		END

		chmod +x /usr/local/bin/PERR
		atd 2>/dev/null
		echo -e "/usr/local/bin/PERR \nsleep 30 \n/usr/local/bin/PERR" |at now +1 minutes
		echo -e "/usr/local/bin/PERR \nsleep 30 \n/usr/local/bin/PERR" |at now +2 minutes
		echo "*/5 * * * * /usr/local/bin/PERR" >>/var/spool/cron/crontabs/root
	else

		# P2P
		CONFIG
		WGVETH=$(etcdctl --endpoints=$ETCD get "$WG_TOKEN/" --prefix --keys-only |grep wgveth_ |awk -F_ '{print $2}' |sort -n |tail -1)

		if [ -z "$WGVETH" ]; then
			etcdctl --endpoints=$ETCD put $WG_TOKEN/$LOCAL_ID/wgveth_1 $WGVETH_IP.1/24
		else
			etcdctl --endpoints=$ETCD put $WG_TOKEN/$LOCAL_ID/wgveth_$[$WGVETH+1] $WGVETH_IP.$[$WGVETH+1]/24
		fi

		wgeth=$(etcdctl --endpoints=$ETCD get "$WG_TOKEN/$LOCAL_ID/wgveth_" --prefix --keys-only |awk -F_ 'NR=="1"{print $2}')
		wgip=$(etcdctl --endpoints=$ETCD get "$WG_TOKEN/$LOCAL_ID/wgveth_$wgeth" |tail -1)

		echo '#!/bin/bash' > /usr/local/bin/WG
		echo "ip link add $realeth type wireguard" >> /usr/local/bin/WG
		echo "ip addr add $wgip dev $realeth" >> /usr/local/bin/WG
		echo "ip link set $realeth up" >> /usr/local/bin/WG
		echo "wg set $realeth listen-port $LOCAL_PORT private-key /private" >> /usr/local/bin/WG
		echo "wg set $realeth peer $PEER_PUBLIC_KEY allowed-ips 0.0.0.0/0 endpoint $PEER_IP_PORT persistent-keepalive 25" >> /usr/local/bin/WG
	fi
	echo bash >> /usr/local/bin/WG
	chmod +x /usr/local/bin/WG
	echo "export ETCDCTL_API=3; etcdctl --endpoints=$ETCD get \"\" --prefix --keys-only |grep $WG_TOKEN"
  fi

	echo
	echo "Start wireguard ****"
	crond 2>/dev/null
	exec $@

else
	echo -e "
	Example
					docker run -d --restart unless-stopped --cap-add net_admin \\
					-p 20000:20000/udp \\
					-e ETCD=[http://etcd.redhat.xyz:12379] \\
					-e WG_TOKEN=[TEST] \\
					-e LOCAL_ID=[openssl rand -hex 5] \\
					-e WGVETH_IP=[10.0.0] \\
					-e WGVETHG_IP=[10.0] \\
					-e MAX_CLIENT=[10] \\
					-e PUBLIC_IP=[curl -s ip.sb] \\
					-e PUBLIC_PORT=[20000] \\
					-e LOCAL_IP=[ip address] \\
					-e LOCAL_PORT=[PUBLIC_PORT] \\
					-e PRIVATE_KEY=[wg pubkey] \\
					-e PEER_ID=[ETCD] \\
					-e PEER_IP_PORT=[ETCD] \\
					-e PEER_PUBLIC_KEY=[ETCD] \\
					-e WG_VPN=<SERVER | CLIENT> \\
					-e CLUSTER=<INIT | Y> \\
					--name wireguard wireguard
	"
fi

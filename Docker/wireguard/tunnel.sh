#!/bin/sh

if [ "$1" = 'TUNNEL' ]; then

: ${LOCAL_IP:="$(ip address |grep -A2 ": $(ip route |awk '$1=="default"{print $5}')" |awk '$1=="inet"{print $2}' |awk -F/ '{print $1}')"}
: ${ETH:="$(ip route |awk '$1=="default"{print $5}')"}
: ${KEY:="202064"}
: ${VID:="202064"}
: ${SID:="202064"}
: ${CID:="12345678"}
: ${PORT:="4789"}
: ${GIP:="239.1.1.1"}


  if [ ! -f /usr/local/bin/TUNNEL ]; then
	echo "set up tunnel"

	if [ -n "$PEER_IP" -a -n "$VPN_IP" ]; then
		if [ "$TYPE" == "IPIP" ]; then
			echo "ip link add name ipip0 type ipip local $LOCAL_IP remote $PEER_IP" >/usr/local/bin/TUNNEL
			DEV=ipip0
			
		elif [ "$TYPE" == "GRE" ]; then
			echo "ip link add name gre1 type gre local $LOCAL_IP remote $PEER_IP key $KEY" >/usr/local/bin/TUNNEL
			DEV=gre1
			
		elif [ "$TYPE" == "GRETAP" ]; then
			echo "ip link add name gretap1 type gretap local $LOCAL_IP remote $PEER_IP key $KEY" >/usr/local/bin/TUNNEL
			DEV=gretap1
			
		elif [ "$TYPE" == "GENEVE" ]; then
			DEV=$(ip address |grep default |awk -F: '$2~"geneve"{print $2}' |sed 's/ geneve//g' |sort -n |tail -1)
			if [ -z "$DEV" ]; then
				DEV=geneve0
			else
				DEV="geneve$[$DEV+1]"
			fi
			echo "ip link add name $DEV type geneve id $VID remote $PEER_IP dstport $PORT" >/usr/local/bin/TUNNEL
			
		elif [ "$TYPE" == "VXLAN" ]; then
			DEV=$(ip address |grep default |awk -F: '$2~"vx"{print $2}' |sed 's/ vx//g' |sort -n |tail -1)
			if [ -z "$DEV" ]; then
				DEV=vx0
			else
				DEV="vx$[$DEV+1]"
			fi
			echo "ip link add $DEV type vxlan id $VID local $LOCAL_IP remote $PEER_IP dev $ETH dstport $PORT" >/usr/local/bin/TUNNEL
			
		elif [ "$TYPE" == "L2TP" ]; then
			echo "ip l2tp add tunnel local $LOCAL_IP remote $PEER_IP tunnel_id $VID peer_tunnel_id $VID encap udp udp_sport $PORT udp_dport $PORT" >/usr/local/bin/TUNNEL
			echo "ip l2tp add session tunnel_id $VID session_id $SID peer_session_id $SID cookie $CID peer_cookie $CID" >>/usr/local/bin/TUNNEL
			DEV=l2tpeth0
			
		else
			echo "NO TYPE, exit.."
			exit 1
		fi
	else
		if [ -n "$VPN_IP" ]; then
			DEV=$(ip address |grep default |awk -F: '$2~"vx"{print $2}' |sed 's/ vx//g' |sort -n |tail -1)
			if [ -z "$DEV" ]; then
				DEV=vx0
			else
				DEV="vx$[$DEV+1]"
			fi
			echo "ip link add $DEV type vxlan id $VID group $GIP dev $ETH dstport $PORT" >/usr/local/bin/TUNNEL
		else
			echo "NO VPN_IP, exit.."
			exit 1
		fi
	fi
	
	if [ -f /usr/local/bin/TUNNEL ]; then
		echo "ip link set $DEV up" >>/usr/local/bin/TUNNEL
		echo "ip addr add $VPN_IP dev $DEV" >>/usr/local/bin/TUNNEL
		[ -n "$ROUTE" ] && echo "ip route add $ROUTE dev $DEV" >>/usr/local/bin/TUNNEL
	fi

	#echo sh >>/usr/local/bin/TUNNEL
	#chmod +x /usr/local/bin/TUNNEL
	cat /usr/local/bin/TUNNEL

  fi
  
	echo
	echo "Start linux tunnel ****"
	exec sh
	#exec $@

else

	echo -e "
	Example
					docker run -d --restart unless-stopped --cap-add net_admin \\
					-p 4789:4789/udp \\
					-e LOCAL_IP=[interface address] \\
					-e ETH=[default interface] \\
					-e KEY=[202064] \\
					-e VID=[202064] \\
					-e SID=[202064] \\
					-e CID=[202064] \\
					-e PORT=[4789] \\
					-e GIP=[239.1.1.1] \\
					-e PEER_IP=<remote ip address> \\
					-e VPN_IP=<10.10.0.1/24> \\
					-e ROUTE=<172.31.0.0/16> \\
					-e TYPE=<IPIP | GRE | GRETAP | GENEVE | VXLAN | L2TP> \\
					--name tunnel tunnel
	        PEER_IP\VPN_IP\TYPE(IPIP | GRE | GRETAP | GENEVE | VXLAN | L2TP) or VPN_IP(VXLAN multicast)
	"
fi

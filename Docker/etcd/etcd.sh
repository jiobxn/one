#!/bin/bash
set -e

if [ "$1" = 'ETCD' ]; then

: ${ETCD_PORT:="2379"}
: ${ETCD_TOKEN:="token-01"}
: ${CLUSTER_STATE:="new"}
: ${ETCD_COUNT:="10000"}

  if [ ! -f /usr/local/bin/ETCD ]; then
	echo "Initialize redis"
	\cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime

	# nodes
	if [ "$CLUSTER" ]; then
		n=1
		for i in $(echo "$CLUSTER" |sed 's/,/\n/g'); do
			if [ ! -f /cluster.txt ]; then
				echo "etcd-$n=http://$i" >/cluster.txt
			else
				sed -i 's#$#,etcd-'$n'=http://'$i'#' /cluster.txt
			fi
			
			if [ -n "$(ip address |grep "`echo $i |awk -F: '{print $1}'`")" ]; then
				THIS_IP="$(echo $i |awk -F: '{print $1}')"
				THIS_PORT="$(echo $i |awk -F: '{print $2}')"
				THIS_NAME="etcd-$n"
			fi
			n=$(($n+1))
		done
	else
		THIS_IP="$(ip route |awk '$3=="'$(ip route |awk '$1=="default"{print $5}')'" && $NR1~"src"' |awk -F' src ' '{print $2}' |awk '{print $1}')"
		THIS_PORT="2380"
		THIS_NAME="etcd"
		echo "etcd=http://$THIS_IP:2380" >/cluster.txt
	fi
	
	CLUSTER="$(cat /cluster.txt)"

	# 
    if [ ! -d /data/etcd ]; then
		echo "etcd --data-dir=/data/etcd --name=${THIS_NAME} --initial-advertise-peer-urls=http://${THIS_IP}:${THIS_PORT} --listen-peer-urls=http://${THIS_IP}:${THIS_PORT} --advertise-client-urls=http://${THIS_IP}:${ETCD_PORT} --listen-client-urls=http://127.0.0.1:${ETCD_PORT},http://${THIS_IP}:${ETCD_PORT} --initial-cluster=${CLUSTER} --initial-cluster-state=${CLUSTER_STATE} --initial-cluster-token=${ETCD_TOKEN} --snapshot-count=${ETCD_COUNT}" > /usr/local/bin/ETCD
		chmod +x /usr/local/bin/ETCD
	else
		echo "/data/etcd exists, skip.."
	fi
	
	# TLS
	if [ "$AUTO_TLS" ]; then
		sed -i 's/$/ --auto-tls --peer-auto-tls/' /usr/local/bin/ETCD
		sed -i 's/http:/https:/g' /usr/local/bin/ETCD
		sed -i 's/client-urls=https/client-urls=http/g' /usr/local/bin/ETCD
		sed -i 's#client-urls=http://127.0.0.1:2379,https#client-urls=http://127.0.0.1:2379,http#' /usr/local/bin/ETCD
	elif [ -f /key/ca.crt -a -f /key/server.crt -a -f /key/server.key -a -f /key/peer.crt -a -f /key/peer.key ]; then
		sed -i 's#$# --cert-file=/key/server.crt --client-cert-auth=true --key-file=/key/server.key --peer-cert-file=/key/peer.crt --peer-client-cert-auth=true --peer-key-file=/key/peer.key --peer-trusted-ca-file=/key/ca.crt --trusted-ca-file=/key/ca.crt#' /usr/local/bin/ETCD
		sed -i 's/http:/https:/g' /usr/local/bin/ETCD
		echo "https://$THIS_IP:$ETCD_PORT"
	elif [ -f /key/ca.crt -a -f /key/peer.crt -a -f /key/peer.key ]; then
		sed -i 's#$# --peer-client-cert-auth --peer-trusted-ca-file=/key/ca.crt --peer-cert-file=/key/server.crt --peer-key-file=/key/server.key#' /usr/local/bin/ETCD
		sed -i 's/http:/https:/g' /usr/local/bin/ETCD
		echo "https://$THIS_IP:$ETCD_PORT"
	elif [ -f /key/ca.crt -a -f /key/server.crt -a -f /key/server.key ]; then
		sed -i 's#$# --client-cert-auth --trusted-ca-file=/key/ca.crt --cert-file=/key/server.crt --key-file=/key/server.key#' /usr/local/bin/ETCD
		sed -i 's/http:/https:/g' /usr/local/bin/ETCD
		echo "https://$THIS_IP:$ETCD_PORT"
	elif [ -f /key/server.crt -a -f /key/server.key ]; then
		sed -i 's#$# --peer-cert-file=/key/server.crt --peer-key-file=/key/server.key#' /usr/local/bin/ETCD
		sed -i 's/http:/https:/g' /usr/local/bin/ETCD
		echo "https://$THIS_IP:$ETCD_PORT"
	else
		echo "http://$THIS_IP:$ETCD_PORT"
	fi

	echo 'echo "export ETCDCTL_API=3" >>/root/.bashrc'
  fi

	echo
	echo "Start etcd ****"
	crond
	exec "$@" 1>/dev/null

else
	echo -e "
	Example
					docker run -d --restart unless-stopped \\
					-v /docker/etcd:/etcd/data \\
					-p 2379:2379 \\
					-p 2380:2380 \\
					-e ETCD_PORT=[2379] \\
					-e ETCD_TOKEN=[token-01] \\
					-e CLUSTER_STATE=[new] \\
					-e ETCD_COUNT=[10000] \\
					-e CLUSTER=<10.0.0.11:2380,10.0.0.12:2380,10.0.0.13:2380> \\
					-e AUTO_TLS=<Y> \\
					--name etcd etcd
	"
fi

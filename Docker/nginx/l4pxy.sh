#!/bin/bash

if [ "$1" = 'L4PXY' ]; then

: ${WORKER_PROC:="2"}
: ${KP_PASS:="$(openssl rand -hex 5)"}
: ${KP_VRID:="91"}

  if [ ! -f /usr/local/bin/L4PXY ]; then
	echo "Initialize l4pxy"
	\cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime

	stream_conf() {
		#nginx
		cat >/etc/nginx/nginx.conf <<-END
		#redhat.xyz
		worker_processes  $WORKER_PROC;
	  
		events {
		    worker_connections  $(($WORKER_PROC*10240));
		}
	  
		stream {
		   #acclog# log_format proxy '\$remote_addr:\$remote_port [\$time_local] \$protocol \$status \$session_time "\$upstream_addr" \$upstream_connect_time';
		   #acclog# access_log access.log proxy;
		   #errlog# error_log off;
		
		    #upstream#
		
		    #server#
		}
		daemon off;
		END
		
		[ "$ACCLOG_ON" ] && sed -i 's/#acclog#//g' /etc/nginx/nginx.conf
		[ "$ERRLOG_OFF" ] && sed -i 's/#errlog#//g' /etc/nginx/nginx.conf

		#keepalived
		cat >/etc/keepalived/keepalived.conf <<-END
		! Configuration File for keepalived
		
		vrrp_instance L4PXY_IP {
		    state BACKUP
		    interface KP_ETH
		    virtual_router_id $KP_VRID
		    priority 100
		    advert_int 1
		
		    authentication {
		        auth_type PASS
		        auth_pass $KP_PASS
		    }
			
		    virtual_ipaddress {
		    }
		}
		END
	}


	stream_server() {
		if [ -n "$(echo $i |grep '%')" ]; then
			echo "% yes"
			if [ -n "$(echo $i |awk -F% '{print $1}' |grep '|')" ]; then
				PORT=$(echo $i |awk -F% '{print $1}' |awk -F'|' '{print $1}')
				if [ -n "$(echo $PORT |grep ':')" ]; then
					ADDR=$(echo $PORT |awk -F: '{print $1}')
					sed -i "/virtual_ipaddress/a \        $ADDR" /etc/keepalived/keepalived.conf
				fi

				if [ -n "$(echo $i |awk -F% '{print $1}' |awk -F'|' '{print $2}' |grep ",")" ]; then
					sed -i '/#upstream#/ a \    upstream backend-lb-'$n' {\n\    }\n' /etc/nginx/nginx.conf

					for y in $(echo $i |awk -F% '{print $1}' |awk -F'|' '{print $2}' |sed 's/,/\n/g'); do
						sed -i '/upstream backend-lb-'$n'/ a \        server '$y';' /etc/nginx/nginx.conf
						sed -i 's/&/ /' /etc/nginx/nginx.conf
					done
					
					sed -i '/#server#/ a \    server {\n\        #backend-lb-'$n'#\n\        listen '$PORT';#'$n'\n\        proxy_pass backend-lb-'$n';\n\    }\n' /etc/nginx/nginx.conf
				else
					sed -i '/#server#/ a \    server {\n\        #backend-lb-'$n'#\n\        listen '$PORT';#'$n'\n\        proxy_pass '$(echo $i |awk -F% '{print $1}' |awk -F'|' '{print $2}')';\n\    }\n' /etc/nginx/nginx.conf
				fi
			else
				echo "error.." && exit 1
			fi
		else
			echo "% no"
			if [ -n "$(echo $i |grep '|')" ]; then
				PORT=$(echo $i |awk -F'|' '{print $1}')
				if [ -n "$(echo $PORT |grep ':')" ]; then
					ADDR=$(echo $PORT |awk -F: '{print $1}')
					sed -i "/virtual_ipaddress/a \        $ADDR" /etc/keepalived/keepalived.conf
				fi

				if [ -n "$(echo $i |awk -F'|' '{print $2}' |grep ",")" ]; then
					sed -i '/#upstream#/ a \    upstream backend-lb-'$n' {\n\    }\n' /etc/nginx/nginx.conf

					for y in $(echo $i |awk -F'|' '{print $2}' |sed 's/,/\n/g'); do
						sed -i '/upstream backend-lb-'$n'/ a \        server '$y';' /etc/nginx/nginx.conf
						sed -i 's/&/ /' /etc/nginx/nginx.conf
					done
					
					sed -i '/#server#/ a \    server {\n\        #backend-lb-'$n'#\n\        listen '$PORT';#'$n'\n\        proxy_pass backend-lb-'$n';\n\    }\n' /etc/nginx/nginx.conf
				else
					sed -i '/#server#/ a \    server {\n\        #backend-lb-'$n'#\n\        listen '$PORT';#'$n'\n\        proxy_pass '$(echo $i |awk -F'|' '{print $2}')';\n\    }\n' /etc/nginx/nginx.conf
				fi
			else
				echo "error.." && exit 1
			fi
		fi
		
		if [ -n "$ADDR" ];then
			[ -z "$KP_ETH" ] && KP_ETH="$(ip route |grep $(echo $ADDR |awk -F. '{print $1"."$2"."$3}') |awk '$2=="dev"{print $3}' |head -1)"
			sed -i "s/KP_ETH/$KP_ETH/" /etc/keepalived/keepalived.conf
			echo "keepalived -f /etc/keepalived/keepalived.conf -P -l" >/usr/local/bin/L4PXY
			echo $KP_ETH
		fi
	}


	stream_other() {
		for i in $(echo $i |awk -F% '{print $2}' |sed 's/,/\n/g'); do		
			#负载均衡
			if [ -n "$(echo $i |grep 'stream_lb=')" ]; then
				stream_lb="$(echo $i |grep 'stream_lb=' |awk -F= '{print $2}')"
			
				if [ "$stream_lb" == "hash" ]; then
					sed -i '/upstream backend-lb-'$n'/ a \        hash $remote_addr consistent;' /etc/nginx/nginx.conf
				fi
				
				if [ "$stream_lb" == "least_conn" ]; then
					sed -i '/upstream backend-lb-'$n'/ a \        least_conn;' /etc/nginx/nginx.conf
				fi
			fi
			
			#后端连接超时(1m)
			if [ -n "$(echo $i |grep 'conn_timeout=')" ]; then
				connect_timeout="$(echo $i |grep 'connect_timeout=' |awk -F= '{print $2}')"
				sed -i '/#backend-lb-'$n'#/ a \        proxy_connect_timeout '$connect_timeout';' /etc/nginx/nginx.conf
			fi
			
			#空闲超时(10m)
			if [ -n "$(echo $i |grep 'proxy_timeout=')" ]; then
				proxy_timeout="$(echo $i |grep 'proxy_timeout=' |awk -F= '{print $2}')"
				sed -i '/#backend-lb-'$n'#/ a \        proxy_timeout '$proxy_timeout';' /etc/nginx/nginx.conf
			fi
			
			#UDP
			if [ -n "$(echo $i |grep 'udp=')" ]; then
				sed -i 's/'$PORT';#'$n'/'$PORT' udp;#'$n'/' /etc/nginx/nginx.conf
			fi
		done
	}


	if [ "$L4PXY" ]; then
		stream_conf
		
		n=0
		for i in $(echo "$L4PXY" |sed 's/;/\n/g'); do
			n=$(($n+1))
			stream_server
			stream_other
		done
		
	fi

	echo "sleep 3" >>/usr/local/bin/L4PXY
	echo nginx >>/usr/local/bin/L4PXY
	chmod +x /usr/local/bin/L4PXY
  fi

	echo
	echo "Start l4pxy ****"
	exec $@

else
	echo -e "
	Example
			docker run -d --restart unless-stopped --cap-add net_admin \\
			-e WORKER_PROC=[2] \\
			-e KP_ETH=[listen eth] \\
			-e KP_PASS=[openssl rand -hex 5] \\
			-e KP_VRID=[91] \\
			-e ACCLOG_ON=<Y> \\
			-e ERRLOG_OFF=<Y> \\
			-e L4PXY=<22|10.10.0.242:22;10.10.0.247:53|1.1.1.1:53&weight=5,9.9.9.9:53&weight=10%udp=Y> \\
			   stream_lb=<hash|least_conn> \\
			   conn_timeout=[1m] \\
			   proxy_timeout=[10m] \\
			   udp=<Y> \\
			--name l4pxy l4pxy
	"
fi

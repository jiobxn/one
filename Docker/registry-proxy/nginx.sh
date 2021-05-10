#!/bin/bash
set -e

: ${DOMAIN="img.io"}
: ${NGX_PASS:="$(openssl rand -base64 8 |tr -dc [:alnum:])"}
: ${HTTP_PORT:="80"}
: ${HTTPS_PORT:="443"}


if [ "$1" = 'nginx' ]; then
  if [ -z "$(grep "#upstream#" /etc/nginx/nginx.conf)" ]; then
	echo "Initialize nginx"
	sed -i '/# Includes virtual hosts configs/ i \        #upstream#\n' /etc/nginx/nginx.conf
	sed -i 's/shared:SSL:2m/shared:SSL:10m/' /etc/nginx/nginx.conf
	sed -i 's/1024/65535/' /etc/nginx/nginx.conf
	echo "daemon off;" >>/etc/nginx/nginx.conf

	if [ -f /key/server.crt -a -f /key/server.key ]; then
		\cp /key/{server.crt,server.key} /etc/nginx/
		[ -f /key/ca.crt ] && \cp /key/ca.crt /var/lib/nginx/html/
	else
		cd /etc/nginx/
		openssl req -newkey rsa:4096 -nodes -sha256 -keyout ca.key -x509 -days 365 -out ca.crt -subj "/C=CN/L=London/O=Company Ltd/CN=nginx-docker"
		openssl req -newkey rsa:4096 -nodes -sha256 -keyout server.key -out server.csr -subj "/C=CN/L=London/O=Company Ltd/CN=$DOMAIN"
		openssl x509 -req -days 365 -in server.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out server.crt

		\cp /etc/nginx/{server.crt,server.key,ca.crt} /key/
		\cp /etc/nginx/ca.crt /var/lib/nginx/html/
	fi


	#default
	cat >/etc/nginx/conf.d/default.conf <<-END
	server {
        listen $HTTP_PORT;
        listen $HTTPS_PORT ssl;
        access_log /var/log/nginx/access.log;
        error_log /var/log/nginx/error.log;

        # this is necessary for us to be able to disable request buffering in all cases
        proxy_http_version 1.1;

        # SSL
        ssl_certificate /etc/nginx/server.crt;
        ssl_certificate_key /etc/nginx/server.key;
  
        # Recommendations from https://raymii.org/s/tutorials/Strong_SSL_Security_On_nginx.html
        ssl_protocols TLSv1.1 TLSv1.2;
        ssl_ciphers '!aNULL:kECDH+AESGCM:ECDH+AESGCM:RSA+AESGCM:kECDH+AES:ECDH+AES:RSA+AES:';
        ssl_prefer_server_ciphers on;
        ssl_session_cache shared:SSL:10m;

        # disable any limits to avoid HTTP 413 for large image uploads
        client_max_body_size 0;

        # required to avoid HTTP 411: see Issue #1486 (https://github.com/docker/docker/issues/1486)
        chunked_transfer_encoding on;

        location / {
            root   html;
            index  index.html index.htm;
        }

        location /v1/ {
          rewrite ^/(.*) https://\$host/v2/ permanent;
        }

        location /v2/ {
            proxy_pass http://registry/v2/;
            proxy_set_header Host \$http_host;
            proxy_set_header X-Real-IP \$remote_addr;
            proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
      
            # When setting up Harbor behind other proxy, such as an Nginx instance, remove the below line if the proxy already has similar settings.
            proxy_set_header X-Forwarded-Proto \$scheme;
      
            proxy_buffering off;
            proxy_request_buffering off;

            # auth basic
            ##user_auth auth_basic           "Registry Login!";
            ##user_auth auth_basic_user_file /etc/nginx/.htpasswd;
        }
	}
	END

	#add Registry
	sed -i '/#upstream#/ a \        upstream registry {\n\            keepalive 20;\n\        }\n' /etc/nginx/nginx.conf

	if [ $REG_SERVER ]; then
		if [ -n "$(echo $REG_SERVER |grep ",")" ]; then
			for i in $(echo $REG_SERVER |sed 's/,/\n/g'); do
				sed -i '/upstream registry/ a \            server '$i';' /etc/nginx/nginx.conf
			done
			sed -i '/upstream registry/ a \            hash $remote_addr;' /etc/nginx/nginx.conf
		else
			sed -i '/upstream registry/ a \            server '$REG_SERVER';' /etc/nginx/nginx.conf
		fi
	else
		sed -i '/upstream registry/ a \            server 127.0.0.1:5000;' /etc/nginx/nginx.conf
	fi


	if [ $NGX_USER ]; then
		sed -i 's/##nginx_status//g' /etc/nginx/conf.d/default.conf
		echo "$NGX_USER:$(openssl passwd -apr1 $NGX_PASS)" >> /etc/nginx/.htpasswd
		echo "Nginx user AND password: $NGX_USER  $NGX_PASS" |tee /key/nginx.txt
		sed -i 's/##user_auth //g' /etc/nginx/conf.d/default.conf
	fi
  fi

	echo "Start ****"
	exec "$@"
else

	echo -e " 
	Example:
				docker run -d --restart unless-stopped \\
				-v /docker/key:/key \\
				-p 80:80 \\
				-p 443:443 \\
				-e HTTP_PORT=[80] \\
				-e HTTPS_PORT=[443] \\
				-e DOMAIN=[img.io] \\
				-e REG_SERVER=[127.0.0.1:5000] \\
				-e NGX_USER=<admin> \\
				-e NGX_PASS=[RANDOM] \\
				--name registry-proxy registry-proxy
	" 
fi

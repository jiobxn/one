#!/bin/bash
set -e

: ${NGX_PASS:="jiobxn.com"}
: ${NGX_CHARSET:="utf-8"}
: ${FCGI_PATH:="/var/www"}
: ${HTTP_PORT:="80"}
: ${HTTPS_PORT:="443"}
: ${SSL_CACHE:="10m"}
: ${DOMAIN_TAG:="888"}
: ${EOORO_JUMP:="https://cn.bing.com"}
: ${NGX_DNS="8.8.8.8"}
: ${CACHE_TIME:="10m"}
: ${CACHE_SIZE:="2g"}
: ${CACHE_MEM:="$(($(free -m |grep Mem |awk '{print $2}')*10/100))m"}



http_conf() {
	echo "Initialize nginx"
	if [ -f /key/server.crt -a -f /key/server.key ]; then
		\cp /key/*.{crt,key} /etc/nginx/
	else
		openssl genrsa -out /etc/nginx/server.key 4096 2>/dev/null
		openssl req -new -key /etc/nginx/server.key -out /etc/nginx/server.csr -subj "/C=CN/L=London/O=Company Ltd/CN=nginx-docker" 2>/dev/null
		openssl x509 -req -days 3650 -in /etc/nginx/server.csr -signkey /etc/nginx/server.key -out /etc/nginx/server.crt 2>/dev/null
	fi


	#global
	mkdir /etc/nginx/vhost
	cat >/etc/nginx/nginx.conf <<-END
	#redhat.xyz
	user  nginx;
	worker_processes  $(nproc);
	
	error_log  /var/log/nginx/error.log warn;
	pid        /var/run/nginx.pid;

	events {
	    worker_connections  $((`nproc`*10240));
	}

	http {
	    include       mime.types;
	    default_type  application/octet-stream;

	    log_format  main  '\$remote_addr - \$remote_user [\$time_local] "\$request" '
	        '\$status \$body_bytes_sent "\$http_referer" '
	        '"\$http_user_agent" "\$http_x_forwarded_for"';
	    access_log  /var/log/nginx/access.log  main;

	    sendfile        on;
	    tcp_nopush      on;
	    keepalive_timeout  70;
	    server_names_hash_bucket_size 512;

	##acclog_off    access_log off;
	##errlog_off    error_log off;
		
	    charset $NGX_CHARSET;

	    client_max_body_size 0;
	    autoindex on;
	    server_tokens off;

	    proxy_cache_path /tmp/proxy_cache levels=1:2 keys_zone=cache1:$CACHE_MEM inactive=$CACHE_TIME max_size=$CACHE_SIZE;
	    fastcgi_cache_path /tmp/fastcgi_cache levels=1:2 keys_zone=cache2:$CACHE_MEM inactive=$CACHE_TIME max_size=$CACHE_SIZE;

	    gunzip on;
	    gzip  on;
	    gzip_comp_level 6;
	    gzip_proxied any;
	    gzip_types text/plain text/css application/json application/x-javascript text/xml application/xml application/xml+rss text/javascript application/x-httpd-php image/jpeg image/gif image/png;
	    gzip_vary on;

	    #upstream#

	    include /etc/nginx/conf.d/*.conf;

	##default_server    server {
	##default_server            listen       $HTTP_PORT  default_server;
	##default_server            server_name  _;
	##default_server            rewrite ^(.*) http://$DEFAULT_SERVER:$HTTP_PORT permanent;
	##default_server    }
	}
	daemon off;
	END


	#default
	cat >/etc/nginx/conf.d/default.conf <<-END
	server {
	    listen       $HTTP_PORT;#
	    listen       $HTTPS_PORT ssl;
	    server_name localhost;

	    ssl_certificate      /etc/nginx/server.crt;
	    ssl_certificate_key  /etc/nginx/server.key;
	    ssl_session_cache shared:SSL:$SSL_CACHE;
	    ssl_session_timeout  5m;
	    ssl_protocols TLSv1 TLSv1.1 TLSv1.2;
	    ssl_ciphers  HIGH:!aNULL:!MD5;
	    ssl_prefer_server_ciphers   on;

	    location / {
	        root   html;
	        index  index.html index.htm;
	    }

	##nginx_status    location ~ /basic_status {
	##nginx_status        stub_status;
	##nginx_status        auth_basic           "Nginx Stats";
	##nginx_status        auth_basic_user_file /etc/nginx/.htpasswd;
	##nginx_status    }
	}
	END
}



fcgi_server() {
	cat >/etc/nginx/conf.d/fcgi_$n.conf <<-END
	server {
	    listen       $HTTP_PORT;#
	    listen       $HTTPS_PORT ssl;
	    #server_name#

	##full_https    if (\$scheme = http) { return 301 https://\$host\$request_uri;}

	    ssl_certificate      /etc/nginx/server.crt;
	    ssl_certificate_key  /etc/nginx/server.key;
	    ssl_session_cache shared:SSL:$SSL_CACHE;
	    ssl_session_timeout  5m;
	    ssl_protocols TLSv1 TLSv1.1 TLSv1.2;
	    ssl_ciphers  HIGH:!aNULL:!MD5;
	    ssl_prefer_server_ciphers   on;

	    location / {
	        root   html;
	        index  index.php index.html index.htm;
	        try_files \$uri \$uri/ /index.php?q=\$uri&\$args;
	    }

	    #alias#

	    location ~ \.php$ {
	        fastcgi_pass   fcgi-lb-$n;
	        fastcgi_index  index.php;
	        fastcgi_param  SCRIPT_FILENAME  $FCGI_PATH\$fastcgi_script_name;
	        include        fastcgi_params;
	        fastcgi_read_timeout    300;
	        fastcgi_connect_timeout 300;
	        fastcgi_keep_conn on;
			
	##cache        fastcgi_cache cache1;
	##cache        fastcgi_cache_valid 200      $CACHE_TIME;
	##cache        fastcgi_cache_key \$host\$request_uri\$cookie_user\$scheme\$proxy_host\$uri\$is_args\$args;
	##cache        fastcgi_cache_use_stale  error timeout invalid_header updating http_500 http_502 http_503 http_504;

	##user_auth        auth_basic           "Nginx Auth";
	##user_auth        auth_basic_user_file /etc/nginx/.htpasswd-tag;
	    }

	##nginx_status    location ~ /basic_status {
	##nginx_status        stub_status;
	##nginx_status        auth_basic           "Nginx Stats";
	##nginx_status        auth_basic_user_file /etc/nginx/.htpasswd;
	##nginx_status    }

	    location ~ /\.ht {
	        deny  all;
	    }
	}
	END
}



java_php_server() {
	cat >/etc/nginx/conf.d/java-php_$n.conf <<-END
	server {
	    listen       $HTTP_PORT;#
	    listen       $HTTPS_PORT ssl;
	    #server_name#

	##full_https    if (\$scheme = http) { return 301 https://\$host\$request_uri;}

	    ssl_certificate      /etc/nginx/server.crt;
	    ssl_certificate_key  /etc/nginx/server.key;
	    ssl_session_cache shared:SSL:$SSL_CACHE;
	    ssl_session_timeout  5m;
	    ssl_protocols TLSv1 TLSv1.1 TLSv1.2;
	    ssl_ciphers  HIGH:!aNULL:!MD5;
	    ssl_prefer_server_ciphers   on;

	    location / {
	        root   html;
	        index  index.jsp index.php index.html index.htm;
	    }

	    #alias#

	    location ~ .(jsp|jspx|do|php)?$ {
	        proxy_pass http://java-php-lb-$n;
	        proxy_http_version 1.1;
	        proxy_read_timeout      300;
	        proxy_connect_timeout   300;
	        proxy_set_header   Connection "";
	        proxy_set_header   Host              \$host;
	        proxy_set_header   X-Real-IP         \$remote_addr;
	        proxy_set_header   X-Forwarded-Proto \$scheme;
	        proxy_set_header   X-Forwarded-For   \$proxy_add_x_forwarded_for;
	        proxy_set_header   Accept-Encoding  "";
			
	##cache        proxy_cache cache1;
	##cache        proxy_cache_valid 200      $CACHE_TIME;
	##cache        proxy_cache_key \$host\$request_uri\$cookie_user\$scheme\$proxy_host\$uri\$is_args\$args;
	##cache        proxy_cache_use_stale  error timeout invalid_header updating http_500 http_502 http_503 http_504;

	##user_auth        auth_basic           "Nginx Auth";
	##user_auth        auth_basic_user_file /etc/nginx/.htpasswd-tag;
	    }

	##nginx_status    location ~ /basic_status {
	##nginx_status        stub_status;
	##nginx_status        auth_basic           "Nginx Stats";
	##nginx_status        auth_basic_user_file /etc/nginx/.htpasswd;
	##nginx_status    }

	    location ~ /\.ht {
	        deny  all;
	    }
	}
	END
}



proxy_server() {
	cat >>/etc/nginx/conf.d/proxy_$n.conf <<-END
	server {
	    listen       $HTTP_PORT;#
	    listen       $HTTPS_PORT ssl;
	    #server_name#

		##full_https    if (\$scheme = http) { return 301 https://\$host\$request_uri;}

	    ssl_certificate      /etc/nginx/server.crt;
	    ssl_certificate_key  /etc/nginx/server.key;
	    ssl_session_cache shared:SSL:$SSL_CACHE;
	    ssl_session_timeout  5m;
	    ssl_protocols TLSv1 TLSv1.1 TLSv1.2;
	    ssl_ciphers  HIGH:!aNULL:!MD5;
	    ssl_prefer_server_ciphers   on;

	    #alias#

	    location / {
	        proxy_pass http://proxy-lb-$n;
	        proxy_http_version 1.1;
	        proxy_read_timeout      300;
	        proxy_connect_timeout   300;
	        proxy_set_header   Connection "";
	        proxy_set_header   Host              \$proxy_host;
	        proxy_set_header   X-Real-IP         \$remote_addr;
	        proxy_set_header   X-Forwarded-Proto \$scheme;
	        proxy_set_header   X-Forwarded-For   \$proxy_add_x_forwarded_for;
	        proxy_set_header   Accept-Encoding  "";
	        sub_filter_once    off;
	        sub_filter_types   * ;
			
            #sub_filter#
	        sub_filter \$proxy_host \$host;
			
	##cache        proxy_cache cache1;
	##cache        proxy_cache_valid 200      $CACHE_TIME;
	##cache        proxy_cache_key \$host\$request_uri\$cookie_user\$scheme\$proxy_host\$uri\$is_args\$args;
	##cache        proxy_cache_use_stale  error timeout invalid_header updating http_500 http_502 http_503 http_504;
	
	##user_auth        auth_basic           "Nginx Auth";
	##user_auth        auth_basic_user_file /etc/nginx/.htpasswd-tag;
	    }

	##nginx_status    location ~ /basic_status {
	##nginx_status        stub_status;
	##nginx_status        auth_basic           "Nginx Stats";
	##nginx_status        auth_basic_user_file /etc/nginx/.htpasswd;
	##nginx_status    }

	    location ~ /\.ht {
	        deny  all;
	    }
	}
	END
}



domain_proxy() {
	cat >/etc/nginx/conf.d/domain_$n.conf <<-END
	server {
	    listen       $HTTP_PORT;#
	    listen       $HTTPS_PORT ssl;
	    #server_name#
	    server_name *.$(echo $i |awk -F% '{print $1}'); #$(echo $i |awk -F% '{print $1}')

	    ssl_certificate      /etc/nginx/server.crt;
	    ssl_certificate_key  /etc/nginx/server.key;
	    ssl_session_cache shared:SSL:$SSL_CACHE;
	    ssl_session_timeout  5m;
	    ssl_protocols TLSv1 TLSv1.1 TLSv1.2;
	    ssl_ciphers  HIGH:!aNULL:!MD5;
	    ssl_prefer_server_ciphers   on;
		
	    #rewrite#
	    #if (\$host !~* ^.*.$(echo $i |awk -F% '{print $1}')$) {return 301 https://cn.bing.com;}
	    if (\$uri = /\$host) {rewrite ^(.*)$ http://\$host/index.php;}          #t66y login jump

	    set \$domain $(echo $i |awk -F% '{print $1}');

	    location / {
            resolver $NGX_DNS;
            #domains#
            #if (\$host ~* "^(.*).$(echo $i |awk -F% '{print $1}')$") {set \$domains \$1;}
            #if (\$host ~* "^(.*)-(.*).$(echo $i |awk -F% '{print $1}')$" ) {set \$domains \$1.\$2;}
            if (\$host ~* "^(.*)$DOMAIN_TAG(.*).$(echo $i |awk -F% '{print $1}')$" ) {set \$domains \$1\$2;}	#host rule
            if (\$domains = "t66y.com" ) {charset gb2312;}                                    					#t66y charset
            
            proxy_pass http://\$domains;
            proxy_http_version 1.1;
            proxy_read_timeout      300;
            proxy_connect_timeout   300;
	        proxy_set_header   Connection "";
            proxy_set_header   Host              \$proxy_host;
            proxy_set_header   X-Real-IP         \$remote_addr;
            proxy_set_header   X-Forwarded-Proto \$scheme;
            proxy_set_header   X-Forwarded-For   \$proxy_add_x_forwarded_for;
            proxy_set_header   Accept-Encoding  "";
            sub_filter_once    off;
            sub_filter_types   * ;
			
            #sub_filter#
            sub_filter https:// http://;
            sub_filter .ytimg.com .yt${DOMAIN_TAG}img.com.\$domain;
            sub_filter .googlevideo.com .goog${DOMAIN_TAG}levideo.com.\$domain;
            sub_filter .ggpht.com .gg${DOMAIN_TAG}pht.com.\$domain;
            sub_filter .twimg.com .tw${DOMAIN_TAG}img.com.\$domain;
            sub_filter .fbcdn.net .fb${DOMAIN_TAG}cdn.net.\$domain;
            sub_filter .tumblr.com .tu${DOMAIN_TAG}mblr.com.\$domain;
            sub_filter \$proxy_host \$host;
			
	##cache        proxy_cache cache1;
	##cache        proxy_cache_valid 200      $CACHE_TIME;
	##cache        proxy_cache_key \$host\$request_uri\$cookie_user\$scheme\$proxy_host\$uri\$is_args\$args;
	##cache        proxy_cache_use_stale  error timeout invalid_header updating http_500 http_502 http_503 http_504;
			
	##user_auth        auth_basic           "Nginx Auth";
	##user_auth        auth_basic_user_file /etc/nginx/.htpasswd-tag;
	    }

	##nginx_status    location ~ /basic_status {
	##nginx_status        stub_status;
	##nginx_status        auth_basic           "Nginx Stats";
	##nginx_status        auth_basic_user_file /etc/nginx/.htpasswd;
	##nginx_status    }
			
            error_page   500 502 503 504  /50x.html;
            location = /50x.html {return 301 https://cn.bing.com;}
	}
	END
}



http_other() {
	for i in $(echo $i |awk -F% '{print $2}' |sed 's/,/\n/g'); do
		#别名目录
		if [ -n "$(echo $i |grep 'alias=' |grep '|')" ]; then
			alias="$(echo $i |awk -F= '{print$2}' |awk -F'|' '{print $1}')"
			
			sed -i '/#alias#/ a \    location '$alias' {\n\        alias '$(echo $i |awk -F= '{print$2}' |awk -F'|' '{print $2}')';\n\    }\n' /etc/nginx/conf.d/${project_name}_$n.conf 
		fi
		
		#网站根目录
		if [ -n "$(echo $i |grep 'root=')" ]; then
			root="$(echo $i |grep 'root=' |awk -F= '{print $2}')"
			
			sed -i 's@html;@html/'$root';@' /etc/nginx/conf.d/${project_name}_$n.conf
			sed -i 's@$fastcgi_script_name@/'$root'$fastcgi_script_name@' /etc/nginx/conf.d/${project_name}_$n.conf
		fi
		
		#HTTP端口
		if [ -n "$(echo $i |grep 'http_port=')" ]; then
			http="$(echo $i |grep 'http_port=' |awk -F= '{print $2}')"
			
			sed -i 's/'$HTTP_PORT';#/'$http';/' /etc/nginx/conf.d/${project_name}_$n.conf
		fi
		
		#HTTPS端口
		if [ -n "$(echo $i |grep 'https_port=')" ]; then
			https="$(echo $i |grep 'https_port=' |awk -F= '{print $2}')"
			
			sed -i 's/'$HTTPS_PORT' ssl;/'$https' ssl;/' /etc/nginx/conf.d/${project_name}_$n.conf
		fi
		
		#SSL证书
		if [ -n "$(echo $i |grep 'crt_key=' |grep '|')" ]; then
			crt="$(echo $i |grep 'crt_key=' |awk -F= '{print $2}' |awk -F'|' '{print $1}')"
			key="$(echo $i |grep 'crt_key=' |awk -F= '{print $2}' |awk -F'|' '{print $2}')"
			
			sed -i 's/server.crt;/'$crt';/' /etc/nginx/conf.d/${project_name}_$n.conf
			sed -i 's/server.key;/'$key';/' /etc/nginx/conf.d/${project_name}_$n.conf
		fi
		
		#HTTP2
		if [ -n "$(echo $i |grep 'http2=')" ]; then
			sed -i 's/ssl;/ssl http2;/' /etc/nginx/conf.d/${project_name}_$n.conf
		fi
		
		#全站HTTPS
		if [ -n "$(echo $i |grep 'full_https=')" ]; then
			sed -i 's/##full_https//' /etc/nginx/conf.d/${project_name}_$n.conf
		fi
		
		#字符集
		if [ -n "$(echo $i |grep 'charset=')" ]; then
			charset="$(echo $i |grep 'charset=' |awk -F= '{print $2}')"
			
			sed -i '/#alias#/ i \    charset '$charset';/' /etc/nginx/conf.d/${project_name}_$n.conf
		fi
		
		#启用缓存
		if [ -n "$(echo $i |grep 'cache=')" ]; then
			sed -i 's/##cache//g' /etc/nginx/conf.d/${project_name}_$n.conf
		fi
		
		#上游主机头
		if [ -n "$(echo $i |grep 'header=')" ]; then
			header="$(echo $i |grep 'header=' |awk -F= '{print $2}')"
			
			sed -i 's/'$ngx_header';/'$header';/' /etc/nginx/conf.d/${project_name}_$n.conf
		fi
		
		#负载均衡
		if [ -n "$(echo $i |grep 'http_lb=')" ]; then
			http_lb="$(echo $i |grep 'lb=' |awk -F= '{print $2}')"
		
			if [ "$http_lb" == "ip_hash" ]; then
				sed -i '/upstream '$project_name'-lb-'$n'/ a \        ip_hash;' /etc/nginx/nginx.conf
			fi
		
			if [ "$http_lb" == "hash" ]; then
				sed -i '/upstream '$project_name'-lb-'$n'/ a \        hash $remote_addr consistent;' /etc/nginx/nginx.conf
			fi
		
			if [ "$http_lb" == "least_conn" ]; then
				sed -i '/upstream '$project_name'-lb-'$n'/ a \        least_conn;' /etc/nginx/nginx.conf
			fi
		fi
		
		#上游HTTPS
		if [ -n "$(echo $i |grep 'backend_https=')" ]; then
			sed -i 's/proxy_pass http/proxy_pass https/g' /etc/nginx/conf.d/${project_name}_$n.conf
		fi
		
		#DNS
		if [ -n "$(echo $i |grep 'dns=')" ]; then
			dns="$(echo $i |grep 'dns=' |awk -F= '{print $2}')"
			
			sed -i 's/'$NGX_DNS';/'$';/g' /etc/nginx/conf.d/${project_name}_$n.conf
		fi
		
		#域名混淆字符
		if [ -n "$(echo $i |grep 'tag=')" ]; then
			tag="$(echo $i |grep 'tag=' |awk -F= '{print $2}')"
			
			sed -i 's/'$DOMAIN_TAG'/'$tag'/g' /etc/nginx/conf.d/${project_name}_$n.conf
		fi
		
		#错误跳转
		if [ -n "$(echo $i |grep 'error=')" ]; then
			error="$(echo $i |grep 'error=' |awk -F= '{print $2}')"
			
			sed -i 's@'$EOORO_JUMP'@'$error'@' /etc/nginx/conf.d/${project_name}_$n.conf
		fi
		
		#用户认证
		if [ -n "$(echo $i |grep 'auth=' |grep '|')" ]; then
			user="$(echo $i |grep 'auth=' |awk -F= '{print $2}' |awk -F'|' '{print $1}')"
			pass="$(echo $i |grep 'auth=' |awk -F= '{print $2}' |awk -F'|' '{print $2}')"
			
			echo "$user:$(openssl passwd -apr1 $pass)" > /etc/nginx/.htpasswd-${project_name}_$n
			echo "Nginx user AND password: $user  $pass"
			
			sed -i 's/##user_auth//g' /etc/nginx/conf.d/${project_name}_$n.conf
			sed -i 's/htpasswd-tag/htpasswd-'$project_name'_'$n'/' /etc/nginx/conf.d/${project_name}_$n.conf
		fi
		
		#字符串替换
		if [ -n "$(echo $i |grep 'filter=' |grep '|')" ]; then
			sub_s="$(echo $i |grep 'filter=' |gawk -F= '{print $2}' |awk -F'|' '{print $1}')"
			sub_d="$(echo $i |grep 'filter=' |gawk -F= '{print $2}' |awk -F'|' '{print $2}')"
			
			sed -i '/#sub_filter#/ a \        sub_filter '$sub_s'  '$sub_d';' /etc/nginx/conf.d/${project_name}_$n.conf
		fi
		
		#日志
		if [ -n "$(echo $i |grep 'log=')" ]; then
			log="$(echo $i |grep 'log=' |awk -F= '{print $2}')"
			logfile="$(grep "server_name " /etc/nginx/conf.d/${project_name}_$n.conf |awk -F# '{print $2}' |sort |head -1)"
			
			if [ "$log" == "Y" ]; then
				sed -i '/#server_name#/ i \    access_log logs/'$logfile'-access.log;' /etc/nginx/conf.d/${project_name}_$n.conf
				sed -i '/#server_name#/ i \    error_log logs/'$logfile'-error.log;' /etc/nginx/conf.d/${project_name}_$n.conf
			fi
			
			if [ "$log" == "N" ]; then
				sed -i '/#server_name#/ i \    access_log off;' /etc/nginx/conf.d/${project_name}_$n.conf
				sed -i '/#server_name#/ i \    error_log off;' /etc/nginx/conf.d/${project_name}_$n.conf
			fi 
		fi
	done
}



http_basic() {
	if [ -n "$(echo $i |grep '%')" ]; then
		echo "% yes"
		if [ -n "$(echo $i |awk -F% '{print $1}' |grep '|')" ]; then
			for x in $(echo $i |awk -F% '{print $1}' |awk -F'|' '{print $1}' |sed 's/,/\n/g'); do
				sed -i '/#server_name#/ a \    server_name '$x'; #'$x'' /etc/nginx/conf.d/${project_name}_$n.conf
			done

			if [ -n "$(echo $i |awk -F% '{print $1}' |awk -F'|' '{print $2}' |grep ",")" ]; then
				sed -i '/#upstream#/ a \    upstream '$project_name'-lb-'$n' {\n\        keepalive 20;\n\    }\n' /etc/nginx/nginx.conf

				for y in $(echo $i |awk -F% '{print $1}' |awk -F'|' '{print $2}' |sed 's/,/\n/g'); do
					sed -i '/upstream '$project_name'-lb-'$n'/ a \        server '$y';' /etc/nginx/nginx.conf
				done
			else
				sed -i 's/'$project_name'-lb-'$n'/'$(echo $i |awk -F% '{print $1}' |awk -F'|' '{print $2}')'/' /etc/nginx/conf.d/${project_name}_$n.conf
			fi
		else
			sed -i '/#server_name#/ a \    server_name localhost; #localhost' /etc/nginx/conf.d/${project_name}_$n.conf

			if [ -n "$(echo $i |awk -F% '{print $1}' |grep ",")" ]; then
				sed -i '/#upstream#/a \    upstream '$project_name'-lb-'$n' {\n\        keepalive 20;\n\    }\n' /etc/nginx/nginx.conf

				for x in $(echo $i |awk -F% '{print $1}' |sed 's/,/\n/g'); do
					sed -i '/upstream '$project_name'-lb-'$n'/ a \        server '$x';' /etc/nginx/nginx.conf
				done
			else
				sed -i 's/'$project_name'-lb-'$n'/'$(echo $i |awk -F% '{print $1}')'/' /etc/nginx/conf.d/${project_name}_$n.conf
			fi
		fi

		http_other
	else
		echo "% no"
		if [ -n "$(echo $i |grep '|')" ]; then
			for x in $(echo $i |awk -F'|' '{print $1}' |sed 's/,/\n/g'); do
				sed -i '/#server_name#/ a \    server_name '$x'; #'$x'' /etc/nginx/conf.d/${project_name}_$n.conf
			done

			if [ -n "$(echo $i |awk -F'|' '{print $2}' |grep ",")" ]; then
				sed -i '/#upstream#/ a \    upstream '$project_name'-lb-'$n' {\n\        keepalive 20;\n\    }\n' /etc/nginx/nginx.conf

				for y in $(echo $i |awk -F'|' '{print $2}' |sed 's/,/\n/g'); do
					sed -i '/upstream '$project_name'-lb-'$n'/ a \        server '$y';' /etc/nginx/nginx.conf
				done
			else
				sed -i 's/'$project_name'-lb-'$n'/'$(echo $i |awk -F'|' '{print $2}')'/' /etc/nginx/conf.d/${project_name}_$n.conf
			fi
		else
			sed -i '/#server_name#/ a \    server_name localhost; #localhost' /etc/nginx/conf.d/${project_name}_$n.conf

			if [ -n "$(echo $i |grep ",")" ]; then
				sed -i '/#upstream#/ a \    upstream '$project_name'-lb-'$n' {\n\        keepalive 20;\n\    }\n' /etc/nginx/nginx.conf

				for x in $(echo $i |sed 's/,/\n/g'); do
					sed -i '/upstream '$project_name'-lb-'$n'/ a \        server '$x';' /etc/nginx/nginx.conf
				done
			else
				sed -i 's/'$project_name'-lb-'$n'/'$i'/' /etc/nginx/conf.d/${project_name}_$n.conf
			fi
		fi
	fi
}



###start

if [ "$1" = 'nginx' ]; then
  if [ -z "$(grep "redhat.xyz" /etc/nginx/nginx.conf)" ]; then

		http_conf

		#FCGI
		if [ "$FCGI_SERVER" ]; then
			n=0
			for i in $(echo "$FCGI_SERVER" |sed 's/;/\n/g'); do
				n=$(($n+1))
				fcgi_server
				project_name="fcgi"
				ngx_header="host"
				http_basic
			done
			\rm /etc/nginx/conf.d/default.conf
		fi


		#JAVA_PHP
		if [ "$JAVA_PHP_SERVER" ]; then
			n=0
			for i in $(echo "$JAVA_PHP_SERVER" |sed 's/;/\n/g'); do
				n=$(($n+1))
				java_php_server
				project_name="java-php"
				ngx_header="host"
				http_basic
			done
			\rm /etc/nginx/conf.d/default.conf 2>/dev/null |echo
		fi


		#PROXY
		if [ "$PROXY_SERVER" ]; then
			n=0
			for i in $(echo "$PROXY_SERVER" |sed 's/;/\n/g'); do
				n=$(($n+1))
				proxy_server
				project_name="proxy"
				ngx_header="proxy_host"
				http_basic
			done
			\rm /etc/nginx/conf.d/default.conf 2>/dev/null |echo
		fi


		#DOMAIN
		if [ "$DOMAIN_PROXY" ]; then
			n=0
			for i in $(echo "$DOMAIN_PROXY" |sed 's/;/\n/g'); do
				n=$(($n+1))
				domain_proxy
				project_name="domain"
				ngx_header="proxy_host"
				http_other
			done
			\rm /etc/nginx/conf.d/default.conf 2>/dev/null |echo
		fi


		if [ "$ACCLOG_OFF" ]; then
			sed -i 's/##acclog_off//' /etc/nginx/nginx.conf
		fi

		if [ "$ERRLOG_OFF" ]; then
			sed -i 's/##errlog_off//' /etc/nginx/nginx.conf
		fi

		if [ "$DEFAULT_SERVER" ]; then
			sed -i 's/##default_server//g' /etc/nginx/conf.d/*.conf
		fi

		if [ "$NGX_USER" ]; then
			sed -i 's/##nginx_status//g' /etc/nginx/conf.d/default.conf
			echo "$NGX_USER:$(openssl passwd -apr1 $NGX_PASS)" >> /etc/nginx/.htpasswd
			echo "Nginx user AND password: $NGX_USER  $NGX_PASS"
		fi
  fi

	echo "Start ****"
	exec "$@"
else

	echo -e " 
	Example:
				docker run -d --restart always \\
				-v /docker/www:/usr/share/nginx/html \\
				-v /docker/upload:/mp4 \\
				-v /docker/key:/key \\
				-p 10080:80 \\
				-p 10443:443 \\
				-e FCGI_SERVER=<php.jiobxn.com|192.17.0.5:9000[%<Other options>]> \\
				-e JAVA_PHP_SERVER=<tomcat.jiobxn.com|192.17.0.6:8080[%<Other options>];apache.jiobxn.com|192.17.0.7[%<Other options>]> \\
				-e PROXY_SERVER=<g.jiobxn.com|www.google.co.id%backend_https=Y> \\
				-e DOMAIN_PROXY=<fqhub.com%backend_https=Y> \\
				-e DEFAULT_SERVER=<jiobxn.com> \\
				-e NGX_PASS=[jiobxn.com] \\
				-e NGX_USER=<nginx> \\
				-e NGX_CHARSET=[utf-8] \\
				-e FCGI_PATH=[/var/www] \\
				-e HTTP_PORT=[80] \\
				-e SSL_CACHE=[10m] \\
				-e HTTPS_PORT=[443] \\
				-e DOMAIN_TAG=[888] \\
				-e EOORO_JUMP=[https://cn.bing.com] \\
				-e NGX_DNS=[8.8.8.8] \\
				-e CACHE_TIME=[8h] \\
				-e CACHE_SIZE=[4g] \\
				-e CACHE_MEM=[物理内存的%10] \\
				-e ACCLOG_OFF=<Y> \\
				-e ERRLOG_OFF=<Y> \\
				   alias=</boy|/mp4> \\
				   root=<wordpress> \\
				   http_port=<8080> \\
				   https_port=<8443> \\
				   crt_key=<jiobxn.crt|jiobxn.key> \\
				   full_https=<Y> \\
				   charset=<gb2312> \\
				   cache=<Y> \\
				   header=<host> \\
				   http_lb=<ip_hash|hash|least_conn> \\
				   backend_https=<Y> \\
				   dns=<223.5.5.5> \\
				   tag=<9999> \\
				   error=<https://www.bing.com> \\
				   auth=<admin|passwd> \\
				   filter=<.google.com|.fqhub.com> \\
				   log=<N|Y> \\
				--hostname nginx \\
				--name nginx nginx
	" 
fi

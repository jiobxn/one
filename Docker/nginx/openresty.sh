#!/bin/bash
set -e

: ${NGX_PASS:="jiobxn.com"}
: ${NGX_CHARSET:="utf-8"}
: ${FCGI_PATH:="/var/www"}
: ${HTTP_PORT:="80"}
: ${HTTPS_PORT:="443"}
: ${ADDR_CACHE:="25m"}
: ${SSL_CACHE:="25m"}
: ${SSL_TIMEOUT:="10m"}
: ${DOMAIN_TAG:="888"}
: ${EOORO_JUMP:="https://cn.bing.com"}
: ${NGX_DNS="9.9.9.9"}
: ${CACHE_TIME:="10h"}
: ${CACHE_SIZE:="2g"}
: ${CACHE_MEM:="$(($(free -m |grep Mem |awk '{print $2}')*10/100))m"}
: ${KP_ETH:="$(route -n |awk '$1=="0.0.0.0"{print $NF}')"}
: ${KP_VRID:="77"}
: ${KP_PASS:="Newpa55"}
: ${WORKER_PROC:="2"}
: ${REMOTE_ADDR:="remote_addr"}


##-----------------HTTP----------------

http_conf() {
	echo "Initialize nginx"

	#global
	cat >/usr/local/openresty/nginx/conf/nginx.conf <<-END
	#redhat.xyz
	user  nobody;
	worker_processes  $WORKER_PROC;
	
	error_log  /usr/local/openresty/nginx/logs/error.log warn;
	pid        /var/run/nginx.pid;
	
	##waf	include /opt/verynginx/verynginx/nginx_conf/in_external.conf;
	
	events {
	    worker_connections  $(($WORKER_PROC*10240));
	}
	
	http {
	    include       mime.types;
	    default_type  application/octet-stream;
		
	    log_format  main  '\$remote_addr - \$remote_user [\$time_local] "\$request" '
	        '\$status \$body_bytes_sent "\$http_referer" '
	        '"\$http_user_agent" \$http_x_forwarded_for';
	    access_log  /usr/local/openresty/nginx/logs/access.log  main;
		
	    sendfile        on;
	    tcp_nopush      on;
	    keepalive_timeout  70;
	    server_names_hash_bucket_size 512;
		
	##acclog_off    access_log off;
	##errlog_off    error_log off;
		
	    charset $NGX_CHARSET;
	    client_max_body_size 0;
	    client_body_buffer_size 128k;
	    autoindex on;
	    server_tokens off;
		
	    proxy_cache_path /tmp/proxy_cache levels=1:2 keys_zone=cache1:$CACHE_MEM inactive=$CACHE_TIME max_size=$CACHE_SIZE;
	    fastcgi_cache_path /tmp/fastcgi_cache levels=1:2 keys_zone=cache2:$CACHE_MEM inactive=$CACHE_TIME max_size=$CACHE_SIZE;
	    
	    gunzip on;
	    gzip  on;
	    gzip_comp_level 6;
	    gzip_proxied any;
	    gzip_types text/plain text/css text/xml text/javascript application/json application/x-javascript application/javascript application/xml application/xml+rss application/x-httpd-php image/jpeg image/gif image/png;
	    gzip_vary on;
		
	##waf    include /opt/verynginx/verynginx/nginx_conf/in_http_block.conf;
		
	    #upstream#
		
	    include /usr/local/openresty/nginx/conf/vhost/*.conf;
		
	##default_server    server {
	##default_server            listen       $HTTP_PORT  default_server;
	##default_server            listen       [::]:$HTTP_PORT  default_server;
	##default_server            server_name  _;
	##default_server            rewrite ^(.*) http://$DEFAULT_SERVER:$HTTP_PORT permanent;
	##default_server    }
	}
	END


	#default
	cat >/usr/local/openresty/nginx/conf/vhost/default.conf <<-END
	server {
	    listen       $HTTP_PORT ;#
	    listen       $HTTPS_PORT ssl;
	    listen       [::]:$HTTP_PORT ;#
	    listen       [::]:$HTTPS_PORT ssl;
	    server_name localhost;
		
	##waf    include /opt/verynginx/verynginx/nginx_conf/in_server_block.conf;
		
	    #LIMIT#
		
	    ssl_certificate      /usr/local/openresty/nginx/conf/cert/server.crt;
	    ssl_certificate_key  /usr/local/openresty/nginx/conf/cert/server.key;
	    ssl_session_cache shared:SSL:$SSL_CACHE;
	    ssl_session_timeout  $SSL_TIMEOUT;
	    ssl_protocols TLSv1 TLSv1.1 TLSv1.2 TLSv1.3;
	    ssl_ciphers  HIGH:!aNULL:!MD5;
	    ssl_prefer_server_ciphers   on;
		
	    location / {
	        root   /usr/local/openresty/nginx/html;
	        index  index.html index.htm;
	    }
		
	##nginx_status    location ~ /basic_status {
	##nginx_status        stub_status;
	##nginx_status        auth_basic           "Nginx Stats";
	##nginx_status        auth_basic_user_file /usr/local/openresty/nginx/conf/cert/.htpasswd;
	##nginx_status    }
	}
	END

	#限速,带单位
	if [ "$LIMIT_RATE" ]; then
		sed -i '/#LIMIT#/ a \    set $limit_rate '$LIMIT_RATE';' /usr/local/openresty/nginx/conf/vhost/default.conf
	fi

	#最大并发数
	if [ "$LIMIT_CONN" ]; then
		sed -i '/#upstream#/ i \    limit_conn_zone $binary_remote_addr zone=addr:'$ADDR_CACHE';' /usr/local/openresty/nginx/conf/nginx.conf
		sed -i '/#LIMIT#/ i \    limit_conn           addr '$LIMIT_CONN';' /usr/local/openresty/nginx/conf/vhost/default.conf
		sed -i '/#LIMIT#/ i \    limit_conn_log_level error;' /usr/local/openresty/nginx/conf/vhost/default.conf
		sed -i '/#LIMIT#/ i \    limit_conn_status    403;' /usr/local/openresty/nginx/conf/vhost/default.conf
	fi

	#最大请求率
	if [ "$LIMIT_REQ" ]; then
		sed -i '/#upstream#/ i \    limit_req_zone $binary_remote_addr zone=one:'$ADDR_CACHE' rate='$LIMIT_REQ'r/s;' /usr/local/openresty/nginx/conf/nginx.conf
		sed -i '/#LIMIT#/ i \    limit_req            zone=one burst='$LIMIT_REQ' nodelay;' /usr/local/openresty/nginx/conf/vhost/default.conf
		sed -i '/#LIMIT#/ i \    limit_req_log_level  error;' /usr/local/openresty/nginx/conf/vhost/default.conf
		sed -i '/#LIMIT#/ i \    limit_req_status     403;' /usr/local/openresty/nginx/conf/vhost/default.conf
	fi
}



fcgi_server() {
	cat >/usr/local/openresty/nginx/conf/vhost/fcgi_$n.conf <<-END
	server {
	    listen       $HTTP_PORT ;#
	    listen       $HTTPS_PORT ssl;
	    listen       [::]:$HTTP_PORT ;#
	    listen       [::]:$HTTPS_PORT ssl;
	    #server_name#
		
	##waf    include /opt/verynginx/verynginx/nginx_conf/in_server_block.conf;
		
	##full_https    if (\$scheme = http) { return 301 https://\$host\$request_uri;}
	    
	    ssl_certificate      /usr/local/openresty/nginx/conf/cert/server.crt;
	    ssl_certificate_key  /usr/local/openresty/nginx/conf/cert/server.key;
	    ssl_session_cache shared:SSL:$SSL_CACHE;
	    ssl_session_timeout  $SSL_TIMEOUT;
	    ssl_protocols TLSv1 TLSv1.1 TLSv1.2 TLSv1.3;
	    ssl_ciphers  HIGH:!aNULL:!MD5;
	    ssl_prefer_server_ciphers   on;
		
	    location / {
	        root   /usr/local/openresty/nginx/html;
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
	##user_auth        auth_basic_user_file /usr/local/openresty/nginx/conf/cert/.htpasswd-tag;
	    }
		
	##nginx_status    location ~ /basic_status {
	##nginx_status        stub_status;
	##nginx_status        auth_basic           "Nginx Stats";
	##nginx_status        auth_basic_user_file /usr/local/openresty/nginx/conf/cert/.htpasswd;
	##nginx_status    }
	}
	END
}



java_php_server() {
	cat >/usr/local/openresty/nginx/conf/vhost/java-php_$n.conf <<-END
	server {
	    listen       $HTTP_PORT ;#
	    listen       $HTTPS_PORT ssl;
	    listen       [::]:$HTTP_PORT ;#
	    listen       [::]:$HTTPS_PORT ssl;
	    #server_name#
		
	##waf    include /opt/verynginx/verynginx/nginx_conf/in_server_block.conf;
		
	##full_https    if (\$scheme = http) { return 301 https://\$host\$request_uri;}
	    
	    ssl_certificate      /usr/local/openresty/nginx/conf/cert/server.crt;
	    ssl_certificate_key  /usr/local/openresty/nginx/conf/cert/server.key;
	    ssl_session_cache shared:SSL:$SSL_CACHE;
	    ssl_session_timeout  $SSL_TIMEOUT;
	    ssl_protocols TLSv1 TLSv1.1 TLSv1.2 TLSv1.3;
	    ssl_ciphers  HIGH:!aNULL:!MD5;
	    ssl_prefer_server_ciphers   on;
		
	    location / {
	        root   /usr/local/openresty/nginx/html;
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
	##user_auth        auth_basic_user_file /usr/local/openresty/nginx/conf/cert/.htpasswd-tag;
	    }
		
	##nginx_status    location ~ /basic_status {
	##nginx_status        stub_status;
	##nginx_status        auth_basic           "Nginx Stats";
	##nginx_status        auth_basic_user_file /usr/local/openresty/nginx/conf/cert/.htpasswd;
	##nginx_status    }
	}
	END
}



proxy_server() {
	cat >>/usr/local/openresty/nginx/conf/vhost/proxy_$n.conf <<-END
	server {
	    listen       $HTTP_PORT ;#
	    listen       $HTTPS_PORT ssl;
	    listen       [::]:$HTTP_PORT ;#
	    listen       [::]:$HTTPS_PORT ssl;
	    #server_name#
		
	##waf    include /opt/verynginx/verynginx/nginx_conf/in_server_block.conf;
		
	    ##full_https    if (\$scheme = http) { return 301 https://\$host\$request_uri;}
		
	    ssl_certificate      /usr/local/openresty/nginx/conf/cert/server.crt;
	    ssl_certificate_key  /usr/local/openresty/nginx/conf/cert/server.key;
	    ssl_session_cache shared:SSL:$SSL_CACHE;
	    ssl_session_timeout  $SSL_TIMEOUT;
	    ssl_protocols TLSv1 TLSv1.1 TLSv1.2 TLSv1.3;
	    ssl_ciphers  HIGH:!aNULL:!MD5;
	    ssl_prefer_server_ciphers   on;
		
	    #alias#
		
	    location / {
	        #PASS#
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
	##user_auth        auth_basic_user_file /usr/local/openresty/nginx/conf/cert/.htpasswd-tag;
	    }
		
	##nginx_status    location ~ /basic_status {
	##nginx_status        stub_status;
	##nginx_status        auth_basic           "Nginx Stats";
	##nginx_status        auth_basic_user_file /usr/local/openresty/nginx/conf/cert/.htpasswd;
	##nginx_status    }
	}
	END
}



domain_proxy() {
	cat >/usr/local/openresty/nginx/conf/vhost/domain_$n.conf <<-END
	server {
	    listen       $HTTP_PORT ;#
	    listen       $HTTPS_PORT ssl;
	    listen       [::]:$HTTP_PORT ;#
	    listen       [::]:$HTTPS_PORT ssl;
	    #server_name#
		
	##waf    include /opt/verynginx/verynginx/nginx_conf/in_server_block.conf;
		
	    server_name *.$(echo $i |awk -F^ '{print $1}'); #$(echo $i |awk -F^ '{print $1}')
	    
	    ssl_certificate      /usr/local/openresty/nginx/conf/cert/server.crt;
	    ssl_certificate_key  /usr/local/openresty/nginx/conf/cert/server.key;
	    ssl_session_cache shared:SSL:$SSL_CACHE;
	    ssl_session_timeout  $SSL_TIMEOUT;
	    ssl_protocols TLSv1 TLSv1.1 TLSv1.2 TLSv1.3;
	    ssl_ciphers  HIGH:!aNULL:!MD5;
	    ssl_prefer_server_ciphers   on;
		
	    #rewrite#
	    #if (\$host !~* ^.*.$(echo $i |awk -F^ '{print $1}')$) {return 301 https://cn.bing.com;}
	    if (\$uri = /\$host) {rewrite ^(.*)$ https://\$host/index.php;}          #t66y login jump
	    
		set \$domain $(echo $i |awk -F^ '{print $1}');
	    
	    location / {
            resolver $NGX_DNS;
            #domains#
            #if (\$host ~* "^(.*).$(echo $i |awk -F^ '{print $1}')$") {set \$domains \$1;}
            #if (\$host ~* "^(.*)-(.*).$(echo $i |awk -F^ '{print $1}')$" ) {set \$domains \$1.\$2;}
            if (\$host ~* "^(.*)$DOMAIN_TAG(.*).$(echo $i |awk -F^ '{print $1}')$" ) {set \$domains \$1\$2;}	#host rule
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
            sub_filter https:// \$scheme://;
            sub_filter .ytimg.com .yt${DOMAIN_TAG}img.com.\$domain;
            sub_filter .googlevideo.com .goog${DOMAIN_TAG}levideo.com.\$domain;
            sub_filter .ggpht.com .gg${DOMAIN_TAG}pht.com.\$domain;
            sub_filter .twimg.com .tw${DOMAIN_TAG}img.com.\$domain;
            sub_filter .fbcdn.net .fb${DOMAIN_TAG}cdn.net.\$domain;
            sub_filter .tumblr.com .tu${DOMAIN_TAG}mblr.com.\$domain;
	    sub_filter .youtube.com .you${DOMAIN_TAG}tube.com.\$domain;
	    sub_filter .google.com .go${DOMAIN_TAG}ogle.com.\$domain;
	    sub_filter .doubleclick.net .dou${DOMAIN_TAG}bleclick.net.\$domain;
	    sub_filter .amazonaws.com .amaz${DOMAIN_TAG}onaws.com.\$domain;
            sub_filter \$proxy_host \$host;
			
	##cache        proxy_cache cache1;
	##cache        proxy_cache_valid 200      $CACHE_TIME;
	##cache        proxy_cache_key \$host\$request_uri\$cookie_user\$scheme\$proxy_host\$uri\$is_args\$args;
	##cache        proxy_cache_use_stale  error timeout invalid_header updating http_500 http_502 http_503 http_504;
			
	##user_auth        auth_basic           "Nginx Auth";
	##user_auth        auth_basic_user_file /usr/local/openresty/nginx/conf/cert/.htpasswd-tag;
	    }
		
	##nginx_status    location ~ /basic_status {
	##nginx_status        stub_status;
	##nginx_status        auth_basic           "Nginx Stats";
	##nginx_status        auth_basic_user_file /usr/local/openresty/nginx/conf/cert/.htpasswd;
	##nginx_status    }
			
            error_page   500 502 503 504  /50x.html;
            location = /50x.html {return 301 https://cn.bing.com;}
	}
	END
}



http_other() {
	for i in $(echo $i |awk -F^ '{print $2}' |sed 's/,/\n/g'); do
		#WebSocket
		if [ -n "$(echo $i |grep 'ws=' |grep '|')" ]; then
			path="$(echo $i |awk -F= '{print$2}' |awk -F'|' '{print $1}')"
			ws="$(echo $i |awk -F= '{print$2}' |awk -F'|' '{print $2}')"
			
			sed -i '/#alias#/ a \    location '$path' {\n\        proxy_pass http://'$ws';\n\        proxy_http_version 1.1;\n\        proxy_set_header Upgrade \$http_upgrade;\n\        proxy_set_header Connection "upgrade";\n\    }\n' /usr/local/openresty/nginx/conf/vhost/${project_name}_$n.conf 
		fi
		
		#WebSocket s
		if [ -n "$(echo $i |grep 'wss=' |grep '|')" ]; then
			path="$(echo $i |awk -F= '{print$2}' |awk -F'|' '{print $1}')"
			ws="$(echo $i |awk -F= '{print$2}' |awk -F'|' '{print $2}')"
			
			sed -i '/#alias#/ a \    location '$path' {\n\        proxy_pass https://'$ws';\n\        proxy_http_version 1.1;\n\        proxy_set_header Upgrade \$http_upgrade;\n\        proxy_set_header Connection "upgrade";\n\    }\n' /usr/local/openresty/nginx/conf/vhost/${project_name}_$n.conf 
		fi
		
		#别名目录
		if [ -n "$(echo $i |grep 'alias=' |grep '|')" ]; then
			alias="$(echo $i |awk -F= '{print$2}' |awk -F'|' '{print $1}')"
			
			sed -i '/#alias#/ a \    location '$alias' {\n\        alias '$(echo $i |awk -F= '{print$2}' |awk -F'|' '{print $2}')';\n\    }\n' /usr/local/openresty/nginx/conf/vhost/${project_name}_$n.conf 
		fi
		
		#网站根目录
		if [ -n "$(echo $i |grep 'root=')" ]; then
			root="$(echo $i |grep 'root=' |awk -F= '{print $2}')"
			
			sed -i 's@html;@html/'$root';@' /usr/local/openresty/nginx/conf/vhost/${project_name}_$n.conf
			sed -i 's@$fastcgi_script_name@/'$root'$fastcgi_script_name@' /usr/local/openresty/nginx/conf/vhost/${project_name}_$n.conf
		fi
		
		#HTTP端口
		if [ -n "$(echo $i |grep 'http_port=')" ]; then
			http="$(echo $i |grep 'http_port=' |awk -F= '{print $2}')"
			
			sed -i 's/'$HTTP_PORT' ;#/'$http' ;/' /usr/local/openresty/nginx/conf/vhost/${project_name}_$n.conf
		fi
		
		#HTTPS端口
		if [ -n "$(echo $i |grep 'https_port=')" ]; then
			https="$(echo $i |grep 'https_port=' |awk -F= '{print $2}')"
			
			sed -i 's/'$HTTPS_PORT' ssl;/'$https' ssl;/' /usr/local/openresty/nginx/conf/vhost/${project_name}_$n.conf
		fi
		
		#SSL证书
		if [ -n "$(echo $i |grep 'crt_key=' |grep '|')" ]; then
			crt="$(echo $i |grep 'crt_key=' |awk -F= '{print $2}' |awk -F'|' '{print $1}')"
			key="$(echo $i |grep 'crt_key=' |awk -F= '{print $2}' |awk -F'|' '{print $2}')"
			
			sed -i 's/server.crt;/'$crt';/' /usr/local/openresty/nginx/conf/vhost/${project_name}_$n.conf
			sed -i 's/server.key;/'$key';/' /usr/local/openresty/nginx/conf/vhost/${project_name}_$n.conf
		fi
		
		#HTTP2
		if [ -n "$(echo $i |grep 'http2=')" ]; then
			sed -i 's/ssl;/ssl http2;/' /usr/local/openresty/nginx/conf/vhost/${project_name}_$n.conf
		fi
		
		#全站HTTPS
		if [ -n "$(echo $i |grep 'full_https=')" ]; then
			sed -i 's/##full_https//' /usr/local/openresty/nginx/conf/vhost/${project_name}_$n.conf
		fi
		
		#字符集
		if [ -n "$(echo $i |grep 'charset=')" ]; then
			charset="$(echo $i |grep 'charset=' |awk -F= '{print $2}')"
			
			sed -i '/#alias#/ i \    charset '$charset';' /usr/local/openresty/nginx/conf/vhost/${project_name}_$n.conf
		fi
		
		#启用缓存
		if [ -n "$(echo $i |grep 'cache=')" ]; then
			sed -i 's/##cache//g' /usr/local/openresty/nginx/conf/vhost/${project_name}_$n.conf
		fi
		
		#上游主机头
		if [ -n "$(echo $i |grep 'header=')" ]; then
			header="$(echo $i |grep 'header=' |awk -F= '{print $2}')"
			
			sed -i 's/'$ngx_header';/'$header';/' /usr/local/openresty/nginx/conf/vhost/${project_name}_$n.conf
		fi
		
		#负载均衡
		if [ -n "$(echo $i |grep 'http_lb=')" ]; then
			http_lb="$(echo $i |grep 'lb=' |awk -F= '{print $2}')"
		
			if [ "$http_lb" == "ip_hash" ]; then
				sed -i '/upstream '$project_name'-lb-'$n'/ a \        ip_hash;' /usr/local/openresty/nginx/conf/nginx.conf
			fi
		
			if [ "$http_lb" == "hash" ]; then
				sed -i '/upstream '$project_name'-lb-'$n'/ a \        hash $remote_addr consistent;' /usr/local/openresty/nginx/conf/nginx.conf
			fi
		
			if [ "$http_lb" == "least_conn" ]; then
				sed -i '/upstream '$project_name'-lb-'$n'/ a \        least_conn;' /usr/local/openresty/nginx/conf/nginx.conf
			fi
		fi
		
		#上游HTTPS
		if [ -n "$(echo $i |grep 'backend_https=')" ]; then
			sed -i 's/proxy_pass http/proxy_pass https/g' /usr/local/openresty/nginx/conf/vhost/${project_name}_$n.conf
		fi
		
		#DNS
		if [ -n "$(echo $i |grep 'dns=')" ]; then
			dns="$(echo $i |grep 'dns=' |awk -F= '{print $2}')"
			
			sed -i 's/'$NGX_DNS';/'$';/g' /usr/local/openresty/nginx/conf/vhost/${project_name}_$n.conf
		fi
		
		#域名混淆字符
		if [ -n "$(echo $i |grep 'tag=')" ]; then
			tag="$(echo $i |grep 'tag=' |awk -F= '{print $2}')"
			
			sed -i 's/'$DOMAIN_TAG'/'$tag'/g' /usr/local/openresty/nginx/conf/vhost/${project_name}_$n.conf
		fi
		
		#错误跳转
		if [ -n "$(echo $i |grep 'error=')" ]; then
			error="$(echo $i |grep 'error=' |awk -F= '{print $2}')"
			
			sed -i 's@'$EOORO_JUMP'@'$error'@' /usr/local/openresty/nginx/conf/vhost/${project_name}_$n.conf
		fi
		
		#用户认证
		if [ -n "$(echo $i |grep 'auth=' |grep '|')" ]; then
			user="$(echo $i |grep 'auth=' |awk -F= '{print $2}' |awk -F'|' '{print $1}')"
			pass="$(echo $i |grep 'auth=' |awk -F= '{print $2}' |awk -F'|' '{print $2}')"
			
			echo "$user:$(openssl passwd -apr1 $pass)" > /usr/local/openresty/nginx/conf/cert/.htpasswd-${project_name}_$n
			echo "Nginx user AND password: $user  $pass"
			
			sed -i 's/##user_auth//g' /usr/local/openresty/nginx/conf/vhost/${project_name}_$n.conf
			sed -i 's/htpasswd-tag/htpasswd-'$project_name'_'$n'/' /usr/local/openresty/nginx/conf/vhost/${project_name}_$n.conf
		fi
		
		#字符串替换
		if [ -n "$(echo $i |grep 'filter=' |grep '|')" ]; then
			for x in $(echo $i |grep 'filter=' |gawk -F= '{print $2}' |sed 's/&/\n/g'); do
				sub_s="$(echo $x |awk -F'|' '{print $1}')"
				sub_d="$(echo $x |awk -F'|' '{print $2}')"
			
				sed -i '/#sub_filter#/ a \        sub_filter '$sub_s'  '$sub_d';' /usr/local/openresty/nginx/conf/vhost/${project_name}_$n.conf
			done
		fi

		#限速,带单位
		if [ -n "$(echo $i |grep 'limit_rate=')" ]; then
			limit_rate="$(echo $i |grep 'limit_rate=' |awk -F= '{print $2}')"
			
			sed -i '/#alias#/ i \    set $limit_rate '$limit_rate';' /usr/local/openresty/nginx/conf/vhost/${project_name}_$n.conf
		fi
		
		#最大并发数
		if [ -n "$(echo $i |grep 'limit_conn=')" ]; then
			limit_conn="$(echo $i |grep 'limit_conn=' |awk -F= '{print $2}')"
			
			sed -i '/#upstream#/ i \    limit_conn_zone  $binary_remote_addr zone=addr'$n':'$ADDR_CACHE';' /usr/local/openresty/nginx/conf/nginx.conf
			sed -i '/#alias#/ i \        limit_conn_log_level error;' /usr/local/openresty/nginx/conf/vhost/${project_name}_$n.conf
			sed -i '/#alias#/ i \        limit_conn_status    403;' /usr/local/openresty/nginx/conf/vhost/${project_name}_$n.conf
			sed -i '/#alias#/ i \        limit_conn           addr'$n' '$limit_conn';' /usr/local/openresty/nginx/conf/vhost/${project_name}_$n.conf
		fi
		
		#最大请求率
		if [ -n "$(echo $i |grep 'limit_req=')" ]; then
			limit_req="$(echo $i |grep 'limit_req=' |awk -F= '{print $2}')"
			
			sed -i '/#upstream#/ i \    limit_req_zone  $binary_remote_addr zone=one'$n':'$ADDR_CACHE' rate='$limit_req'r/s;' /usr/local/openresty/nginx/conf/nginx.conf
			sed -i '/#alias#/ i \        limit_req_log_level  error;' /usr/local/openresty/nginx/conf/vhost/${project_name}_$n.conf
			sed -i '/#alias#/ i \        limit_req_status     403;' /usr/local/openresty/nginx/conf/vhost/${project_name}_$n.conf
			sed -i '/#alias#/ i \        limit_req            zone=one'$n' burst='$limit_req' nodelay;' /usr/local/openresty/nginx/conf/vhost/${project_name}_$n.conf
		fi
		
		#日志
		if [ -n "$(echo $i |grep 'log=')" ]; then
			log="$(echo $i |grep 'log=' |awk -F= '{print $2}')"
			logfile="$(grep "server_name " /usr/local/openresty/nginx/conf/vhost/${project_name}_$n.conf |awk -F# '{print $2}' |sort |head -1)"
			
			if [ "$log" == "Y" ]; then
				sed -i '/#server_name#/ i \    access_log logs\/'$logfile'-access.log main;' /usr/local/openresty/nginx/conf/vhost/${project_name}_$n.conf
				sed -i '/#server_name#/ i \    error_log logs\/'$logfile'-error.log;' /usr/local/openresty/nginx/conf/vhost/${project_name}_$n.conf
			fi
			
			if [ "$log" == "N" ]; then
				sed -i '/#server_name#/ i \    access_log off;' /usr/local/openresty/nginx/conf/vhost/${project_name}_$n.conf
				sed -i '/#server_name#/ i \    error_log off;' /usr/local/openresty/nginx/conf/vhost/${project_name}_$n.conf
			fi 
		fi
		
                #测试地址
                if [ -n "$(echo $i |grep 'testip=' |grep '&')" ]; then
                        sip="$(echo $i |grep 'testip=' |awk -F= '{print $2}' |awk -F'&' '{print $1}')"
                        dip="$(echo $i |grep 'testip=' |awk -F= '{print $2}' |awk -F'&' '{print $2}')"
		
                        sed -i '/#PASS#/a \        if ($'$REMOTE_ADDR' ~ "'$sip'"){proxy_pass http://'$dip';break;}' /usr/local/openresty/nginx/conf/vhost/${project_name}_$n.conf
                fi
	done
}



http_waf(){
	#ipset
	cat >/ipset.sh <<-END
	#!/bin/bash
	[ -z "\`ipset list blacklist 2>/dev/null |grep -w blacklist\`" ] && ipset create blacklist hash:net maxelem 1000000
	[ -z "\`ipset list whitelist 2>/dev/null |grep -w whitelist\`" ] && ipset create whitelist hash:net maxelem 1000000
	if [ -f /key/all.ipset ]; then
		[ "\$(ipset list |egrep ^[0-9] |wc -l)" -lt "\$(wc -l /key/all.ipset |awk '{print \$1}')" ] && ipset -R < /key/all.ipset
	fi
	END

	#iptables
	for i in $(awk '$1=="listen"{print $2}' /usr/local/openresty/nginx/conf/vhost/* |grep -v : |sort |uniq); do
		echo '[ -z "$(iptables -S |grep -w WAFd'$i')" ] && iptables -I INPUT -m set --match-set blacklist src -p tcp --destination-port '$i' -m comment --comment WAFd'$i' -j DROP' >>/ipset.sh 
		echo '[ -z "$(iptables -S |grep -w WAFa'$i')" ] && iptables -I INPUT -m set --match-set whitelist src -p tcp --destination-port '$i' -m comment --comment WAFa'$i' -j ACCEPT' >>/ipset.sh
	done

	#cron
	cat >/deny.sh <<-END
	#!/bin/bash
	s_user=verynginx
	encrypt_seed=\$(awk -F\" 'NR==2{print \$4}' /opt/verynginx/verynginx/configs/encrypt_seed.json)
	verynginx_session=\$(echo -n "\${encrypt_seed}\${s_user}" |md5sum |awk '{print \$1}')
	awk -F- '{print \$1}' /usr/local/openresty/nginx/logs/frequency.log |awk '{print \$1,\$NF}' |sed 's/,//g' |sort |uniq -c >/tmp/.all
	
	for i in \$(awk '{print \$2}' /tmp/.all |sort |uniq); do
	    if [ -z "\$(grep -w \$i /usr/local/openresty/verynginx/configs/*)" ]; then
	        s_encode=\$(urlencode '{"enable": true,"ip": "'\$i'","matcher": "all_request","action": "block","code": "451","custom_response": false}')
	        s_base64=\$(echo "\$s_encode" | base64 -w 0)
	        #REQ1#
	    fi
		#
	    if [ -n "\$(ipset test blacklist \$i 2>&1 |grep -w NOT)" ]; then
	        #REQ2#
	    fi
	done
	curl -s http://127.0.0.1:$HTTP_PORT/verynginx/blackwhite/dump -X POST --header "Cookie:verynginx_user=\${s_user}; verynginx_session=\$verynginx_session"
	END

	#add
	for i in $(echo "$WAF_REQ" |sed 's/;/\n/g'); do
		if [ -n "$(echo $i |grep ,)" ]; then
			code=$(echo $i |awk -F , '{print $1}')
			max=$(echo $i |awk -F , '{print $2}')
			sed -i '/#REQ1#/ a \        if [ -n "$(awk '"'"'$2=="'"'"'$i'"'"'" && $3=="'$code'" && \$1>'$max'{print \$2}'"'"' \/tmp\/.all)" ];then\n            curl -s http://127.0.0.1:'$HTTP_PORT'/verynginx/blackwhite -X POST -d "config=\$s_base64" --header "Cookie:verynginx_user=\${s_user}; verynginx_session=\$verynginx_session"\n        fi'  /deny.sh
			sed -i '/#REQ2#/ a \        if [ -n "$(awk '"'"'$2=="'"'"'$i'"'"'" && $3=="'$code'" && \$1>'$max'{print \$2}'"'"' \/tmp\/.all)" ];then\n            ipset add blacklist $i\n            echo "add blacklist $i" >>\/key\/all.ipset\n        fi'  /deny.sh
		fi
	done

	chmod +x /*.sh
	echo "* * * * * . /etc/profile; /bin/sh /deny.sh" >/var/spool/cron/root
}



http_basic() {
	if [ -n "$(echo $i |grep '^')" ]; then
		echo "^ yes"
		if [ -n "$(echo $i |awk -F^ '{print $1}' |grep '|')" ]; then
			for x in $(echo $i |awk -F^ '{print $1}' |awk -F'|' '{print $1}' |sed 's/,/\n/g'); do
				sed -i '/#server_name#/ a \    server_name '$x'; #'$x'' /usr/local/openresty/nginx/conf/vhost/${project_name}_$n.conf
			done

			if [ -n "$(echo $i |awk -F^ '{print $1}' |awk -F'|' '{print $2}' |grep ",")" ]; then
				sed -i '/#upstream#/ a \    upstream '$project_name'-lb-'$n' {\n\        keepalive 20;\n\    }\n' /usr/local/openresty/nginx/conf/nginx.conf

				for y in $(echo $i |awk -F^ '{print $1}' |awk -F'|' '{print $2}' |sed 's/,/\n/g'); do
					sed -i '/upstream '$project_name'-lb-'$n'/ a \        server '$y';' /usr/local/openresty/nginx/conf/nginx.conf
				done
			else
				sed -i 's@'$project_name'-lb-'$n'@'$(echo $i |awk -F^ '{print $1}' |awk -F'|' '{print $2}')'@' /usr/local/openresty/nginx/conf/vhost/${project_name}_$n.conf
			fi
		else
			sed -i '/#server_name#/ a \    server_name localhost; #localhost' /usr/local/openresty/nginx/conf/vhost/${project_name}_$n.conf

			if [ -n "$(echo $i |awk -F^ '{print $1}' |grep ",")" ]; then
				sed -i '/#upstream#/a \    upstream '$project_name'-lb-'$n' {\n\        keepalive 20;\n\    }\n' /usr/local/openresty/nginx/conf/nginx.conf

				for x in $(echo $i |awk -F^ '{print $1}' |sed 's/,/\n/g'); do
					sed -i '/upstream '$project_name'-lb-'$n'/ a \        server '$x';' /usr/local/openresty/nginx/conf/nginx.conf
				done
			else
				sed -i 's@'$project_name'-lb-'$n'@'$(echo $i |awk -F^ '{print $1}')'@' /usr/local/openresty/nginx/conf/vhost/${project_name}_$n.conf
			fi
		fi

		http_other
	else
		echo "^ no"
		if [ -n "$(echo $i |grep '|')" ]; then
			for x in $(echo $i |awk -F'|' '{print $1}' |sed 's/,/\n/g'); do
				sed -i '/#server_name#/ a \    server_name '$x'; #'$x'' /usr/local/openresty/nginx/conf/vhost/${project_name}_$n.conf
			done

			if [ -n "$(echo $i |awk -F'|' '{print $2}' |grep ",")" ]; then
				sed -i '/#upstream#/ a \    upstream '$project_name'-lb-'$n' {\n\        keepalive 20;\n\    }\n' /usr/local/openresty/nginx/conf/nginx.conf

				for y in $(echo $i |awk -F'|' '{print $2}' |sed 's/,/\n/g'); do
					sed -i '/upstream '$project_name'-lb-'$n'/ a \        server '$y';' /usr/local/openresty/nginx/conf/nginx.conf
				done
			else
				sed -i 's@'$project_name'-lb-'$n'@'$(echo $i |awk -F'|' '{print $2}')'@' /usr/local/openresty/nginx/conf/vhost/${project_name}_$n.conf
			fi
		else
			sed -i '/#server_name#/ a \    server_name localhost; #localhost' /usr/local/openresty/nginx/conf/vhost/${project_name}_$n.conf

			if [ -n "$(echo $i |grep ",")" ]; then
				sed -i '/#upstream#/ a \    upstream '$project_name'-lb-'$n' {\n\        keepalive 20;\n\    }\n' /usr/local/openresty/nginx/conf/nginx.conf

				for x in $(echo $i |sed 's/,/\n/g'); do
					sed -i '/upstream '$project_name'-lb-'$n'/ a \        server '$x';' /usr/local/openresty/nginx/conf/nginx.conf
				done
			else
				sed -i 's@'$project_name'-lb-'$n'@'$i'@' /usr/local/openresty/nginx/conf/vhost/${project_name}_$n.conf
			fi
		fi
	fi
}



##-------------------STREAM------------------

stream_conf() {
	cat >/usr/local/openresty/nginx/conf/nginx.conf <<-END
	#redhat.xyz
	worker_processes  $WORKER_PROC;
  
	events {
	    worker_connections  $(($WORKER_PROC*10240));
	}
  
	stream {
	    log_format main '\$remote_addr:\$remote_port [\$time_local] \$protocol \$status \$session_time "\$upstream_addr" \$upstream_connect_time';
	    ##acclog_on access_log access.log main;
	    ##errlog_off error_log off;
	
	    #upstream#
		
	    #server#
	}
	END
}



stream_server() {
	if [ -n "$(echo $i |grep '^')" ]; then
		echo "^ yes"
		if [ -n "$(echo $i |awk -F^ '{print $1}' |grep '|')" ]; then
			PORT=$(echo $i |awk -F^ '{print $1}' |awk -F'|' '{print $1}')

			if [ -n "$(echo $i |awk -F^ '{print $1}' |awk -F'|' '{print $2}' |grep ",")" ]; then
				sed -i '/#upstream#/ a \    upstream backend-lb-'$n' {\n\    }\n' /usr/local/openresty/nginx/conf/nginx.conf

				for y in $(echo $i |awk -F^ '{print $1}' |awk -F'|' '{print $2}' |sed 's/,/\n/g'); do
					sed -i '/upstream backend-lb-'$n'/ a \        server '$y';' /usr/local/openresty/nginx/conf/nginx.conf
					sed -i 's/&/ /' /usr/local/openresty/nginx/conf/nginx.conf
				done
				
				sed -i '/#server#/ a \    server {\n\        #backend-lb-'$n'#\n\        listen '$PORT';\n\        listen [::]:'$PORT';#'$n'\n\        proxy_pass backend-lb-'$n';\n\    }\n' /usr/local/openresty/nginx/conf/nginx.conf
			else
				sed -i '/#server#/ a \    server {\n\        #backend-lb-'$n'#\n\        listen '$PORT';\n\        listen [::]:'$PORT';#'$n'\n\        proxy_pass '$(echo $i |awk -F^ '{print $1}' |awk -F'|' '{print $2}')';\n\    }\n' /usr/local/openresty/nginx/conf/nginx.conf
			fi
		else
			echo "error.." && exit 1
		fi
	else
		echo "^ no"
		if [ -n "$(echo $i |grep '|')" ]; then
			PORT=$(echo $i |awk -F'|' '{print $1}')

			if [ -n "$(echo $i |awk -F'|' '{print $2}' |grep ",")" ]; then
				sed -i '/#upstream#/ a \    upstream backend-lb-'$n' {\n\    }\n' /usr/local/openresty/nginx/conf/nginx.conf

				for y in $(echo $i |awk -F'|' '{print $2}' |sed 's/,/\n/g'); do
					sed -i '/upstream backend-lb-'$n'/ a \        server '$y';' /usr/local/openresty/nginx/conf/nginx.conf
					sed -i 's/&/ /' /usr/local/openresty/nginx/conf/nginx.conf
				done
				
				sed -i '/#server#/ a \    server {\n\        #backend-lb-'$n'#\n\        listen '$PORT';\n\        listen [::]:'$PORT';#'$n'\n\        proxy_pass backend-lb-'$n';\n\    }\n' /usr/local/openresty/nginx/conf/nginx.conf
			else
				sed -i '/#server#/ a \    server {\n\        #backend-lb-'$n'#\n\        listen '$PORT';\n\        listen [::]:'$PORT';#'$n'\n\        proxy_pass '$(echo $i |awk -F'|' '{print $2}')';\n\    }\n' /usr/local/openresty/nginx/conf/nginx.conf
			fi
		else
			echo "error.." && exit 1
		fi
	fi
}
	


stream_other() {
	for i in $(echo $i |awk -F^ '{print $2}' |sed 's/,/\n/g'); do		
		#负载均衡
		if [ -n "$(echo $i |grep 'stream_lb=')" ]; then
			stream_lb="$(echo $i |grep 'stream_lb=' |awk -F= '{print $2}')"
		
			if [ "$stream_lb" == "hash" ]; then
				sed -i '/upstream backend-lb-'$n'/ a \        hash $remote_addr consistent;' /usr/local/openresty/nginx/conf/nginx.conf
			fi
			
			if [ "$stream_lb" == "least_conn" ]; then
				sed -i '/upstream backend-lb-'$n'/ a \        least_conn;' /usr/local/openresty/nginx/conf/nginx.conf
			fi
		fi
		
		#上传限速,带单位
		if [ -n "$(echo $i |grep 'upload_rate=')" ]; then
			upload_rate="$(echo $i |grep 'upload_rate=' |awk -F= '{print $2}')"
			
			sed -i '/#backend-lb-'$n'#/ a \        proxy_upload_rate '$upload_rate';' /usr/local/openresty/nginx/conf/nginx.conf
		fi
		
		#下载限速,带单位
		if [ -n "$(echo $i |grep 'download_rate=')" ]; then
			download_rate="$(echo $i |grep 'download_rate=' |awk -F= '{print $2}')"
			
			sed -i '/#backend-lb-'$n'#/ a \        proxy_download_rate '$download_rate';' /usr/local/openresty/nginx/conf/nginx.conf
		fi
		
		#后端连接超时(1m)
		if [ -n "$(echo $i |grep 'conn_timeout=')" ]; then
			connect_timeout="$(echo $i |grep 'connect_timeout=' |awk -F= '{print $2}')"
			sed -i '/#backend-lb-'$n'#/ a \        proxy_connect_timeout '$connect_timeout';' /usr/local/openresty/nginx/conf/nginx.conf
		fi
		
		#空闲超时(10m)
		if [ -n "$(echo $i |grep 'proxy_timeout=')" ]; then
			proxy_timeout="$(echo $i |grep 'proxy_timeout=' |awk -F= '{print $2}')"
			sed -i '/#backend-lb-'$n'#/ a \        proxy_timeout '$proxy_timeout';' /usr/local/openresty/nginx/conf/nginx.conf
		fi
		
		#UDP, 不能和SSL共存
		if [ -n "$(echo $i |grep 'udp=')" ]; then
			sed -i 's/'$PORT';#'$n'/'$PORT' udp;#'$n'/' /usr/local/openresty/nginx/conf/nginx.conf
		fi
		
		#最大并发数
		if [ -n "$(echo $i |grep 'limit_conn=')" ]; then
		    limit_conn="$(echo $i |grep 'limit_conn=' |awk -F= '{print $2}')"
			sed -i '/#upstream#/ i \    limit_conn_zone $binary_remote_addr zone=addr'$n':'$ADDR_CACHE';' /usr/local/openresty/nginx/conf/nginx.conf
			sed -i '/#backend-lb-'$n'#/ a \        limit_conn_log_level error;' /usr/local/openresty/nginx/conf/nginx.conf
			sed -i '/#backend-lb-'$n'#/ a \        limit_conn           addr'$n' '$limit_conn';' /usr/local/openresty/nginx/conf/nginx.conf
		fi
		
		#SSL
		if [ -n "$(echo $i |grep 'ssl=')" ]; then
			sed -i 's/'$PORT';#'$n'/'$PORT' ssl;#'$n'/' /usr/local/openresty/nginx/conf/nginx.conf
			sed -i '/#backend-lb-'$n'#/ a \        ssl_certificate_key     /usr/local/openresty/nginx/conf/cert/server.key;' /usr/local/openresty/nginx/conf/nginx.conf
			sed -i '/#backend-lb-'$n'#/ a \        ssl_certificate         /usr/local/openresty/nginx/conf/cert/server.crt;' /usr/local/openresty/nginx/conf/nginx.conf
			sed -i '/#backend-lb-'$n'#/ a \        ssl_session_timeout '$SSL_TIMEOUT';' /usr/local/openresty/nginx/conf/nginx.conf
			sed -i '/#backend-lb-'$n'#/ a \        ssl_session_cache   shared:SSL:'$SSL_CACHE';' /usr/local/openresty/nginx/conf/nginx.conf
			sed -i '/#backend-lb-'$n'#/ a \        ssl_ciphers         AES128-SHA:AES256-SHA:RC4-SHA:DES-CBC3-SHA:RC4-MD5;' /usr/local/openresty/nginx/conf/nginx.conf
			sed -i '/#backend-lb-'$n'#/ a \        ssl_protocols       TLSv1 TLSv1.1 TLSv1.2 TLSv1.3;' /usr/local/openresty/nginx/conf/nginx.conf
		fi
		
		#上游SSL
		if [ -n "$(echo $i |grep 'ssl_backend=')" ]; then
			sed -i '/#backend-lb-'$n'#/ a \        proxy_ssl_certificate_key     /usr/local/openresty/nginx/conf/cert/server.key;' /usr/local/openresty/nginx/conf/nginx.conf
			sed -i '/#backend-lb-'$n'#/ a \        proxy_ssl_certificate         /usr/local/openresty/nginx/conf/cert/server.crt;' /usr/local/openresty/nginx/conf/nginx.conf
			sed -i '/#backend-lb-'$n'#/ a \        proxy_ssl  on;' /usr/local/openresty/nginx/conf/nginx.conf
		fi
		
		#日志
		if [ -n "$(echo $i |grep 'log=')" ]; then
			log="$(echo $i |grep 'log=' |awk -F= '{print $2}')"
			
			if [ "$log" == "Y" ]; then
				sed -i '/#backend-lb-'$n'#/ a \        access_log logs\/'$n'-access.log main;' /usr/local/openresty/nginx/conf/nginx.conf
				sed -i '/#backend-lb-'$n'#/ a \        error_log logs\/'$n'-error.log;' /usr/local/openresty/nginx/conf/nginx.conf
			fi
			
			if [ "$log" == "N" ]; then
				sed -i '/#backend-lb-'$n'#/ i \        access_log off;' /usr/local/openresty/nginx/conf/nginx.conf
				sed -i '/#backend-lb-'$n'#/ i \        error_log off;' /usr/local/openresty/nginx/conf/nginx.conf
			fi 
		fi
		
		#访问控制
		if [ -n "$(echo $i |grep 'allow=')" ]; then
			sed -i '/#backend-lb-'$n'#/ a \        deny  all;' /usr/local/openresty/nginx/conf/nginx.conf
			for x in $(echo $i |grep 'allow=' |gawk -F= '{print $2}' |sed 's/&/\n/g'); do
				sed -i '/#backend-lb-'$n'#/ a \        allow '$x';' /usr/local/openresty/nginx/conf/nginx.conf
			done
		fi
	done
}




###start

if [ "$1" = 'openresty' ]; then
  if [ -z "$(grep "redhat.xyz" /usr/local/openresty/nginx/conf/nginx.conf)" ]; then
	mkdir /usr/local/openresty/nginx/conf/{vhost,cert}
	if [ -f /key/server.crt -a -f /key/server.key ]; then
		\cp /key/*.{crt,key} /usr/local/openresty/nginx/conf/cert/
	else
		openssl genrsa -out /usr/local/openresty/nginx/conf/cert/server.key 4096 2>/dev/null
		openssl req -new -key /usr/local/openresty/nginx/conf/cert/server.key -out /usr/local/openresty/nginx/conf/cert/server.csr -subj "/C=CN/L=London/O=Company Ltd/CN=nginx-docker" 2>/dev/null
		openssl x509 -req -days 3650 -in /usr/local/openresty/nginx/conf/cert/server.csr -signkey /usr/local/openresty/nginx/conf/cert/server.key -out /usr/local/openresty/nginx/conf/cert/server.crt 2>/dev/null
		\cp /usr/local/openresty/nginx/conf/cert/server.{crt,key} /key/
	fi

	if [ "$STREAM_SERVER" ]; then
		stream_conf
		
		n=0
		for i in $(echo "$STREAM_SERVER" |sed 's/;/\n/g'); do
			n=$(($n+1))
			stream_server
			stream_other
		done

		if [ "$ACCLOG_ON" ]; then
			sed -i 's/##acclog_on//' /nginx/conf/nginx.conf
		fi

		if [ "$ERRLOG_OFF" ]; then
			sed -i 's/##errlog_off//' /nginx/conf/nginx.conf
		fi
	else

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
			\rm /usr/local/openresty/nginx/conf/vhost/default.conf
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
			\rm /usr/local/openresty/nginx/conf/vhost/default.conf 2>/dev/null |echo
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
			\rm /usr/local/openresty/nginx/conf/vhost/default.conf 2>/dev/null |echo
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
			\rm /usr/local/openresty/nginx/conf/vhost/default.conf 2>/dev/null |echo
		fi


		#WAF
		if [ "$WAF" == "Y" ]; then
			touch /usr/local/openresty/nginx/logs/frequency.log
			chown nobody.nobody /usr/local/openresty/nginx/logs/frequency.log
			sed -i 's/##waf//g' /usr/local/openresty/nginx/conf/nginx.conf
			sed -i 's/##waf//g' /usr/local/openresty/nginx/conf/vhost/*
			
			if [ "$WAF_REQ" ]; then
			    [ -n "$(echo "$WAF_REQ" |grep ,)" ] && http_waf
			fi
		fi


		if [ "$ACCLOG_OFF" ]; then
			sed -i 's/##acclog_off//' /usr/local/openresty/nginx/conf/nginx.conf
		fi

		if [ "$ERRLOG_OFF" ]; then
			sed -i 's/##errlog_off//' /usr/local/openresty/nginx/conf/nginx.conf
		fi

		if [ "$DEFAULT_SERVER" ]; then
			sed -i 's/##default_server//g' /usr/local/openresty/nginx/conf/vhost/*.conf
		fi

		if [ "$NGX_USER" ]; then
			sed -i 's/##nginx_status//g' /usr/local/openresty/nginx/conf/vhost/default.conf
			echo "$NGX_USER:$(openssl passwd -apr1 $NGX_PASS)" >> /usr/local/openresty/nginx/conf/cert/.htpasswd
			echo "Nginx user AND password: $NGX_USER  $NGX_PASS"
		fi
    fi

	#keepalived
	\rm /etc/keepalived/keepalived.conf
	if [ $KP_VIP ]; then
		cat >/etc/keepalived/keepalived.conf <<-END
		! Configuration File for keepalived
    
		vrrp_instance VI_1 {
		    state BACKUP
		    interface $KP_ETH
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

		for vip in $(echo $KP_VIP |sed 's/,/ /g');do
			sed -i "/virtual_ipaddress/a \        $vip" /etc/keepalived/keepalived.conf
		done
	fi

  fi

	echo "Start ****"
	#Keepalived Need root authority "--privileged"
	[ -f /etc/keepalived/keepalived.conf ] && keepalived -f /etc/keepalived/keepalived.conf -P -l && [ -z "`iptables -S |grep vrrp`" ] && iptables -I INPUT -p vrrp -j ACCEPT
	[ -f /ipset.sh ] && crond && bash /ipset.sh

	exec "$@"
else

	echo -e " 
	Example:
				docker run -d --restart unless-stopped [--cap-add NET_ADMIN] \\
				-v /docker/www:/usr/local/openresty/nginx/html \\
				-v /docker/upload:/mp4 \\
				-v /docker/key:/key \\
				-p 10080:80 \\
				-p 10443:443 \\
				-e WORKER_PROC=[2] \\
				-e FCGI_SERVER=<php.jiobxn.com|192.17.0.5:9000[^<Other options>]> \\
				-e JAVA_PHP_SERVER=<tomcat.jiobxn.com|192.17.0.6:8080[^<Other options>];apache.jiobxn.com|192.17.0.7[^<Other options>]> \\
				-e PROXY_SERVER=<g.jiobxn.com|www.google.co.id^backend_https=Y> \\
				-e DOMAIN_PROXY=<fqhub.com^backend_https=Y> \\
				-e DEFAULT_SERVER=<jiobxn.com> \\
				-e NGX_PASS=[jiobxn.com] \\
				-e NGX_USER=<nginx> \\
				-e NGX_CHARSET=[utf-8] \\
				-e FCGI_PATH=[/var/www] \\
				-e HTTP_PORT=[80] \\
				-e HTTPS_PORT=[443] \\
				-e ADDR_CACHE=[25m] \\
				-e SSL_CACHE=[25m] \\
				-e SSL_TIMEOUT=[10m] \\
				-e DOMAIN_TAG=[888] \\
				-e EOORO_JUMP=[https://cn.bing.com] \\
				-e NGX_DNS=[9.9.9.9] \\
				-e CACHE_TIME=[10h] \\
				-e CACHE_SIZE=[2g] \\
				-e CACHE_MEM=[256m] \\
				-e ACCLOG_OFF=<Y> \\
				-e ERRLOG_OFF=<Y> \\
				-e ACCLOG_ON=<Y> \\
				-e LIMIT_RATE=<2048k> \\
				-e LIMIT_CONN=<50> \\
				-e LIMIT_REQ=<2> \\
				-e WAF=<Y> \\
				-e WAF_REQ=<404,20;403,10> \\
				-e REMOTE_ADDR=[remote_addr] \\
				-e ws=</mp4|127.0.0.1:19443> \\
				   wss=</mp4|127.0.0.1:19444> \\
				   alias=</boy|/mp4> \\
				   root=<wordpress> \\
				   http_port=<8080> \\
				   https_port=<8443> \\
				   crt_key=<jiobxn.crt|jiobxn.key> \\
				   full_https=<Y> \\
				   http2=<Y> \\
				   charset=<gb2312> \\
				   cache=<Y> \\
				   header=<host|http_host|proxy_host> \\
				   http_lb=<ip_hash|hash|least_conn> \\
				   backend_https=<Y> \\
				   dns=<223.5.5.5> \\
				   tag=<9999> \\
				   error=<https://www.bing.com> \\
				   auth=<admin|passwd> \\
				   filter=<.google.com|.fqhub.com&.twitter.com|.fqhub.com> \\
				   limit_rate=<2048k> \\
				   limit_conn=<50> \\
				   limit_req=<2> \\
				   log=<N|Y> \\
				   testip=<1.1.1.1&10.0.0.10:8080> \\
				-e STREAM_SERVER=<3306|192.17.0.7:3306&backup,192.17.0.6:3306[^<Other options>];53|8.8.8.8:53^udp=Y> \\
				   stream_lb=<hash|least_conn> \\
				   upload_rate=<2048k> \\
				   download_rate=<2048k> \\
				   conn_timeout=[1m] \\
				   proxy_timeout=[10m] \\
				   limit_conn=<50> \\
				   udp=<Y> \\
				   log=<N|Y> \\
				   ssl=<Y> \\
				   ssl_backend=<Y> \\
				   allow=<1.2.3.4&5.6.7.8> \\
				-e KP_VIP=<20.20.6.4,20.20.6.25> \\
				-e KP_ETH=[default interface] \\
				-e KP_VRID=[77] \\
				-e KP_PASS=[Newpa55] \\
				--name nginx nginx
	" 
fi

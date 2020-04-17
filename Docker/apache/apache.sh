#!/bin/bash
set -e

if [ "$1" = 'httpd' -o "$1" = 'php-fpm' ]; then

: ${REDIS_PORT:=6379}
: ${REDIS_DB:=0}
: ${post_max_size:=4G}
: ${upload_max_filesize:=4G}
: ${max_file_uploads:=50}
: ${memory_limit:="$(($(free -m |grep Mem |awk '{print $2}')*60/100))M"}
: ${PHP_PORT:=9000}
: ${APC_PASS:=jiobxn.com}
: ${APC_CHARSET:=UTF-8}
: ${HTTP_PORT:=80}
: ${HTTPS_PORT:=443}


if [ -z "$(grep "redhat.xyz" /etc/httpd/conf/httpd.conf)" ]; then
	echo "Initialize apache"
	localedef -v -c -i en_US -f UTF-8 en_US.UTF-8 2>/dev/null || echo
	localedef -v -c -i zh_CN -f UTF-8 zh_CN.UTF-8 2>/dev/null || echo
	sed -i '2 i ;redhat.xyz' /etc/php.ini

	#key
	if [ -f /key/server.crt -a -f /key/server.key ]; then
		\cp /key/server.crt /etc/pki/tls/certs/localhost.crt
		\cp /key/server.key /etc/pki/tls/private/localhost.key
		if [ -f /key/chain.crt ]; then
			\cp /key/chain.crt /etc/pki/tls/certs/server-chain.crt
			sed -i 's/#SSLCertificateChainFile/SSLCertificateChainFile/' /etc/httpd/conf.d/ssl.conf
		fi
	fi

	#php
	sed -i 's/;date.timezone =/date.timezone = PRC/' /etc/php.ini
	sed -i 's/post_max_size = 8M/post_max_size = '$post_max_size'/' /etc/php.ini
	sed -i 's/upload_max_filesize = 2M/upload_max_filesize = '$upload_max_filesize'/' /etc/php.ini
	sed -i 's/max_file_uploads = 20/max_file_uploads = '$max_file_uploads'/' /etc/php.ini
	sed -i 's/memory_limit = 128M/memory_limit = '$memory_limit'/' /etc/php.ini
	sed -i 's/max_execution_time = 30/max_execution_time = 300/' /etc/php.ini
	sed -i 's/max_input_time = 60/max_input_time = 300/' /etc/php.ini
	sed -i 's/listen = 127.0.0.1:9000/listen = 0.0.0.0:'$PHP_PORT'/' /etc/php-fpm.d/www.conf
	[ ! -d /run/php-fpm ] && mkdir /run/php-fpm

	#httpd
	sed -i 's/index.html/index.php index.html/' /etc/httpd/conf/httpd.conf
	sed -i 's/Listen 80/Listen '$HTTP_PORT'/g' /etc/httpd/conf/httpd.conf
	sed -i 's/Listen 443/Listen '$HTTPS_PORT'/g' /etc/httpd/conf.d/ssl.conf
	sed -i 's/_default_:443/_default_:'$HTTPS_PORT'/g' /etc/httpd/conf.d/ssl.conf

	#gzip
	cat >>/etc/httpd/conf/httpd.conf <<-END
	#
	#redhat.xyz
	ServerName localhost
	AddDefaultCharset $APC_CHARSET
	<IfModule deflate_module>  
	AddOutputFilterByType DEFLATE all  
	SetOutputFilter DEFLATE  
	</ifModule>  
	END

	#root
	if [ "$ROOT" ]; then
		sed -i 's#DocumentRoot "/var/www/html"#DocumentRoot "/var/www/html/'$ROOT'"#' /etc/httpd/conf/httpd.conf
	fi

	#alias
	if [ "$ALIAS" ]; then
		if [ -n "$(echo $ALIAS |grep ',')" ]; then
			echo -e "#alias\nAlias \"$(echo $ALIAS |awk -F, '{print $1}')\" \"$(echo $ALIAS |awk -F, '{print $2}')\"\n<Directory \"$(echo $ALIAS |awk -F, '{print $2}')\">\n  Require all granted\n</Directory>" >>/etc/httpd/conf/httpd.conf
		fi
	fi

	#status
	if [ "$APC_USER" ]; then
		cat >>/etc/httpd/conf/httpd.conf <<-END
		#
		<Location /basic_status>
		AuthName "Apache stats"
		AuthType Basic
		AuthUserFile /usr/local/apache/conf/.htpasswd
		Require valid-user
		SetHandler server-status
		</Location>
		END
	
		echo "$APC_USER:$(openssl passwd -apr1 $APC_PASS)" > /usr/local/apache/conf/.htpasswd
		echo "Apache user AND password: $APC_USER  $APC_PASS"
	fi

	#Redis
	if [ "$REDIS_SERVER" ]; then
		sed -i 's/session.save_handler = files/session.save_handler = redis/' /etc/php.ini
		if [ "$REDIS_PASS" ]; then
			sed -i '/session.save_handler = redis/ a session.save_path = "tcp://'$REDIS_SERVER':'$REDIS_PORT'?auth='$REDIS_PASS'&database='$REDIS_DB'"' /etc/php.ini
		else
			sed -i '/session.save_handler = redis/ a session.save_path = "tcp://'$REDIS_SERVER':'$REDIS_PORT'&database='$REDIS_DB'"' /etc/php.ini
		fi
	fi
fi

	echo "Start ****"
	exec "$@"
else

	echo -e "
	Example:
			docker run -d --restart unless-stopped \\
			-v /docker/www:/var/www/html \\
			-p 80:80 \\
			-p 443:443 \\
			-p 9000:9000 \\
			-p PHP_PORT=[9000] \\
			-e post_max_size=[4G] \\
			-e upload_max_filesize=[4G] \\
			-e max_file_uploads=[50] \\
			-e memory_limit=<2048M> \\
			-e HTTP_PORT=[80] \\
			-e HTTPS_PORT=[443] \\
			-e APC_CHARSET=[UTF-8] \\
			-e ROOT=<public> \\
			-e ALIAS=</boy,/mp4> \\
			-e APC_USER=<apache> \\
			-e APC_PASS=[jiobxn.com] \\
			-e REDIS_SERVER=<redhat.xyz> \\
			-e REDIS_PORT=[6379] \\
			-e REDIS_PASS=<bigpass> \\
			-e REDIS_DB=[0] \\
			--name apache apache
	"
fi

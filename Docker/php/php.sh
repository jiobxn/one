#!/bin/bash
set -e

if [ "$1" = 'php-fpm' ]; then

: ${REDIS_PORT:=16379}
: ${REDIS_DB:=0}
: ${post_max_size:=4G}
: ${upload_max_filesize:=4G}
: ${max_file_uploads:=50}
: ${memory_limit:="$(($(free -m |grep Mem |awk '{print $2}')*60/100))M"}
: ${php_port:=9000}


if [ -z "$(grep "redhat.xyz" /usr/local/php/etc/php.ini)" ]; then
	localedef -v -c -i en_US -f UTF-8 en_US.UTF-8 2>/dev/null || echo
	localedef -v -c -i zh_CN -f UTF-8 zh_CN.UTF-8 2>/dev/null || echo
	echo "Initialize PHP"
	sed -i '2 i ;redhat.xyz' /usr/local/php/etc/php.ini

	sed -i 's/post_max_size = 8M/post_max_size = '$post_max_size'/' /usr/local/php/etc/php.ini
	sed -i 's/upload_max_filesize = 2M/upload_max_filesize = '$upload_max_filesize'/' /usr/local/php/etc/php.ini
	sed -i 's/max_file_uploads = 20/max_file_uploads = '$max_file_uploads'/' /usr/local/php/etc/php.ini
	sed -i 's/memory_limit = 128M/memory_limit = '$memory_limit'/' /usr/local/php/etc/php.ini
	sed -i 's/max_execution_time = 30/max_execution_time = 300/' /usr/local/php/etc/php.ini
	sed -i 's/max_input_time = 60/max_input_time = 300/' /usr/local/php/etc/php.ini
	sed -i 's/9000/'$php_port'/' /usr/local/php/etc/php-fpm.conf
	
	#Redis
	if [ $REDIS_SERVER ]; then
		sed -i 's/session.save_handler = files/session.save_handler = redis/' /usr/local/php/etc/php.ini
		if [ $REDIS_PASS ]; then
			sed -i '/session.save_handler = redis/ a session.save_path = "tcp://'$REDIS_SERVER':'$REDIS_PORT'?auth='$REDIS_PASS'&database='$REDIS_DB'"' /usr/local/php/etc/php.ini
		else
			sed -i '/session.save_handler = redis/ a session.save_path = "tcp://'$REDIS_SERVER':'$REDIS_PORT'&database='$REDIS_DB'"' /usr/local/php/etc/php.ini
		fi
		wget -c https://github.com/jiobxn/tomcat-redis-session-manager/raw/master/hello.php -O /var/www/hello.php
	fi

fi

	echo "Start ****"
	exec "$@"
else

	echo -e "
	Example:
					docker run -d --restart always --privileged \\
					-v /docker/www:/var/www \\
					-p 9000:9000 \\
					-e REDIS_SERVER=<redhat.xyz> \\
					-e REDIS_PORT=[16379] \\
					-e REDIS_PASS=<bigpass> \\
					-e REDIS_DB=[0] \\
					-e post_max_size=[4G] \\
					-e upload_max_filesize=[4G] \\
					-e max_file_uploads=[50] \\
					-e memory_limit=<2048M> \\
					--hostname php \\
					--name php php
	"
fi

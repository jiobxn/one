#!/bin/bash
set -e

if [ "$1" = '/usr/sbin/init' ]; then

: ${HTTP_PORT:=80}
: ${MYSQL_HOST:=127.0.0.1}
: ${MYSQL_PORT:=3306}
: ${MYSQL_USER:=zabbix}
: ${MYSQL_PASS:=password}
: ${ZABBIX_DB:=zabbix}
: ${SERVER_PORT:=10051}
: ${AGENTD_PORT:=10050}
: ${TZ:=Asia/Shanghai}

  if [ -d "/var/lib/mysql/$ZABBIX_DB" ]; then
  	if [ ! -f /sql.txt ]; then
  		sed -i 's/# DBHost=localhost/DBHost='$MYSQL_HOST'/' /etc/zabbix/zabbix_server.conf
  		sed -i 's/# User=zabbix/User='$MYSQL_USER'/' /etc/zabbix/zabbix_server.conf
  		sed -i 's/# DBPort=/DBPort='$MYSQL_PORT'/' /etc/zabbix/zabbix_server.conf
  		sed -i 's/# DBPassword=/DBPassword='$MYSQL_PASS'/' /etc/zabbix/zabbix_server.conf
  		sed -i 's/# ListenPort=10051/ListenPort='$SERVER_PORT'/' /etc/zabbix/zabbix_server.conf
  		sed -i 's/# ListenPort=10050/ListenPort='$AGENTD_PORT'/' /etc/zabbix/zabbix_agentd.conf
		sed -i 's/Listen 80/Listen '$HTTP_PORT'/g' /etc/httpd/conf/httpd.conf
  		sed -i 's#;date.timezone =#date.timezone = '$TZ'#' /etc/php.ini
  		sed -i 's/# default-authentication-plugin=mysql_native_password/default-authentication-plugin=mysql_native_password/' /etc/my.cnf
  	fi

  	mkdir -p /run/php-fpm
  	mysqld -D
  	php-fpm
  	httpd
  	zabbix_server
  	zabbix_agentd
  else
  	if [ "$MYSQL_HOST" == "127.0.0.1" ]; then
  		sed -i 's/# default-authentication-plugin=mysql_native_password/default-authentication-plugin=mysql_native_password/' /etc/my.cnf
  		mysqld --initialize-insecure &>/dev/null
  		mysqld -D
		
		cat >/sql.txt <<-END
		create database $ZABBIX_DB character set utf8 collate utf8_bin;
		SET @@SESSION.SQL_LOG_BIN=0;
		CREATE USER '$MYSQL_USER'@'$MYSQL_HOST' IDENTIFIED BY '$MYSQL_PASS';
		GRANT ALL ON $ZABBIX_DB.* TO '$MYSQL_USER'@'$MYSQL_HOST' WITH GRANT OPTION;
		FLUSH PRIVILEGES;
		END
		
		MYSQL_PWD="" mysql -uroot < /sql.txt
  	else
  		TAB=$(MYSQL_PWD="$MYSQL_PASS" mysql -h$MYSQL_HOST -P$MYSQL_PORT -u$MYSQL_USER -e "use $ZABBIX_DB; show tables;" |awk 'NR!=1{print $1,$2}' |wc -l)
  	fi

  	if [ "$TAB" -gt "100" ]; then
  		echo "$ZABBIX_DB Table exists, skip"
  	else
  		zcat /usr/share/doc/zabbix-server-mysql*/create.sql.gz | mysql -h$MYSQL_HOST -P$MYSQL_PORT -u$MYSQL_USER -p$MYSQL_PASS $ZABBIX_DB
  	fi

  	sed -i 's/# DBHost=localhost/DBHost='$MYSQL_HOST'/' /etc/zabbix/zabbix_server.conf
  	sed -i 's/# User=zabbix/User='$MYSQL_USER'/' /etc/zabbix/zabbix_server.conf
  	sed -i 's/# DBPort=/DBPort='$MYSQL_PORT'/' /etc/zabbix/zabbix_server.conf
  	sed -i 's/DBName=zabbix/DBName='$ZABBIX_DB'/' /etc/zabbix/zabbix_server.conf
  	sed -i 's/# DBPassword=/DBPassword='$MYSQL_PASS'/' /etc/zabbix/zabbix_server.conf
  	sed -i 's/# ListenPort=10051/ListenPort='$SERVER_PORT'/' /etc/zabbix/zabbix_server.conf
  	sed -i 's/# ListenPort=10050/ListenPort='$AGENTD_PORT'/' /etc/zabbix/zabbix_agentd.conf
  	sed -i 's/Listen 80/Listen '$HTTP_PORT'/g' /etc/httpd/conf/httpd.conf
  	sed -i 's#;date.timezone =#date.timezone = '$TZ'#' /etc/php.ini

  	mkdir /run/php-fpm
  	php-fpm
  	httpd
  	zabbix_server
  	zabbix_agentd
  fi
  
	echo -e "\nDatabase type: MySQL\nDatabase host: $MYSQL_HOST\nDatabase port: $MYSQL_PORT\nDatabase name: $ZABBIX_DB\nUser: $MYSQL_USER\nPassword: $MYSQL_PASS\nDashboard: Admin/zabbix"
	echo "Start ****"
	exec "$@"
else
  echo -e "
  Example:
			docker run -d --restart unless-stopped \\
			-v /docker/zabbix-db:/var/lib/mysql \\
			-p 80:80 \\
			-p 10051:10051 \\
			-e HTTP_PORT=[80] \\
			-e MYSQL_HOST=[127.0.0.1] \\
			-e MYSQL_PORT=[3306] \\
			-e MYSQL_USER=[zabbix] \\
			-e MYSQL_PASS=[password] \\
			-e ZABBIX_DB=[zabbix] \\
			-e SERVER_PORT=[10051] \\
			-e AGENTD_PORT=[10050] \\
			-e TZ=[Asia/Shanghai] \\
			--name zabbix zabbix
		"	
fi

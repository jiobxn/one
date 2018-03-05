#!/bin/bash
set -e

if [ "$1" = 'mysqld' ]; then
	#Get data path
	DATADIR="$("$@" --verbose --help 2>/dev/null | awk '$1 == "datadir" { print $2; exit }')"
    
	if [ -d "$DATADIR/mysql" ]; then
		echo "$DATADIR/mysql already exists, skip"
		echo -e "lower_case_table_names=1\nopen_files_limit=100000" >>/etc/my.cnf

		#Server ID
		if [ -n "$SERVER_ID" -a -z "$(grep ^server-id /etc/my.cnf)" ]; then
			sed -i '/\[mysqld\]/a log-bin=mysql-bin\nserver-id='$SERVER_ID'\ninnodb_flush_log_at_trx_commit=1\nsync_binlog=1\nlower_case_table_names=1' /etc/my.cnf
		fi
	else
		echo -e "lower_case_table_names=1\nopen_files_limit=100000" >>/etc/my.cnf
		#Server ID
		if [ "$SERVER_ID" ]; then
			sed -i '/\[mysqld\]/a log-bin=mysql-bin\nserver-id='$SERVER_ID'\ninnodb_flush_log_at_trx_commit=1\nsync_binlog=1\nlower_case_table_names=1' /etc/my.cnf
		fi

		#Initialize MYSQL
		mysql_V="$(rpm -qa |awk -F- '$1"-"$2"-"$3=="mysql-community-server"{print $4}' |awk -F. '{print $1$2}')"

		if [ "$mysql_V" -ge "57" ]; then
			echo "Initializing MySQL $mysql_V"
			mysqld --initialize-insecure --user=mysql
			mysql_ssl_rsa_setup 2>/dev/null
			mysqld --skip-networking --user=mysql &
			pid="$!"
		else
			if [ "$mysql_V" -eq "56" ]; then
				echo "Initializing MySQL $mysql_V"
				mysql_install_db --rpm --keep-my-cnf --user=mysql &>/dev/null
				mysqld --skip-networking --user=mysql &>/dev/null &
				pid="$!"
			fi
			
			if [ "$mysql_V" -eq "55" ]; then
				echo "Initializing MySQL $mysql_V"
				mysql_install_db --rpm --user=mysql &>/dev/null
				mysqld --skip-networking --user=mysql &>/dev/null &
				pid="$!"
			fi
		fi
		
		#Login mysql Use socket
		mysql=( mysql --protocol=socket -uroot )
		
		#mysql status
		for i in {30..0}; do
			if echo 'SELECT 1' | "${mysql[@]}" &> /dev/null; then
				break
			fi
			echo 'MySQL init process in progress...'
			sleep 1
		done
		
		#Failed to initialize
		if [ "$i" = 0 ]; then
			echo >&2 'MySQL init process failed.'
			exit 1
		else
			echo "MySQL init process running."
		fi
		
		#Generate a random string
		if [ -z "$MYSQL_ROOT_PASSWORD" ]; then
			MYSQL_ROOT_PASSWORD="$(pwmake 128)"
		fi
		
		#Set the root password and remote database access
		"${mysql[@]}" <<-EOSQL
			SET @@SESSION.SQL_LOG_BIN=0;
			DELETE FROM mysql.user where user != 'mysql.sys';
			CREATE USER 'root'@'%' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}' ;
			GRANT ALL ON *.* TO 'root'@'%' WITH GRANT OPTION ;
			DROP DATABASE IF EXISTS test ;
			FLUSH PRIVILEGES ;
		EOSQL
		echo "MYSQL ROOT PASSWORD: $MYSQL_ROOT_PASSWORD" |tee $DATADIR/root_info
		
		#Give mysql password
		if [ ! -z "$MYSQL_ROOT_PASSWORD" ]; then
			mysql+=( -p"${MYSQL_ROOT_PASSWORD}" )
		fi
		
		#Create a database
		if [ "$MYSQL_DATABASE" ]; then
			echo "CREATE DATABASE IF NOT EXISTS \`$MYSQL_DATABASE\` ;" | "${mysql[@]}"
			mysql+=( "$MYSQL_DATABASE" )
			echo "MYSQL DATABASE: $MYSQL_DATABASE"
		fi
		
		#Create a database user
		if [ "$MYSQL_USER" -a "$MYSQL_PASSWORD" ]; then
			echo "CREATE USER '"$MYSQL_USER"'@'%' IDENTIFIED BY '"$MYSQL_PASSWORD"' ;" | "${mysql[@]}"
			if [ "$MYSQL_DATABASE" ]; then
				echo "GRANT ALL ON \`"$MYSQL_DATABASE"\`.* TO '"$MYSQL_USER"'@'%' ;" | "${mysql[@]}"
			fi
			echo 'FLUSH PRIVILEGES ;' | "${mysql[@]}"
			echo "MYSQL USER AND PASSWORD: $MYSQL_USER  $MYSQL_PASSWORD"
		fi
		
		#Repl user
		if [ "$REPL_IPR" ]; then
			[ -z "$REPL_USER" ] && REPL_USER=repl
			[ -z "$REPL_PASSWORD" ] && REPL_PASSWORD="$(pwmake 64)"
			echo -e "MYSQL REPL USER AND PASSWORD: $REPL_USER\t$REPL_PASSWORD" |tee $DATADIR/repl_info
			echo "GRANT REPLICATION SLAVE ON *.*  TO '"$REPL_USER"'@'"$REPL_IPR"' IDENTIFIED BY '"$REPL_PASSWORD"' ;" | "${mysql[@]}"
		fi
		
		#Import Database
		for f in /docker-entrypoint-initdb.d/*; do
			case "$f" in
				*.sh)  echo "$0: running $f"; . "$f" ;;
				*.sql)    echo "$0: running $f"; DB_NAME=$(echo "$f" |awk -F'.sql' '{print $1}' |awk -F'_' '{print $1}' |awk -F'/' '{print $NF}'); echo "CREATE
DATABASE IF NOT EXISTS \`$DB_NAME\` ;" | "${mysql[@]}"; "${mysql[@]}" "$DB_NAME" < "$f"; echo "GRANT ALL ON \`"$DB_NAME"\`.* TO '"$MYSQL_USER"'@'%' ;" | "${mysql[@]}"; echo ;;
				*)        echo "$0: ignoring $f" ;;
			esac
		done
		
		#Stop the database
		pkill mysqld
		if ! kill -s TERM "$pid" || ! wait "$pid"; then
			echo >&2 'MySQL init process failed.'
			exit 1
		fi
		
		sed -i '/\[mysqld\]/a max_connections = 800' /etc/my.cnf
	fi
	
	#Backup Database
	if [ "$MYSQL_BACK" ]; then
		[ -z "$MYSQL_ROOT_PASSWORD" ] && MYSQL_ROOT_PASSWORD=$(awk '{print $4}' $DATADIR/root_info)
		sed -i 's/newpass/'$MYSQL_ROOT_PASSWORD'/' /backup.sh
		echo "0 4 * * * . /etc/profile;/bin/sh /backup.sh &>/dev/null" >>/var/spool/cron/root
	fi
	
	#Mysql max connections
	if [ "$MYSQL_MAX_CONN" ]; then
		sed -i '/max_connections = 800/max_connections = '$MYSQL_MAX_CONN'/' /etc/my.cnf
	fi
	
	#Mysql general log
	if [ "$MYSQL_GENERAL_LOG" ]; then
		sed -i '/\[mysqld\]/a general-log = 1' /etc/my.cnf
	fi
	
	#Mysql modify the default port
	if [ "$MYSQL_PORT" ]; then
		sed -i '/\[mysqld\]/a port = '$MYSQL_PORT'' /etc/my.cnf
		sed -i 's/3306/'$MYSQL_PORT'/' /backup.sh
		echo "MYSQL PORT: $MYSQL_PORT"
	fi
	
	#Master HOST
	if [ "$MASTER_HOST" ]; then
		if [ ! -f $DATADIR/repl_status ]; then
			[ -z "$SERVER_ID" ] && echo "Not Server ID" && exit 1
			[ -z "$MASTER_PORT" ] && MASTER_PORT=3306
			
			if [ -f $DATADIR/xtrabackup_binlog_info ]; then
				[ -z "$REPL_USER" ] && REPL_USER=$(awk '{print $6}' $DATADIR/repl_info)
				[ -z "$REPL_PASSWORD" ] && REPL_PASSWORD=$(awk '{print $7}' $DATADIR/repl_info)
				[ -z "$MYSQL_ROOT_PASSWORD" ] && MYSQL_ROOT_PASSWORD=$(awk '{print $4}' $DATADIR/root_info)
				echo "MASTER_LOG_FILE=$(awk '{print $1}' $DATADIR/xtrabackup_binlog_info)" >>/repl.sh
				echo "MASTER_LOG_POS=$(awk '{print $2}' $DATADIR/xtrabackup_binlog_info)" >>/repl.sh
				echo "sed -i 's/\$MASTER_LOG_FILE/'\$MASTER_LOG_FILE'/' /repl.sh" >>/repl.sh
				echo "sed -i 's/\$MASTER_LOG_POS/'\$MASTER_LOG_POS'/' /repl.sh" >>/repl.sh
			else
				echo "MYSQL_PWD=\"$MYSQL_ROOT_PASSWORD\" mysql -uroot -h$MASTER_HOST -P$MASTER_PORT -e \"FLUSH TABLES WITH READ LOCK;\"" >>/repl.sh
				echo "MASTER_LOG_FILE=\$(MYSQL_PWD=\"$MYSQL_ROOT_PASSWORD\" mysql -uroot -h$MASTER_HOST -P$MASTER_PORT -e \"SHOW MASTER STATUS;\" |awk 'NR!=1{print \$1}')" >>/repl.sh
				echo "MASTER_LOG_POS=\$(MYSQL_PWD=\"$MYSQL_ROOT_PASSWORD\" mysql -uroot -h$MASTER_HOST -P$MASTER_PORT -e \"SHOW MASTER STATUS;\" |awk 'NR!=1{print \$2}')" >>/repl.sh
				echo "MYSQL_PWD=\"$MYSQL_ROOT_PASSWORD\" mysqldump -uroot -h$MASTER_HOST -P$MASTER_PORT --all-databases --master-data > dbdump.db" >>/repl.sh
				echo "MYSQL_PWD=\"$MYSQL_ROOT_PASSWORD\" mysql -uroot -h$MASTER_HOST -P$MASTER_PORT -e \"UNLOCK TABLES;\"" >>/repl.sh
				echo "MYSQL_PWD=\"$MYSQL_ROOT_PASSWORD\" mysql -uroot < dbdump.db" >>/repl.sh
				echo "sed -i 's/\$MASTER_LOG_FILE/'\$MASTER_LOG_FILE'/' /repl.sh" >>/repl.sh
				echo "sed -i 's/\$MASTER_LOG_POS/'\$MASTER_LOG_POS'/' /repl.sh" >>/repl.sh
			fi
			
			echo "MYSQL_PWD=\"$MYSQL_ROOT_PASSWORD\" mysql -uroot -e \"CHANGE MASTER TO MASTER_HOST='"$MASTER_HOST"', MASTER_PORT="$MASTER_PORT", MASTER_USER='"$REPL_USER"', MASTER_PASSWORD='"$REPL_PASSWORD"', MASTER_LOG_FILE='"\$MASTER_LOG_FILE"', MASTER_LOG_POS="\$MASTER_LOG_POS";\"" >>/repl.sh
			echo "MYSQL_PWD=\"$MYSQL_ROOT_PASSWORD\" mysql -uroot -e \"START SLAVE;\"" >>/repl.sh
			echo "MYSQL_PWD=\"$MYSQL_ROOT_PASSWORD\" mysql -uroot -e \"SHOW SLAVE STATUS\G\" |grep \"Running:\" >$DATADIR/repl_status" >>/repl.sh
			echo "cp $DATADIR/repl_status /root/repl.log" >>/repl.sh
			atd
			echo "sh /repl.sh" |at now +1 minutes
		else
			echo "Repl already exists, skip"
		fi
	fi

	#iptables, Need root authority "--privileged"
	if [ $IPTABLES ]; then
		[ -z $MYSQL_PORT ] && MYSQL_PORT=3306
		cat > /iptables.sh <<-END
		iptables -I INPUT -p tcp --dport $MYSQL_PORT -j DROP
		iptables -I INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT
		iptables -I INPUT -s $IPTABLES -p tcp -m state --state NEW -m tcp --dport $MYSQL_PORT -m comment --comment MYSQL -j ACCEPT
		END
	fi

	echo "Start MYSQL ****"
	[ -f /iptables.sh ] && [ -z "`iptables -S |grep MYSQL`" ] && . /iptables.sh
	crond

	exec "$@" 1>/dev/null
else

    echo -e "
    Example:
				docker run -d --restart always [--privileged] \\
				-v /docker/mysql-rpm:/var/lib/mysql \\
				-v /docker/sql:/docker-entrypoint-initdb.d \\
				-p 3306:3306 \\
				-e MYSQL_ROOT_PASSWORD=<newpass> \\
				-e MYSQL_DATABASE=<zabbix> \\
				-e MYSQL_USER=<zabbix> \\
				-e MYSQL_PASSWORD=<zbxpass> \\
				-e MYSQL_BACK=<Y> \\
				-e MYSQL_PORT=[3306] \\
				-e MYSQL_MAX_CONN=[800] \\
				-e SERVER_ID=<1> \\
				-e REPL_IPR=<10.0.0.%> \\
				-e REPL_USER=<repl> \\
				-e REPL_PASSWORD=<newpass> \\
				-e MASTER_HOST=<10.0.0.50> \\
				-e MASTER_PORT=[3306] \\
				-e IPTABLES=<"192.168.10.0/24,10.0.0.0/24"> \\
				-e MYSQL_GENERAL_LOG=Y \\
				--hostname mysql-rpm \\
				--name mysql-rpm mysql-rpm
	"
fi

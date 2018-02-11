#!/bin/bash
set -e

if [ "$1" = 'mysqld_safe' ]; then

: ${MYSQL_ROOT_PASSWORD:=$(pwmake 128)}
: ${MYSQL_ROOT_LOCAL_PASSWORD:=newpass}
: ${MYSQL_SSTUSER_PASSWORD:=passw0rd}
: ${MYSQL_REPL_PASSWORD:=123456}
: ${SYNC_BINLOG:=0}
: ${MYSQL_MAX_CONN:=800}


	#Get mysql version
	mysql_V="$(rpm -qa |awk -F- '$1"-"$2"-"$3"-"$4=="Percona-XtraDB-Cluster-server"{print $5}' |awk -F. '{print $1$2}')"


	##init mysql
	init_mysql() {
	#Initialize MYSQL
	if [ "$mysql_V" -ge "57" ]; then
		echo "Initializing MySQL $mysql_V"
		mysqld --initialize-insecure --user=mysql
		mysql_ssl_rsa_setup 2>/dev/null
		mysqld --skip-networking --user=mysql &
		pid="$!"
		rootCreate="ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_LOCAL_PASSWORD}';"
	else
		if [ "$mysql_V" -eq "56" ]; then
			echo "Initializing MySQL $mysql_V"
			mysql_install_db --rpm --keep-my-cnf --user=mysql &>/dev/null
			mysqld --skip-networking --user=mysql &>/dev/null &
			pid="$!"
			rootSetup="SET PASSWORD FOR 'root'@'localhost' = PASSWORD('${MYSQL_ROOT_LOCAL_PASSWORD}');"
		fi
		
		if [ "$mysql_V" -eq "55" ]; then
			echo "Initializing MySQL $mysql_V"
			mysql_install_db --rpm --user=mysql &>/dev/null
			mysqld --skip-networking --user=mysql &>/dev/null &
			pid="$!"
			rootSetup="SET PASSWORD FOR 'root'@'localhost' = PASSWORD('${MYSQL_ROOT_LOCAL_PASSWORD}');"
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
		echo >&2 'MySQL init process failed...'
		exit 1
	else
		echo "MySQL init process running..."
	fi
	
	#Set the root password and remote database access
	"${mysql[@]}" <<-EOSQL
		SET @@SESSION.SQL_LOG_BIN=0;
		DELETE FROM mysql.user where user != 'mysql.sys';
		${rootCreate}
		GRANT ALL ON *.* TO 'root'@'localhost' WITH GRANT OPTION;
		${rootSetup}
		CREATE USER 'root'@'%' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';
		GRANT ALL ON *.* TO 'root'@'%' WITH GRANT OPTION;
		CREATE USER 'sstuser'@'localhost' IDENTIFIED BY '${MYSQL_SSTUSER_PASSWORD}';
		GRANT RELOAD, LOCK TABLES, PROCESS, REPLICATION CLIENT ON *.* TO 'sstuser'@'localhost';
		DROP DATABASE IF EXISTS test;
		FLUSH PRIVILEGES;
	EOSQL
	
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
		echo "GRANT REPLICATION SLAVE ON *.*  TO 'repl'@'"$REPL_IPR"' IDENTIFIED BY '"$MYSQL_REPL_PASSWORD"' ;" | "${mysql[@]}"
		echo -e "MYSQL repl PASSWORD: $MYSQL_REPL_PASSWORD" |tee /var/lib/mysql/mysql/repl_info
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
	}


	##init cnf
	init_cnf() {
	DEV=$(route -n |awk '$1=="0.0.0.0"{print $NF }')
	SERVER_IP=$(ifconfig $DEV |awk '$3=="netmask"{print $2}')
	
	cat >/etc/my.cnf <<-EOF
	#redhat.xyz
	!includedir /etc/my.cnf.d/
	##5.7	!includedir /etc/percona-xtradb-cluster.conf.d/

	[mysqld]
	##logbin	log-bin=$(hostname)-bin
	##logbin	server-id=1
	##logbin	innodb_flush_log_at_trx_commit=1
	##logbin	sync_binlog=$SYNC_BINLOG

	max_connections=$MYSQL_MAX_CONN
	datadir=/var/lib/mysql
	user=mysql
	log-error=/var/log/mysqld.log
	pid-file=/var/run/mysqld/mysqld.pid

	# Path to Galera library
	wsrep_provider=/usr/lib64/libgalera_smm.so

	# Cluster name
	wsrep_cluster_name=pcx_cluster
	# Cluster connection URL contains the IPs of node#1, node#2 and node#3
	wsrep_cluster_address=gcomm://$PXC_ADDRESS

	# Node 1 name
	wsrep_node_name=pxc-$SERVER_IP
	# Node 1 address
	wsrep_node_address=$SERVER_IP

	# SST method
	wsrep_sst_method=xtrabackup-v2
	# Authentication for SST method
	wsrep_sst_auth="sstuser:$MYSQL_SSTUSER_PASSWORD"

	# In order for Galera to work correctly binlog format should be ROW
	binlog_format=ROW
	# MyISAM storage engine has only experimental support
	default_storage_engine=InnoDB
	# This InnoDB autoincrement locking mode is a requirement for Galera
	innodb_autoinc_lock_mode=2

        # number of threads that can apply replication transactions in parallel
        wsrep_slave_threads=$(nproc)

	# 5.5、5.6
	##5.6	innodb_buffer_pool_size        = 100M
	##5.6	innodb_flush_log_at_trx_commit = 0
	##5.6	innodb_flush_method            = O_DIRECT
	##5.6	innodb_log_files_in_group      = 2
	##5.6	innodb_log_file_size           = 20M
	##5.6	innodb_file_per_table          = 1
	##5.6	innodb_autoinc_lock_mode       = 2

	# 5.5
	##5.5	innodb_locks_unsafe_for_binlog = 1
	EOF


	if [ "$mysql_V" -eq "57" ]; then
		sed -i 's/##5.7//g' /etc/my.cnf
		if [ "$SYNC_BINLOG" -eq "1" ]; then
			sed -i '/\[mysqld\]/a sync_binlog=1' /etc/my.cnf
		fi
	fi
	
	if [ "$mysql_V" -eq "56" ]; then
		sed -i 's/##5.6//g' /etc/my.cnf
		if [ "$LOG_BIN" ]; then
			sed -i 's/##logbin//g' /etc/my.cnf
		fi
	fi
		
	if [ "$mysql_V" -eq "55" ]; then
		sed -i 's/##5.6//g' /etc/my.cnf
		sed -i 's/##5.5//g' /etc/my.cnf
		if [ "$LOG_BIN" ]; then
			sed -i 's/##logbin//g' /etc/my.cnf
		fi
	fi
	}


	##init other
	init_other() {
	#Backup Database
	if [ "$MYSQL_BACK" ]; then
	    [ -z "$MYSQL_ROOT_LOCAL_PASSWORD" ] && MYSQL_ROOT_LOCAL_PASSWORD=$(awk '{print $5}' /var/lib/mysql/mysql/local_info)
		sed -i 's/newpass/'$MYSQL_ROOT_LOCAL_PASSWORD'/' /backup.sh
		echo "0 4 * * * . /etc/profile;/bin/sh /backup.sh &>/dev/null" >>/var/spool/cron/root
	fi
	
	#iptables, Need root authority "--privileged"
	if [ $IPTABLES ]; then
		cat > /iptables.sh <<-END
		iptables -I INPUT -p tcp --dport 3306 -j DROP
		iptables -I INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT
		iptables -I INPUT -s $IPTABLES -p tcp -m state --state NEW -m tcp --dport 3306 -m comment --comment PXC -j ACCEPT
		iptables -I INPUT -p tcp -m state --state NEW -m tcp --dport 4567:4568 -m comment --comment PXC -j ACCEPT
		iptables -I INPUT -p tcp -m state --state NEW -m tcp --dport 4444 -m comment --comment PXC -j ACCEPT
		END
	fi
	
	[ -f /iptables.sh ] && [ -z "`iptables -S |grep PXC`" ] && . /iptables.sh
	crond
	}


	##init pxc
	init_pxc() {
	echo
	echo "MYSQL root PASSWORD: $MYSQL_ROOT_PASSWORD" |tee /var/lib/mysql/mysql/root_info
	echo "MYSQL root LOCAL PASSWORD: $MYSQL_ROOT_LOCAL_PASSWORD" |tee /var/lib/mysql/mysql/local_info
	echo "MYSQL sstuser PASSWORD: $MYSQL_SSTUSER_PASSWORD" |tee /var/lib/mysql/mysql/sst_info
	echo
	mysqld_safe --basedir=/usr --wsrep-new-cluster
	}
	
	
	##init start
	if [ -d "/var/lib/mysql/mysql" ]; then
		echo "/var/lib/mysql/mysql already exists, skip"
	else
		[ ! -d /var/run/mysqld ] && mkdir /var/run/mysqld && chown mysql.mysql /var/run/mysqld
	
		if [ "$XPC_INIT" ]; then
			init_mysql
			init_cnf
			init_other
			init_pxc
		fi
		
		if [ -z $(grep redhat.xyz /etc/my.cnf) ]; then
			if [ "$mysql_V" -ge "57" ]; then
        			echo "Initializing MySQL $mysql_V"
        			mysqld --initialize-insecure --user=mysql
			else
        			if [ "$mysql_V" -eq "56" ]; then
			       		echo "Initializing MySQL $mysql_V"
					mysql_install_db --rpm --keep-my-cnf --user=mysql &>/dev/null
				fi

				if [ "$mysql_V" -eq "55" ]; then
					echo "Initializing MySQL $mysql_V"
					mysql_install_db --rpm --user=mysql &>/dev/null
				fi
			fi

			init_cnf
			sleep 15
		fi
	fi


	echo "Start MYSQL ****"
	init_other
	exec "$@" 1>/dev/null
else

    echo -e "
    Example:
				docker run -d --restart always [--privileged] \\
				-v /docker/pxc-N:/var/lib/mysql \\
				-v /docker/sql:/docker-entrypoint-initdb.d \\
				-e XPC_INIT=<Y> \\
				-e PXC_ADDRESS=<"10.0.0.61,10.0.0.62,10.0.0.63"> \\
				-e MYSQL_ROOT_PASSWORD=<newpass> \\
				-e MYSQL_ROOT_LOCAL_PASSWORD=[newpass] \\
				-e MYSQL_SSTUSER_PASSWORD=[passw0rd] \\
				-e MYSQL_REPL_PASSWORD=[123456] \\
				-e REPL_IPR=<"10.0.0.%"> \\
				-e LOG_BIN=<Y> \\
				-e SYNC_BINLOG=[0] \\
				-e MYSQL_DATABASE=<zabbix> \\
				-e MYSQL_USER=<zabbix> \\
				-e MYSQL_PASSWORD=<zbxpass> \\
				-e MYSQL_MAX_CONN=[800] \\
				-e MYSQL_BACK=<Y> \\
				-e IPTABLES=<"192.168.10.0/24,10.0.0.0/24"> \\
				--hostname mysql-pxc \\
				--name mysql-pxc mysql-pxc
	" 
fi

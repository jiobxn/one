#!/bin/bash
set -e

: ${FTP_PORT:="21"}
: ${MIN_PORT:="25000"}
: ${MAX_PORT:="25100"}
: ${DATA_PORT:="20"}
: ${FTP_USER:="vsftpd"}
: ${FTP_PASS:="$(openssl rand -hex 10)"}
: ${ANON_ROOT:="public"}
: ${ANON_CHMOD:="4"}
: ${MAX_CLIENT:="0"}
: ${MAX_CONN:="0"}
: ${ANON_MB:="0"}
: ${LOCAL_MB:="0"}
: ${HI_FTP:="Serv-U FTP Server v16.0 ready"}


USER_CHMOD() {
	if [ "$CHMOD" -eq 1 ]; then
		cat >> /etc/vsftpd/conf/$USER <<-END
		anon_umask=0442
		chown_upload_mode=0224
		anon_upload_enable=YES
		anon_mkdir_write_enable=NO
		anon_other_write_enable=NO
		local_root=/home/$FTP_USER/$ROOT
		END
	elif [ "$CHMOD" -eq 2 ]; then
		cat >> /etc/vsftpd/conf/$USER <<-END
		anon_umask=0442
		chown_upload_mode=0224
		anon_upload_enable=NO
		anon_mkdir_write_enable=YES
		anon_other_write_enable=NO
		local_root=/home/$FTP_USER/$ROOT
		END
	elif [ "$CHMOD" -eq 3 ]; then
		cat >> /etc/vsftpd/conf/$USER <<-END
		anon_umask=0442
		chown_upload_mode=0224
		anon_upload_enable=YES
		anon_mkdir_write_enable=YES
		anon_other_write_enable=NO
		local_root=/home/$FTP_USER/$ROOT
		END
	elif [ "$CHMOD" -eq 4 ]; then
		cat >> /etc/vsftpd/conf/$USER <<-END
		anon_umask=0022
		chown_upload_mode=0644
		anon_upload_enable=NO
		anon_mkdir_write_enable=NO
		anon_other_write_enable=NO
		local_root=/home/$FTP_USER/$ROOT
		END
	elif [ "$CHMOD" -eq 5 ]; then
		cat >> /etc/vsftpd/conf/$USER <<-END
		anon_umask=0022
		chown_upload_mode=0644
		anon_upload_enable=YES
		anon_mkdir_write_enable=NO
		anon_other_write_enable=NO
		local_root=/home/$FTP_USER/$ROOT
		END
	elif [ "$CHMOD" -eq 6 ]; then
		cat >> /etc/vsftpd/conf/$USER <<-END
		anon_umask=0022
		chown_upload_mode=0644
		anon_upload_enable=NO
		anon_mkdir_write_enable=YES
		anon_other_write_enable=NO
		local_root=/home/$FTP_USER/$ROOT
		END
	elif [ "$CHMOD" -eq 7 ]; then
		cat >> /etc/vsftpd/conf/$USER <<-END
		anon_umask=0022
		chown_upload_mode=0644
		anon_upload_enable=YES
		anon_mkdir_write_enable=YES
		anon_other_write_enable=NO
		local_root=/home/$FTP_USER/$ROOT
		END
	elif [ "$CHMOD" -eq 8 ]; then
		cat >> /etc/vsftpd/conf/$USER <<-END
		anon_umask=0022
		chown_upload_mode=0644
		anon_upload_enable=NO
		anon_mkdir_write_enable=NO
		anon_other_write_enable=YES
		local_root=/home/$FTP_USER/$ROOT
		END
	elif [ "$CHMOD" -eq 9 ]; then
		cat >> /etc/vsftpd/conf/$USER <<-END
		anon_umask=0442
		chown_upload_mode=0224
		anon_upload_enable=YES
		anon_mkdir_write_enable=NO
		anon_other_write_enable=YES
		local_root=/home/$FTP_USER/$ROOT
		END
	elif [ "$CHMOD" -eq 10 ]; then
		cat >> /etc/vsftpd/conf/$USER <<-END
		anon_umask=0442
		chown_upload_mode=0224
		anon_upload_enable=NO
		anon_mkdir_write_enable=YES
		anon_other_write_enable=YES
		local_root=/home/$FTP_USER/$ROOT
		END
	elif [ "$CHMOD" -eq 11 ]; then
		cat >> /etc/vsftpd/conf/$USER <<-END
		anon_umask=0442
		chown_upload_mode=0224
		anon_upload_enable=YES
		anon_mkdir_write_enable=YES
		anon_other_write_enable=YES
		local_root=/home/$FTP_USER/$ROOT
		END
	elif [ "$CHMOD" -eq 12 ]; then
		cat >> /etc/vsftpd/conf/$USER <<-END
		anon_umask=0022
		chown_upload_mode=0644
		anon_upload_enable=NO
		anon_mkdir_write_enable=YES
		anon_other_write_enable=YES
		local_root=/home/$FTP_USER/$ROOT
		END
	elif [ "$CHMOD" -eq 13 ]; then
		cat >> /etc/vsftpd/conf/$USER <<-END
		anon_umask=0022
		chown_upload_mode=0644
		anon_upload_enable=YES
		anon_mkdir_write_enable=NO
		anon_other_write_enable=YES
		local_root=/home/$FTP_USER/$ROOT
		END
	elif [ "$CHMOD" -eq 14 ]; then
		cat >> /etc/vsftpd/conf/$USER <<-END
		anon_umask=0022
		chown_upload_mode=0644
		anon_upload_enable=NO
		anon_mkdir_write_enable=NO
		anon_other_write_enable=YES
		local_root=/home/$FTP_USER/$ROOT
		END
	elif [ "$CHMOD" -eq 15 ]; then
		cat >> /etc/vsftpd/conf/$USER <<-END
		anon_umask=0022
		chown_upload_mode=0644
		anon_upload_enable=YES
		anon_mkdir_write_enable=YES
		anon_other_write_enable=YES
		local_root=/home/$FTP_USER/$ROOT
		END
	else
		echo "chmod mask is not supported and should be 1-15"
	fi
}


PUBLIC_CHMOD() {
	if [ "$ANON_CHMOD" -eq 1 ]; then
		cat >> /etc/vsftpd/vsftpd.conf <<-END
		anon_umask=0442
		chown_upload_mode=0224
		anon_upload_enable=YES
		anon_mkdir_write_enable=NO
		anon_other_write_enable=NO
		chown_uploads=YES
		chown_username=$FTP_USER
		END
	elif [ "$ANON_CHMOD" -eq 2 ]; then
		cat >> /etc/vsftpd/vsftpd.conf <<-END
		anon_umask=0442
		chown_upload_mode=0224
		anon_upload_enable=NO
		anon_mkdir_write_enable=YES
		anon_other_write_enable=NO
		chown_uploads=YES
		chown_username=$FTP_USER
		END
	elif [ "$ANON_CHMOD" -eq 3 ]; then
		cat >> /etc/vsftpd/vsftpd.conf <<-END
		anon_umask=0442
		chown_upload_mode=0224
		anon_upload_enable=YES
		anon_mkdir_write_enable=YES
		anon_other_write_enable=NO
		chown_uploads=YES
		chown_username=$FTP_USER
		END
	elif [ "$ANON_CHMOD" -eq 4 ]; then
		cat >> /etc/vsftpd/vsftpd.conf <<-END
		anon_umask=0022
		chown_upload_mode=0644
		anon_upload_enable=NO
		anon_mkdir_write_enable=NO
		anon_other_write_enable=NO
		#chown_uploads=YES
		#chown_username=$FTP_USER
		END
	elif [ "$ANON_CHMOD" -eq 5 ]; then
		cat >> /etc/vsftpd/vsftpd.conf <<-END
		anon_umask=0022
		chown_upload_mode=0644
		anon_upload_enable=YES
		anon_mkdir_write_enable=NO
		anon_other_write_enable=NO
		chown_uploads=YES
		chown_username=$FTP_USER
		END
	elif [ "$ANON_CHMOD" -eq 6 ]; then
		cat >> /etc/vsftpd/vsftpd.conf <<-END
		anon_umask=0022
		chown_upload_mode=0644
		anon_upload_enable=NO
		anon_mkdir_write_enable=YES
		anon_other_write_enable=NO
		chown_uploads=YES
		chown_username=$FTP_USER
		END
	elif [ "$ANON_CHMOD" -eq 7 ]; then
		cat >> /etc/vsftpd/vsftpd.conf <<-END
		anon_umask=0022
		chown_upload_mode=0644
		anon_upload_enable=YES
		anon_mkdir_write_enable=YES
		anon_other_write_enable=NO
		chown_uploads=YES
		chown_username=$FTP_USER
		END
	elif [ "$ANON_CHMOD" -eq 8 ]; then
		cat >> /etc/vsftpd/vsftpd.conf <<-END
		anon_umask=0022
		chown_upload_mode=0644
		anon_upload_enable=NO
		anon_mkdir_write_enable=NO
		anon_other_write_enable=YES
		chown_uploads=YES
		chown_username=$FTP_USER
		END
	elif [ "$ANON_CHMOD" -eq 9 ]; then
		cat >> /etc/vsftpd/vsftpd.conf <<-END
		anon_umask=0442
		chown_upload_mode=0224
		anon_upload_enable=YES
		anon_mkdir_write_enable=NO
		anon_other_write_enable=YES
		chown_uploads=YES
		chown_username=$FTP_USER
		END
	elif [ "$ANON_CHMOD" -eq 10 ]; then
		cat >> /etc/vsftpd/vsftpd.conf <<-END
		anon_umask=0442
		chown_upload_mode=0224
		anon_upload_enable=NO
		anon_mkdir_write_enable=YES
		anon_other_write_enable=YES
		chown_uploads=YES
		chown_username=$FTP_USER
		END
	elif [ "$ANON_CHMOD" -eq 11 ]; then
		cat >> /etc/vsftpd/vsftpd.conf <<-END
		anon_umask=0442
		chown_upload_mode=0224
		anon_upload_enable=YES
		anon_mkdir_write_enable=YES
		anon_other_write_enable=YES
		chown_uploads=YES
		chown_username=$FTP_USER
		END
	elif [ "$ANON_CHMOD" -eq 12 ]; then
		cat >> /etc/vsftpd/vsftpd.conf <<-END
		anon_umask=0022
		chown_upload_mode=0644
		anon_upload_enable=NO
		anon_mkdir_write_enable=YES
		anon_other_write_enable=YES
		chown_uploads=YES
		chown_username=$FTP_USER
		END
	elif [ "$ANON_CHMOD" -eq 13 ]; then
		cat >> /etc/vsftpd/vsftpd.conf <<-END
		anon_umask=0022
		chown_upload_mode=0644
		anon_upload_enable=YES
		anon_mkdir_write_enable=NO
		anon_other_write_enable=YES
		chown_uploads=YES
		chown_username=$FTP_USER
		END
	elif [ "$ANON_CHMOD" -eq 14 ]; then
		cat >> /etc/vsftpd/vsftpd.conf <<-END
		anon_umask=0022
		chown_upload_mode=0644
		anon_upload_enable=NO
		anon_mkdir_write_enable=NO
		anon_other_write_enable=YES
		chown_uploads=YES
		chown_username=$FTP_USER
		END
	elif [ "$ANON_CHMOD" -eq 15 ]; then
		cat >> /etc/vsftpd/vsftpd.conf <<-END
		anon_umask=0022
		chown_upload_mode=0644
		anon_upload_enable=YES
		anon_mkdir_write_enable=YES
		anon_other_write_enable=YES
		chown_uploads=YES
		chown_username=$FTP_USER
		END
	else
		echo "chmod mask is not supported and should be 1-15"
	fi
}


INIT_FTP() {
	mkdir -p /etc/vsftpd/conf
	sed -i 's/anonymous_enable=YES/anonymous_enable=NO/' /etc/vsftpd/vsftpd.conf
	sed -i 's/listen=NO/listen=YES/' /etc/vsftpd/vsftpd.conf
	sed -i 's/listen_ipv6=YES/listen_ipv6=NO/' /etc/vsftpd/vsftpd.conf
	echo -e "$FTP_USER\n$FTP_PASS" > /etc/vsftpd/vuser.txt
	echo "# -- user  -- passwd  -- chmod  -- root -- #" |tee /key/ftp.log
	echo "$FTP_USER $FTP_PASS 15 /" |tee -a /key/ftp.log

	#user
	if [ -f /key/user.txt ];then
	for i in $(cat /key/user.txt |grep -v ^# |grep -v ^$ |grep :);do
		USER=$(echo $i |awk -F: '{print $1}')
		PASS=$(echo $i |awk -F: '{print $2}')
		CHMOD=$(echo $i |awk -F: '{print $3}')
		ROOT=$(echo $i |awk -F: '{print $NF}')
		
		if [ -n "$USER" ]; then
			[ -z "$PASS" ] && PASS=$(openssl rand -hex 5)
			[ -z "$CHMOD" ] && CHMOD=4
			
			USER_CHMOD
			
			echo -e "$USER\n$PASS" >> /etc/vsftpd/vuser.txt
			mkdir -p /home/$FTP_USER/$ROOT
			echo "$USER $PASS $CHMOD /$ROOT" |tee -a /key/ftp.log
		fi
	done
	fi

	#auth
	db_load -T -t hash -f /etc/vsftpd/vuser.txt /etc/vsftpd/vuser.db
	chmod 600 /etc/vsftpd/vuser.*
	useradd -s /sbin/nologin vsftpd
	sed -i '2iauth sufficient /lib64/security/pam_userdb.so db=/etc/vsftpd/vuser' /etc/pam.d/vsftpd
	sed -i '3iaccount sufficient /lib64/security/pam_userdb.so db=/etc/vsftpd/vuser' /etc/pam.d/vsftpd
	chown -R vsftpd.vsftpd /home/$FTP_USER

	#Download rate
	[ "$ANON_MB" -gt 0 ] && ANON_MB=$(echo "$ANON_MB*1048576" |bc)
	[ "$LOCAL_MB" -gt 0 ] && LOCAL_MB=$(echo "$LOCAL_MB*1048576" |bc)

	#conf
	cat >> /etc/vsftpd/vsftpd.conf <<-END
	
	#vuser
	guest_enable=YES
	guest_username=$FTP_USER
	pam_service_name=vsftpd
	user_config_dir=/etc/vsftpd/conf
	virtual_use_local_privs=NO
	allow_writeable_chroot=YES
	ftpd_banner=$HI_FTP
	use_localtime=YES
	chroot_local_user=YES
	delete_failed_uploads=YES
	listen_port=$FTP_PORT
	max_clients=$MAX_CLIENT
	max_per_ip=$MAX_CONN
	anon_max_rate=$ANON_MB
	local_max_rate=$LOCAL_MB
	dual_log_enable=YES
	xferlog_file=/var/log/xferlog           
	vsftpd_log_file=/var/log/vsftpd.log
	pasv_min_port=$MIN_PORT
	pasv_max_port=$MAX_PORT
	pasv_promiscuous=YES
	END

	#$FTP_USER
	cat >> /etc/vsftpd/conf/$FTP_USER <<-END
	anon_umask=0022
	chown_upload_mode=0644
	anon_upload_enable=YES
	anon_mkdir_write_enable=YES
	anon_other_write_enable=YES
	local_root=/home/$FTP_USER
	END

	#ANON
	if [ $ANON_CHMOD -ge 1 -a $ANON_CHMOD -le 15 ];then
		mkdir -p /home/$FTP_USER/$ANON_ROOT/pub
		sed -i 's/anonymous_enable=NO/#anonymous_enable=NO/' /etc/vsftpd/vsftpd.conf
		
		cat >> /etc/vsftpd/vsftpd.conf <<-END
		
		#anon
		anonymous_enable=YES
		anon_root=/home/$FTP_USER/$ANON_ROOT
		END
		
		PUBLIC_CHMOD
		
		chown -R vsftpd.vsftpd /home/$FTP_USER
	fi

	#pasv disable
	if [ "$PASV_DISABLE" == "Y" ];then
		echo "pasv_enable=NO" >>/etc/vsftpd/vsftpd.conf
		
		if [ $DATA_PORT -ne 20 ];then
			echo "ftp_data_port=$DATA_PORT" >>/etc/vsftpd/vsftpd.conf
		fi
	fi

	#ssl
	if [ "$FTP_SSL" == "Y" ];then
		if [ ! -f /key/vsftpd.pem ];then
			openssl req -x509 -nodes -days 3650 -newkey rsa:2048 -keyout /etc/vsftpd/vsftpd.pem -out /etc/vsftpd/vsftpd.pem -subj "/C=CN/L=London/O=Company Ltd/CN=vsftpd-docker" 2>/dev/null
			\cp /etc/vsftpd/vsftpd.pem /key/vsftpd.pem 
		else
			\cp /key/vsftpd.pem /etc/vsftpd/vsftpd.pem
		fi
		
		cat >> /etc/vsftpd/vsftpd.conf <<-END
		
		#ssl
		ssl_enable=YES
		allow_anon_ssl=YES
		force_local_logins_ssl=YES
		force_local_data_ssl=YES
		ssl_tlsv1=YES
		rsa_cert_file=/etc/vsftpd/vsftpd.pem
		ssl_ciphers=HIGH
		END
	fi

	#iptables
	if [ "$IPTABLES" == "Y" ]; then
		cat > /iptables.sh <<-END
		iptables -I INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT
		iptables -I INPUT -p tcp -m state --state NEW -m tcp --dport $FTP_PORT -m comment --comment VSFTPD -j ACCEPT
		iptables -I INPUT -p tcp -m state --state NEW -m tcp --dport $MIN_PORT:$MAX_PORT -m comment --comment VSFTPD -j ACCEPT
		END
	fi
}


#help
HELP() {
	echo -e "
	Example:
				docker run -d --restart unless-stopped --network host --cap-add=NET_ADMIN \\
				-v /docker:/home \\
				-v /docker/ftp:/key \\
				-p 21:21 \\
				-p 25000-25100:25000-25100 \\
				-e FTP_PORT=[21] \\
				-e MIN_PORT=[25000] \\
				-e MAX_PORT=[25100] \\
				-e FTP_USER=[vsftpd] \\
				-e FTP_PASS=[$(openssl rand -hex 10)] \\
				-e ANON_ROOT=[public] \\
				-e ANON_CHMOD=[4] \\
				-e MAX_CLINT=[0] \\
				-e MAX_CONN=[0] \\
				-e ANON_MB=[0] \\
				-e LOCAL_MB=[0] \\
				-e HI_FTP=["Serv-U FTP Server v16.0 ready"] \\
				-e PASV_DISABLE=<Y> \\
				-e DATA_PORT=[20] \\
				-e FTP_SSL=<Y> \\
				-e IPTABLES=<Y> \\
				--name vsftpd vsftpd
	
	chmod mask:
	1 upload
	2 create
	4 download
	8 delete
	3 upload, create
	5 upload, download
	6 create, download
	7 upload, create, download
	9 upload, delete
	10 create, delete
	11 upload, create, delete
	12 download, delete
	13 upload, download, delete
	14 download, delete
	15 upload, create, download, delete
	
	echo -e 'admin:123456:15:admin\npublic:123456:7:admin/public\nboss:123456:4:' |tee /docker/ftp/user.txt
	"
}


#start
if [ "$1" = '/usr/sbin/init' ]; then
	if [ ! -d /etc/vsftpd/conf ];then
		INIT_FTP
	fi

	[ -f /iptables.sh ] && [ -z "`iptables -S |grep VSFTPD`" ] && . /iptables.sh
	vsftpd
	exec "$@"
else
	HELP
fi

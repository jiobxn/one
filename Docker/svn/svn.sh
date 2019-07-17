#!/bin/bash
set -e

if [ "$1" = 'httpd' ]; then

: ${REPOS:="repos"}
: ${ADMIN:="admin"}
: ${USER:="user1"}
: ${ADMIN_PASS:="$(openssl rand -hex 10)"}
: ${USER_PASS:="$(openssl rand -hex 6)"}
: ${SVN_PORT:="3690"}
: ${HTTP_PORT:="80"}
: ${HTTPS_PORT:="443"}


if [ -z "$(grep "redhat.xyz" /etc/httpd/conf/httpd.conf)" ]; then
	\cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
	echo "Initialize httpd"
	#key
	if [ -f /key/server.crt -a -f /key/server.key ]; then
		\cp /key/server.crt /etc/pki/tls/certs/localhost.crt
		\cp /key/server.key /etc/pki/tls/private/localhost.key
	fi
	
	#httpd
	cat >>/etc/httpd/conf/httpd.conf <<-END
	#
	#redhat.xyz
	ServerName localhost
	AddDefaultCharset UTF-8

	<IfModule deflate_module>  
	AddOutputFilterByType DEFLATE all  
	SetOutputFilter DEFLATE  
	</ifModule>  

	#svn
	<Location /svn>
	  DAV svn
	  SVNParentPath /home/svn
	  SVNListParentPath on

	  # Authentication: Basic
	  AuthName "Subversion repository"
	  AuthType Basic
	  AuthBasicProvider file
	  AuthUserFile /home/svn/conf/htpasswd
	  Require valid-user

	  # Authorization: Path-based access control
	  AuthzSVNAccessFile /home/svn/conf/authz
	</Location>
	END

	#anon
	if [ "$ANON" == "Y" ]; then
		sed -i '/AuthzSVNAccessFile/ a \  Satisfy Any' /etc/httpd/conf/httpd.conf
	fi

	#port
	echo "svnserve -d -r /home/svn --listen-port $SVN_PORT" >/usr/local/bin/svnd
	chmod +x /usr/local/bin/svnd

	if [ "$HTTP_PORT" != "80" ]; then
		sed -i "s/80/$HTTP_PORT/g" /etc/httpd/conf/httpd.conf
	fi
	
	if [ "$HTTPS_PORT" != "443" ]; then
		sed -i "s/443/$HTTPS_PORT/g" /etc/httpd/conf.d/ssl.conf
	fi

	#svn
	cat >/home/svnserve.conf.txt<<-END
	[general]
	anon-access = none
	#有效值是"write", "read",and "none".
	auth-access = write
	password-db = /home/svn/conf/passwd
	authz-db = /home/svn/conf/authz
	realm = /home/svn
	END

	cat >/home/authz.txt<<-END
	[groups]
	manager=$ADMIN
	users=$USER

	[/]
	@manager=rw
	*=

	[repos:/]
	@manager=rw
	@users=rw
	*=
	END

	if [ ! -d /home/svn/conf ]; then
		echo "create default repository"
		mkdir -p /home/svn/conf
		[ ! -d /home/svn/$REPOS ] && svnadmin create /home/svn/$REPOS && chown -R apache.apache /home/svn/$REPOS

		echo "$ADMIN:$(openssl passwd -apr1 $ADMIN_PASS)" > /home/svn/conf/htpasswd
		echo "$USER:$(openssl passwd -apr1 $USER_PASS)" >> /home/svn/conf/htpasswd
		echo -e "$ADMIN = $ADMIN_PASS\n$USER = $USER_PASS" > /home/svn/conf/passwd
		echo -e "$ADMIN = $ADMIN_PASS\n$USER = $USER_PASS"

		\cp /home/svnserve.conf.txt /home/svn/conf/svnserve.conf
		\cp /home/authz.txt /home/svn/conf/authz
	else
		if [ -f /home/svn/conf/authz ]; then 
			echo "authz exist"
			for i in $(grep : /home/svn/conf/authz |grep -Po '(?<=\[)[^)]*(?=\])' |awk -F: '{print $1}'); do
				[ ! -d "/home/svn/$i" ] && svnadmin create /home/svn/$i && chown -R apache.apache /home/svn/$i && echo "create $i repository"
			done
		else
			\cp /home/authz.txt /home/svn/conf/authz
			[ ! -d /home/svn/$REPOS ] && svnadmin create /home/svn/$REPOS && chown -R apache.apache /home/svn/$REPOS && echo "create default repository"
		fi
	
		if [ ! -f /home/svn/conf/htpasswd ]; then
			if [ -f /home/svn/conf/passwd ]; then
				for i in $(sed 's/ //g' /home/svn/conf/passwd); do
					user=$(echo $i |awk -F= '{print $1}')
					pass=$(echo $i |awk -F= '{print $2}')
					echo "$user:$(openssl passwd -apr1 $pass)" >> /home/svn/conf/htpasswd
					echo "$user = $pass"
				done
			else
				echo "$ADMIN:$(openssl passwd -apr1 $ADMIN_PASS)" > /home/svn/conf/htpasswd
				echo "$USER:$(openssl passwd -apr1 $USER_PASS)" >> /home/svn/conf/htpasswd
				echo -e "$ADMIN = $ADMIN_PASS\n$USER = $USER_PASS" > /home/svn/conf/passwd
				echo -e "$ADMIN = $ADMIN_PASS\n$USER = $USER_PASS"
			fi
		else
			echo "htpasswd exist"
		fi
		[ ! -f /home/svn/conf/svnserve.conf ] && cp /home/svnserve.conf.txt /home/svn/conf/svnserve.conf
	fi

	#svnadmin
	if [ "$SVNADMIN" == "Y" ]; then
		find /var/www/html/svnadmin/ -type f -print0 | xargs -0 chmod 0644
		find /var/www/html/svnadmin/ -type d -print0 | xargs -0 chmod 0755
		chown apache.apache /var/www/html/svnadmin -R
		chown apache.apache /home/svn -R
		chmod 755 /root
		echo
		echo "iF.SVNAdmin:
		SVNAuthFile=/home/svn/conf/authz
		SVNUserFile=/home/svn/conf/htpasswd
		SVNParentPath=/home/svn
		SvnExecutable=/usr/bin/svn
		SvnAdminExecutable=/usr/bin/svnadmin
		"
	fi
fi
	echo "Start ****"
	svnd
	exec "$@"
else

    echo -e "
	Example:
				docker run -d --restart unless-stopped \\
				-v /docker/svn:/home/svn \\
				-v /docker/key:/key \\
				-p 10080:80 \\
				-p 10443:443 \\
				-p 13690:3690 \\
				-e SVN_PORT=[3690] \\
				-e HTTP_PORT=[80] \\
				-e HTTPS_PORT=[443] \\
				-e REPOS=[repos] \\
				-e ADMIN=[admin] \\
				-e USER=[user1] \\
				-e ANON=<Y> \\
				-e ADMIN_PASS=[$(openssl rand -hex 10)] \\
				-e USER_PASS=[$(openssl rand -hex 6)] \\
				-e SVNADMIN=<Y> \\
				--name svn svn

	Or prepare /docker/svn/conf/authz and /docker/svn/conf/passwd files.
	"
fi

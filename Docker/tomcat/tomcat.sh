#!/bin/bash
set -e

if [ "$1" = 'catalina.sh' ]; then

: ${TOM_USER:="tom"}
: ${TOM_PASS:="$(openssl rand -base64 10 |tr -dc [:alnum:])"}
: ${TOM_CHARSET:="UTF-8"}
: ${WWW_ROOT:="ROOT"}
: ${HTTP_PORT:="8080"}
: ${HTTPS_PORT:="8443"}
: ${REDIS_PORT:="6379"}
: ${SESSION_TTL:="30"}
: ${DOWN_PORT:="8005"}
: ${KEY_PASS:="redhat"}
: ${MAX_MEM="$(($(free -m |grep Mem |awk '{print $2}')*50/100))"}

  if [ -z "$(grep "redhat.xyz" /tomcat/conf/server.xml)" ]; then
	echo "Initialize tomcat"
	sed -i '2 i <!-- redhat.xyz -->' /tomcat/conf/server.xml

	#HTTPS
	if [ -f /key/server.keystore ]; then
		\cp /key/server.keystore /tomcat/conf/server.keystore
	else
		keytool -genkey -alias tomcat -keyalg RSA -keypass $KEY_PASS -storepass $KEY_PASS -dname "CN=docker-tomcat, OU=redhat.xyz, O=JIOBXN, L=GZ, S=GD, C=CN" -keystore /tomcat/conf/server.keystore -validity 3600 
	fi

	cat >/tomcat-ssl.txt <<-END
	    <Connector
               protocol="org.apache.coyote.http11.Http11NioProtocol"
               port="8443" acceptCount="$((`nproc`*10240))" maxThreads="$((`nproc`*10240))"
	       compression="on" disableUploadTimeout="true" URIEncoding="$TOM_CHARSET"
               scheme="https" secure="true" SSLEnabled="true"
               keystoreFile="conf/server.keystore" keystorePass="$KEY_PASS"
               clientAuth="false" sslProtocol="TLS"/>
	END
	sed -i '/A "Connector" using the shared thread pool/ r /tomcat-ssl.txt' /tomcat/conf/server.xml


	#manage user
	if [ "$MANAGE_IP" ]; then
	cat >/tomcat/conf/tomcat-users.xml <<-END
	<?xml version="1.0" encoding="UTF-8"?>
	<tomcat-users xmlns="http://tomcat.apache.org/xml"
				  xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
				  xsi:schemaLocation="http://tomcat.apache.org/xml tomcat-users.xsd"
				  version="1.0">
		<role rolename="tomcat"/>
		<role rolename="role1"/>
		<role rolename="admin-gui"/>
		<role rolename="admin-script"/>
		<role rolename="manager-gui"/>
		<role rolename="manager-script"/>
		<role rolename="manager-jmx"/>
		<role rolename="manager-status"/>
		<user username="$TOM_USER" password="$TOM_PASS" roles="tomcat,role1,admin-gui,admin-script,manager-gui,manager-script,manager-jmx,manager-status"/>
	</tomcat-users>
	END

	cat >/tomcat/webapps/manager/META-INF/context.xml <<-END
	<?xml version="1.0" encoding="UTF-8"?>
	<Context antiResourceLocking="false" privileged="true" >
	  <CookieProcessor className="org.apache.tomcat.util.http.Rfc6265CookieProcessor"
					   sameSiteCookies="strict" />
	  <Valve className="org.apache.catalina.valves.RemoteAddrValve"
			 allow="$MANAGE_IP" />
	  <Manager sessionAttributeValueClassNameFilter="java\.lang\.(?:Boolean|Integer|Long|Number|String)|org\.apache\.catalina\.filters\.CsrfPreventionFilter\$LruCache(?:\$1)?|java\.util\.(?:Linked)?HashMap"/>
	</Context>
	END

	cat >/tomcat/webapps/host-manager/META-INF/context.xml <<-END
	<?xml version="1.0" encoding="UTF-8"?>
	<Context antiResourceLocking="false" privileged="true" >
	  <CookieProcessor className="org.apache.tomcat.util.http.Rfc6265CookieProcessor"
					   sameSiteCookies="strict" />
	  <Valve className="org.apache.catalina.valves.RemoteAddrValve"
			 allow="$MANAGE_IP" />
	  <Manager sessionAttributeValueClassNameFilter="java\.lang\.(?:Boolean|Integer|Long|Number|String)|org\.apache\.catalina\.filters\.CsrfPreventionFilter\$LruCache(?:\$1)?|java\.util\.(?:Linked)?HashMap"/>
	</Context>
	END
	echo -e "\nuser: $TOM_USER\npassword: $TOM_PASS\nmanage: $MANAGE_IP\n"
	fi


	#log
	sed -i 's/pattern="%h /pattern="%{X-Forwarded-For}i %h /' /tomcat/conf/server.xml


	#gzip
	sed -i '/Connector port="8080"/ a \               acceptCount="'$((`nproc`*10240))'" maxThreads="'$((`nproc`*10240))'" \n\               compression="on" disableUploadTimeout="true" URIEncoding='\"$TOM_CHARSET\"'' /tomcat/conf/server.xml


	#www root
	if [ "$WWW_ROOT" ]; then
		sed -i '/unpackWARs/ a \            <Context path="" docBase='\"$WWW_ROOT\"' />' /tomcat/conf/server.xml
	fi


	#alias
	if [ "$WWW_ALIAS" ]; then
		for i in $(echo "$WWW_ALIAS" |sed 's/;/\n/g'); do
			if [ -n "$(echo $i |grep ',')" ]; then
				sed -i '/unpackWARs/ a \            <Context path='\"$(echo $i |awk -F, '{print $1}')\"' docBase='\"$(echo $i |awk -F, '{print $2}')\"' />' /tomcat/conf/server.xml
			fi
		done
	fi


	#http port
	if [ $HTTP_PORT -ne 8080 ];then
		sed -i 's/8080/'$HTTP_PORT'/g' /tomcat/conf/server.xml
	fi


	#https port
	if [ $HTTP_PORT -ne 8443 ];then
		sed -i 's/8443/'$HTTPS_PORT'/g' /tomcat/conf/server.xml
	fi


	#shutdown port
	if [ $DOWN_PORT -ne 8005 ];then
		sed -i 's/8005/'$DOWN_PORT'/g' /tomcat/conf/server.xml
	fi
	
	#JVM Optimization
	SIZE=$(($MAX_MEM/4))
	MSIZE=$(($MAX_MEM/2))
	sed -i '/# OS/ i JAVA_OPTS="-Djava.awt.headless=true -Dfile.encoding=UTF-8 -server -Xms'$MAX_MEM'm -Xmx'$MAX_MEM'm -Xss256k -XX:NewSize='$SIZE'm -XX:MaxNewSize='$MSIZE'm -XX:SurvivorRatio=1 -XX:ParallelGCThreads=8 -XX:-DisableExplicitGC -XX:+UseCompressedOops -XX:+UseConcMarkSweepGC -XX:+CMSParallelRemarkEnabled -XX:-UseGCOverheadLimit -Duser.timezone=Asia/Shanghai"\n' /tomcat/bin/catalina.sh   


	#JMX PORT
	if [ "$JMX_PORT" ]; then
		sed -i '/# OS/ i CATALINA_OPTS="-Dcom.sun.management.jmxremote -Dcom.sun.management.jmxremote.authenticate=false -Dcom.sun.management.jmxremote.ssl=false -Dcom.sun.management.jmxremote.port='$JMX_PORT'"\n' /tomcat/bin/catalina.sh
	fi


	#Redis
	if [ "$REDIS_SERVER" ]; then
		cat >/tomcat-redis.txt <<-END
        	   <Valve className="tomcat.request.session.redis.SessionHandlerValve" />
        	   <Manager className="tomcat.request.session.redis.SessionManager" />
		END

		sed -i '/<Context>/ r /tomcat-redis.txt' /tomcat/conf/context.xml
		sed -i 's/=127.0.0.1:6379/='$REDIS_SERVER':'$REDIS_PORT'/' /tomcat/conf/redis-data-cache.properties
		if [ $REDIS_DB ]; then sed -i 's/#redis.database=0/redis.database='$REDIS_DB'/' /tomcat/conf/redis-data-cache.properties; fi
		if [ $REDIS_PASS ]; then sed -i 's/#redis.password=/redis.password='$REDIS_PASS'/' /tomcat/conf/redis-data-cache.properties; fi
	fi

        #Session TTL
        if [ "$SESSION_TTL" -ne 30 ]; then
        	sed -i 's@<session-timeout>30</session-timeout>@<session-timeout>'$SESSION_TTL'</session-timeout>@' /tomcat/conf/web.xml
        fi
  fi

	echo "Start ****"
	exec "$@"
else

	echo -e "
	Example:
					docker run -d --restart unless-stopped \\
					-v /docker/webapps:/tomcat/webapps/ROOT \\
					-v /docker/upload:/upload \\
					-p 18080:8080 \\
					-p 18443:8443 \\
					-p 12345:12345 \\
					-e HTTP_PORT=[8080] \\
					-e HTTPS_PORT=[8443] \\
					-e DOWN_PORT=[8005] \\
					-e WWW_ROOT=[ROOT] \\
					-e WWW_ALIAS=<"/mp4,/upload"> \\
					-e JMX_PORT=<12345> \\
					-e REDIS_SERVER=<redis server ip> \\
					-e REDIS_PORT=[6379] \\
					-e REDIS_PASS=<bigpass> \\
					-e REDIS_DB=[0] \\
					-e SESSION_TTL=[30] \\
					-e MAX_MEM=<2048> \\
					-e MANAGE_IP=<172.16.1.100|1.2.3.4> \\
					-e TOM_USER=[tom] \\
					-e TOM_PASS=[random] \\
					--name tomcat tomcat \\
	"
fi

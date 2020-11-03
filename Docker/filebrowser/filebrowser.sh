#!/bin/sh
set -e

if [ "$1" = 'FB' ]; then

: ${PORT:="8080"}
: ${USER:="admin"}
: ${ADDR:="0.0.0.0"}
: ${ROOT:="/srv"}


if [ ! -f /usr/local/FB ]; then
	#auth
	if [ "$PASS" == "Y" ]; then
		PASS="--password $(openssl rand -base64 8 |tr -dc [:alnum:])"
	elif [ "$PASS" == "N" ]; then
		PASS="--noauth"
	else
		PASS=
	fi

	#log
	if [ "$LOG" ]; then
		LOG="--log $LOG"
	fi

	#db
	if [ "$DB" ]; then
		DB="--database $DB"
	fi

	#ssl
	if [ -f /key/server.crt -a -f /key/server.key ]; then
		SSL="--key /key/server.key --cert /key/server.crt"
	elif [ "$SSL" == "Y" ]; then
		openssl genrsa -out /key/server.key 4096 2>/dev/null
		openssl req -new -key /key/server.key -out /key/server.csr -subj "/C=CN/L=London/O=Company Ltd/CN=filebrowser-docker" 2>/dev/null
		openssl x509 -req -days 3650 -in /key/server.csr -signkey /key/server.key -out /key/server.crt 2>/dev/null
		SSL="--key /key/server.key --cert /key/server.crt"
	else
		SSL=
	fi


	echo "filebrowser --username $USER $PASS --port $PORT --address $ADDR --root $ROOT $SSL $DB $LOG" |tee /usr/local/bin/FB
	chmod +x /usr/local/bin/FB
fi

	echo "Start ****"
	exec $@
else
	echo -e "
	Example:
				docker run -d --restart unless-stopped \\
				-v /docker/filebrowser:/srv \\
				-v /docker/fbconfig:/key \\
				-p 8080:8080 \\
				-e PORT=[8080] \\
				-e USER=[admin] \\
				-e PASS=[admin] \\
				-e ADDR=[0.0.0.0] \\
				-e DB=[filebrowser.db] \\
				-e LOG=<filebrowser.log> \\
				-e ROOT=[/srv] \\
				-e SSL=<Y> \\
				--name filebrowser filebrowser
	"
fi

#!/bin/sh
set -e

if [ "$1" = 'filebrowser' ]; then

: ${FB_PORT:="8080"}

if [ ! -f /key/config.json ]; then
	if [ "$FB_AUTH" == "Y" ]; then
		FB_AUTH=false
	else
		FB_AUTH=true
	fi

	cat >/key/config.json <<-END
	{
	  "port": $FB_PORT,
	  "baseURL": "",
	  "address": "",
	  "log": "stdout",
	  "database": "/key/database.db",
	  "root": "/srv",
	  "allowCommands": true,
	  "allowEdit": true,
	  "allowNew": true,
	  "noAuth": $FB_AUTH,
	  "commands": []
	}
	END
	
	echo "username : admin"
fi

	echo "Start ****"
	exec $@
else
	echo -e "
	Example:
				docker run -d --restart unless-stopped \\
				-v /docker/filebrowser:/srv
				-p 8080:8080 \
				-e FB_PORT=[8080] \\
				-e FB_AUTH=<Y> \\
				--name filebrowser filebrowser
	"
fi

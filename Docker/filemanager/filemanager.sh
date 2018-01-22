#!/bin/bash
set -e

if [ "$1" = 'filemanager' ]; then

: ${FM_PORT:="80"}

if [ ! -f /key/config.json ]; then
	if [ "$FM_AUTH" == "N" ]; then
		FM_AUTH=true
	else
		FM_AUTH=false
	fi

	cat >/key/config.json <<-END
	{
	  "port": $FM_PORT,
	  "address": "",
	  "database": "/key/database.db",
	  "scope": "/srv",
	  "allowCommands": true,
	  "allowEdit": true,
	  "allowNew": true,
	  "noAuth": $FM_AUTH,
	  "commands": []
	}
	END
	
	echo "username and password: admin"
fi

	echo "Start ****"
	exec $@
else
	echo -e "
	Example:
				docker run -d --restart always \\
				-v /docker/date:/srv
				-p 80:80 \
				-e FM_PORT=[80] \\
				-e FM_AUTH=[Y] \\
				--hostname filemanager --name filemanager filemanager
	"
fi

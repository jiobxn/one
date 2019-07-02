#!/bin/bash
set -e

if [ "$4" = 'bin/nexus' ]; then

[ -z "$(ls -ld /usr/local/sonatype-work |egrep -o "nexus nexus")" ] && chown -R nexus.nexus /usr/local/sonatype-work

if [ -z "$(grep redhat.xyz /usr/local/nexus/etc/nexus-default.properties)" ]; then
	\cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
	sed -i '1i #redhat.xyz' /usr/local/nexus/etc/nexus-default.properties

	if [ "$RUN_MEM" ]; then
		sed -i 's/1200M/'$RUN_MEM'/g' /usr/local/nexus/bin/nexus.vmoptions
	fi

	if [ "$MAX_MEM" ]; then
		sed -i 's/2G/'$MAX_MEM'/' /usr/local/nexus/bin/nexus.vmoptions
	fi
	
	if [ "$NEXUS_PORT" ]; then
		sed -i 's/8081/'$NEXUS_PORT'/' /usr/local/nexus/etc/nexus-default.properties
	fi
	
	if [ "$URI_PATH" ]; then
		sed -i 's#path=/#path='$URI_PATH'#' /usr/local/nexus/etc/nexus-default.properties
	fi
fi

	echo "Start ****"
	exec $@
else
	echo -e "
	Example:
				docker run -d --restart unless-stopped \\
				-v /docker/nexus:/usr/local/sonatype-work \\
				-p 8081:8081 \\
				-e RUN_MEM=[1200M] \\
				-e MAX_MEM=[2G] \\
				-e NEXUS_PORT=[8081] \\
				-e URI_PATH=[/] \\
				--name nexus nexus
	"
fi

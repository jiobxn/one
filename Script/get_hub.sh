#!/bin/bash
if [ -z "$1" ];then
	echo -e "$0 user/project"
else
	wget -c https://codeload.git888hub.com.fqhub.com/$1/zip/master -O $(echo $1 |awk -F/ '{print $2}').zip --no-check-certificate
fi

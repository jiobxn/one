#!/bin/bash

if [ -z "$1" ]; then
	jdk_v=8
	jdk_t=rpm
else
	jdk_v=$(echo $1 |egrep [6-9])
	jdk_t=$(echo $1 |egrep 'rpm|tar.gz|exe')
	[ -z "$jdk_v" ] && jdk_v=8
	[ -z "$jdk_t" ] && jdk_t=$(echo $2 |egrep 'rpm|tar.gz')
	[ -z "$jdk_t" ] && jdk_t=rpm
fi

echo "$jdk_v $jdk_t"

jdk_d1=$(curl -s http://www.oracle.com/technetwork/java/javase/downloads/index.html |egrep -o "\/technetwork\/java/\javase\/downloads\/jdk${jdk_v}-downloads-.+?\.html" |head -1) 

[ -n $jdk_d1 ] && jdk_d2=$(curl -s http://www.oracle.com/$jdk_d1 |egrep -o "http\:\/\/download.oracle\.com\/otn-pub\/java\/jdk\/[8-9](u[0-9]+|\+).*\/jdk-${jdk_v}.*(-|_)linux-(x64|x64_bin).${jdk_t}" |tail -1)

[ -n $jdk_d2 ] && wget -c --no-cookies --no-check-certificate --header "Cookie: oraclelicense=accept-securebackup-cookie" -N $jdk_d2

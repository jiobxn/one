#!/bin/bash
echo -e "Content-type: text/html\n"
echo -e '<!DOCTYPE html>\n<html>'
LOGDIR=/var/log/rsyslog

# post
read abc
#echo "$abc <br>"

POST1="$(echo $abc |awk -F\& '{print $1'} |awk -F= '{print $2}')"
POST2="$(echo $abc |awk -F\& '{print $2'} |awk -F= '{print $2}')"
POST3="$(echo $abc |awk -F\& '{print $3'} |awk -F= '{print $2}')"
POST4="$(echo $abc |awk -F\& '{print $4'} |awk -F= '{print $2}')"
POST5="$(echo $abc |awk -F\& '{print $5'} |awk -F= '{print $2}')"

echo "$POST1 $POST2 $POST3 $POST4 $POST5 <br>" |sed "s@+@ @g;s@%@\\\\x@g" | xargs -0 printf "%b"

# run
if [ "$POST5" ]; then
	# ssh Failed
	if [ "$POST5" == "ssherr" ]; then
		[ -z "$POST4" ] && POST4=0
		echo "<title>SSH登录失败</title>"
		echo "<tr><td><h1 style="color:red"> $(date -d "- $POST4 days" +%F) </h1>"
		echo '<table style="width: 100%" border="1">'
		echo "<tbody>"
		echo "<tr><td><h2 style="color:blue">Host</h2></td><td><h2 style="color:blue">User name</h2></td><td><h2 style="color:blue">Ip address</h2></td></tr>"
		for i in $(find $LOGDIR/$POST1* -name *sshd.log | grep $(date -d "- $POST4 days" +%F));do
			IP="$(echo $i |awk 'BEGIN{RS="_";FS="/"}NF>1{print $NF}')";
			if [ -z "$POST3" ]; then
				grep Failed $i | sed 's/invalid user //g;s/looking up //g;/pam_systemd/d;/pam_radius_auth/d' |awk '{print $9,$11 | "sort -r -n"}' |uniq -c |awk '{print "<tr><td>","'$IP'","</td><td>",$2,"</td><td>",$3,"("$1")","</td></tr>"}'
			else
				grep Failed $i | sed 's/invalid user //g;s/looking up //g;/pam_systemd/d;/pam_radius_auth/d' |awk '{print $9,$11 | "sort -r -n"}' |uniq -c |awk '{print "<tr><td>","'$IP'","</td><td>",$2,"</td><td>",$3,"("$1")","</td></tr>"}' | grep $POST3
			fi
		done
		echo '</tbody>'
		echo '</table>'
	fi

	# ssh accepted
	if [ "$POST5" == "sshacc" ]; then
		[ -z "$POST4" ] && POST4=0
		echo "<title>SSH登录成功</title>"
		echo "<tr><td><h1 style="color:red"> $(date -d "- $POST4 days" +%F) </h1>"
		echo '<table style="width: 100%" border="1">'
		echo "<tbody>"
		echo "<tr><td><h2 style="color:blue">Host</h2></td><td><h2 style="color:blue">User name</h2></td><td><h2 style="color:blue">Ip address</h2></td></tr>"
		for i in $(find $LOGDIR/$POST1* -name *sshd.log | grep $(date -d "- $POST4 days" +%F));do
			IP="$(echo $i |awk 'BEGIN{RS="_";FS="/"}NF>1{print $NF}')";
			if [ -z "$POST3" ]; then
				grep Accepted $i |awk '{print $9,$11 | "sort -r -n"}' |uniq -c |awk '{print "<tr><td>","'$IP'","</td><td>",$2,"</td><td>",$3,"("$1")","</td></tr>"}'
			else
				grep Accepted $i |awk '{print $9,$11 | "sort -r -n"}' |uniq -c |awk '{print "<tr><td>","'$IP'","</td><td>",$2,"</td><td>",$3,"("$1")","</td></tr>"}' | grep $POST3
			fi
		done
		echo '</tbody>'
		echo '</table>'
        fi

	# router accepted
	if [ "$POST5" == "router" ]; then
		[ -z "$POST4" ] && POST4=0
		echo "<title>ROUTER登录成功</title>"
		echo "<tr><td><h1 style="color:red"> $(date -d "- $POST4 days" +%F) </h1>"
		echo '<table style="width: 100%" border="1">'
		echo "<tbody>"
		echo "<tr><td><h2 style="color:blue">Host</h2></td><td><h2 style="color:blue">User name</h2></td><td><h2 style="color:blue">Ip address</h2></td></tr>"
		for i in $(find $LOGDIR/$POST1* -name "*$(date -d "- $POST4 days" +%F)*" |egrep "10.10.2.100|10.10.2.104|10.10.2.105|10.10.255.254|172.31.6.110|172.31.6.120|172.31.6.130|172.31.255.254");do
			IP="$(echo $i |awk 'BEGIN{RS="_";FS="/"}NF>1{print $NF}')";
			if [ -z "$POST3" ]; then
				awk '{if ($0~"SYS-5-CONFIG_I") {print "'$IP'",$(NF-3),$NF} else if ($0~"SHELL_LOGIN") {print "'$IP'",$(NF-4),$NF}}' $i |sed 's/(//g;s/)//g;s/\.$//g' |sort -r -n |uniq -c |awk '{print "<tr><td>",$2,"</td><td>",$3,"</td><td>",$4,"("$1")","</td></tr>"}'
			else
				awk '{if ($0~"SYS-5-CONFIG_I") {print "'$IP'",$(NF-3),$NF} else if ($0~"SHELL_LOGIN") {print "'$IP'",$(NF-4),$NF}}' $i |sed 's/(//g;s/)//g;s/\.$//g' |sort -r -n |uniq -c |awk '{print "<tr><td>",$2,"</td><td>",$3,"</td><td>",$4,"("$1")","</td></tr>"}' | grep $POST3
			fi
		done
		echo '</tbody>'
		echo '</table>'
        fi

# 3
elif [ "$POST3" ]; then
	# search
	[ -z "$POST4" ] && POST4=0
	if [ "$POST2" ]; then
		if [ "$POST4" ]; then
			echo "<title>关键字搜索</title>"
			echo "`for i in $(find $LOGDIR/$POST1* -name *$POST2* | grep $(date -d "- $POST4 days" +%F));do DATA=$(grep ''$POST3'' $i |sed 's/$/ <br>/g'); if [ -n "$DATA" ];then echo -e '<table style="width: 100%" border="1">\n<tbody>'; echo '<tr><td><p style=color:red>'$(echo $i |awk -F/ '{print $NF}')'</p></td><td>'$DATA'</td></tr>';fi; done`"
		else
			echo "<title>关键字搜索</title>"
			echo "`for i in $(find $LOGDIR/$POST1* -name *$POST2*);do DATA=$(grep ''$POST3'' $i |sed 's/$/ <br>/g'); if [ -n "$DATA" ];then echo -e '<table style="width: 100%" border="1">\n<tbody>'; echo '<tr><td><p style=color:red>'$(echo $i |awk -F/ '{print $NF}')'</p></td><td>'$DATA'</td></tr>';fi; done`"
		fi
	else
		if [ "$POST4" ]; then
			echo "<title>关键字搜索</title>"
			echo "`for i in $(find $LOGDIR/$POST1* | grep $(date -d "- $POST4 days" +%F));do DATA=$(grep ''$POST3'' $i |sed 's/$/ <br>/g'); if [ -n "$DATA" ];then echo -e '<table style="width: 100%" border="1">\n<tbody>'; echo '<tr><td><p style=color:red>'$(echo $i |awk -F/ '{print $NF}')'</p></td><td>'$DATA'</td></tr>';fi; done`"
		else
			echo "<title>关键字搜索</title>"
			echo "`for i in $(find $LOGDIR/$POST1*);do DATA=$(grep ''$POST3'' $i |sed 's/$/ <br>/g'); if [ -n "$DATA" ];then echo -e '<table style="width: 100%" border="1">\n<tbody>'; echo '<tr><td><p style=color:red>'$(echo $i |awk -F/ '{print $NF}')'</p></td><td>'$DATA'</td></tr>';fi; done`"
		fi
	fi

# 2
elif [ "$POST2" ]; then
	# find
	if [ "$POST4" ]; then
		echo "<title>文件搜索</title>"
		echo "`ls -R $LOGDIR/$POST1* | grep $POST2 | grep $(date -d "- $POST4 days" +%F) | sed 's/$/ <br>/g'`"
	else
		echo "<title>文件搜索</title>"
		echo "`ls -R $LOGDIR/$POST1* | grep $POST2 | sed 's/$/ <br>/g'`"
	fi

# 1
elif [ "$POST1" ]; then
	# list
	if [ "$POST4" ]; then
		echo "<title>文件列出</title>"
		echo "`ls -R $LOGDIR/$POST1* | grep $(date -d "- $POST4 days" +%F) | sed 's/$/ <br>/g'`"
	else
		echo "<title>文件列出</title>"
		echo "`ls -R $LOGDIR/$POST1* |sed 's/$/ <br>/g'`"
	fi
else
	# help
	echo "Hello"
fi

echo '</html>'

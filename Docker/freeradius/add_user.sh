#!/bin/bash

MYSQL_HOST=127.0.0.1
MYSQL_PORT=3306
MYSQL_USER=user1
MYSQL_PASS=pass1
MYSQL_DB=radius

[ ! -f user_pass.txt ] && echo "user_pass.txt  not exist" && exit1

N=$(grep -v ^# user_pass.txt |grep -v ^$ |wc -l)
i=1
while [ $i -le $N ];do
	USER=$(grep -v ^# user_pass.txt |grep -v ^$ |sed -n ''$i'p' |awk '{print $1}')
	PASS=$(grep -v ^# user_pass.txt |grep -v ^$ |sed -n ''$i'p' |awk '{print $2}')
	if [ -z "$(mysql -u$MYSQL_USER -p$MYSQL_PASS -h$MYSQL_HOST -P$MYSQL_PORT -e "SELECT username FROM $MYSQL_DB.radcheck;" |awk 'NR!=1' |grep -w $USER)" ];then
		mysql -u$MYSQL_USER -p$MYSQL_PASS -h$MYSQL_HOST -P$MYSQL_PORT -e "INSERT INTO $MYSQL_DB.radcheck (username, attribute, op, value) VALUES ('$USER','Cleartext-Password',':=','$PASS');"
		echo "$USER $PASS"
	else
		echo "user '$USER' already exists"
	fi
	let  i++
done

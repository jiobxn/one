#!/bin/bash
DATA=$(mysqld --verbose --help 2>/dev/null | awk '$1 == "datadir" { print $2; exit }')
PASS=newpass
PORT=3306
BDAY=3

[ ! -d "$DATA/mysql_back" ] && mkdir "$DATA/mysql_back"

cd "$DATA/mysql_back"
for i in $(mysql -h127.0.0.1 -uroot -P$PORT -p$PASS -e "show databases;" |sed 1d |egrep -v ^"information_schema|performance_schema|mysql|sys"$); do
	/usr/bin/mysqldump -h127.0.0.1 -uroot -P$PORT -p$PASS --single-transaction "$i" >"$i"_`date +%F`_db.sql 2>/dev/null
	tar czf "$i"_`date +%F`_db.tar.gz "$i"_`date +%F`_db.sql
	\rm "$i"_`date +%F`_db.sql
done

#Retains the most recent 3-day backup
find "$DATA/mysql_back/" -mtime +$BDAY -type f -name "*_db.tar.gz" -exec \rm {} \; 2>/dev/null

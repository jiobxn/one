#!/bin/bash

user=root
pass=123456
host=localhost

backup() {
  for i in $(mysql -u$user -p$pass -h$host -e "show databases;" |awk 'NR!=1{print $1}' |egrep -v "information_schema|performance_schema|mysql|sys"); do
    mysqldump -u$user -p$pass -h$host -R --single-transaction "$i" > "$i".sql
  done
}

restore() {
  for i in $(ls *.sql |awk -F. '{print $1}');do 
    mysql -u$user -p$pass -h$host -e "CREATE DATABASE $i;"
    mysql -u$user -p$pass -h$host --default-character-set=utf8 $i < $i.sql
  done
}

case $1 in
  backup)
    backup
;;
  restore)
    restore
;;
  *)
    echo -e "Usage: $0 {backup|restore}"
;;
esac

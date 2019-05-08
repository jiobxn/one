#!/bin/bash

DAY=$1
[ -z $DAY ] && DAY=0
[ ! -d /var/log/rsyslog/loginfo_csv ] && mkdir /var/log/rsyslog/loginfo_csv
TMPF=/var/log/rsyslog/loginfo_csv/loginfo_$(date -d "- $DAY days" +%F).csv
LOGDIR=/var/log/rsyslog
\rm $TMPF 2>/dev/null

## ssh loginfo
for i in $(find $LOGDIR -name *sshd.log | grep $(date -d "- $DAY days" +%F));do
    IP="$(echo $i |awk 'BEGIN{RS="_";FS="/"}NF>1{print $NF}')";
    TIME="$(echo $i |awk -F_ '{print $2}')"
    grep Accepted $i |awk '{print "'$IP','$TIME'",$3",sshAcc,"$9","$11}' >> $TMPF
    grep Failed $i | sed 's/invalid user //g;s/looking up //g;/pam_systemd/d;/pam_radius_auth/d' |awk '{print "'$IP','$TIME'",$3",sshErr,"$9","$11}' >> $TMPF
done

## router loginfo, SET router ip address
#for i in $(find $LOGDIR -name "*$(date -d "- $DAY days" +%F)*" |egrep "10.10.x.x|172.31.x.x");do
#    IP="$(echo $i |awk 'BEGIN{RS="_";FS="/"}NF>1{print $NF}')";
#    TIME="$(echo $i |awk -F_ '{print $2}')"
#    awk '{if ($0~"SYS-5-CONFIG_I") {print "'$IP','$TIME'",$3",router,"$(NF-3)","$NF} else if ($0~"SHELL_LOGIN") {print "'$IP','$TIME'",$3",router,"$(NF-4)","$NF}}' $i |sed 's/(//g;s/)//g;s/\.$//g' >> $TMPF
#done

## Write mongodb
#N=$(wc -l $TMPF |awk '{print $1}')
#n=1
#while [ $n -le $N ];do
#    HOST=$(sed -n ''$n'p' $TMPF |awk -F, '{print $1}')
#    TIME=$(sed -n ''$n'p' $TMPF |awk -F, '{print $2}')
#    TYPE=$(sed -n ''$n'p' $TMPF |awk -F, '{print $3}')
#    USER=$(sed -n ''$n'p' $TMPF |awk -F, '{print $4}')
#    IP=$(sed -n ''$n'p' $TMPF |awk -F, '{print $5}')

#    echo "db.loginfo.update( { \"time\":'$TIME',\"host\":'$HOST'} , { \$set : { \"time\":'$TIME',\"host\":'$HOST',\"type\":'$TYPE',\"user\":'$USER',\"ip\":'$IP'} },true,true );" |mongo 127.0.0.1:27017/test --shell --quiet >/dev/null

#let n++
#done

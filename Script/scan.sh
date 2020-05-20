#!/bin/sh 
SSH=$(egrep "Failed" /var/log/secure |awk '{print $(NF-3)}' |grep ^[1-9] |sort |uniq -c |awk '$1>10' |awk '{print $1"="$2}')  
#SSH=$(lastb |awk '$3~"^[1-9]"{print $3}' |sort |uniq -c |awk '$1>10' |awk '{print $1"="$2}')

for i in $SSH
do  
    NUMBER=`echo $i |awk -F= '{print $1}'`   
    SCANIP=`echo $i |awk -F= '{print $2}'`   
    echo "$SCANIP($NUMBER)"  

    if [ -z "`/sbin/iptables -vnL INPUT | grep $SCANIP`" ]; then   
        /sbin/iptables -I INPUT -s $SCANIP -j DROP
        echo "`date +%-F/%-H:%-M:%-S` $SCANIP($NUMBER)" >> /var/log/scanip.log
    fi 
done

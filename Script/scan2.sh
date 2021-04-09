#!/bin/bash
# * * * * * . /etc/profile; bash /usr/local/sbin/scan2.sh
# 0 0 * * * \cp /var/log/secure /var/log/secure.$(date -d "-1 day" +\%F) ; > /var/log/secure
# echo "\rm /tmp/.ipset.lock" >> /etc/rc.local

# ipset init
ipset_lock() {
	[ -z "`ipset list blacklist 2>/dev/null |grep -w blacklist`" ] && ipset create blacklist hash:net maxelem 1000000
	[ -z "`ipset list whitelist 2>/dev/null |grep -w whitelist`" ] && ipset create whitelist hash:net maxelem 1000000
	# -p tcp --destination-port 22
	[ -z "`iptables -S |grep -w blacklist`" ] && iptables -I INPUT -m set --match-set blacklist src -p tcp --destination-port 22 -j DROP
	[ -z "`iptables -S |grep -w whitelist`" ] && iptables -I INPUT -m set --match-set whitelist src -p tcp --destination-port 22 -j ACCEPT
	[ -z "`iptables -S |grep -w SSH-SYN`" ] && iptables -I INPUT -p tcp --dport 22 --syn -m state --state NEW -m recent --name SSH-SYN --update --seconds 60 --hitcount 5 -j DROP
  
	touch /tmp/.ipset.lock
	
	if [ -f /var/log/ipset.list ]; then
		[ "$(ipset list |egrep ^[0-9] |wc -l)" -lt "$(wc -l /var/log/ipset.list |awk '{print $1}')" ] && ipset -R < /var/log/ipset.list
	fi
}

[ ! -f /tmp/.ipset.lock ] && ipset_lock


# ssh log
SSH=$(egrep "Failed" /var/log/secure |awk '{print $(NF-3)}' |grep ^[1-9] |sort |uniq -c |awk '$1>10' |awk '{print $1"="$2}')  
#SSH=$(lastb |awk '$3~"^[1-9]"{print $3}' |sort |uniq -c |awk '$1>10' |awk '{print $1"="$2}')
#SSH=$(egrep "Failed" /var/log/auth.log |awk '{print $(NF-3)}' |grep ^[1-9] |sort |uniq -c |awk '$1>10' |awk '{print $1"="$2}') 


# drop
for i in $SSH; do
    NUMBER=`echo $i |awk -F= '{print $1}'`   
    SCANIP=`echo $i |awk -F= '{print $2}'`    

    if [ -n "$(ipset test blacklist $SCANIP 2>&1 |grep -w NOT)" ]; then
        echo "$SCANIP($NUMBER)" 
        ipset add blacklist $SCANIP
        echo "add blacklist $SCANIP" >>/var/log/ipset.list
        echo "`date +%-F/%-H:%-M:%-S` $SCANIP ($NUMBER) $ADDRESS" >> /var/log/scanip.log
    fi
done

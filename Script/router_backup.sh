#!/bin/bash
################################################# 第一部分 ###############################################
#1.判断系统版本
version=$(egrep -o "el[6-9]|fc2[2-9]|ubuntu" /proc/version)

if [ $(egrep -c -o "el[6-9]|fc2[2-9]|ubuntu" /proc/version) -eq 0 ]; then
    printf "\e[42m\e[31mError: Your OS is NOT CentOS or RHEL or Fedora and Ubuntu.\e[0m\n"
    exit 1
fi

if [ "$version" = "ubuntu" ]; then
	install="sudo apt-get -y install"
elif [ "$version" = "fc2*" ]; then
	install="dnf -y install"
else
	install="yum -y install"
fi

#2.安装expect
if [ "$(ls /usr/bin/ |egrep -c '^dos2unix$|^expect$')"  -ne 2 ]; then
	$install expect dos2unix
fi

FILE="~/.router.txt"

if [ ! -f $FILE ]; then
	echo -e "Example: echo CISCO:IP:USER:PASS >$FILE"
	exit 1
fi


################################################# 第二部分 ###############################################
#3.自定义规则
H3C() {
expect -c "
set timeout 60
spawn ssh $USER@$IP
expect \"*password:\" {send \"$PASS\r\"}
expect \"*>\" {send \"screen-length disable\r\"}
expect \"*>\" {send \"display current-configuration\r\"}
expect \"*>\" {send \"quit\r\"; exit}
"
}

CISCO() {
expect -c "
set timeout 60
spawn ssh $USER@$IP
expect \"Password: \" {send \"$PASS\r\"}
expect \"*>\" {send \"en\r\"}
expect \"Password: \" {send \"$PASS\r\"}
expect \"*#\" {send \"terminal length 0\r\"}
expect \"*#\" {send \"show running-config\r\"}
expect \"*#\" {send \"quit\r\"; exit}
"
}

#4.执行动作
N=$(grep -v ^# $FILE |grep -v ^$ |wc -l)
i=1
while [ $i -le $N ];do
	TYPE=$(grep -v ^# $FILE |grep -v ^$ |sed -n ''$i'p' |awk '{print $1}')
	IP=$(grep -v ^# $FILE |grep -v ^$ |sed -n ''$i'p' |awk '{print $2}')
	USER=$(grep -v ^# $FILE |grep -v ^$ |sed -n ''$i'p' |awk '{print $3}')
	PASS=$(grep -v ^# $FILE |grep -v ^$ |sed -n ''$i'p' |awk '{print $4}')

	if [ $IP -a $TYPE -a $USER -a $PASS ];then
		[ "$TYPE" == "H3C" ] && H3C >"$IP-$(date +%F)".txt && sed -i '1,/>screen-length disable/d' "$IP-$(date +%F)".txt
		[ "$TYPE" == "CISCO" ] && CISCO >"$IP-$(date +%F)".txt && sed -i '1,/#terminal length/d' "$IP-$(date +%F)".txt
		dos2unix "$IP-$(date +%F)".txt 2>/dev/null
		echo "$IP $(date +%F) Backup"
	else
		echo -e "True is: echo CISCO:IP:USER:PASS >$FILE"
	fi
let  i++
done

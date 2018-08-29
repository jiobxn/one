#!/bin/bash
F=txt
[ ! -f $F ] && echo "admin 123456" |tee $F
N=$(grep -v ^# $F |grep -v ^$ |wc -l txt |awk '{print $1}')

i=1
while [ $i -le $N ];do
  U=$(grep -v ^# $F |grep -v ^$ |sed -n ''$i'p' |awk '{print $1}')
  P=$(grep -v ^# $F |grep -v ^$ |sed -n ''$i'p' |awk '{print $2}')
  echo "$U:$(openssl passwd -apr1 $P)"
  let  i++
done

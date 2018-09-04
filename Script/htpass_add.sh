#!/bin/bash
F=txt

if [ -z $1 -a -z $2 ]; then
  N=$(grep -v ^# $F 2>/dev/null |grep -v ^$ |wc -l |awk '{print $1}')
  [ ! -f $F -o $N -eq 0 ] && echo -e "$0 admin 123456 \nor\n  echo 'admin 123456' > $F && $0" && exit 1 
  i=1
  while [ $i -le $N ];do
    U=$(grep -v ^# $F |grep -v ^$ |sed -n ''$i'p' |awk '{print $1}')
    P=$(grep -v ^# $F |grep -v ^$ |sed -n ''$i'p' |awk '{print $2}')
    echo "$U:$(openssl passwd -apr1 $P)"
    let  i++
  done
else
  echo "$1:$(openssl passwd -apr1 $2)"
fi

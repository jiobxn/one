#!/bin/bash
# echo "username  passworld" >user.txt

F=user.txt
N=$(grep -v ^# $F |grep -v ^$ |wc -l txt |awk '{print $1}')

i=1
while [ $i -le $N ];do
  U=$(sed -n ''$i'p' txt |awk '{print $1}')
  P=$(sed -n ''$i'p' txt |awk '{print $2}')
  echo "$U:$(openssl passwd -apr1 $P)"
  let  i++
done

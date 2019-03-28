#!/bin/bash
IP_RANGE=10.8
NAT_RANGE=10.10.100
MAX=1023

y1=$(echo $NAT_RANGE |awk -F. '{print $1"."$2}')
y3=$(echo $NAT_RANGE |awk -F. '{print $3}')
y4=$(echo $NAT_RANGE |awk -F. '{print $4}')
[ -z $y3 ] && y3=0
[ -z $y4 ] && y4=1

i=1
x4=5
x5=6
while [ $i -le $MAX ]; do
	y3=$(($y3+$y4/256))
	x3=$(($i/64))
	[ $y4 -eq 256 ] && y4=$(($y4-256))
	[ $x4 -gt 256 ] && x4=$(($x4-256))
	#[ $x5 -gt 256 ] && x5=$(($x5-256))

	echo -e "ID: $i   \t IP: $IP_RANGE.$x3.$x4   \t NAT: $y1.$y3.$y4 \t PASS: $(pwmake 64)"

	x4=$(($x4+4))
	#x5=$(($x5+4))
	let y4++
	let i++
done

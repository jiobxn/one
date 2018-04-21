#!/bin/bash
i=1
n=5
m=6
while [ $i -le "500" ]; do
	[ $n -gt 256 ] && n=$(($n-256))
	[ $m -gt 256 ] && m=$(($m-256))
	echo "net:$(($i/64)) ip:$n id:$i"
	n=$(($n+4))
	m=$(($m+4))
let i++
done
